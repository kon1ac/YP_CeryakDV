import json
import urllib.error
import urllib.request

login = json.loads(
    urllib.request.urlopen(
        urllib.request.Request(
            "http://127.0.0.1:8080/api/auth/login",
            data=json.dumps({"username": "admin", "password": "admin123"}).encode(),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
    ).read()
)
tok = login["accessToken"]
req = urllib.request.Request(
    "http://127.0.0.1:8080/api/players?page=1&size=100&includeDeleted=true",
    headers={"Authorization": f"Bearer {tok}"},
)
data = json.loads(urllib.request.urlopen(req).read())
js = sorted({p.get("jerseyNumber") for p in data["items"] if p.get("jerseyNumber")})
print("jerseys", js)
print("total", data["total"])
free = next(i for i in range(1, 100) if i not in js)
body = {
    "name": "Demo2",
    "category": "Нападающий",
    "price": 1000,
    "jerseyNumber": free,
    "status": "in_roster",
    "notes": "x",
    "teamId": 1,
    "achievementIds": [],
}
print("try jersey", free)
r = urllib.request.Request(
    "http://127.0.0.1:8080/api/players",
    data=json.dumps(body).encode(),
    headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"},
    method="POST",
)
try:
    print(urllib.request.urlopen(r).read().decode())
except urllib.error.HTTPError as e:
    print(e.code, e.read().decode())
