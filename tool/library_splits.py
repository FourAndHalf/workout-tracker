"""Gym and home training splits, written for this app.

Each split is a repeating week. The builder expands it into a 4-week block
(settle in, add reps, push, deload). A day item is (exercise id, sets, reps)
or a list of two/three of them, which becomes a superset.

Design rules used throughout:
  * every muscle trained about twice a week, on 10-20 hard sets, which is the
    range the volume and frequency meta-analyses support;
  * big compound first, isolation last; one vertical and one horizontal pull;
  * home days only use bodyweight, dumbbells, bands and a pull-up bar.
"""

# --------------------------------------------------------------------------- gym
G_FULL_A = [("Barbell_Squat", 3, "6-10"), ("Barbell_Bench_Press_-_Medium_Grip", 3, "6-10"),
            ("Seated_Cable_Rows", 3, "8-12"), ("Side_Lateral_Raise", 3, "12-20"),
            [("Triceps_Pushdown_-_Rope_Attachment", 2, "10-15"), ("Barbell_Curl", 2, "8-12")],
            ("Plank", 3, "30-60s")]
G_FULL_B = [("Romanian_Deadlift", 3, "6-10"), ("Dumbbell_Shoulder_Press", 3, "8-12"),
            ("Wide-Grip_Lat_Pulldown", 3, "8-12"), ("Leg_Press", 3, "8-15"),
            ("Incline_Dumbbell_Press", 3, "8-12"), ("Standing_Calf_Raises", 3, "8-15"),
            ("Cable_Crunch", 3, "10-15")]
G_FULL_C = [("Hack_Squat", 3, "8-12"), ("Dumbbell_Bench_Press", 3, "8-12"),
            ("One-Arm_Dumbbell_Row", 3, "8-12"), ("Seated_Leg_Curl", 3, "8-15"),
            ("Cable_Rear_Delt_Fly", 3, "12-20"),
            [("Cable_Rope_Overhead_Triceps_Extension", 2, "10-15"), ("Hammer_Curls", 2, "8-12")],
            ("Hanging_Leg_Raise", 3, "8-15")]

G_UPPER_A = [("Barbell_Bench_Press_-_Medium_Grip", 4, "5-8"), ("Bent_Over_Barbell_Row", 4, "6-10"),
             ("Dumbbell_Shoulder_Press", 3, "8-12"), ("Wide-Grip_Lat_Pulldown", 3, "8-12"),
             ("Side_Lateral_Raise", 3, "12-20"),
             [("Triceps_Pushdown_-_Rope_Attachment", 3, "10-15"), ("Incline_Dumbbell_Curl", 3, "8-12")]]
G_UPPER_B = [("Incline_Dumbbell_Press", 4, "8-12"), ("Seated_Cable_Rows", 4, "8-12"),
             ("Pullups", 3, "6-12"), ("Cable_Crossover", 3, "12-15"), ("Reverse_Machine_Flyes", 3, "12-20"),
             [("Cable_Rope_Overhead_Triceps_Extension", 3, "10-15"), ("Hammer_Curls", 3, "8-12")]]
G_LOWER_A = [("Barbell_Squat", 4, "5-8"), ("Romanian_Deadlift", 3, "6-10"), ("Leg_Press", 3, "8-12"),
             ("Seated_Leg_Curl", 3, "8-15"), ("Standing_Calf_Raises", 4, "8-15"),
             ("Cable_Crunch", 3, "10-15")]
G_LOWER_B = [("Barbell_Hip_Thrust", 4, "6-12"), ("Hack_Squat", 3, "8-12"), ("Dumbbell_Lunges", 3, "8-12"),
             ("Lying_Leg_Curls", 3, "8-15"), ("Leg_Extensions", 3, "10-15"), ("Seated_Calf_Raise", 4, "10-20"),
             ("Hanging_Leg_Raise", 3, "8-15")]

G_PUSH_A = [("Barbell_Bench_Press_-_Medium_Grip", 4, "5-8"), ("Incline_Dumbbell_Press", 3, "8-12"),
            ("Dumbbell_Shoulder_Press", 3, "8-12"), ("Standing_Low-Pulley_Deltoid_Raise", 3, "12-20"),
            ("Cable_Rope_Overhead_Triceps_Extension", 3, "10-15"),
            ("Triceps_Pushdown_-_Rope_Attachment", 3, "10-15")]
