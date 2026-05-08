"""
Sigma rule evaluation engine — Detect stage of the WFTAF pipeline.

Loads Sigma rules from the /Rules directory and evaluates each OssemRecord
against the detection logic defined in the rule's `detection` block.

Supported Sigma constructs:
  - Field modifiers : |contains, |startswith, |endswith, |re
  - Value types     : string, list (OR logic), null check
  - Condition atoms : selection, filter (AND/NOT composition)
  - Condition syntax: 'selection', 'selection and not filter'

Sigma specification: https://sigmahq.io/docs/basics/rules.html
"""

from __future__ import annotations

import re
import logging
import yaml
from dataclasses import dataclass
from pathlib import Path

from .schema import OssemRecord

logger = logging.getLogger(__name__)


@dataclass
class DetectionResult:
    rule_id: str
    title: str
    level: str
    technique_id: str
    matched_field: str
    matched_value: str
    artefact_type: str


class SigmaEngine:
    """
    Lightweight Sigma rule evaluation engine targeting persistence detection.

    Usage::

        engine     = SigmaEngine(Path("Rules"))
        detections = engine.evaluate(ossem_records)
    """

    def __init__(self, rules_dir: Path) -> None:
        self.rules = self._load_rules(rules_dir)
        logger.info('Loaded %d Sigma rules from %s', len(self.rules), rules_dir)

    def evaluate(self, records: list[OssemRecord]) -> list[DetectionResult]:
        """Evaluate all records against all loaded rules, returning every match."""
        results: list[DetectionResult] = []
        for record in records:
            for rule in self.rules:
                result = self._evaluate_rule(rule, record)
                if result:
                    results.append(result)
        return results

    # ------------------------------------------------------------------
    # Rule loading
    # ------------------------------------------------------------------

    def _load_rules(self, rules_dir: Path) -> list[dict]:
        rules: list[dict] = []
        for rule_path in sorted(rules_dir.glob('*.yml')):
            try:
                with rule_path.open(encoding='utf-8') as fh:
                    rule = yaml.safe_load(fh)
                if rule and isinstance(rule.get('detection'), dict):
                    rules.append(rule)
                else:
                    logger.warning('Skipping %s — no valid detection block', rule_path.name)
            except yaml.YAMLError as exc:
                logger.warning('Skipping malformed rule %s: %s', rule_path.name, exc)
        return rules

    # ------------------------------------------------------------------
    # Rule evaluation
    # ------------------------------------------------------------------

    def _evaluate_rule(self, rule: dict, record: OssemRecord) -> DetectionResult | None:
        detection  = rule.get('detection', {})
        condition  = detection.get('condition', 'selection')

        # Build named selection results — each named key is evaluated independently
        selections: dict[str, bool] = {}
        for key, criteria in detection.items():
            if key == 'condition' or not isinstance(criteria, dict):
                continue
            field, value = self._evaluate_selection(criteria, record)
            selections[key] = bool(field)

        # Parse the condition string into a boolean result
        matched = self._resolve_condition(condition, selections)
        if not matched:
            return None

        # Find which selection produced the match for reporting
        matched_field, matched_value = '', ''
        for key, criteria in detection.items():
            if key == 'condition' or not isinstance(criteria, dict):
                continue
            if selections.get(key):
                matched_field, matched_value = self._evaluate_selection(criteria, record)
                break

        tags       = rule.get('tags', [])
        technique  = next(
            (t.replace('attack.', '').upper() for t in tags if re.match(r'attack\.t\d', t, re.I)),
            '',
        )

        return DetectionResult(
            rule_id=rule.get('id', ''),
            title=rule.get('title', ''),
            level=rule.get('level', 'medium'),
            technique_id=technique,
            matched_field=matched_field,
            matched_value=matched_value,
            artefact_type=record.artefact_type or '',
        )

    def _resolve_condition(self, condition: str, selections: dict[str, bool]) -> bool:
        """
        Resolve a Sigma condition string against a dict of named selection results.
        Handles: 'selection', 'selection and not filter', 'filter and not selection', etc.
        """
        condition = condition.strip().lower()

        # Tokenise: split on ' and ', ' or ', ' not '
        # Simple recursive descent for the subset of Sigma conditions we support
        if ' and not ' in condition:
            parts = condition.split(' and not ', 1)
            return self._resolve_condition(parts[0], selections) and \
                   not self._resolve_condition(parts[1], selections)

        if ' and ' in condition:
            parts = condition.split(' and ', 1)
            return self._resolve_condition(parts[0], selections) and \
                   self._resolve_condition(parts[1], selections)

        if ' or ' in condition:
            parts = condition.split(' or ', 1)
            return self._resolve_condition(parts[0], selections) or \
                   self._resolve_condition(parts[1], selections)

        if condition.startswith('not '):
            return not self._resolve_condition(condition[4:], selections)

        return selections.get(condition.strip(), False)

    # ------------------------------------------------------------------
    # Selection evaluation
    # ------------------------------------------------------------------

    def _evaluate_selection(self, criteria: dict, record: OssemRecord) -> tuple[str, str]:
        """
        Evaluate a single selection block against a record.
        Returns (matched_field, matched_value) on first match, or ('', '') on no match.
        All criteria in the block must match (AND logic across fields).
        """
        last_match: tuple[str, str] = ('', '')

        for field_expr, expected in criteria.items():
            field_name, *modifiers = field_expr.split('|')
            record_value = getattr(record, field_name, None)

            if record_value is None:
                return '', ''

            values = expected if isinstance(expected, list) else [expected]
            field_matched = False

            for val in values:
                if val is None:
                    # null check — matches if the field is absent or empty
                    if not record_value:
                        field_matched = True
                        last_match = (field_name, '')
                    continue

                rv   = str(record_value)
                sv   = str(val)
                mods = set(modifiers)

                if 're' in mods:
                    hit = bool(re.search(sv, rv, re.IGNORECASE))
                elif 'contains' in mods:
                    hit = sv.lower() in rv.lower()
                elif 'startswith' in mods:
                    hit = rv.lower().startswith(sv.lower())
                elif 'endswith' in mods:
                    hit = rv.lower().endswith(sv.lower())
                else:
                    hit = rv.lower() == sv.lower()

                if hit:
                    field_matched = True
                    last_match = (field_name, rv)
                    break

            if not field_matched:
                return '', ''

        return last_match
