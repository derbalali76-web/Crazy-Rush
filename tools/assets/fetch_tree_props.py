"""ينزّل مجسمات الأشجار/الجذوع/الجذور الثقيلة (Poly Haven، CC0) إلى مجلد عمل مؤقت (work/models) دون إيداعها في المستودع،
لأن ملفاتها كبيرة. بعدها يبسّطها tools/blender/bake_trees.py ويودع المخرجات الخفيفة فقط."""
import json, pathlib, urllib.request, hashlib, sys
MAN = json.load(open("tools/assets/manifest_jungle.json"))
OUT = pathlib.Path("work/models"); OUT.mkdir(parents=True, exist_ok=True)
LOCK = pathlib.Path("docs/art/tree_props_lock.json")
log = []

def get(url, binary=True):
    req = urllib.request.Request(url, headers={"User-Agent": "crazy-rush-asset-fetch/1.0 (CC0 assets)"})
    with urllib.request.urlopen(req, timeout=300) as r:
        d = r.read()
    return d if binary else d.decode("utf-8", "replace")

lic = get("https://polyhaven.com/license", False)
assert "CC0" in lic, "license page does not mention CC0"
for m in MAN["polyhaven_models_trees_props"]:
    aid = m["id"]
    try:
        f = json.loads(get(f"https://api.polyhaven.com/files/{aid}", False))
        g = f["gltf"]["1k"]["gltf"]; d = OUT / aid; d.mkdir(parents=True, exist_ok=True)
        data = get(g["url"]); (d / pathlib.Path(g["url"]).name).write_bytes(data)
        log.append({"id": aid, "url": g["url"], "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)})
        for rel, inc in g.get("include", {}).items():
            data = get(inc["url"]); p = d / rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(data)
            log.append({"id": aid, "url": inc["url"], "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data), "note": rel})
        print("ok", aid, sum(x["bytes"] for x in log if x["id"] == aid) // 1024, "KB")
    except Exception as e:
        print("FAIL", aid, e)
LOCK.write_text(json.dumps({"license": "CC0 (polyhaven.com/license)", "files": log}, indent=1))
