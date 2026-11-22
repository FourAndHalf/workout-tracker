#!/usr/bin/env python3
"""Builds the Explore library assets from the hand-written sources.

  python3 tool/build_library.py [--dataset PATH] [--cache DIR]

Reads  tool/library_muscles.py, library_cues.py, library_splits.py
       free-exercise-db exercises.json (public domain; downloaded if missing)
Writes assets/library/library.json
       assets/library/img/<id>_0.jpg / _1.jpg (downscaled photos)
       assets/programs/split_*.json (one per split)
"""
import argparse, json, os, subprocess, sys, urllib.request
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import library_muscles as LM  # noqa: E402
import library_cues as LC  # noqa: E402
import library_splits as LS  # noqa: E402

RAW = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main"
GROUP_OF = {  # free-exercise-db muscle name -> our muscle group id
    "abdominals": "core", "abductors": "hips", "adductors": "hips", "biceps": "biceps", "calves": "calves",
    "chest": "chest", "forearms": "forearms", "glutes": "glutes", "hamstrings": "hamstrings", "lats": "back",
    "lower back": "lower-back", "middle back": "back", "quadriceps": "quads", "shoulders": "shoulders",
    "traps": "traps", "triceps": "triceps",
}
EQUIPMENT = {"barbell": "Barbell", "dumbbell": "Dumbbells", "body only": "Bodyweight", "cable": "Cable",
             "machine": "Machine", "kettlebells": "Kettlebell", "bands": "Band", "e-z curl bar": "EZ-bar",
             "other": "Other", None: "Bodyweight", "medicine ball": "Medicine ball", "exercise ball": "Exercise ball"}
# Moves that need no more than a bar, bench or sturdy surface even though the dataset tags them "other".
EQUIPMENT_OVERRIDE = {"Pullups": "Pull-up bar", "Chin-Up": "Pull-up bar", "Hanging_Leg_Raise": "Pull-up bar",
                      "Scapular_Pull-Up": "Pull-up bar", "Band_Assisted_Pull-Up": "Pull-up bar + band",
                      "Inverted_Row": "Bar or table", "Dips_-_Chest_Version": "Dip bars",
                      "Dips_-_Triceps_Version": "Dip bars", "Bench_Dips": "Chair or bench",
                      "Goblet_Squat": "Dumbbell", "Kettlebell_One-Legged_Deadlift": "Dumbbell",
                      "Kettlebell_Pistol_Squat": "Bodyweight", "Weighted_Sissy_Squat": "Bodyweight or plate",
                      "Platform_Hamstring_Slides": "Towel or sliders", "Seated_Band_Hamstring_Curl": "Band",
                      "Hyperextensions_Back_Extensions": "Back-extension bench", "Ab_Roller": "Ab wheel",
                      "Donkey_Calf_Raises": "Machine or partner", "Plate_Pinch": "Weight plates"}
# The dataset has no steps for these; written for this app.
STEPS_OVERRIDE = {
    "Side_Bridge": [
        "Lie on your side with your forearm directly under your shoulder and your legs stacked.",
        "Lift your hips off the floor until your body forms a straight line from head to feet.",
        "Hold, breathing steadily and keeping your hips from sagging, then switch sides.",
    ],
}
STABILISERS = {"calves", "forearms", "lower-back", "core", "hips"}
DASH = "–"


def pretty_reps(reps):
    return reps.replace("-", DASH)


def load_dataset(path):
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        urllib.request.urlretrieve(f"{RAW}/dist/exercises.json", path)
    return {e["id"]: e for e in json.load(open(path))}


def fetch_images(ids, dataset, cache):
    from PIL import Image
    out_dir = os.path.join(ROOT, "assets", "library", "img")
    os.makedirs(out_dir, exist_ok=True)
    jobs = []
    for i in ids:
        for n, rel in enumerate(dataset[i]["images"][:2]):
            jobs.append((i, n, rel))

    def one(job):
        i, n, rel = job
        dest = os.path.join(out_dir, f"{i}_{n}.jpg")
        if os.path.exists(dest):
            return dest
        src = os.path.join(cache, rel.replace("/", "__"))
        if not os.path.exists(src):
            url = f"{RAW}/exercises/{rel}"
            subprocess.run(["curl", "-sSf", "-m", "60", "-o", src, url], check=True)
        im = Image.open(src).convert("RGB")
        im.thumbnail((520, 520))
        im.save(dest, "JPEG", quality=70, optimize=True, progressive=True)
        return dest

    os.makedirs(cache, exist_ok=True)
    with ThreadPoolExecutor(8) as pool:
        list(pool.map(one, jobs))