G_PULL_A = [("Wide-Grip_Lat_Pulldown", 4, "8-12"), ("Seated_Cable_Rows", 4, "8-12"),
            ("One-Arm_Dumbbell_Row", 3, "8-12"), ("Face_Pull", 3, "12-20"),
            [("Incline_Dumbbell_Curl", 3, "8-12"), ("Hammer_Curls", 3, "8-12")]]
G_LEGS_A = [("Barbell_Squat", 4, "5-8"), ("Romanian_Deadlift", 3, "6-10"), ("Leg_Press", 3, "8-15"),
            ("Seated_Leg_Curl", 3, "8-15"), ("Standing_Calf_Raises", 4, "8-15"),
            ("Hanging_Leg_Raise", 3, "8-15")]
G_PUSH_B = [("Barbell_Incline_Bench_Press_-_Medium_Grip", 4, "6-10"), ("Dumbbell_Bench_Press", 3, "8-12"),
            ("Machine_Shoulder_Military_Press", 3, "8-12"), ("Side_Lateral_Raise", 4, "12-20"),
            ("Cable_Crossover", 3, "12-15"), ("Lying_Triceps_Press", 3, "8-12"),
            ("Triceps_Pushdown", 3, "10-15")]
G_PULL_B = [("Pullups", 4, "6-12"), ("Bent_Over_Barbell_Row", 4, "6-10"), ("Straight-Arm_Pulldown", 3, "12-15"),
            ("Reverse_Machine_Flyes", 3, "12-20"), ("Dumbbell_Shrug", 3, "10-15"),
            [("Preacher_Curl", 3, "8-12"), ("Cable_Hammer_Curls_-_Rope_Attachment", 3, "10-15")]]
G_LEGS_B = [("Hack_Squat", 4, "8-12"), ("Barbell_Hip_Thrust", 4, "6-12"), ("Split_Squat_with_Dumbbells", 3, "8-12"),
            ("Lying_Leg_Curls", 3, "8-15"), ("Leg_Extensions", 3, "10-15"), ("Seated_Calf_Raise", 4, "10-20"),
            ("Cable_Crunch", 3, "10-15")]

# -------------------------------------------------------------------------- home
H_FULL_A = [("Goblet_Squat", 4, "10-15"), ("Pushups", 4, "8-20"), ("One-Arm_Dumbbell_Row", 3, "8-12"),
            ("Standing_Dumbbell_Press", 3, "8-12"), ("Single_Leg_Glute_Bridge", 3, "10-15"),
            ("Plank", 3, "30-60s")]
H_FULL_B = [("Stiff-Legged_Dumbbell_Deadlift", 3, "8-12"), ("Push-Ups_With_Feet_Elevated", 3, "8-15"),
            ("Pullups", 3, "5-12"), ("Side_Lateral_Raise", 3, "12-20"), ("Split_Squat_with_Dumbbells", 3, "8-12"),
            [("Hammer_Curls", 2, "8-12"), ("Standing_Dumbbell_Triceps_Extension", 2, "10-15")]]
H_FULL_C = [("Dumbbell_Lunges", 3, "10-12"), ("Dumbbell_Floor_Press", 3, "8-12"),
            ("Bent_Over_Two-Dumbbell_Row", 3, "10-15"), ("Reverse_Flyes", 3, "12-20"),
            ("Standing_Dumbbell_Calf_Raise", 4, "10-20"), ("Dead_Bug", 3, "8-12"), ("Crunches", 3, "15-25")]

H_UPPER_A = [("Pushups", 4, "8-20"), ("One-Arm_Dumbbell_Row", 4, "8-14"), ("Standing_Dumbbell_Press", 3, "8-12"),
             ("Pullups", 3, "5-12"), ("Side_Lateral_Raise", 3, "12-20"),
             [("Standing_Dumbbell_Triceps_Extension", 3, "10-15"), ("Dumbbell_Alternate_Bicep_Curl", 3, "8-12")]]
H_UPPER_B = [("Push-Ups_With_Feet_Elevated", 4, "8-15"), ("Bent_Over_Two-Dumbbell_Row", 4, "10-15"),
             ("Chin-Up", 3, "5-12"), ("Cross_Over_-_With_Bands", 3, "12-20"), ("Reverse_Flyes", 3, "12-20"),
             [("Push-Ups_-_Close_Triceps_Position", 3, "10-20"), ("Hammer_Curls", 3, "8-12")]]
