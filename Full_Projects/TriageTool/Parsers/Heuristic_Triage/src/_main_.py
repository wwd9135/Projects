from collections import OrderedDict
import json
import hashlib



def compute_payload_hash(payload_obj):
    # debug
 
    json_bytes = json.dumps(
        payload_obj,
    separators=(",", ":"),
    ensure_ascii=False, # ← THIS is the missing piece
    sort_keys=True      # ← THIS is the missing piece
    ).encode("utf-8")
    print("PY canonical length:", len(json_bytes))
    print("PY canonical start :", json_bytes[:100])
    with open("py.json", "wb") as f:
        f.write(json_bytes)

    return hashlib.sha256(json_bytes).hexdigest().upper()
def main():
    # Load the triage file
    with open("Trig_Hash.log", "r", encoding="utf-8-sig") as f:
        data = json.load(f)
    print("Keys in Trig_Hash.log:", list(data.keys()))
    data["Payload"] = OrderedDict(sorted(data["PayloadSHA256"].items()))


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
