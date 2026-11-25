#!/usr/bin/env python3
"""Independent checks on the bundled data, written separately from the Dart
tests so a regression in one is caught by the other.

  python3 tool/verify_assets.py

Each check prints PASS/FAIL with its id from docs/CHANGES.md. Exit code is
the number of failures (0 = everything verified).
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAILS = []


def load(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return json.load(f)


def check(cid, ok, detail=""):
    print(f"{'PASS' if ok else 'FAIL'}  {cid}  {detail}")
    if not ok:
        FAILS.append(cid)


def all_exercises(program):
    for w in program["weeks"]:
        for d in w["days"]:
            for b in d["blocks"]:
                for e in b["exercises"]:
                    yield w, d, b, e


# --------------------------------------------------------------- endurance
end = load("assets/programs/endurance_run_8wk.json")
check("E1", end["programId"] == "endurance-run-8wk" and len(end["weeks"]) == 8,
      "8-week endurance track present")
rest_ok = all(len(w["days"]) == 7 and sum(d.get("type") == "rest" for d in w["days"]) == 2
              for w in end["weeks"])
check("E2", rest_ok, "every week has 7 days, 2 of them rest days")
km = [sum((e.get("distanceMeters") or 0) * e["targetSets"]
          for d in w["days"] for b in d["blocks"] for e in b["exercises"]) / 1000 for w in end["weeks"]]
check("E3", max(km) == km[6] and km[3] < km[2] and km[7] < km[6] and 20 <= km[0] <= 26 and km[6] > 40,
      "weekly km " + ", ".join(f"{k:.1f}" for k in km))
ramp = all(km[i] / km[i - 1] < 1.25 for i in (1, 2, 5, 6))
check("E4", ramp, "no build week rises 25% or more")
last = [d for d in end["weeks"][-1]["days"] if d.get("type") != "rest"][-1]
check("E5", any(e.get("distanceMeters") == 10000 for b in last["blocks"] for e in b["exercises"]),
      f"final session '{last['name']}' includes a 10K")
modes = {e["logMode"] for _, _, _, e in all_exercises(end)}
check("E6", modes <= {"distance", "time", "reps"}, f"log modes {sorted(modes)}")
ids = [e["id"] for _, _, _, e in all_exercises(end)]
check("E7", len(ids) == len(set(ids)), f"{len(ids)} exercise ids, all unique")

bmt = load("assets/programs/badminton_mobility_strength.json")
empty = [d for w in bmt["weeks"] for d in w["days"] if not d["blocks"]]
check("E8", empty and all(d.get("type") == "rest" for d in empty),
      f"{len(empty)} empty badminton days are all typed 'rest'")

# ----------------------------------------------------------------- library
lib = load("assets/library/library.json")
ex = lib["exercises"]
check("L1", len(lib["muscles"]) == 14 and len(ex) >= 150,
      f"{len(lib['muscles'])} muscles, {len(ex)} exercises")
missing, short, bad_reps = [], [], []
for m in lib["muscles"]:
    for r in m["regions"]:
        for s in ("gym", "home"):
            if len(r[s]) < 2:
                short.append(f"{m['id']}/{r['id']}/{s}")
            for p in r[s]:
                if p["exercise"] not in ex:
                    missing.append(p["exercise"])
                if not re.fullmatch(r"\d+–\d+s?", p["reps"]):
                    bad_reps.append(p["reps"])
check("L2", not missing, f"every pick resolves to an exercise {missing[:3]}")
check("L3", not short, f"every part has >=2 gym and >=2 home picks {short[:3]}")
check("L4", not bad_reps, "rep ranges are 'lo–hi' (seconds marked with s)")
no_img = [i for i, e in ex.items()
          if not e["images"] or not all(os.path.exists(os.path.join(ROOT, "assets/library/img", f))
                                        for f in e["images"])]
check("L5", not no_img, f"every exercise has photos on disk {no_img[:3]}")
no_text = [i for i, e in ex.items() if not e["cue"] or not e["steps"]]
check("L6", not no_text, f"every exercise has a cue and steps {no_text[:3]}")
GYM_ONLY = {"Barbell", "Cable", "Machine", "EZ-bar"}
gym_at_home = sorted({p["exercise"] for m in lib["muscles"] for r in m["regions"] for p in r["home"]
                      if ex[p["exercise"]]["equipment"] in GYM_ONLY})
check("L7", not gym_at_home, f"home picks avoid gym-only equipment {gym_at_home[:3]}")
check("L8", "public domain" in lib["credits"]["photos"] and len(lib["references"]) >= 8
      and all(r["url"].startswith("https://") for r in lib["references"]),
      f"photo credit + {len(lib['references'])} https references")
img_mb = sum(os.path.getsize(os.path.join(ROOT, "assets/library/img", f))
             for f in os.listdir(os.path.join(ROOT, "assets/library/img"))) / 1e6
check("L9", img_mb < 7, f"photos total {img_mb:.1f} MB (budget 7 MB)")

# ------------------------------------------------------------------ splits
picks = {s: {p["exercise"] for m in lib["muscles"] for r in m["regions"] for p in r[s]}
         for s in ("gym", "home")}
split_files = sorted(f for f in os.listdir(os.path.join(ROOT, "assets/programs")) if f.startswith("split_"))
check("S1", len(split_files) == 8, f"{len(split_files)} split files")
settings = []
for f in split_files:
    sp = load(f"assets/programs/{f}")
    sid = sp["programId"]
    settings.append(sp["setting"])
    exs = list(all_exercises(sp))
    off = sorted({e["libraryId"] for _, _, _, e in exs if e["libraryId"] not in picks[sp["setting"]]})
    check(f"S2[{sid}]", not off, f"only {sp['setting']} picks are used {off[:3]}")
    uniq = len({e['id'] for _, _, _, e in exs}) == len(exs)
    check(f"S3[{sid}]", uniq and len(sp["weeks"]) == 4, "4 weeks, unique exercise ids")

    def total(w):
        return sum(b["targetSets"] * len(b["exercises"]) for d in w["days"] for b in d["blocks"])
    t = [total(w) for w in sp["weeks"]]
    check(f"S4[{sid}]", t[0] == t[1] and t[2] > t[1] and t[3] < 0.75 * t[0],
          f"weekly sets {t} (same, same, up, deload)")

    # Recompute weekly sets from week 1 and the library's muscle roles.
    calc = {}
    for d in sp["weeks"][0]["days"]:
        for b in d["blocks"]:
            for e in b["exercises"]:
                role = ex[e["libraryId"]]
                for g in role["primary"]:
                    calc.setdefault(g, [0, 0])[0] += b["targetSets"]
                for g in role["secondary"]:
                    calc.setdefault(g, [0, 0])[1] += b["targetSets"]
    stored = {k: (v["direct"], v["indirect"]) for k, v in sp["weeklySets"].items()}
    recomputed = {k: tuple(v) for k, v in calc.items() if v[0] or v[1]}
    check(f"S5[{sid}]", stored == recomputed, "stored weekly sets match a fresh recount")
    eff_ok = all(abs(v["effective"] - (v["direct"] + v["indirect"] * (0.25 if k == "shoulders" else 0.5))) <= 0.5
                 for k, v in sp["weeklySets"].items())
    check(f"S6[{sid}]", eff_ok, "effective = direct + indirect x 1/2 (shoulders 1/4)")
check("S7", sorted(settings) == ["gym"] * 4 + ["home"] * 4, "four gym and four home splits")

# ------------------------------------------------------------- design tokens
# Read the colours straight from the theme source and re-measure every
# coral pairing that design/DESIGN.md promises (WCAG 2.x contrast).
src = open(os.path.join(ROOT, "lib/core/theme/app_colors.dart"), encoding="utf-8").read()


def theme(name):
    body = src[src.index(f"static const {name} = AppColors("):]
    body = body[: body.index(");")]
    return {k: v[2:] for k, v in re.findall(r"(\w+): Color\((0x[0-9A-Fa-f]{8})\)", body)}


def lum(argb):
    r, g, b = (int(argb[i:i + 2], 16) / 255 for i in (2, 4, 6))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def ratio(a, b):
    hi, lo = sorted((lum(a), lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


PAIRS = [  # (foreground, background, minimum, what)
    ("accentText", "background", 4.5, "coral text on canvas"),
    ("accentText", "card", 4.5, "coral text on module"),
    ("accentText", "raised", 4.5, "coral text on raised control"),
    ("accentText", "accentContainer", 4.5, "coral text on tint"),
    ("textPrimary", "accentContainer", 4.5, "ink on tint"),
    ("onAccent", "accentFill", 4.5, "label on fill start"),
    ("onAccent", "accentFillEnd", 4.5, "label on fill end"),
    ("accent", "card", 3.0, "coral graphic on module"),
]
for mode in ("light", "dark"):
    t = theme(mode)
    missing = [k for k in ("accent", "accentText", "accentFill", "accentFillEnd", "onAccent", "accentContainer")
               if k not in t]
    check(f"D1[{mode}]", not missing, f"coral tokens defined {missing}")
    if missing:
        continue
    worst = [(ratio(t[fg], t[bg]), fg, bg, need, what) for fg, bg, need, what in PAIRS]
    bad = [f"{w} {r:.2f}<{n}" for r, fg, bg, n, w in worst if r < n]
    check(f"D2[{mode}]", not bad, "coral pairings meet WCAG AA " + (str(bad) if bad else
          f"(lowest {min(r / n for r, _, _, n, _ in worst) * 100:.0f}% of the requirement met)"))
doc = open(os.path.join(ROOT, "design/DESIGN.md"), encoding="utf-8").read()
light, darkt = theme("light"), theme("dark")
documented = all(f"`#{light[k][2:].upper()}`" in doc and f"`#{darkt[k][2:].upper()}`" in doc
                 for k in ("accent", "accentText", "accentFill", "accentFillEnd", "onAccent", "accentContainer"))
check("D3", documented, "every coral token value in code appears in design/DESIGN.md")

# --- A*: the Explore body figure (anatomy paths + licence) ---------------------
anat = open(os.path.join(ROOT, "lib/features/explore/widgets/anatomy_paths.g.dart"), encoding="utf-8").read()
need = {"front": ["chest", "abs", "obliques", "deltoids", "biceps", "quadriceps", "adductors", "calves", "forearm"],
        "back": ["upper-back", "lower-back", "trapezius", "triceps", "gluteal", "hamstring", "calves", "deltoids"]}
present = {side: [slug for slug in slugs if f"'{slug}'" in anat] for side, slugs in need.items()}
missing = {side: sorted(set(need[side]) - set(present[side])) for side in need}
check("A1", "'front':" in anat and "'back':" in anat and not any(missing.values()),
      "anatomy_paths.g.dart has front/back outlines and every muscle the figure maps " +
      (str(missing) if any(missing.values()) else ""))
lic_path = os.path.join(ROOT, "third_party/react-native-body-highlighter/LICENSE")
lic = open(lic_path, encoding="utf-8").read() if os.path.exists(lic_path) else ""
legal = open(os.path.join(ROOT, "lib/core/legal/third_party_licenses.dart"), encoding="utf-8").read()
main_src = open(os.path.join(ROOT, "lib/main.dart"), encoding="utf-8").read()
check("A2", "MIT License" in lic and lic.strip() in legal and "react-native-body-highlighter" in anat
      and "registerThirdPartyLicenses();" in main_src,
      "the MIT licence is bundled, matches third_party/, is credited in the generated file and registered at start-up")

print()
print(f"{len(FAILS)} failed" if FAILS else "All asset checks passed")
sys.exit(len(FAILS))
