#!/usr/bin/env python3
"""Exercise the browser's real console and uncaught-error collection."""

import http.server
import json
import shutil
import subprocess
import threading
import uuid


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        broken = self.path == "/broken"
        content = (
            '<title>Browser capture smoke</title><h1 id="ready">Capture ready</h1>'
        )
        if broken:
            content += '<script>console.error("capture-console-sentinel"); throw new Error("capture-page-sentinel");</script>'
        self.send_response(200)
        self.send_header("Content-Type", "text/html")
        self.end_headers()
        self.wfile.write(content.encode())

    def log_message(self, *_):
        pass


def main():
    executable = shutil.which("agent-browser")
    if not executable:
        raise SystemExit("agent-browser is required")
    session = "error-capture-" + uuid.uuid4().hex[:10]

    def browser(*args):
        result = subprocess.run(
            [executable, "--session", session, "--json", *args],
            check=True,
            capture_output=True,
            text=True,
            timeout=45,
        )
        body = json.loads(result.stdout)
        if not body.get("success"):
            raise RuntimeError("Browser command failed: " + args[0])
        return body.get("data")

    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = "http://127.0.0.1:" + str(server.server_port)
    try:
        browser("open", url + "/healthy")
        browser("wait", "#ready")
        healthy_logs = browser("console")
        healthy_errors = browser("errors")
        browser("open", url + "/broken")
        browser("wait", "#ready")
        broken_logs = browser("console")
        broken_errors = browser("errors")
        assert "capture-console-sentinel" not in json.dumps(healthy_logs)
        assert "capture-page-sentinel" not in json.dumps(healthy_errors)
        assert "capture-console-sentinel" in json.dumps(broken_logs), (
            "Console error was not collected"
        )
        assert "capture-page-sentinel" in json.dumps(broken_errors), (
            "Uncaught error was not collected"
        )
        print("PASS: healthy page and both actual browser error collectors")
    finally:
        try:
            browser("close")
        finally:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    main()
