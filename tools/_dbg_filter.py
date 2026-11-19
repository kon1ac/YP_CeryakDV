import json
import urllib.parse
import urllib.request

tok = json.load(
    urllib.request.urlopen(
        urllib.request.Request(
            "http://127.0.0.1:8090/api/collections/users/auth-with-password",
            data=json.dumps(
                {"identity": "admin@hockey.local", "password": "admin123"}
            ).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
    )
)["token"]
h = {"Authorization": tok}
filters = [
    "",
    '(deletedAt = "" || deletedAt = null)',
    'deletedAt = ""',
    "deletedAt = null",
]
for f in filters:
    url = "http://127.0.0.1:8090/api/collections/players/records?perPage=5"
    if f:
        url += "&filter=" + urllib.parse.quote(f)
    try:
        d = json.load(urllib.request.urlopen(urllib.request.Request(url, headers=h)))
        print(repr(f), "OK", d.get("totalItems"), [i["name"] for i in d.get("items", [])])
    except Exception as e:
        print(repr(f), "ERR", e)
