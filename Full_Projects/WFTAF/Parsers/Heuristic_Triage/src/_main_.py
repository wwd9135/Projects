from collections import OrderedDict
import json
import hashlib



def compute_payload_hash():
    with open("Trig.json","rb") as f:
        digest = hashlib.file_digest(f, "sha256")
    return digest.hexdigest()

def log_creator():
# Log needs to be markdown formatted, add in data for integrity check & the output of each class, formatted in a way that is easy to read and understand.
# Also compile the LLM data nicely near the top, aiming to provide a clear summary of the triage report, with the more detailed data from each class following after.
    pass

def main():
    # Load the hash file
    with open("Trig_Hash.log", "r", encoding="utf-8-sig") as f:
        data = json.load(f)
    hash =  data["PayloadSHA256"]
    print("Stored Hash: ", hash)
    try:
        computed_hash = compute_payload_hash().upper()
        print(f"Python Hash: {computed_hash}")
        print(f"{'Match' if hash == computed_hash else 'No Match'}")
    except Exception as e:
        print(f"Error computing hash: {e}")

    # Example of accessing the Advanced artefacts data
    with open("Trig.json", "r", encoding="utf-8-sig") as f:
        data = json.load(f)
    #print(f"Advanced Artefacts: {data['Payload']['Advanced']}")

if __name__ == "__main__":
    main()