H_LOWER_A = [("Goblet_Squat", 4, "10-15"), ("Stiff-Legged_Dumbbell_Deadlift", 3, "8-12"),
             ("Split_Squat_with_Dumbbells", 3, "8-12"), ("Single_Leg_Glute_Bridge", 3, "10-15"),
             ("Standing_Dumbbell_Calf_Raise", 4, "10-20"), ("Plank", 3, "30-60s")]
H_LOWER_B = [("Dumbbell_Step_Ups", 3, "8-12"), ("Natural_Glute_Ham_Raise", 3, "5-10"),
             ("Dumbbell_Rear_Lunge", 3, "10-12"), ("Band_Good_Morning", 3, "12-20"),
             ("Dumbbell_Seated_One-Leg_Calf_Raise", 3, "12-20"), ("Reverse_Crunch", 3, "12-20")]

H_PUSH_A = [("Pushups", 4, "8-20"), ("Standing_Dumbbell_Press", 3, "8-12"), ("Dumbbell_Floor_Press", 3, "8-12"),
            ("Side_Lateral_Raise", 3, "12-20"), ("Standing_Dumbbell_Triceps_Extension", 3, "10-15"),
            ("Push-Ups_-_Close_Triceps_Position", 3, "10-20")]
H_PUSH_B = [("Push-Ups_With_Feet_Elevated", 4, "8-15"), ("Arnold_Dumbbell_Press", 3, "8-12"),
            ("Cross_Over_-_With_Bands", 3, "12-20"), ("Lateral_Raise_-_With_Bands", 3, "15-25"),
            ("Seated_Triceps_Press", 3, "10-15"), ("Bench_Dips", 3, "10-20")]
H_PULL_A = [("Pullups", 4, "5-12"), ("One-Arm_Dumbbell_Row", 4, "8-14"), ("Reverse_Flyes", 3, "12-20"),
            ("Dumbbell_Shrug", 3, "10-20"),
            [("Dumbbell_Alternate_Bicep_Curl", 3, "8-12"), ("Hammer_Curls", 3, "8-12")]]
H_PULL_B = [("Chin-Up", 4, "5-12"), ("Bent_Over_Two-Dumbbell_Row", 4, "10-15"), ("Back_Flyes_-_With_Bands", 3, "15-25"),
            ("Band_Pull_Apart", 3, "15-25"),
            [("Concentration_Curls", 3, "10-15"), ("Cross_Body_Hammer_Curl", 3, "8-12")]]
H_LEGS_A = [("Goblet_Squat", 4, "10-15"), ("Stiff-Legged_Dumbbell_Deadlift", 3, "8-12"),
            ("Dumbbell_Lunges", 3, "10-12"), ("Single_Leg_Glute_Bridge", 3, "10-15"),
            ("Standing_Dumbbell_Calf_Raise", 4, "10-20"), ("Plank", 3, "30-60s")]
H_LEGS_B = [("Split_Squat_with_Dumbbells", 3, "8-12"), ("Dumbbell_Step_Ups", 3, "8-12"),
            ("Natural_Glute_Ham_Raise", 3, "5-10"), ("Monster_Walk", 3, "12-20"),
            ("Dumbbell_Seated_One-Leg_Calf_Raise", 3, "12-20"), ("Reverse_Crunch", 3, "12-20")]

BW_A = [("Bodyweight_Squat", 4, "15-25"), ("Pushups", 4, "8-20"), ("Inverted_Row", 4, "8-15"),
        ("Single_Leg_Glute_Bridge", 3, "10-15"), ("Push-Ups_-_Close_Triceps_Position", 3, "10-20"),
        ("Plank", 3, "30-60s")]
BW_B = [("Bodyweight_Walking_Lunge", 3, "10-20"), ("Push-Ups_With_Feet_Elevated", 3, "8-15"),
        ("Pullups", 3, "5-12"), ("Natural_Glute_Ham_Raise", 3, "5-10"), ("Incline_Push-Up", 3, "12-20"),
        ("Reverse_Crunch", 3, "12-20")]
