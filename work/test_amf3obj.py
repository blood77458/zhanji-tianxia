import sys, binascii
sys.path.insert(0, r"E:\deepseek_projects\app_server\server")
import canon_server as cs

w = cs.AMF3Writer()
w.w_object({"method": "login", "retCode": 0})
b = w.bytes()
print("encoded %d bytes: %s" % (len(b), binascii.hexlify(b).decode()))
print("decoded ->", cs.AMF3Reader(b).read_value())

# re-encode the captured client frame's payload and compare byte-for-byte
cap_payload = binascii.unhexlify(
    "0a0b" "01"
    "0d6d6574686f64060b6c6f67696e"
    "0775696404868d21"
    "15736572766572506f727404cb64"
    "0b746f6b656e06256c6f63616c2d746f6b656e2d343534353235"
    "1b73657276657241646472657373061131302e302e322e3201")
w2 = cs.AMF3Writer()
w2.w_object({"method": "login", "uid": 100001, "serverPort": 9700,
             "token": "local-token-454525", "serverAddress": "10.0.2.2"})
mine = w2.bytes()
print("\nclient payload %d bytes, server payload %d bytes" % (len(cap_payload), len(mine)))
print("byte-identical:", mine == cap_payload)
if mine != cap_payload:
    print("client:", binascii.hexlify(cap_payload).decode())
    print("server:", binascii.hexlify(mine).decode())

hdr = (len(b) + 10).to_bytes(4, "big") + b"\x00" * 10
print("\nserver frame header:", binascii.hexlify(hdr).decode())
