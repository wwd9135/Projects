"""
OSSEM normalisation layer — Transform stage of the WFTAF pipeline.

Responsibilities:
  1. Load and validate the raw JSON payload emitted by collector_main.ps1
  2. Parse each artefact section into typed dataclasses (schema.py)
  3. Flatten each artefact to an OssemRecord for Sigma rule evaluation

Field names in OssemRecord follow the OSSEM standard:
  https://github.com/OTRF/OSSEM
Alignment ensures Sigma rules that reference Image, CommandLine,
TargetObject, etc. evaluate correctly without field remapping.
"""

from __future__ import annotations

import json
import re
import logging
from pathlib import Path

from .schema import (
    ScanMeta,
    PersistenceArtefacts,
    OssemRecord,
    RegistryRunKey,
    ScheduledTask,
    WindowsService,
    WmiSubscription,
)

logger = logging.getLogger(__name__)

# Matches the first quoted or unquoted executable path in a command-line string
_IMAGE_RE = re.compile(
    r'"([A-Za-z]:\\[^"]+\.(?:exe|dll|bat|cmd|vbs|ps1))"|'
    r'([A-Za-z]:\\[^\s"]+\.(?:exe|dll|bat|cmd|vbs|ps1))',
    re.IGNORECASE,
)


class Normaliser:
    """
    Loads a collector payload and produces OSSEM-normalised records.

    Usage::

        normaliser = Normaliser()
        artefacts  = normaliser.load(Path("Output/payload.json"), payload_sha256=stored_hash)
        records    = normaliser.to_ossem(artefacts)
    """

    def load(self, payload_path: Path, payload_sha256: str = '') -> PersistenceArtefacts:
        """Parse a collector JSON payload into typed artefact dataclasses."""
        with payload_path.open(encoding='utf-8') as fh:
            raw = json.load(fh)

        meta = self._parse_meta(raw.get('Meta', {}), payload_sha256)

        payload = raw.get('Payload', {})
        artefacts = PersistenceArtefacts(
            meta=meta,
            registry_run_keys=self._parse_run_keys(payload.get('RegistryRunKeys', [])),
            scheduled_tasks=self._parse_scheduled_tasks(payload.get('ScheduledTasks', [])),
            services=self._parse_services(payload.get('Services', [])),
            wmi_subscriptions=self._parse_wmi(payload.get('WmiSubscriptions', [])),
        )

        logger.debug(
            'Loaded payload: %d run keys, %d tasks, %d services, %d WMI subs',
            len(artefacts.registry_run_keys),
            len(artefacts.scheduled_tasks),
            len(artefacts.services),
            len(artefacts.wmi_subscriptions),
        )
        return artefacts

    def to_ossem(self, artefacts: PersistenceArtefacts) -> list[OssemRecord]:
        """Flatten all artefact types to a list of OssemRecords for rule evaluation."""
        records: list[OssemRecord] = []
        records.extend(self._run_key_to_ossem(rk) for rk in artefacts.registry_run_keys)
        records.extend(self._task_to_ossem(t)      for t  in artefacts.scheduled_tasks)
        records.extend(self._service_to_ossem(s)   for s  in artefacts.services)
        records.extend(self._wmi_to_ossem(w)        for w  in artefacts.wmi_subscriptions)
        return records

    # ------------------------------------------------------------------
    # Internal parsers — raw dict → typed dataclass
    # ------------------------------------------------------------------

    def _parse_meta(self, raw: dict, sha256: str) -> ScanMeta:
        return ScanMeta(
            computer_name=raw.get('ComputerName', ''),
            username=raw.get('Username', ''),
            domain=raw.get('Domain', ''),
            timestamp_utc=raw.get('TimestampUtc', ''),
            collector_version=raw.get('CollectorVersion', ''),
            payload_sha256=sha256,
        )

    def _parse_run_keys(self, raw_list: list[dict]) -> list[RegistryRunKey]:
        results = []
        for entry in raw_list:
            results.append(RegistryRunKey(
                hive=entry.get('Hive', ''),
                key_path=entry.get('KeyPath', ''),
                value_name=entry.get('ValueName', ''),
                value_data=entry.get('ValueData', ''),
                value_type=entry.get('ValueType', ''),
                collected_at=entry.get('CollectedAt', ''),
            ))
        return results

    def _parse_scheduled_tasks(self, raw_list: list[dict]) -> list[ScheduledTask]:
        results = []
        for entry in raw_list:
            results.append(ScheduledTask(
                task_name=entry.get('TaskName', ''),
                task_path=entry.get('TaskPath', ''),
                state=entry.get('State', ''),
                description=entry.get('Description'),
                author=entry.get('Author'),
                run_as_user=entry.get('RunAsUser'),
                run_level=entry.get('RunLevel'),
                action_path=entry.get('ActionPath'),
                action_arguments=entry.get('ActionArguments'),
                action_work_dir=entry.get('ActionWorkDir'),
                action_hash=entry.get('ActionHash'),
                trigger_types=entry.get('TriggerTypes') or [],
                last_run_time=entry.get('LastRunTime'),
                next_run_time=entry.get('NextRunTime'),
                last_task_result=entry.get('LastTaskResult'),
                collected_at=entry.get('CollectedAt', ''),
            ))
        return results

    def _parse_services(self, raw_list: list[dict]) -> list[WindowsService]:
        results = []
        for entry in raw_list:
            results.append(WindowsService(
                name=entry.get('Name', ''),
                display_name=entry.get('DisplayName', ''),
                description=entry.get('Description'),
                binary_path=entry.get('BinaryPath', ''),
                dll_path=entry.get('DllPath'),
                start_mode=entry.get('StartMode', ''),
                state=entry.get('State', ''),
                run_as=entry.get('RunAs', ''),
                process_id=entry.get('ProcessId'),
                binary_hash=entry.get('BinaryHash'),
                collected_at=entry.get('CollectedAt', ''),
            ))
        return results

    def _parse_wmi(self, raw_list: list[dict]) -> list[WmiSubscription]:
        results = []
        for entry in raw_list:
            results.append(WmiSubscription(
                filter_name=entry.get('FilterName'),
                filter_query=entry.get('FilterQuery'),
                filter_query_language=entry.get('FilterQueryLanguage'),
                consumer_name=entry.get('ConsumerName'),
                consumer_type=entry.get('ConsumerType'),
                consumer_command=entry.get('ConsumerCommand'),
                consumer_script=entry.get('ConsumerScript'),
                namespace=entry.get('Namespace', 'root\\subscription'),
                collected_at=entry.get('CollectedAt', ''),
            ))
        return results

    # ------------------------------------------------------------------
    # OSSEM mappers — typed dataclass → OssemRecord
    # ------------------------------------------------------------------

    def _run_key_to_ossem(self, rk: RegistryRunKey) -> OssemRecord:
        return OssemRecord(
            Image=self._extract_image(rk.value_data),
            CommandLine=rk.value_data,
            TargetObject=f'{rk.hive}\\{rk.key_path}\\{rk.value_name}',
            Details=rk.value_data,
            technique_id=rk.technique,
            technique_name='Boot or Logon Autostart Execution: Registry Run Keys',
            artefact_type='registry_run_key',
        )

    def _task_to_ossem(self, task: ScheduledTask) -> OssemRecord:
        command_line = task.action_path
        if task.action_arguments:
            command_line = f'{task.action_path} {task.action_arguments}'.strip()

        return OssemRecord(
            Image=task.action_path,
            CommandLine=command_line,
            technique_id=task.technique,
            technique_name='Scheduled Task/Job: Scheduled Task',
            artefact_type='scheduled_task',
            action_hash=task.action_hash,
        )

    def _service_to_ossem(self, svc: WindowsService) -> OssemRecord:
        image = self._extract_image(svc.binary_path) or svc.binary_path
        return OssemRecord(
            Image=image,
            CommandLine=svc.binary_path,
            technique_id=svc.technique,
            technique_name='Create or Modify System Process: Windows Service',
            artefact_type='service',
            action_hash=svc.binary_hash,
        )

    def _wmi_to_ossem(self, wmi: WmiSubscription) -> OssemRecord:
        return OssemRecord(
            CommandLine=wmi.consumer_command or wmi.consumer_script,
            consumer_type=wmi.consumer_type,
            filter_query=wmi.filter_query,
            technique_id=wmi.technique,
            technique_name='Event Triggered Execution: WMI Event Subscription',
            artefact_type='wmi_subscription',
        )

    @staticmethod
    def _extract_image(command_line: str | None) -> str | None:
        if not command_line:
            return None
        match = _IMAGE_RE.search(command_line)
        if match:
            return match.group(1) or match.group(2)
        return None
