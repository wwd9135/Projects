import hashlib

with open("payload_exact_ps.txt", "rb") as f:
    raw = f.read()

print("Python SHA256:", hashlib.sha256(raw).hexdigest().upper())