def collect_ids():
    ids = []
    for m in LM.MUSCLES:
        for r in m["regions"]:
            for s in ("gym", "home"):
                for p in r[s]:
                    if p[0] not in ids:
                        ids.append(p[0])

    def walk(x):
        if isinstance(x, list):
            for y in x:
                walk(y)
        elif x[0] not in ids:
            ids.append(x[0])
    for sp in LS.SPLITS:
        for _, day in sp["days"]:
            walk(day)
    return ids


def muscle_roles(dataset):
    """exercise id -> {'primary': set(group), 'secondary': set(group)}."""
    roles = {}
    for m in LM.MUSCLES:
        for r in m["regions"]:
            for s in ("gym", "home"):
                for ex, _, _, focus in r[s]:
                    role = roles.setdefault(ex, {"primary": set(), "secondary": set()})
                    role["primary" if focus == "P" else "secondary"].add(m["id"])
    for ex, role in roles.items():
        for name in dataset[ex]["secondaryMuscles"]:
            g = GROUP_OF.get(name)
            # Stabiliser-only tags (calves in squats, forearms in rows, ...) are too
            # generous to count as training volume, so they are left out.
            if g and g not in STABILISERS:
                role["secondary"].add(g)
        role["secondary"] -= role["primary"]
    return roles


def build_exercises(ids, dataset, roles):
    out = {}
    for i in ids:
        d = dataset[i]
        role = roles[i]
        eq = EQUIPMENT_OVERRIDE.get(i) or EQUIPMENT[d["equipment"]]
        out[i] = {
            "name": d["name"].replace("3/4", "¾"),
            "equipment": eq,
            "level": d["level"],
            "mechanic": d["mechanic"] or "isolation",
            "primary": sorted(role["primary"]),
            "secondary": sorted(role["secondary"]),
            "cue": LC.CUES[i],
            "steps": STEPS_OVERRIDE.get(i) or [s.strip() for s in d["instructions"] if s.strip()],
            "images": [f"{i}_{n}.jpg" for n in range(min(2, len(d["images"])))],
            "timed": i in LC.TIMED,
        }
    return out


def build_library(dataset, ids):
    roles = muscle_roles(dataset)
    exercises = build_exercises(ids, dataset, roles)
    muscles = []
    for m in LM.MUSCLES:
        regions = []
        for r in m["regions"]:
            reg = {k: r[k] for k in ("id", "name", "latin", "note")}
            for s in ("gym", "home"):
                reg[s] = [{"exercise": ex, "sets": sets, "reps": pretty_reps(reps), "focus": "primary" if f == "P" else "assist"}
                          for ex, sets, reps, f in r[s]]
            regions.append(reg)
        muscles.append({"id": m["id"], "name": m["name"], "latin": m["latin"], "view": m["view"],
                        "summary": m["summary"], "regions": regions})
    return {
        "version": 1,
        "credits": {
            "photos": "Exercise photos and step-by-step instructions come from free-exercise-db "
                      "(github.com/yuhonas/free-exercise-db), released into the public domain under the Unlicense.",
            "picks": "The muscle map, exercise picks, sets and reps, notes and splits were written for this app "
                     "from the studies below. They are general guidance, not medical advice.",
        },
        "references": [{"title": t, "url": u} for t, u in LM.REFERENCES],
        "muscles": muscles,
        "exercises": exercises,
    }, roles


def rest_for(ex, exercises, superset):
    if superset:
        return 90
    e = exercises[ex]
    if e["timed"]:
        return 45
    return 120 if e["mechanic"] == "compound" else 75


def parse_reps(reps):
    return reps.replace("s", "").split("-")


WEEKS = [
    ("Settle in", "Stop each set about 3 reps before failure. Learn the lifts and find your starting weights."),
    ("Add reps", "Beat last week's reps on your main lifts, stopping about 2 reps short of failure."),
    ("Push", "The hardest week. The first two lifts each day get an extra set; stop about 1 rep short of failure."),
    ("Deload", "Cut sets by about 40% and stay about 4 reps short of failure. Recovering now makes the next block better."),
]


def effective(group, v):
    """Hard-set equivalent. Helper sets count half, but only the front head of the
    shoulder is helped by pressing, so shoulder helper sets count a quarter."""
    return v["direct"] + v["indirect"] * (0.25 if group == "shoulders" else 0.5)


def week_sets(base, item_index, week):
    if week == 3 and item_index < 2:
        return base + 1
    if week == 4:
        return max(2, round(base * 0.6))
    return base


