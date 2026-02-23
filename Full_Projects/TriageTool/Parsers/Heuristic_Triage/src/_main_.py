from collections import OrderedDict
import json
import hashlib



def compute_payload_hash():
    with open("Trig.json","rb") as f:
        digest = hashlib.file_digest(f, "sha256")
    return digest.hexdigest()

def main():
    # Load the triage file
    with open("Trig_Hash.log", "r", encoding="utf-8-sig") as f:
        data = json.load(f)
    hash =  data["PayloadSHA256"]
    print("Stored Hash: ", hash)
    print(f"Python Hash: {compute_payload_hash().upper()}")
    print(f"{'Match' if hash == compute_payload_hash().upper() else 'No Match'}")



    #stored_hash = 
    #payload = data["Payload"]
    #print(payload)
    # Compute hash in Python
    #python_hash = compute_payload_hash(payload)

    #print("Stored Hash: ", stored_hash)
    #print("Python Hash: ", python_hash)
    #print("Match:       ", stored_hash == python_hash)



if __name__ == "__main__":
    main()
