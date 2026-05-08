"""
Data models for WFTAF persistence artefacts and OSSEM-normalised output.

Artefact dataclasses mirror the JSON emitted by each PowerShell collector module.
OssemRecord is the flattened, field-normalised representation consumed by the
Sigma detection engine — field names align with the OSSEM standard so that
Sigma rules port directly without modification.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class ScanMeta:
    computer_name: str
    username: str
    domain: str
    timestamp_utc: str
    collector_version: str
    payload_sha256: str


# ---------------------------------------------------------------------------
# Raw artefact types — mirroring PowerShell collector output
# ---------------------------------------------------------------------------

@dataclass
class RegistryRunKey:
    hive: str
    key_path: str
    value_name: str
    value_data: str
    value_type: str
    collected_at: str
    technique: str = 'T1547.001'


@dataclass
class ScheduledTask:
    task_name: str
    task_path: str
    state: str
    description: str | None
    author: str | None
    run_as_user: str | None
    run_level: str | None
    action_path: str | None
    action_arguments: str | None
    action_work_dir: str | None
    action_hash: str | None
    trigger_types: list[str]
    last_run_time: str | None
    next_run_time: str | None
    last_task_result: int | None
    collected_at: str
    technique: str = 'T1053.005'


@dataclass
class WindowsService:
    name: str
    display_name: str
    description: str | None
    binary_path: str
    dll_path: str | None
    start_mode: str
    state: str
    run_as: str
    process_id: int | None
    binary_hash: str | None
    collected_at: str
    technique: str = 'T1543.003'


@dataclass
class WmiSubscription:
    filter_name: str | None
    filter_query: str | None
    filter_query_language: str | None
    consumer_name: str | None
    consumer_type: str | None
    consumer_command: str | None
    consumer_script: str | None
    namespace: str
    collected_at: str
    technique: str = 'T1546.003'


@dataclass
class PersistenceArtefacts:
    meta: ScanMeta
    registry_run_keys: list[RegistryRunKey] = field(default_factory=list)
    scheduled_tasks: list[ScheduledTask]    = field(default_factory=list)
    services: list[WindowsService]          = field(default_factory=list)
    wmi_subscriptions: list[WmiSubscription] = field(default_factory=list)


# ---------------------------------------------------------------------------
# OSSEM-normalised output — consumed by the Sigma engine
# ---------------------------------------------------------------------------

@dataclass
class OssemRecord:
    """
    Flat record with OSSEM-standard field names.

    Field naming follows the Open Source Security Events Metadata (OSSEM)
    project so that Sigma rules referencing standard fields (Image,
    CommandLine, TargetObject, etc.) evaluate correctly without field
    remapping at rule level.
    """
    # Process / execution context
    Image: str | None            = None
    CommandLine: str | None      = None
    ParentImage: str | None      = None
    ParentCommandLine: str | None = None

    # Registry context
    TargetObject: str | None     = None
    Details: str | None          = None

    # WMI context
    consumer_type: str | None    = None
    filter_query: str | None     = None

    # Detection metadata
    technique_id: str | None     = None
    technique_name: str | None   = None
    artefact_type: str | None    = None
    action_hash: str | None      = None