def build_split(sp, exercises, roles):
    # Weekly sets per muscle from week 1.
    # direct = sets where the muscle is the main driver; indirect = sets where it
    # assists. The app scores direct + indirect/2 against the 10-20 set range.
    weekly = {m["id"]: {"direct": 0, "indirect": 0} for m in LM.MUSCLES}

    def flat(day):
        for item in day:
            for t in (item if isinstance(item, list) else [item]):
                yield t
    for _, day in sp["days"]:
        for ex, sets, _ in flat(day):
            role = roles[ex]
            for g in role["primary"]:
                weekly[g]["direct"] += sets
            for g in role["secondary"]:
                weekly[g]["indirect"] += sets

    weeks = []
    for w, (wtitle, wfocus) in enumerate(WEEKS, 1):
        days = []
        for d, (dname, day) in enumerate(sp["days"], 1):
            did = f"{sp['id']}-w{w}-d{d}"
            blocks, n = [], 0
            seconds = 0
            day_sets = {}
            for bi, item in enumerate(day):
                group = item if isinstance(item, list) else [item]
                superset = len(group) > 1
                rest = rest_for(group[0][0], exercises, superset)
                block_sets = week_sets(group[0][1], bi, w)
                b = {"id": f"{did}-b{bi + 1}",
                     "name": " + ".join(exercises[g[0]]["name"] for g in group),
                     "type": "superset" if superset else "straight",
                     "targetSets": block_sets, "restSeconds": rest, "exercises": []}
                for g in group:
                    ex, base_sets, reps = g
                    n += 1
                    e = exercises[ex]
                    lo, hi = parse_reps(reps)
                    entry = {"id": f"{did}-{n:02d}", "order": len(b["exercises"]) + 1, "name": e["name"],
                             "targetSets": block_sets, "libraryId": ex, "instructions": e["cue"]}
                    if e["timed"]:
                        secs = int(round((int(lo) + int(hi)) / 2 / 5) * 5)
                        entry.update(logMode="time", durationSeconds=secs,
                                     prescription=f"{block_sets} × {lo}{DASH}{hi} sec")
                    else:
                        entry.update(logMode="repsOnly" if ex in LC.REPS_ONLY else "weightReps",
                                     prescription=f"{block_sets} × {pretty_reps(reps)}")
                    b["exercises"].append(entry)
                    seconds += block_sets * ((int(hi) if e["timed"] else 45) + rest)
                    # Muscle chips use week-1 sets so a deload week keeps them.
                    for gm in roles[ex]["primary"]:
                        day_sets[gm] = day_sets.get(gm, 0) + base_sets
                blocks.append(b)
            muscles = [m for m, _ in sorted(day_sets.items(), key=lambda kv: -kv[1]) if day_sets[m] >= 3][:5]
            days.append({"id": did, "name": dname, "order": d, "type": "strength", "muscles": muscles,
                         "estimatedDurationSeconds": int(round(seconds / 300.0)) * 300, "blocks": blocks})
        weeks.append({"number": w, "id": f"{sp['id']}-w{w}", "title": wtitle, "focus": wfocus, "days": days})
    return {
        "schemaVersion": 1, "programId": sp["id"], "programName": sp["name"],
        "category": "split", "setting": sp["setting"], "level": sp["level"],
        "daysPerWeek": sp["days_per_week"], "schedule": sp["schedule"], "description": sp["summary"],
        "sourceNote": f"{sp['schedule']} · {sp['level']} · {sp['setting'].title()}",
        "durationWeeks": 4,
        "weeklySets": {k: dict(v, effective=round(effective(k, v) * 2) / 2)
                       for k, v in weekly.items() if v["direct"] or v["indirect"]},
        "logModes": {"weightReps": "Weight field + reps field.", "repsOnly": "Reps field only (bodyweight).",
                     "time": "Duration in seconds."},
        "blockTypes": {"straight": "Exercises performed and rested independently.",
                       "superset": "Two exercises back to back, no rest between."},
        "weeks": weeks,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", default=os.path.join(ROOT, ".dart_tool", "fedb", "exercises.json"))
    ap.add_argument("--cache", default=os.path.join(ROOT, ".dart_tool", "fedb", "img"))
    a = ap.parse_args()
    dataset = load_dataset(a.dataset)
    ids = collect_ids()
    missing = [i for i in ids if i not in dataset]
    nocue = [i for i in ids if i not in LC.CUES]
    if missing or nocue:
        sys.exit(f"missing from dataset: {missing}; missing cues: {nocue}")
    fetch_images(ids, dataset, a.cache)
    library, roles = build_library(dataset, ids)
    lib_dir = os.path.join(ROOT, "assets", "library")
    json.dump(library, open(os.path.join(lib_dir, "library.json"), "w"), indent=1, ensure_ascii=False)
    for sp in LS.SPLITS:
        prog = build_split(sp, library["exercises"], roles)
        fname = sp["id"].replace("-", "_") + ".json"
        json.dump(prog, open(os.path.join(ROOT, "assets", "programs", fname), "w"), indent=1, ensure_ascii=False)
        print(fname, {k: v for k, v in prog["weeklySets"].items()})
    print(len(ids), "exercises,", len(LS.SPLITS), "splits")


if __name__ == "__main__":
    main()