BW_C = [("Split_Squat_with_Dumbbells", 3, "8-15"), ("Push-Up_Wide", 3, "10-20"), ("Chin-Up", 3, "5-12"),
        ("Butt_Lift_Bridge", 3, "12-20"), ("Bench_Dips", 3, "10-20"), ("Side_Bridge", 3, "20-45s"),
        ("Dead_Bug", 3, "8-12")]

SPLITS = [
    dict(id="split-gym-full-3", name="Gym Full Body", setting="gym", level="Beginner",
         days_per_week=3, schedule="Mon / Wed / Fri",
         summary="Three full-body sessions a week. Every muscle is trained three times, so you practise each lift often while recovering between sessions. The best place to start in a gym.",
         days=[("Full Body A", G_FULL_A), ("Full Body B", G_FULL_B), ("Full Body C", G_FULL_C)]),
    dict(id="split-gym-ul-4", name="Gym Upper / Lower", setting="gym", level="Intermediate",
         days_per_week=4, schedule="Mon / Tue / Thu / Fri",
         summary="Two upper days and two lower days. Each muscle gets worked twice a week with 12-16 hard sets, which is the sweet spot in the research for most people.",
         days=[("Upper A", G_UPPER_A), ("Lower A", G_LOWER_A), ("Upper B", G_UPPER_B), ("Lower B", G_LOWER_B)]),
    dict(id="split-gym-hybrid-5", name="Gym Push / Pull / Legs + Upper / Lower", setting="gym", level="Intermediate",
         days_per_week=5, schedule="Mon-Fri",
         summary="Push, pull and legs early in the week, then an upper and a lower day to finish. Everything gets hit twice, with extra upper-body volume.",
         days=[("Push", G_PUSH_A), ("Pull", G_PULL_A), ("Legs", G_LEGS_A), ("Upper", G_UPPER_B), ("Lower", G_LOWER_B)]),
    dict(id="split-gym-ppl-6", name="Gym Push / Pull / Legs", setting="gym", level="Advanced",
         days_per_week=6, schedule="Mon-Sat",
         summary="The classic six-day split. Push, pull, legs twice a week, with two different lists so you do not repeat the same sessions. Needs good recovery and sleep.",
         days=[("Push A", G_PUSH_A), ("Pull A", G_PULL_A), ("Legs A", G_LEGS_A),
               ("Push B", G_PUSH_B), ("Pull B", G_PULL_B), ("Legs B", G_LEGS_B)]),
    dict(id="split-home-full-3", name="Home Full Body", setting="home", level="Beginner",
         days_per_week=3, schedule="Mon / Wed / Fri",
         summary="Dumbbells, a pull-up bar and your bodyweight. Three full-body sessions a week with push-ups, rows and single-leg work. Hard sets taken close to failure grow muscle at home, too.",
         days=[("Full Body A", H_FULL_A), ("Full Body B", H_FULL_B), ("Full Body C", H_FULL_C)]),
    dict(id="split-home-ul-4", name="Home Upper / Lower", setting="home", level="Intermediate",
         days_per_week=4, schedule="Mon / Tue / Thu / Fri",
         summary="Two upper and two lower days using dumbbells, bands and a pull-up bar. Each muscle is trained twice a week; add reps each week, then add load.",
         days=[("Upper A", H_UPPER_A), ("Lower A", H_LOWER_A), ("Upper B", H_UPPER_B), ("Lower B", H_LOWER_B)]),
    dict(id="split-home-ppl-6", name="Home Push / Pull / Legs", setting="home", level="Advanced",
         days_per_week=6, schedule="Mon-Sat",
         summary="Six days with dumbbells, bands and a pull-up bar. High volume, so keep most sets one or two reps short of failure and progress slowly.",
         days=[("Push A", H_PUSH_A), ("Pull A", H_PULL_A), ("Legs A", H_LEGS_A),
               ("Push B", H_PUSH_B), ("Pull B", H_PULL_B), ("Legs B", H_LEGS_B)]),
    dict(id="split-home-bodyweight-3", name="Home No Equipment", setting="home", level="Beginner",
         days_per_week=3, schedule="Mon / Wed / Fri",
         summary="Only your bodyweight. Push-up and lunge variations, a table or bar for rows and a hamstring slide. Progress by slowing the lowering and choosing harder variations.",
         days=[("Bodyweight A", BW_A), ("Bodyweight B", BW_B), ("Bodyweight C", BW_C)]),
]
