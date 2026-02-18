import json
import hashlib

def compute_payload_hash(payload_obj):
    """
    Reproduce PowerShell: ConvertTo-Json -Depth 10 -Compress
    """
    json_str = json.dumps(
        payload_obj,
        separators=(",", ":"),   # no whitespace
        ensure_ascii=False
    )
    return hashlib.sha256(json_str.encode("utf-8")).hexdigest().upper()


def main():
    # Load the triage file
    with open("Trig.json", "r", encoding="utf-8-sig") as f:
        data = json.load(f)

    stored_hash = data["Integrity"]["PayloadSHA256"]
    payload = data["Payload"]

    # Compute hash in Python
    python_hash = compute_payload_hash(payload)

    print("Stored Hash: ", stored_hash)
    print("Python Hash: ", python_hash)
    print("Match:       ", stored_hash == python_hash)


if __name__ == "__main__":
    main()
