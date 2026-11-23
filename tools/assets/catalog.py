#!/usr/bin/env python3
"""فهرسة بيانات وصفية فقط (بلا تنزيل أي أصل) من Poly Haven وambientCG لاختيار أصول الغابة.
لا يستخدم أي مفتاح أو سر. الرخصة المسجلة هنا تُقرأ من وصف المصدر ويجب مراجعتها في ASSETS_LICENSES.md."""
import json, sys, time, urllib.request, urllib.parse, pathlib

OUT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "docs/art/catalog")
OUT.mkdir(parents=True, exist_ok=True)
UA = {"User-Agent": "CrazyRush-asset-catalog/1.0 (metadata only; github.com/derbalali76-web/Crazy-Rush)"}

def get(url):
    for i in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
                return json.load(r)
        except Exception as e:
            err = e
            time.sleep(2)
    return {"_error": str(err), "_url": url}

report = {"polyhaven": {}, "ambientcg": {}}

# ---------- Poly Haven ----------
WANT = {
 "models": ["tree","fern","plant","rock","boulder","stump","log","mushroom","ruin","pillar","column","bridge","barrel","crate","rope","flower","bush","vine","root","branch","arch","stone","wood","lantern"],
 "textures": ["bark","moss","rock","cliff","mud","dirt","grass","plank","wood","brick","stone","ground","forest","leaves","cobble","path","rough","mossy"],
}
for kind in ("models", "textures"):
    allv = get(f"https://api.polyhaven.com/assets?t={kind}")
    if "_error" in allv:
        report["polyhaven"][kind] = allv; continue
    picked = []
    for aid, a in allv.items():
        text = " ".join([aid, a.get("name",""), *a.get("categories",[]), *a.get("tags",[])]).lower()
        hits = [k for k in WANT[kind] if k in text]
        if hits:
            picked.append((len(hits), a.get("download_count",0), aid, a, hits))
    picked.sort(key=lambda t: (-t[0], -t[1]))
    keep = picked[:70]
    items = []
    for _, dl, aid, a, hits in keep:
        info = get(f"https://api.polyhaven.com/info/{aid}")
        files = get(f"https://api.polyhaven.com/files/{aid}")
        item = {"id": aid, "name": a.get("name"), "categories": a.get("categories"), "tags": a.get("tags"),
                "max_resolution": a.get("max_resolution"), "downloads": dl, "hits": hits,
                "authors": info.get("authors"), "polycount": info.get("polycount"),
                "dimensions": info.get("dimensions"), "page": f"https://polyhaven.com/a/{aid}"}
        # أحجام ملفات 1k/2k فقط (للميزانية)
        sizes = {}
        try:
            if kind == "textures":
                for mp, v in files.items():
                    if isinstance(v, dict):
                        for res in ("1k", "2k"):
                            if res in v and "jpg" in v[res]:
                                sizes.setdefault(mp, {})[res] = v[res]["jpg"].get("size")
            else:
                gl = files.get("gltf", {})
                for res in ("1k", "2k"):
                    if res in gl:
                        g = gl[res]["gltf"]
                        sizes[res] = {"gltf_size": g.get("size"), "include_total": sum(i.get("size", 0) for i in g.get("include", {}).values())}
        except Exception as e:
            sizes = {"_err": str(e)}
        item["file_sizes_bytes"] = sizes
        items.append(item)
        time.sleep(0.15)
    report["polyhaven"][kind] = {"total_in_library": len(allv), "shortlist": items}

# ---------- ambientCG ----------
AQ = ["Bark","Moss","Rock","Ground","Grass","WoodPlanks","Bricks","PavingStones","Leaf","Wood","Cliff","Mud","Roots"]
seen = {}
for q in AQ:
    d = get("https://ambientcg.com/api/v2/full_json?" + urllib.parse.urlencode(
        {"q": q, "type": "Material", "sort": "Popular", "limit": 12, "include": "tagData,downloadData,displayData"}))
    for a in d.get("foundAssets", []) if isinstance(d, dict) else []:
        aid = a.get("assetId")
        if aid in seen: continue
        dl = a.get("downloadFolders", {}).get("default", {}).get("downloadFiletypeCategories", {}).get("zip", {}).get("downloads", [])
        seen[aid] = {"id": aid, "tags": a.get("tags"), "query": q, "license_field": a.get("license") or a.get("licence"),
                     "page": f"https://ambientcg.com/view?id={aid}",
                     "downloads": [{"attr": x.get("attribute"), "size": x.get("size")} for x in dl if x.get("attribute") in ("1K-JPG","2K-JPG")]}
    time.sleep(0.3)
report["ambientcg"]["materials"] = list(seen.values())

(OUT / "catalog.json").write_text(json.dumps(report, ensure_ascii=False, indent=1))
print("polyhaven models:", len(report["polyhaven"].get("models", {}).get("shortlist", [])),
      "textures:", len(report["polyhaven"].get("textures", {}).get("shortlist", [])),
      "ambientcg:", len(seen))
for k in ("models", "textures"):
    e = report["polyhaven"].get(k, {})
    if "_error" in e: print("ERROR polyhaven", k, e["_error"])
