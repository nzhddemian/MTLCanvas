#!/usr/bin/env python3
import argparse
import functools
import os
import threading
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class ShaderRequestHandler(SimpleHTTPRequestHandler):
    last_request_time = time.monotonic()
    server_ref = None

    def do_GET(self):
        type(self).last_request_time = time.monotonic()
        if self.path == "/_mtlcanvas/shutdown":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Stopping MTLCanvas shader server\n")
            threading.Thread(target=type(self).server_ref.shutdown, daemon=True).start()
            return

        super().do_GET()

    def do_HEAD(self):
        type(self).last_request_time = time.monotonic()
        super().do_HEAD()


def monitor_idle_timeout(server, handler_class, idle_timeout):
    while True:
        time.sleep(1.0)
        idle_time = time.monotonic() - handler_class.last_request_time
        if idle_time >= idle_timeout:
            print(f"No shader requests for {idle_time:.1f}s. Stopping server.", flush=True)
            server.shutdown()
            return


def main():
    parser = argparse.ArgumentParser(description="MTLCanvas development shader server")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8080)
    parser.add_argument("--root", default=os.getcwd())
    parser.add_argument("--idle-timeout", type=float, default=300.0)
    args = parser.parse_args()

    handler_class = functools.partial(ShaderRequestHandler, directory=args.root)
    server = ThreadingHTTPServer((args.host, args.port), handler_class)
    server.daemon_threads = True
    ShaderRequestHandler.server_ref = server

    monitor = threading.Thread(
        target=monitor_idle_timeout,
        args=(server, ShaderRequestHandler, args.idle_timeout),
        daemon=True,
    )
    monitor.start()

    print(f"Serving {args.root} at http://{args.host}:{args.port}/", flush=True)
    server.serve_forever()
    server.server_close()


if __name__ == "__main__":
    main()
