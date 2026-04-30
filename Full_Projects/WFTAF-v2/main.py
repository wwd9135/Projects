"""
WFTAF-v2 — Windows Forensic Triage & Analysis Framework
Pipeline entry point: integrity check → normalise → detect → report
"""

from __future__ import annotations

import json
import hashlib
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path

from Engine.normalise import Normaliser
from Engine.sigma_engine import SigmaEngine, DetectionResult

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s  %(levelname)-8s  %(message)s',
    datefmt='%H:%M:%S',
)
logger = logging.getLogger('wftaf')

PAYLOAD_PATH = Path('Output/payload.json')
HASH_PATH    = Path('Output/payload.hash')
RULES_DIR    = Path('Rules')
REPORT_DIR   = Path('Output')


def verify_integrity(payload_path: Path, stored_sha256: str) -> bool:
    with payload_path.open('rb') as fh:
        computed = hashlib.file_digest(fh, 'sha256').hexdigest().upper()
    if computed != stored_sha256.upper():
        logger.warning('SHA-256 mismatch — payload may have been modified after collection.')
        logger.warning('  Stored  : %s', stored_sha256.upper())
        logger.warning('  Computed: %s', computed)
        return False
    return True


def write_report(detections: list[DetectionResult], meta: dict, output_dir: Path) -> Path:
    timestamp   = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    report_path = output_dir / f'detections_{timestamp}.json'

    by_level = {'critical': [], 'high': [], 'medium': [], 'low': []}
    for d in detections:
        by_level.setdefault(d.level, []).append(d)

    report = {
        'generated_at': timestamp,
        'host': meta,
        'summary': {
            'total': len(detections),
            'by_level': {lvl: len(items) for lvl, items in by_level.items()},
        },
        'detections': [
            {
                'rule_id':       d.rule_id,
                'title':         d.title,
                'level':         d.level,
                'technique_id':  d.technique_id,
                'artefact_type': d.artefact_type,
                'matched_field': d.matched_field,
                'matched_value': d.matched_value,
            }
            for d in detections
        ],
    }

    report_path.write_text(json.dumps(report, indent=2), encoding='utf-8')
    return report_path


def main() -> None:
    logger.info('WFTAF-v2 — persistence detection pipeline')
    logger.info('')

    if not PAYLOAD_PATH.exists():
        logger.error('Payload not found at %s', PAYLOAD_PATH)
        logger.error("Run '.\\Modules\\collector_main.ps1' first (requires admin).")
        sys.exit(1)

    # 1 — Integrity verification
    if HASH_PATH.exists():
        stored = json.loads(HASH_PATH.read_text(encoding='utf-8')).get('PayloadSHA256', '')
        if stored:
            ok = verify_integrity(PAYLOAD_PATH, stored)
            logger.info('Integrity check: %s', 'PASS' if ok else 'WARN — hash mismatch')
        else:
            logger.info('Integrity check: skipped (no hash stored)')
    else:
        logger.info('Integrity check: skipped (no hash file found)')

    # 2 — Normalise
    logger.info('Normalising payload...')
    stored_hash = ''
    if HASH_PATH.exists():
        stored_hash = json.loads(HASH_PATH.read_text(encoding='utf-8')).get('PayloadSHA256', '')

    normaliser = Normaliser()
    artefacts  = normaliser.load(PAYLOAD_PATH, payload_sha256=stored_hash)
    records    = normaliser.to_ossem(artefacts)

    logger.info(
        '  %d OSSEM records produced  (%d run keys, %d tasks, %d services, %d WMI subs)',
        len(records),
        len(artefacts.registry_run_keys),
        len(artefacts.scheduled_tasks),
        len(artefacts.services),
        len(artefacts.wmi_subscriptions),
    )

    # 3 — Detect
    logger.info('Running Sigma detection engine...')
    engine     = SigmaEngine(RULES_DIR)
    detections = engine.evaluate(records)
    logger.info('  %d detection(s) fired', len(detections))

    if detections:
        logger.info('')
        for d in sorted(detections, key=lambda x: ('critical', 'high', 'medium', 'low').index(x.level)):
            logger.info('  [%-8s] %-55s  %s', d.level.upper(), d.title, d.technique_id)
        logger.info('')

    # 4 — Report
    REPORT_DIR.mkdir(exist_ok=True)
    report_path = write_report(
        detections,
        meta={
            'computer_name':  artefacts.meta.computer_name,
            'username':       artefacts.meta.username,
            'domain':         artefacts.meta.domain,
            'timestamp_utc':  artefacts.meta.timestamp_utc,
            'payload_sha256': artefacts.meta.payload_sha256,
        },
        output_dir=REPORT_DIR,
    )
    logger.info('Report written to %s', report_path)


if __name__ == '__main__':
    main()
