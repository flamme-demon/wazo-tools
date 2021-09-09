#!/usr/bin/env python

import websocket
import sys
import json

from getpass import getpass


ignored_events = [
    'ChannelVarset'
]

host = sys.argv[1]
username = sys.argv[2]
events = sys.argv[3].split(',')
password = getpass('Password for {0}: '.format(username))


def main(argv):
    print("create ws")
    ws_url = "ws://{host}:5039/ari/events?app=callcontrol&api_key={username}:{password}"
    ws = websocket.create_connection(ws_url, sslopt={"cert_reqs": False})
    print("create ok")
    try:
        print("Ready.")
        msg_str = ws.recv()
        while msg_str is not None:
            try:
                msg_json = json.loads(msg_str)
                if msg_json['type'] not in ignored_events:
                    print(json.dumps(msg_json, sort_keys=True,
                          indent=2, separators=(',', ': ')))
            except ValueError:
                print('received json: {}'.format(repr(msg_str)))
            msg_str = ws.recv()
    except KeyboardInterrupt:
        print("*** Closing")
    except websocket.WebSocketConnectionClosedException:
        print("*** Closed")
    ws.close()


if __name__ == "__main__":
    sys.exit(main(sys.argv) or 0)
