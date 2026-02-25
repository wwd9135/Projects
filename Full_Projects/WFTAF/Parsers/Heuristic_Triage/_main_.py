import json
import hashlib

from src import Advanced_Run, System_run, Processes_run, user_activity_run, Network_run, Persistence_run
def compute_payload_hash():
    with open(r"src\Output_folder\Trig.json","rb") as f:
        digest: str = hashlib.file_digest(f, "sha256")
    return digest.hexdigest()

def main():
    # Load the hash file
    with open(r"src\Output_folder\Trig_Hash.log", "r", encoding="utf-8-sig") as f:
        data: str = json.load(f)
    hash: str =  data["PayloadSHA256"]
    print(f"Stored Hash: {hash}")
    try:
        computed_hash: str = compute_payload_hash().upper()
        print(f"Python Hash: {computed_hash}")
        print(f"{'Match' if hash == computed_hash else 'No Match'}")
    except Exception as e:
        print(f"Error computing hash: {e}")

    # Example of accessing the Advanced artefacts data
    with open(r"src\Output_folder\Trig.json", "r", encoding="utf-8-sig") as f:
        data: str = json.load(f)

    # Call each artefact class and feed it the relevant data, create a dict with the 6 data points for each artefact type.
    # 1: System artefacts
    system_artefacts: dict = data["Payload"]["System"]
    System_Data : dict = System_run(system_artefacts)
    print(System_Data) # Test run
    
    # 2: Processes artefacts
    processes_artefacts: dict = data["Payload"]["Processes"]
    Processes_Data: dict = Processes_run(processes_artefacts)
    print(Processes_Data) # Test run

    # 3: Network artefacts
    network_artefacts : dict = data["Payload"]["Network"]  
    Network_data : dict = Network_run(network_artefacts)
    print(Network_data) # Test run

    # 4: User Activity artefacts
    User_artefacts : dict = data["Payload"]["UserActivity"]
    User_data: dict = user_activity_run(User_artefacts)
    print(User_data) # Test run

    # 5: Persistence activity artefacts
    Persistence_artefacts: dict = data["Payload"]["Persistence"]
    Persistence_data: dict = Persistence_run(Persistence_artefacts)
    print(Persistence_data) # Test run

    # 6: Advanced artefacts
    advanced_artefacts = data["Payload"]["Advanced"]
    Advanced_data: dict = Advanced_Run(advanced_artefacts).run()
    print(Advanced_data) # Test run

    # Call LLM class.
    

    # Call report class and feed it all 6 data points + LLM data, expect a .md file back





if __name__ == "__main__":
    main()
