"""Serve Flutter web build with SPA fallback on a fixed port."""
from __future__ import annotations

import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class SpaHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, directory: str | None = None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

    def do_GET(self):  # noqa: N802
        path = Path(self.translate_path(self.path))
        if path.is_file():
            return super().do_GET()
        # SPA fallback
        self.path = "/index.html"
        return super().do_GET()

    def log_message(self, fmt: str, *args) -> None:
        print("[%s] %s" % (self.log_date_time_string(), fmt % args))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--port", type=int, default=5555)
    p.add_argument(
        "--dir",
        default=str(Path(__file__).resolve().parents[1] / "build" / "web"),
    )
    args = p.parse_args()
    root = Path(args.dir).resolve()
    if not (root / "index.html").exists():
        raise SystemExit(f"no index.html in {root}")

    class Handler(SpaHandler):
        def __init__(self, *a, **k):
            super().__init__(*a, directory=str(root), **k)

    httpd = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"SPA {root} on http://127.0.0.1:{args.port}")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
