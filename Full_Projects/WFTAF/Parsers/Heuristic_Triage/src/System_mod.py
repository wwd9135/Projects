# Parsing module for the system artefacts

# System mod is mainly developing a baseline of OS internals/ versions & host details to clarify the environment the triage is being performed on. This can be used to inform the LLM agent of potential vulnerabilities, compatibility issues, or other relevant information that may impact the triage process. The system artefacts can include details about the operating system, hardware specifications, installed software, and user accounts.

# As for what needs parsed here, I'd say we just format the data cleanly, and create a CSV formatted object to feed into the LLM agent, with the relevant details about the system. This can include things like OS version, architecture, installed software, user accounts, and any other relevant information that can be gleaned from the system artefacts.
class System_run:
    def __init__(self, data):
        self.data = data

    def parse(self):
        # Placeholder for parsing logic
        # This should include the actual parsing of the system artefacts from the data
        return {
            "system_info": "Parsed system information",
            "users": "Parsed user information",
            "installed_software": "Parsed installed software information"
        }
    
    