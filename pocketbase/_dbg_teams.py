import json
import urllib.error
import urllib.request

auth = json.loads(
    urllib.request.urlopen(
        urllib.request.Request(
            "http://127.0.0.1:8090/api/collections/_superusers/auth-with-password",
            data=json.dumps(
                {
                    "identity": "pb-admin@hockey.local",
                    "password": "AdminPass123!",
                }
            ).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
    ).read()
)
token = auth["token"]


def get(path):
    req = urllib.request.Request(
        "http://127.0.0.1:8090" + path, headers={"Authorization": token}
    )
    return json.loads(urllib.request.urlopen(req).read())


users = get("/api/collections/users")
arenas = get("/api/collections/arenas")
print(json.dumps(arenas["fields"][0], indent=2))

body = {
    "name": "teams",
    "type": "base",
    "fields": [
        {
            "name": "name",
            "type": "text",
            "required": True,
            "presentable": False,
            "system": False,
            "min": 1,
            "max": 120,
            "pattern": "",
        },
        {
            "name": "city",
            "type": "text",
            "required": True,
            "presentable": False,
            "system": False,
            "min": 1,
            "max": 80,
            "pattern": "",
        },
        {
            "name": "foundedYear",
            "type": "number",
            "required": False,
            "presentable": False,
            "system": False,
            "min": 1900,
            "max": 2100,
            "onlyInt": True,
        },
        {
            "name": "arena",
            "type": "relation",
            "required": True,
            "presentable": False,
            "system": False,
            "collectionId": arenas["id"],
            "cascadeDelete": False,
            "maxSelect": 1,
            "minSelect": 0,
            "displayFields": [],
        },
        {
            "name": "sponsor",
            "type": "relation",
            "required": False,
            "presentable": False,
            "system": False,
            "collectionId": users["id"],
            "cascadeDelete": False,
            "maxSelect": 1,
            "minSelect": 0,
            "displayFields": [],
        },
        {
            "name": "deletedAt",
            "type": "date",
            "required": False,
            "presentable": False,
            "system": False,
            "min": "",
            "max": "",
        },
    ],
    "listRule": '@request.auth.id != ""',
    "viewRule": '@request.auth.id != ""',
    "createRule": '@request.auth.id != ""',
    "updateRule": '@request.auth.id != ""',
    "deleteRule": '@request.auth.id != ""',
}
req = urllib.request.Request(
    "http://127.0.0.1:8090/api/collections",
    data=json.dumps(body).encode(),
    headers={"Authorization": token, "Content-Type": "application/json"},
    method="POST",
)
try:
    print(urllib.request.urlopen(req).read().decode()[:500])
except urllib.error.HTTPError as e:
    print(e.read().decode())
