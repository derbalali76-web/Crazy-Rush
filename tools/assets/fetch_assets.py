#!/usr/bin/env python3
"""يجلب الأصول المذكورة في manifest_jungle.json من Poly Haven وambientCG (CC0) ويحفظ:
- خامات مصغرة 1024 (albedo/normal/rough) بصيغة JPG، لتبقى المستودع خفيفًا.
- مجسمات Poly Haven المرشحة (gltf 1k) كما هي، للخبز لاحقًا.
- لقطة نصية لصفحتي الرخصة + سجل مصادر (url, sha256, حجم) لكل ملف.
بلا مفاتيح أو أسرار."""
import json, sys, hashlib, io, zipfile, urllib.request, pathlib, datetime, re
from PIL import Image

ROOT = pathlib.Path(".")
MAN = json.load(open("tools/assets/manifest_jungle.json"))
OUT = ROOT / "assets/src"
LIC = ROOT / "docs/art/license_snapshots"
UA = {"User-Agent": "CrazyRush-asset-fetch/1.0 (github.com/derbalali76-web/Crazy-Rush)"}
log = []

def get(url, binary=True):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=120) as r:
        d = r.read()
    return d if binary else d.decode("utf-8", "replace")

def rec(kind, aid, url, data, note=""):
    log.append({"kind": kind, "id": aid, "url": url, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data), "note": note})

def save_img(data, path, size=1024, q=88):
    im = Image.open(io.BytesIO(data)).convert("RGB")
    if im.size[0] > size: im = im.resize((size, size), Image.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, "JPEG", quality=q)

# ---- لقطات الرخص ----
LIC.mkdir(parents=True, exist_ok=True)
stamp = datetime.datetime.utcnow().strftime("%Y-%m-%d")
for name, url in [("polyhaven_license", "https://polyhaven.com/license"), ("ambientcg_license", "https://docs.ambientcg.com/license/")]:
    try:
        html = get(url, False)
        txt = re.sub(r"<script.*?</script>|<style.*?</style>", " ", html, flags=re.S)
        txt = re.sub(r"<[^>]+>", " ", txt); txt = re.sub(r"\s+", " ", txt)
        (LIC / f"{name}_{stamp}.txt").write_text(f"URL: {url}\nDATE: {stamp}\n\n{txt[:6000]}\n")
        ok = "CC0" in txt
        print(name, "CC0 mentioned:", ok)
        if not ok: print("WARNING: CC0 not found on", url); sys.exit(2)
    except Exception as e:
        print("license fetch failed", name, e); sys.exit(2)

# ---- Poly Haven textures ----
for t in MAN["polyhaven_textures"]:
    aid = t["id"]
    try:
        f = json.loads(get(f"https://api.polyhaven.com/files/{aid}", False))
        d = OUT / "textures" / aid
        for key, outn in (("Diffuse", "albedo"), ("nor_gl", "normal"), ("Rough", "rough"), ("arm", "arm")):
            if key in f and t["res"] in f[key] and "jpg" in f[key][t["res"]]:
                u = f[key][t["res"]]["jpg"]["url"]; data = get(u)
                save_img(data, d / f"{outn}.jpg"); rec("ph_texture", aid, u, data, outn)
        print("ok ph tex", aid)
    except Exception as e:
        print("FAIL ph tex", aid, e)

# ---- ambientCG ----
for t in MAN["ambientcg_materials"]:
    aid = t["id"]
    try:
        u = f"https://ambientcg.com/get?file={aid}_{t['res']}.zip"
        data = get(u); rec("acg_zip", aid, u, data, "zip (not stored)")
        z = zipfile.ZipFile(io.BytesIO(data)); d = OUT / "textures" / aid
        for n in z.namelist():
            m = re.search(r"_(Color|NormalGL|Roughness|AmbientOcclusion)\.jpg$", n)
            if m:
                outn = {"Color": "albedo", "NormalGL": "normal", "Roughness": "rough", "AmbientOcclusion": "ao"}[m.group(1)]
                save_img(z.read(n), d / f"{outn}.jpg")
        print("ok acg", aid)
    except Exception as e:
        print("FAIL acg", aid, e)

# ---- مجسمات Poly Haven المرشحة (gltf 1k) ----
for m in MAN["polyhaven_models_candidates_after_decimation"]:
    aid = m["id"]
    if (OUT / "models" / aid).exists():
        print("skip existing model", aid); continue
    try:
        f = json.loads(get(f"https://api.polyhaven.com/files/{aid}", False))
        g = f["gltf"]["1k"]["gltf"]; d = OUT / "models" / aid; d.mkdir(parents=True, exist_ok=True)
        data = get(g["url"]); (d / pathlib.Path(g["url"]).name).write_bytes(data); rec("ph_model", aid, g["url"], data)
        for rel, inc in g.get("include", {}).items():
            data = get(inc["url"]); p = d / rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(data); rec("ph_model_part", aid, inc["url"], data, rel)
        print("ok ph model", aid)
    except Exception as e:
        print("FAIL ph model", aid, e)

_old = json.load(open("docs/art/assets_lock.json"))["files"] if pathlib.Path("docs/art/assets_lock.json").exists() else []
_seen = {(x.get("url"), x.get("sha256")) for x in log}
log = log + [x for x in _old if (x.get("url"), x.get("sha256")) not in _seen and x.get("url") not in {y.get("url") for y in log}]
json.dump({"fetched_utc": datetime.datetime.utcnow().isoformat(), "files": log}, open("docs/art/assets_lock.json", "w"), indent=1)
print("files logged:", len(log))
