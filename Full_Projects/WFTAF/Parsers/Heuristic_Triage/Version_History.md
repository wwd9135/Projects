# Overview
Change log to track version history.

## Description
The project follows a simple Major, Minor, Patch (1.0.0) schema.
Major: Changing naming conventions, adding/removing data fields completely.
Minor: Small report changes etc that wont effect the parsers.
Patch: Tiny changes and tweaks to the triage tool.

The PowerShell forensic script adds a version history to MetaData, this is checked by the Python parser ensuring the scripts are compatible with one another.
Python wont accept a script with a different major change eg:
- A parser initially designed for 1.0.0 wont accept JSON with a 2.0.0 version in it's metadata.

## Version history:
1.0.0: First version built for robust JSON parsing and normalisation, depends on the following Key artefact naming naming conventions:
- $Payload = [PSCustomObject]@{
    System       = $System
    Network      = $Network
    Processes    = $Processes
    Persistence  = $Persistence
    UserActivity = $UserActivity
    Advanced     = $Advanced
}

1.0.1: Small patch:
- 