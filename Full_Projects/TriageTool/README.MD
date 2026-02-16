# Overview
**Work in progress**
This project is a comprehensive Windows forensics and triage tool that combines my PowerShell and Python work. Python is used to ingest and parse PowerShell logs, while PowerShell performs fast, targeted data collection on endpoints. The primary goals are reliable forensic data capture and accurate detection with minimal false positives and negatives.

A key focus is performance optimisation: reducing PowerShell runtime by avoiding large in‑memory collections and minimizing repeated variable access. By streaming and processing data in a single pass rather than storing thousands of records in variables and referencing them multiple times, the collector completes tasks far faster and with lower resource overhead.

## Navigation
- Parsers: This folder is for my Python parser, designed to ingest the logs created by 'Scripts'
- Scripts: This folder is my PowerShell scripts designed to run forensics against a windows device to detect IOC.

## How to use
- 
