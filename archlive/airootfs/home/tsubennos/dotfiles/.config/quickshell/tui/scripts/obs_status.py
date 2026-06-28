#!/usr/bin/env python3

import socket
import base64
import hashlib
import os
import json
import struct
import time
import sys

HOST     = "localhost"
PORT     = 4455
PASSWORD = "mr3upbmvahRqGn48"  # set if you have a password

def ws_handshake(sock):
    key = base64.b64encode(os.urandom(16)).decode()
    request = (
        f"GET / HTTP/1.1\r\n"
        f"Host: {HOST}:{PORT}\r\n"
        f"Upgrade: websocket\r\n"
        f"Connection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\n"
        f"Sec-WebSocket-Version: 13\r\n"
        f"\r\n"
    )
    sock.sendall(request.encode())
    response = b""
    while b"\r\n\r\n" not in response:
        response += sock.recv(1)
    return b"101" in response

def send_frame(sock, data):
    payload = json.dumps(data).encode()
    length  = len(payload)
    mask    = b'\x12\x34\x56\x78'
    masked  = bytes(payload[i] ^ mask[i % 4] for i in range(length))
    if length < 126:
        header = struct.pack("BB", 0x81, 0x80 | length)
    elif length < 65536:
        header = struct.pack("!BBH", 0x81, 0xFE, length)
    else:
        header = struct.pack("!BBQ", 0x81, 0xFF, length)
    sock.sendall(header + mask + masked)

def recv_frame(sock):
    def recv_exact(n):
        buf = b""
        while len(buf) < n:
            chunk = sock.recv(n - len(buf))
            if not chunk:
                raise ConnectionError("Connection closed")
            buf += chunk
        return buf

    header  = recv_exact(2)
    opcode  = header[0] & 0x0f
    masked  = (header[1] & 0x80) != 0
    length  = header[1] & 0x7f

    if length == 126:
        length = struct.unpack("!H", recv_exact(2))[0]
    elif length == 127:
        length = struct.unpack("!Q", recv_exact(8))[0]

    if masked:
        mask = recv_exact(4)

    data = recv_exact(length)

    if masked:
        data = bytes(data[i] ^ mask[i % 4] for i in range(length))

    if opcode == 8:
        raise ConnectionError("Server closed connection")

    return json.loads(data.decode())

def make_auth(password, salt, challenge):
    secret = base64.b64encode(
        hashlib.sha256((password + salt).encode()).digest()
    ).decode()
    auth = base64.b64encode(
        hashlib.sha256((secret + challenge).encode()).digest()
    ).decode()
    return auth

def get_status(sock):
    for req_type in ["GetRecordStatus", "GetStreamStatus", "GetVirtualCamStatus"]:
        send_frame(sock, {
            "op": 6,
            "d": {
                "requestType": req_type,
                "requestId":   req_type,
            }
        })

def main():
    while True:
        sock = None
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)
            sock.connect((HOST, PORT))

            if not ws_handshake(sock):
                raise Exception("WebSocket handshake failed")

            # op 0 - hello
            hello = recv_frame(sock)
            auth_data = hello.get("d", {}).get("authentication")
            print(f"Hello: {hello}", file=sys.stderr)

            identify = {
                "op": 1,
                "d": {
                    "rpcVersion": 1,
                    "eventSubscriptions": 0
                }
            }

            if auth_data and PASSWORD:
                identify["d"]["authentication"] = make_auth(
                    PASSWORD,
                    auth_data["salt"],
                    auth_data["challenge"]
                )

            send_frame(sock, identify)

            # op 2 - identified
            identified = recv_frame(sock)
            if identified.get("op") != 2:
                raise Exception("Not identified")

            status = {
                "connected":  True,
                "recording":  False,
                "paused":     False,
                "streaming":  False,
                "virtualCam": False,
            }

            while True:
                get_status(sock)

                for _ in range(3):
                    try:
                        frame = recv_frame(sock)
                        d  = frame.get("d", {})
                        rd = d.get("responseData", {})
                        rt = d.get("requestId", "")

                        if rt == "GetRecordStatus":
                            status["recording"] = rd.get("outputActive", False)
                            status["paused"]    = rd.get("outputPaused", False)
                        elif rt == "GetStreamStatus":
                            status["streaming"] = rd.get("outputActive", False)
                        elif rt == "GetVirtualCamStatus":
                            status["virtualCam"] = rd.get("outputActive", False)
                    except Exception:
                        pass

                print(json.dumps(status))
                sys.stdout.flush()
                time.sleep(1)

        except Exception as e:
            print(json.dumps({"connected": False}), file=sys.stdout)
            sys.stdout.flush()
            print(f"OBS: {e}", file=sys.stderr)
            time.sleep(1)
        finally:
            if sock:
                try:
                    sock.close()
                except:
                    pass

main()
