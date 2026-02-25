# Processes artefact parsing for the Triage Tool. This module will handle the orchestration of parsing the various artefact types and compiling the results into a structured format for the LLM agent.

# 1: one goal of detecting strange processes, but many functions will be needed to achieve this, such as:



class Processes_run:
    def __init__(self, data):
        self.data = data
    def parse(self):
        # Placeholder for parsing logic
        # This should include the actual parsing of the processes artefacts from the data
        return {
            "running_processes": "Parsed running processes information",
            "services": "Parsed services information",
            "scheduled_tasks": "Parsed scheduled tasks information"
        }
    


