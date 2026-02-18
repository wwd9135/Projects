# Overview
This parsing folder will be used to parse my PowerShell data, I will include tests, logging and example input and output to make this tool simpler to follow and use.


## Testing
Testing was split down into 4 different practice files (Designed to push the parser and test edge cases etc), alongside some randomised data entries I ran on my different windows devices to test multiple laptop and hardware type functionality.



## Navigation
Project is split into stages, this folder contains the python program to normalise, parse and analyze JSON windows forensics, forwarding key threats to an LLM to deduce if they're high risk enough for an analyst to persue.

- src\_main_.py: Only executable file, expects Trig.json forensics file saved in your working directory.
- Artefact_Modules: This folder contains the modules that parse each forensics artefact category, built this way for single responsibility OOP & simple maintainability.
- Tests: folder for a range of input tests & environment based tests.