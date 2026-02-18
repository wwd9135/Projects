# Exe file, will trigger a module for each artefact type, and then export the results to a JSON file for use in the LLM agent.
# Output is a markdown formatted report with LLM agent recommendations for next steps in the triage process.
import json

def main():
    try:
        with open("Trig.json", "r", encoding="utf-8-sig") as file:
            data = json.load(file)
            print(data)
    except FileNotFoundError:
        print("File not found.")
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in file: {e}")

main()