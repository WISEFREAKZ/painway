-- =====================================================================
-- PHYSIO APP — SUPABASE POSTGRESQL SCHEMA
-- Run this entire script in the Supabase SQL Editor (Project > SQL Editor)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. CATEGORIES TABLE
-- ---------------------------------------------------------------------
create table if not exists public.categories (
  id           bigint generated always as identity primary key,
  created_at   timestamp with time zone default now() not null,
  name         text not null,                 -- e.g. "Foot & Heel (Plantar Fasciitis)"
  icon_slug    text not null default 'accessibility_new' -- maps to a local Material icon
);

comment on table public.categories is 'Top level PT categories shown as a grid on the dashboard.';

-- ---------------------------------------------------------------------
-- 2. EXERCISES TABLE
-- ---------------------------------------------------------------------
create table if not exists public.exercises (
  id                bigint generated always as identity primary key,
  category_id       bigint not null references public.categories (id) on delete cascade,
  title             text not null,
  target_muscles    text[] not null default '{}',
  description       text not null default '',
  steps             text[] not null default '{}',
  media_url         text,                     -- open-source gif/image URL (Wger, BodyIQDB, etc.)
  media_attribution text,                     -- required credit line when media_url isn't public-domain
  duration_seconds  integer not null default 30,
  created_at        timestamp with time zone default now() not null
);

comment on table public.exercises is 'Individual PT exercises belonging to a category.';

-- Helpful index for the category -> exercise list query
create index if not exists idx_exercises_category_id on public.exercises (category_id);

-- ---------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY
-- This is a 100% free, read-only content app — no user auth needed.
-- Enable RLS and allow anonymous SELECT only. No INSERT/UPDATE/DELETE
-- from the client, keeping the backend zero-maintenance and safe.
-- ---------------------------------------------------------------------
alter table public.categories enable row level security;
alter table public.exercises  enable row level security;

create policy "Public read access - categories"
  on public.categories for select
  using (true);

create policy "Public read access - exercises"
  on public.exercises for select
  using (true);

-- 4. SEED DATA
-- 8 PT categories with ~12-20 exercises each (133 total).
--
-- MEDIA: two sources, mixed deliberately.
--
--  (a) STATIC IMAGES (102 of 133 rows) — free-exercise-db
--      (https://github.com/yuhonas/free-exercise-db), Unlicense/public
--      domain. Every URL individually HTTP-verified (200 OK).
--      media_attribution is null for these — none required.
--
--  (b) ANIMATED GIFS (31 of 133 rows) — hasaneyldrm/exercises-dataset
--      (https://github.com/hasaneyldrm/exercises-dataset). This media
--      is NOT public domain: it is owned by Gym visual (a commercial
--      stock-media company) and redistributed in that repo under a
--      claimed permission arrangement, at 180x180 resolution, with a
--      hard requirement that attribution survive any reuse. Used here
--      ONLY for personal, non-distributed use, and only for exercises
--      where the name matched closely enough between datasets to be
--      confident it's genuinely the same movement (31 out of 133 —
--      fuzzy name-similarity alone produced false positives on exercises
--      that are NOT the same movement, e.g. "Sit Squats" vs "Split
--      Squats" at 91% string similarity, so those were excluded rather
--      than risk showing the wrong exercise's animation). Every GIF URL
--      was individually HTTP-verified (200 OK). media_attribution holds
--      the required "© Gym visual — https://gymvisual.com/" credit line
--      for these rows; the app displays it under the media viewport
--      whenever it's present (see exercise_guide_screen.dart).
--
-- If you ever redistribute this app beyond personal use, replace the
-- 31 GIF rows' media_url back with free-exercise-db equivalents (or
-- your own licensed media) — the Gym visual permission this repo
-- claims does not extend to your redistribution.
--
-- IDEMPOTENT RE-RUNS: if you already ran an earlier version of this
-- script, uncomment the two lines below to wipe existing rows first so
-- re-running this file doesn't create duplicates.
-- truncate table public.exercises restart identity cascade;
-- truncate table public.categories restart identity cascade;
-- Categories (8 total)
insert into public.categories (name, icon_slug) values
  ('Foot & Heel (Plantar Fasciitis)', 'foot_icon'),
  ('Hip & Pelvic Pain', 'hip_icon'),
  ('Lower Back', 'lowerback_icon'),
  ('Knee', 'knee_icon'),
  ('Shoulder', 'shoulder_icon'),
  ('Neck', 'neck_icon'),
  ('Arms', 'arms_icon'),
  ('Legs', 'legs_icon')
on conflict do nothing;

do $$
declare
  foot_heel_cat_id bigint;
  hip_pelvic_cat_id bigint;
  lower_back_cat_id bigint;
  knee_cat_id bigint;
  shoulder_cat_id bigint;
  neck_cat_id bigint;
  arms_cat_id bigint;
  legs_cat_id bigint;
begin
  select id into foot_heel_cat_id from public.categories where name = 'Foot & Heel (Plantar Fasciitis)' limit 1;
  select id into hip_pelvic_cat_id from public.categories where name = 'Hip & Pelvic Pain' limit 1;
  select id into lower_back_cat_id from public.categories where name = 'Lower Back' limit 1;
  select id into knee_cat_id from public.categories where name = 'Knee' limit 1;
  select id into shoulder_cat_id from public.categories where name = 'Shoulder' limit 1;
  select id into neck_cat_id from public.categories where name = 'Neck' limit 1;
  select id into arms_cat_id from public.categories where name = 'Arms' limit 1;
  select id into legs_cat_id from public.categories where name = 'Legs' limit 1;

  insert into public.exercises
    (category_id, title, target_muscles, description, steps, media_url, media_attribution, duration_seconds)
  values
    (
      foot_heel_cat_id,
      'Ankle Circles',
      array['Calves'],
      'Use a sturdy object like a squat rack to hold yourself.',
      array['Use a sturdy object like a squat rack to hold yourself.', 'Lift the right leg in the air (just around 2 inches from the floor) and perform a circular motion with the big toe. Pretend that you are drawing a big circle with it. Tip: One circle equals 1 repetition. Breathe normally as you perform the movement.', 'When you are done with the right foot, then repeat with the left leg.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1368-uL9CsKm.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      foot_heel_cat_id,
      'Anterior Tibialis-SMR',
      array['Calves'],
      'Begin seated on the ground with your legs bent and your feet on the floor.',
      array['Begin seated on the ground with your legs bent and your feet on the floor.', 'Using a Muscle Roller or a rolling pin, apply pressure to the muscles on the outside of your shins. Work from just below the knee to above the ankle, pausing at points of tension for 10-30 seconds. Repeat on the other leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Anterior_Tibialis-SMR/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Calf Stretch Elbows Against Wall',
      array['Calves'],
      'Stand facing a wall from a couple feet away.',
      array['Stand facing a wall from a couple feet away.', 'Lean against the wall, placing your weight on your forearms.', 'Attempt to keep your heels on the ground. Hold for 10-20 seconds. You may move further or closer the wall, making it more or less difficult, respectively.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf_Stretch_Elbows_Against_Wall/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Calf Stretch Hands Against Wall',
      array['Calves'],
      'Stand facing a wall from several feet away. Stagger your stance, placing one foot forward.',
      array['Stand facing a wall from several feet away. Stagger your stance, placing one foot forward.', 'Lean forward and rest your hands on the wall, keeping your heel, hip and head in a straight line.', 'Attempt to keep your heel on the ground. Hold for 10-20 seconds and then switch sides.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1377-m0tCHqc.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      foot_heel_cat_id,
      'Calves-SMR',
      array['Calves'],
      'Begin seated on the floor. Place a foam roller underneath your lower leg. Your other leg can either be crossed over the opposite or be placed on the floor, supporting some of your weight. This will be your starting po...',
      array['Begin seated on the floor. Place a foam roller underneath your lower leg. Your other leg can either be crossed over the opposite or be placed on the floor, supporting some of your weight. This will be your starting position.', 'Place your hands to your side or just behind you, and press down to raise your hips off of the floor, placing much of your weight against your calf muscle. Roll from below the knee to above the ankle, pausing at points of tension for 10-30 seconds. Repeat for the other leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calves-SMR/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Foot-SMR',
      array['Calves'],
      'This exercise stretches the fascia of the muscles in the feet. Start off seated with your shoes removed. Using a foot roller or a similar object, such as a small section of pvc pipe, place your foot against the roller...',
      array['This exercise stretches the fascia of the muscles in the feet. Start off seated with your shoes removed. Using a foot roller or a similar object, such as a small section of pvc pipe, place your foot against the roller across the arch of your foot. This will be your starting position.', 'Press down firmly, rolling across the arch of your foot. Hold for 10-30 seconds, and then switch feet.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Foot-SMR/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Knee Circles',
      array['Calves', 'Hamstrings', 'Quadriceps'],
      'Stand with your legs together and hands by your waist.',
      array['Stand with your legs together and hands by your waist.', 'Now move your knees in a circular motion as you breathe normally.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Knee_Circles/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Peroneals Stretch',
      array['Calves'],
      'In a seated position, loop a belt, rope, or band around one foot. This will be your starting position.',
      array['In a seated position, loop a belt, rope, or band around one foot. This will be your starting position.', 'With the leg extended and the heel off of the ground, pull on the belt so that the foot is inverted, with the inside of the foot being pulled towards you. Hold for 10-20 seconds, and then switch sides.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1388-XhfS1DZ.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      foot_heel_cat_id,
      'Peroneals-SMR',
      array['Calves'],
      'Lay on your side, supporting your weight on your forearm and on a foam roller placed on the outside of your lower leg. Your upper leg can either be on top of your lower leg, or you can cross it in front of you. This w...',
      array['Lay on your side, supporting your weight on your forearm and on a foam roller placed on the outside of your lower leg. Your upper leg can either be on top of your lower leg, or you can cross it in front of you. This will be your starting position.', 'Raise your hips off of the ground and begin to roll from below the knee to above the ankle on the side of your leg, pausing at points of tension for 10-30 seconds. Repeat on the other leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Peroneals-SMR/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Posterior Tibialis Stretch',
      array['Calves'],
      'In a seated position, loop a belt, rope, or band around one foot. This will be your starting position.',
      array['In a seated position, loop a belt, rope, or band around one foot. This will be your starting position.', 'With the leg extended and the heel off of the ground, pull on the belt so that the foot is everted, with the outside of the foot being pulled towards you. Hold for 10-20 seconds, and then switch sides.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1389-DEEqoI2.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      foot_heel_cat_id,
      'Seated Calf Stretch',
      array['Calves', 'Hamstrings', 'Lower Back'],
      'Sit up straight on an exercise mat.',
      array['Sit up straight on an exercise mat.', 'Bend one knee and put that foot on the floor to stabilize the torso.', 'Straighten your other leg and flex your ankle.', 'Using a band, towel, or your hand if you can reach, pull the toes toward you. Hold for 10 to 20 seconds, then switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Seated_Calf_Stretch/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Standing Gastrocnemius Calf Stretch',
      array['Calves', 'Hamstrings'],
      'Place your right heel on a step with your knee extended and lean forward to grab your right toe with your right hand. Your left knee should be slightly bent and your back should be straight.',
      array['Place your right heel on a step with your knee extended and lean forward to grab your right toe with your right hand. Your left knee should be slightly bent and your back should be straight.', 'Support your weight on your left leg and place your left hand on your left thigh.', 'Pull your right toes toward your knee until you feel a stretch in your calf.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Gastrocnemius_Calf_Stretch/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Standing Soleus And Achilles Stretch',
      array['Calves'],
      'Stand with your feet hip-distance apart, one foot slightly in front of the other.',
      array['Stand with your feet hip-distance apart, one foot slightly in front of the other.', 'Bend both knees, keeping your back heel on the floor. Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Soleus_And_Achilles_Stretch/0.jpg',
      null,
      30
    ),
    (
      foot_heel_cat_id,
      'Balance Board',
      array['Calves', 'Hamstrings', 'Quadriceps'],
      'Place a balance board in front of you.',
      array['Place a balance board in front of you.', 'Stand up on it and try to balance yourself.', 'Hold the balance for as long as desired.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0020-xAySMB0.gif',
      '© Gym visual — https://gymvisual.com/',
      35
    ),
    (
      foot_heel_cat_id,
      'Calf Raises - With Bands',
      array['Calves'],
      'Grab an exercise band and stand on it with your toes making sure that the length of the band between the foot and the arms is the same for both sides.',
      array['Grab an exercise band and stand on it with your toes making sure that the length of the band between the foot and the arms is the same for both sides.', 'While holding the handles of the band, raise the arms to the side of your head as if you were getting ready to perform a shoulder press. The palms should be facing forward with the elbows bent and to the sides. This movement will create tension on the band. This will be your starting position.', 'Keeping the hands by your shoulder, stand up on your toes as you exhale and contract the calves hard at the top of the movement.', 'After a one second contraction, slowly go back down to the starting position.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Calf_Raises_-_With_Bands/0.jpg',
      null,
      35
    ),
    (
      foot_heel_cat_id,
      'Donkey Calf Raises',
      array['Calves'],
      'For this exercise you will need access to a donkey calf raise machine. Start by positioning your lower back and hips under the padded lever provided. The tailbone area should be the one making contact with the pad.',
      array['For this exercise you will need access to a donkey calf raise machine. Start by positioning your lower back and hips under the padded lever provided. The tailbone area should be the one making contact with the pad.', 'Place both of your arms on the side handles and place the balls of your feet on the calf block with the heels extending off. Align the toes forward, inward or outward, depending on the area you wish to target, and straighten the knees without locking them. This will be your starting position.', 'Raise your heels as you breathe out by extending your ankles as high as possible and flexing your calf. Ensure that the knee is kept stationary at all times. There should be no bending at any time. Hold the contracted position by a second before you start to go back down.', 'Go back slowly to the starting position as you breathe in by lowering your heels as you bend the ankles until calves are stretched.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0284-u5ESqzH.gif',
      '© Gym visual — https://gymvisual.com/',
      35
    ),
    (
      hip_pelvic_cat_id,
      'Adductor',
      array['Adductors'],
      'Lie face down with one leg on a foam roll.',
      array['Lie face down with one leg on a foam roll.', 'Rotate the leg so that the foam roll contacts against your inner thigh. Shift as much weight onto the foam roll as can be tolerated.', 'While trying to relax the muscles if the inner thigh, roll over the foam between your hip and knee, holding points of tension for 10-30 seconds. Repeat with the other leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Adductor/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Adductor/Groin',
      array['Adductors'],
      'Lie on your back with your feet raised towards the ceiling.',
      array['Lie on your back with your feet raised towards the ceiling.', 'Have your partner hold your feet or ankles. Abduct your legs as far as you can. This will be your starting position.', 'Attempt to squeeze your legs together for 10 or more seconds, while your partner prevents you from doing so.', 'Now, relax the muscles in your legs as your partner pushes your feet apart, stretching as far as is comfortable for you. Be sure to let your partner know when the stretch is adequate to prevent overstretching or injury.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Adductor_Groin/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Ankle On The Knee',
      array['Glutes'],
      'From a lying position, bend your knees and keep your feet on the floor.',
      array['From a lying position, bend your knees and keep your feet on the floor.', 'Place your ankle of one foot on your opposite knee.', 'Grasp the thigh or knee of the bottom leg and pull both of your legs into the chest. Relax your neck and shoulders. Hold for 10-20 seconds and then switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Ankle_On_The_Knee/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Groin and Back Stretch',
      array['Adductors'],
      'Sit on the floor with your knees bent and feet together.',
      array['Sit on the floor with your knees bent and feet together.', 'Interlock your fingers behind your head. This will be your starting position.', 'Curl downwards, bringing your elbows to the inside of your thighs. After a brief pause, return to the starting position with your head up and your back straight. Repeat for 10-20 repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Groin_and_Back_Stretch/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Hip Circles (prone)',
      array['Abductors', 'Adductors'],
      'Position yourself on your hands and knees on the ground. Maintaining good posture, raise one bent knee off of the ground. This will be your starting position.',
      array['Position yourself on your hands and knees on the ground. Maintaining good posture, raise one bent knee off of the ground. This will be your starting position.', 'Keeping the knee in a bent position, rotate the femur in an arc, attempting to make a big circle with your knee.', 'Perform this slowly for a number of repetitions, and repeat on the other side.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hip_Circles_prone/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'IT Band and Glute Stretch',
      array['Abductors'],
      'Loop a belt, rope, or band around one of your feet, and swing that leg across your body to the opposite side, keeping the leg extended as you lay on the ground. This will be your starting position.',
      array['Loop a belt, rope, or band around one of your feet, and swing that leg across your body to the opposite side, keeping the leg extended as you lay on the ground. This will be your starting position.', 'Keeping your foot off of the floor, pull on the belt, using the tension to pull the toes up. Hold for 10-20 seconds, and repeat on the other side.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/IT_Band_and_Glute_Stretch/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Iliotibial Tract-SMR',
      array['Abductors'],
      'Lay on your side, with the bottom leg placed onto a foam roller between the hip and the knee. The other leg can be crossed in front of you.',
      array['Lay on your side, with the bottom leg placed onto a foam roller between the hip and the knee. The other leg can be crossed in front of you.', 'Place as much of your weight as is tolerable onto your bottom leg; there is no need to keep your bottom leg in contact with the ground. Be sure to relax the muscles of the leg you are stretching.', 'Roll your leg over the foam from you hip to your knee, pausing for 10-30 seconds at points of tension. Repeat with the opposite leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Iliotibial_Tract-SMR/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Intermediate Hip Flexor and Quad Stretch',
      array['Quadriceps'],
      'Lie face down on the floor, with a rope, belt, or band looped around one foot.',
      array['Lie face down on the floor, with a rope, belt, or band looped around one foot.', 'Flex the knee and extend the hip of the leg to be stretched, using both hands to pull on the belt. Your knee and your hip should come off of the floor, creating tension in the hip flexors and quadriceps. Hold the stretch for 10-20 seconds, and repeat on the other leg.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1564-tFGKm99.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      hip_pelvic_cat_id,
      'Knee Across The Body',
      array['Glutes', 'Abductors', 'Lower Back'],
      'Lie down on the floor with your right leg straight. Bend your left leg and lower it across your body, holding the knee down toward the floor with your right hand. (The knee doesn''t need to touch the floor if you''re ti...',
      array['Lie down on the floor with your right leg straight. Bend your left leg and lower it across your body, holding the knee down toward the floor with your right hand. (The knee doesn''t need to touch the floor if you''re tight.)', 'Place your left arm comfortably beside you and turn your head to the left. Imagine you have a weight tied to your tailbone. let your tailbone fall back toward the floor as your chest reaches in the opposite direction to stretch your lower back. Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Knee_Across_The_Body/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Kneeling Hip Flexor',
      array['Quadriceps'],
      'Kneel on a mat and bring your right knee up so the bottom of your foot is on the floor and extend your left leg out behind you so the top of your foot is on the floor.',
      array['Kneel on a mat and bring your right knee up so the bottom of your foot is on the floor and extend your left leg out behind you so the top of your foot is on the floor.', 'Shift your weight forward until you feel a stretch in your hip. Hold for 15 seconds, then repeat for your other side.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Kneeling_Hip_Flexor/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Lying Glute',
      array['Glutes', 'Abductors'],
      'Lie on your back with your partner kneeling beside you.',
      array['Lie on your back with your partner kneeling beside you.', 'Flex the hip of one leg, raising it off of the floor. Rotate the leg so the foot is over the opposite hip, the lower leg perpendicular to your body. Your partner should hold the knee and ankle in place. This will be your starting position.', 'Attempt to push your leg towards your partner, who should be preventing any actual movement of the leg.', 'After 10-20 seconds, completely relax as your partner gently pushes the ankle and knee towards your chest. Be sure to inform your helper when the stretch is adequate to prevent injury or overstretching.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Lying_Glute/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'One Knee To Chest',
      array['Glutes', 'Hamstrings', 'Lower Back'],
      'Start off by lying on the floor.',
      array['Start off by lying on the floor.', 'Extend one leg straight and pull the other knee to your chest. Hold under the knee joint to protect the kneecap.', 'Gently tug that knee toward your nose.', 'Switch sides. This stretches the buttocks and lower back of the bent leg and the hip flexor of the straight leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/One_Knee_To_Chest/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Piriformis-SMR',
      array['Glutes'],
      'Sit with your buttocks on top of a foam roll. Bend your knees, and then cross one leg so that the ankle is over the knee. This will be your starting position.',
      array['Sit with your buttocks on top of a foam roll. Bend your knees, and then cross one leg so that the ankle is over the knee. This will be your starting position.', 'Shift your weight to the side of the crossed leg, rolling over the buttocks until you feel tension in your upper glute. You may assist the stretch by using one hand to pull the bent knee towards your chest. Hold this position for 10-30 seconds, and then switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Piriformis-SMR/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Seated Glute',
      array['Glutes', 'Adductors'],
      'In a seated position with your knees bent, cross one ankle over the opposite knee. Your partner will stand behind you. Now, lean forward as your partner braces your shoulders with their hands. This will be your starti...',
      array['In a seated position with your knees bent, cross one ankle over the opposite knee. Your partner will stand behind you. Now, lean forward as your partner braces your shoulders with their hands. This will be your starting position.', 'Attempt to push your torso back for 10-20 seconds, as your partner prevents any actual movement of your torso.', 'Now relax your muscles as your partner increases the stretch by gently pushing your torso forward for 10-20 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Seated_Glute/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Side Leg Raises',
      array['Adductors'],
      'Stand next to a chair, which you may hold onto as a support. Stand on one leg. This will be your starting position.',
      array['Stand next to a chair, which you may hold onto as a support. Stand on one leg. This will be your starting position.', 'Keeping your leg straight, raise it as far out to the side as possible, and swing it back down, allowing it to cross the opposite leg.', 'Repeat this swinging motion 5-10 times, increasing the range of motion as you do so.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Side_Leg_Raises/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Standing Hip Circles',
      array['Abductors', 'Adductors'],
      'Begin standing on one leg, holding to a vertical support.',
      array['Begin standing on one leg, holding to a vertical support.', 'Raise the unsupported knee to 90 degrees. This will be your starting position.', 'Open the hip as far as possible, attempting to make a big circle with your knee.', 'Perform this movement slowly for a number of repetitions, and repeat on the other side.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Hip_Circles/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Standing Hip Flexors',
      array['Quadriceps'],
      'Stand up straight with the spine vertical, the left foot slightly in front of the right.',
      array['Stand up straight with the spine vertical, the left foot slightly in front of the right.', 'Bend both knees and lift the back heel off the floor as you press the right hip forward. You can''t get a thorough, deep stretch in this position, however, because it''s hard to relax the hip flexor and stand on it at the same time. Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Hip_Flexors/0.jpg',
      null,
      30
    ),
    (
      hip_pelvic_cat_id,
      'Monster Walk',
      array['Abductors'],
      'Place a band around both ankles and another around both knees. There should be enough tension that they are tight when your feet are shoulder width apart.',
      array['Place a band around both ankles and another around both knees. There should be enough tension that they are tight when your feet are shoulder width apart.', 'To begin, take short steps forward alternating your left and right foot.', 'After several steps, do just the opposite and walk backward to where you started.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0628-O95afRA.gif',
      '© Gym visual — https://gymvisual.com/',
      35
    ),
    (
      hip_pelvic_cat_id,
      'Butt Lift (Bridge)',
      array['Glutes', 'Hamstrings'],
      'Lie flat on the floor on your back with the hands by your side and your knees bent. Your feet should be placed around shoulder width. This will be your starting position.',
      array['Lie flat on the floor on your back with the hands by your side and your knees bent. Your feet should be placed around shoulder width. This will be your starting position.', 'Pushing mainly with your heels, lift your hips off the floor while keeping your back straight. Breathe out as you perform this part of the motion and hold at the top for a second.', 'Slowly go back to the starting position as you breathe in.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Butt_Lift_Bridge/0.jpg',
      null,
      35
    ),
    (
      hip_pelvic_cat_id,
      'Single Leg Glute Bridge',
      array['Glutes', 'Hamstrings'],
      'Lay on the floor with your feet flat and knees bent.',
      array['Lay on the floor with your feet flat and knees bent.', 'Raise one leg off of the ground, pulling the knee to your chest. This will be your starting position.', 'Execute the movement by driving through the heel, extending your hip upward and raising your glutes off of the ground.', 'Extend as far as possible, pause and then return to the starting position.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Single_Leg_Glute_Bridge/0.jpg',
      null,
      35
    ),
    (
      lower_back_cat_id,
      'Cat Stretch',
      array['Lower Back', 'Middle Back', 'Traps'],
      'Position yourself on the floor on your hands and knees.',
      array['Position yourself on the floor on your hands and knees.', 'Pull your belly in and round your spine, lower back, shoulders, and neck, letting your head drop.', 'Hold for 15 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Cat_Stretch/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Chair Lower Back Stretch',
      array['Lats', 'Lower Back'],
      'Sit upright on a chair.',
      array['Sit upright on a chair.', 'Bend to one side with your arm over your head. You can hold onto the chair with your free hand.', 'Hold for 10 seconds, and repeat for your other side.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chair_Lower_Back_Stretch/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Child''s Pose',
      array['Lower Back', 'Glutes', 'Middle Back'],
      'Get on your hands and knees, walk your hands in front of you.',
      array['Get on your hands and knees, walk your hands in front of you.', 'Lower your buttocks down to sit on your heels. Let your arms drag along the floor as you sit back to stretch your entire spine.', 'Once you settle onto your heels, bring your hands next to your feet and relax. "breathe" into your back. Rest your forehead on the floor. Avoid this position if you have knee problems.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Childs_Pose/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Dancer''s Stretch',
      array['Lower Back', 'Abductors', 'Glutes'],
      'Sit up on the floor.',
      array['Sit up on the floor.', 'Cross your right leg over your left, keeping the knee bent. Your left leg is straight and down on the floor.', 'Place your left arm on your right leg and your right hand on the floor.', 'Rotate your upper body to the right, and hold for 10-20 seconds. Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Dancers_Stretch/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Hug A Ball',
      array['Lower Back', 'Calves', 'Glutes'],
      'Seat yourself on the floor.',
      array['Seat yourself on the floor.', 'Straddle an exercise ball between both legs and lower your hips down toward the floor.', 'Hug your arms around the ball to support your body. Adjust your legs so that your feet are flat on the floor and your knees line up over your ankles. Keep a good grip on the ball so it doesn''t roll away from you and send you back onto your buttocks.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hug_A_Ball/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Hug Knees To Chest',
      array['Lower Back', 'Glutes'],
      'Lie down on your back and pull both knees up to your chest.',
      array['Lie down on your back and pull both knees up to your chest.', 'Hold your arms under the knees, not over (that would put to much pressure on your knee joints).', 'Slowly pull the knees toward your shoulders. This also stretches your buttocks muscles.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1418-znP9SIh.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      lower_back_cat_id,
      'Lower Back-SMR',
      array['Lower Back'],
      'In a seated position, place a foam roll under your lower back. Cross your arms in front of you and protract your shoulders. This will be your starting position.',
      array['In a seated position, place a foam roll under your lower back. Cross your arms in front of you and protract your shoulders. This will be your starting position.', 'Raise your hips off of the floor and lean back, keeping your weight on your lower back. Now shift your weight slightly to one side, keeping your weight off of the spine and on the muscles to the side of it. Roll over your lower back, holding points of tension for 10-30 seconds. Repeat on the other side.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Lower_Back-SMR/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Middle Back Stretch',
      array['Middle Back', 'Abdominals', 'Lats', 'Lower Back'],
      'Stand so your feet are shoulder width apart and your hands are on your hips.',
      array['Stand so your feet are shoulder width apart and your hands are on your hips.', 'Twist at your waist until you feel a stretch. Hold for 10 to 15 seconds, then twist to the other side.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Middle_Back_Stretch/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Pelvic Tilt Into Bridge',
      array['Lower Back'],
      'Lie down with your feet on the floor, heels directly under your knees.',
      array['Lie down with your feet on the floor, heels directly under your knees.', 'Lift only your tailbone to the ceiling to stretch your lower back. (Don''t lift the entire spine yet.) Pull in your stomach.', 'To go into a bridge, lift the entire spine except the neck.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1422-D9qe7CM.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      lower_back_cat_id,
      'Spinal Stretch',
      array['Middle Back', 'Lats', 'Lower Back', 'Neck', 'Traps'],
      'Sit in a chair so your back is straight and your feet planted on the floor.',
      array['Sit in a chair so your back is straight and your feet planted on the floor.', 'Interlace your fingers behind your head, elbows out and your chin down.', 'Twist your upper body to one side about 3 times as far as you can. Then lean forward and twist your torso to reach your elbow to the floor on the inside of your knee.', 'Return to upright position and then repeat for your other side.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1363-JbC2iaV.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      lower_back_cat_id,
      'Standing Pelvic Tilt',
      array['Lower Back', 'Glutes'],
      'Start off with your feet hip-distance apart.',
      array['Start off with your feet hip-distance apart.', 'Bend your knees slightly to keep them soft and springy.', 'You may want to move your pelvis forward and backward and back few times before holding the tailbone forward in this stretch.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1364-cuKYxhu.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      lower_back_cat_id,
      'Superman',
      array['Lower Back', 'Glutes', 'Hamstrings'],
      'To begin, lie straight and face down on the floor or exercise mat. Your arms should be fully extended in front of you. This is the starting position.',
      array['To begin, lie straight and face down on the floor or exercise mat. Your arms should be fully extended in front of you. This is the starting position.', 'Simultaneously raise your arms, legs, and chest off of the floor and hold this contraction for 2 seconds. Tip: Squeeze your lower back to get the best results from this exercise. Remember to exhale during this movement. Note: When holding the contracted position, you should look like superman when he is flying.', 'Slowly begin to lower your arms, legs and chest back down to the starting position while inhaling.', 'Repeat for the recommended amount of repetitions prescribed in your program.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Superman/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Windmills',
      array['Abductors', 'Glutes', 'Hamstrings', 'Lower Back'],
      'Lie on your back with your arms extended out to the sides and your legs straight. This will be your starting position.',
      array['Lie on your back with your arms extended out to the sides and your legs straight. This will be your starting position.', 'Lift one leg and quickly cross it over your body, attempting to touch the ground near the opposite hand.', 'Return to the starting position, and repeat with the opposite leg. Continue to alternate for 10-20 repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Windmills/0.jpg',
      null,
      30
    ),
    (
      lower_back_cat_id,
      'Hyperextensions With No Hyperextension Bench',
      array['Lower Back', 'Glutes', 'Hamstrings'],
      'With someone holding down your legs, slide yourself down to the edge a flat bench until your hips hang off the end of the bench. Tip: Your entire upper body should be hanging down towards the floor. Also, you will be ...',
      array['With someone holding down your legs, slide yourself down to the edge a flat bench until your hips hang off the end of the bench. Tip: Your entire upper body should be hanging down towards the floor. Also, you will be in the same position as if you were on a hyperextension bench but the range of motion will be shorter due to the height of the flat bench vs. that of the hyperextension bench.', 'With your body straight, cross your arms in front of you (my preference) or behind your head. This will be your starting position. Tip: You can also hold a weight plate for extra resistance in front of you under your crossed arms.', 'Start bending forward slowly at the waist as far as you can while keeping your back flat. Inhale as you perform this movement. Keep moving forward until you almost touch the floor or you feel a nice stretch on the hamstrings (whichever comes first). Tip: Never round the back as you perform this exercise.', 'Slowly raise your torso back to the initial position as you exhale. Tip: Avoid the temptation to arch your back past a straight line. Also, do not swing the torso at any time in order to protect the back from injury.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hyperextensions_With_No_Hyperextension_Bench/0.jpg',
      null,
      35
    ),
    (
      lower_back_cat_id,
      'Weighted Ball Hyperextension',
      array['Lower Back', 'Glutes', 'Hamstrings', 'Middle Back'],
      'To begin, lie down on an exercise ball with your torso pressing against the ball and parallel to the floor. The ball of your feet should be pressed against the floor to help keep you balanced. Place a weighted plate u...',
      array['To begin, lie down on an exercise ball with your torso pressing against the ball and parallel to the floor. The ball of your feet should be pressed against the floor to help keep you balanced. Place a weighted plate under your chin or behind your neck. This is the starting position.', 'Slowly raise your torso up by bending at the waist and lower back. Remember to exhale during this movement.', 'Hold the contraction on your lower back for a second and lower your torso back down to the starting position while inhaling.', 'Repeat for the recommended amount of repetitions prescribed in your program.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Weighted_Ball_Hyperextension/0.jpg',
      null,
      35
    ),
    (
      knee_cat_id,
      'All Fours Quad Stretch',
      array['Quadriceps'],
      'Start off on your hands and knees, then lift your leg off the floor and hold the foot with your hand.',
      array['Start off on your hands and knees, then lift your leg off the floor and hold the foot with your hand.', 'Use your hand to hold the foot or ankle, keeping the knee fully flexed, stretching the quadriceps and hip flexors.', 'Focus on extending your hips, thrusting them towards the floor. Hold for 10-20 seconds and then switch sides.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1512-qBcKorM.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      knee_cat_id,
      'Chair Leg Extended Stretch',
      array['Hamstrings', 'Adductors'],
      'Sit upright in a chair and grip the seat on the sides.',
      array['Sit upright in a chair and grip the seat on the sides.', 'Raise one leg, extending the knee, flexing the ankle as you do so.', 'Slowly move that leg outward as far as you can, and then back to the center and down.', 'Repeat for your other leg.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1548-xGgAGPm.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      knee_cat_id,
      'Front Leg Raises',
      array['Hamstrings'],
      'Stand next to a chair or other support, holding on with one hand.',
      array['Stand next to a chair or other support, holding on with one hand.', 'Swing your leg forward, keeping the leg straight. Continue with a downward swing, bringing the leg as far back as your flexibility allows. Repeat 5-10 times, and then switch legs.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Front_Leg_Raises/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'Hamstring Stretch',
      array['Hamstrings'],
      'Lie on your back with one leg extended above you, with the hip at ninety degrees. Keep the other leg flat on the floor.',
      array['Lie on your back with one leg extended above you, with the hip at ninety degrees. Keep the other leg flat on the floor.', 'Loop a belt, band, or rope over the ball of your foot. This will be your starting position.', 'Pull on the belt to create tension in the calves and hamstrings. Hold this stretch for 10-30 seconds, and repeat with the other leg.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1511-99rWm7w.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      knee_cat_id,
      'Hamstring-SMR',
      array['Hamstrings'],
      'In a seated position, extend your legs over a foam roll so that it is position on the back of the upper legs. Place your hands to the side or behind you to help support your weight. This will be your starting position.',
      array['In a seated position, extend your legs over a foam roll so that it is position on the back of the upper legs. Place your hands to the side or behind you to help support your weight. This will be your starting position.', 'Using your hands, lift your hips off of the floor and shift your weight on the foam roll to one leg. Relax the hamstrings of the leg you are stretching.', 'Roll over the foam from below the hip to above the back of the knee, pausing at points of tension for 10-30 seconds. Repeat for the other leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hamstring-SMR/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'Inchworm',
      array['Hamstrings'],
      'Stand with your feet close together. Keeping your legs straight, stretch down and put your hands on the floor directly in front of you. This will be your starting position.',
      array['Stand with your feet close together. Keeping your legs straight, stretch down and put your hands on the floor directly in front of you. This will be your starting position.', 'Begin by walking your hands forward slowly, alternating your left and your right. As you do so, bend only at the hip, keeping your legs straight.', 'Keep going until your body is parallel to the ground in a pushup position.', 'Now, keep your hands in place and slowly take short steps with your feet, moving only a few inches at a time.', 'Continue walking until your feet are by hour hands, keeping your legs straight as you do so.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1471-ZgsNQ6d.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      knee_cat_id,
      'Leg-Up Hamstring Stretch',
      array['Hamstrings'],
      'Lie flat on your back, bend one knee, and put that foot flat on the floor to stabilize your spine.',
      array['Lie flat on your back, bend one knee, and put that foot flat on the floor to stabilize your spine.', 'Extend the other leg in the air. If you''re tight, you wont be able to straighten it. That''s okay. Extend the knee so that the sole of the lifted foot faces the ceiling (or as close as you can get it).', 'Slowly straighten the legs as much as possible and then pull the leg toward your nose. Switch sides.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1576-sU5BrfP.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      knee_cat_id,
      'Lying Prone Quadriceps',
      array['Quadriceps'],
      'Lay face down on the floor with your partner kneeling beside you. Flex one knee and raise that leg off the ground, attempting to touch your glutes with your foot. Your partner should hold the knee and ankle. This will...',
      array['Lay face down on the floor with your partner kneeling beside you. Flex one knee and raise that leg off the ground, attempting to touch your glutes with your foot. Your partner should hold the knee and ankle. This will be your starting position.', 'Attempt to extend your knee while your partner prevents any actual movement.', 'After 10-20 seconds, relax your muscles as your partner gently pushes the foot towards your glutes, further stretching the quadriceps and hip flexors.', 'After 10-20 seconds, switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Lying_Prone_Quadriceps/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'On-Your-Back Quad Stretch',
      array['Quadriceps'],
      'Lie on a flat bench or step, and hang one leg and arm over the side.',
      array['Lie on a flat bench or step, and hang one leg and arm over the side.', 'Bend the knee and hold the top of the foot. As you do this, be careful not to arch your lower back.', 'Pull the belly button to the spine to stay in neutral. Press your foot down and into your hand. To add the hip stretch, lift the hip of the leg you''re holding up toward the ceiling.', 'Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/On-Your-Back_Quad_Stretch/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'Quad Stretch',
      array['Quadriceps'],
      'Lay on your side. Loop a belt, rope, or band around your top foot. Flex the knee and extend your hip, attempting to touch your glutes with your foot, and holding the belt with your hands. This will be your starting po...',
      array['Lay on your side. Loop a belt, rope, or band around your top foot. Flex the knee and extend your hip, attempting to touch your glutes with your foot, and holding the belt with your hands. This will be your starting position.', 'With the belt being held over the shoulder or overhead, gently pull to increase the stretch in the quadriceps. Hold for 10-20 seconds, and then switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Quad_Stretch/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'Quadriceps-SMR',
      array['Quadriceps'],
      'Lay facedown on the floor with your weight supported by your hands or forearms. Place a foam roll underneath one leg on the quadriceps, and keep the foot off of the ground. Make sure to relax the leg as much as possib...',
      array['Lay facedown on the floor with your weight supported by your hands or forearms. Place a foam roll underneath one leg on the quadriceps, and keep the foot off of the ground. Make sure to relax the leg as much as possible. This will be your starting position.', 'Shifting as much weight onto the leg to be stretched as is tolerable, roll over the foam from above the knee to below the hip, holding points of tension for 10-30 seconds. Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Quadriceps-SMR/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'Rear Leg Raises',
      array['Quadriceps'],
      'Place yourself on your hands knees on an exercise mat. Your head should be looking forward and the bend of the knees should create a 90-degree angle between the hamstrings and the calves. This will be your starting po...',
      array['Place yourself on your hands knees on an exercise mat. Your head should be looking forward and the bend of the knees should create a 90-degree angle between the hamstrings and the calves. This will be your starting position.', 'Extend one leg up and behind you. The knee and hip should both extend. Repeat for 5-10 repetitions, and then switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Rear_Leg_Raises/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'Runner''s Stretch',
      array['Hamstrings', 'Calves'],
      'It''s easiest to get into this stretch if you start standing up, put one leg behind you, and slowly lower your torso down to the floor.',
      array['It''s easiest to get into this stretch if you start standing up, put one leg behind you, and slowly lower your torso down to the floor.', 'Keep the front heel on the floor (if it lifts up, scoot your other leg further back).', 'Place your hands on either side of your front leg. To get more out of this stretch, push your butt up toward the ceiling, and then gradually lower it back toward the floor. You''ll Stretch the hip flexor of the back leg and the hamstring and buttocks of the front.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1585-0mB6wHO.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      knee_cat_id,
      'Seated Hamstring',
      array['Hamstrings', 'Calves'],
      'In a seated position with your legs extended, have your partner stand behind you. Now, lean forward as your partner braces your shoulders with their hands. This will be your starting position.',
      array['In a seated position with your legs extended, have your partner stand behind you. Now, lean forward as your partner braces your shoulders with their hands. This will be your starting position.', 'Attempt to push your torso back for 10-20 seconds, as your partner prevents any actual movement of your torso.', 'Now relax your muscles as your partner increases the stretch by gently pushing your torso forward for 10-20 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Seated_Hamstring/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'Standing Elevated Quad Stretch',
      array['Quadriceps'],
      'Start by standing with your back about two to three feet away from a bench or step.',
      array['Start by standing with your back about two to three feet away from a bench or step.', 'Lift one leg behind you and rest your foot on the step,either on your instep or the ball of your foot, whichever you find most comfortable.', 'Keep your supporting knee slightly bent and avoid letting that knee extend out beyond your toes. Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Elevated_Quad_Stretch/0.jpg',
      null,
      30
    ),
    (
      knee_cat_id,
      'Standing Hamstring and Calf Stretch',
      array['Hamstrings'],
      'Being by looping a belt, band, or rope around one foot. While standing, place that foot forward.',
      array['Being by looping a belt, band, or rope around one foot. While standing, place that foot forward.', 'Bend your back leg, while keeping the front one straight. Now raise the toes of your front foot off of the ground and lean forward.', 'Using the belt, pull on the top of the foot to increase the stretch in the calf. Hold for 10-20 seconds and repeat with the other foot.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1599-xTjr103.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      knee_cat_id,
      'Step-up with Knee Raise',
      array['Glutes', 'Hamstrings', 'Quadriceps'],
      'Stand facing a box or bench of an appropriate height with your feet together. This will be your starting position.',
      array['Stand facing a box or bench of an appropriate height with your feet together. This will be your starting position.', 'Begin the movement by stepping up, putting your left foot on the top of the bench. Extend through the hip and knee of your front leg to stand up on the box. As you stand on the box with your left leg, flex your right knee and hip, bringing your knee as high as you can.', 'Reverse this motion to step down off the box, and then repeat the sequence on the opposite leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Step-up_with_Knee_Raise/0.jpg',
      null,
      35
    ),
    (
      knee_cat_id,
      'Bodyweight Squat',
      array['Quadriceps', 'Glutes', 'Hamstrings'],
      'Stand with your feet shoulder width apart. You can place your hands behind your head. This will be your starting position.',
      array['Stand with your feet shoulder width apart. You can place your hands behind your head. This will be your starting position.', 'Begin the movement by flexing your knees and hips, sitting back with your hips.', 'Continue down to full depth if you are able,and quickly reverse the motion until you return to the starting position. As you squat, keep your head and chest up and push your knees out.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bodyweight_Squat/0.jpg',
      null,
      35
    ),
    (
      shoulder_cat_id,
      'Arm Circles',
      array['Shoulders', 'Traps'],
      'Stand up and extend your arms straight out by the sides. The arms should be parallel to the floor and perpendicular (90-degree angle) to your torso. This will be your starting position.',
      array['Stand up and extend your arms straight out by the sides. The arms should be parallel to the floor and perpendicular (90-degree angle) to your torso. This will be your starting position.', 'Slowly start to make circles of about 1 foot in diameter with each outstretched arm. Breathe normally as you perform the movement.', 'Continue the circular motion of the outstretched arms for about ten seconds. Then reverse the movement, going the opposite direction.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Arm_Circles/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Behind Head Chest Stretch',
      array['Chest', 'Shoulders'],
      'Sit upright on the floor with your partner behind you.',
      array['Sit upright on the floor with your partner behind you.', 'Place your hands behind your hand, and push your elbows back as far as you can. Your partner should hold your elbows. This will be your starting position.', 'Gently attempt to pull your elbows forward with your hands still behind your head for 10 or more seconds. Your partner should prevent your elbows from moving.', 'Now, relax your muscles and have your partner gently pull the elbows back as far as it comfortable for you. Be sure to let your partner know when the stretch is adequate to prevent overstretching or injury.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1259-QoHIhPl.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      shoulder_cat_id,
      'Chair Upper Body Stretch',
      array['Shoulders', 'Biceps', 'Chest'],
      'Sit on the edge of a chair, gripping the back of it.',
      array['Sit on the edge of a chair, gripping the back of it.', 'Straighten your arms, keeping your back straight, and pull your upper body forward so you feel a stretch. Hold for 20-30 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chair_Upper_Body_Stretch/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Chest And Front Of Shoulder Stretch',
      array['Chest', 'Shoulders'],
      'Start off by standing with your legs together, holding a bodybar or a broomstick.',
      array['Start off by standing with your legs together, holding a bodybar or a broomstick.', 'Take a slightly wider than shoulder width grip on the pole and hold it in front of you with your palms facing down.', 'Carefully lift the pole up and behind your head.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1271-Uto7l43.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      shoulder_cat_id,
      'Elbow Circles',
      array['Shoulders', 'Traps'],
      'Sit or stand with your feet slightly apart.',
      array['Sit or stand with your feet slightly apart.', 'Place your hands on your shoulders with your elbows at shoulder level and pointing out.', 'Slowly make a circle with your elbows. Breathe out as you start the circle and breathe in as you complete the circle.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Elbow_Circles/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Round The World Shoulder Stretch',
      array['Shoulders', 'Biceps', 'Chest'],
      'Stand up straight with your legs together, holding a bodybar or broomstick.',
      array['Stand up straight with your legs together, holding a bodybar or broomstick.', 'Hold the pole behind your hips with a wider than shoulder width grip. Your palms should be down and your thumbs facing out.', 'Slowly lift your arms up behind your head. Don''t force it if it gets hard to lift further.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Round_The_World_Shoulder_Stretch/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Seated Front Deltoid',
      array['Shoulders', 'Chest'],
      'Sit upright on the floor with your legs bent, your partner standing behind you. Stick your arms straight out to your sides, with your palms facing the ground. Attempt to move them as far behind you as possible, as you...',
      array['Sit upright on the floor with your legs bent, your partner standing behind you. Stick your arms straight out to your sides, with your palms facing the ground. Attempt to move them as far behind you as possible, as your assistant holds your wrists. This will be your starting position.', 'Keeping your elbows straight, attempt to move your arms to the front, with your partner gently restraining you to prevent any actual movement for 10-20 seconds.', 'Now, relax your muscles and allow your partner to gently increase the stretch on the shoulders and chest. Hold for 10 to 20 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Seated_Front_Deltoid/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Shoulder Circles',
      array['Shoulders', 'Traps'],
      'With shoulders relaxed and arms resting loosely at your sides (or in your lap if you''re seated), gently roll your shoulders forward, up, back, and down.',
      array['With shoulders relaxed and arms resting loosely at your sides (or in your lap if you''re seated), gently roll your shoulders forward, up, back, and down.', 'Reverse direction. You can do this exercise alternating shoulders or both at the same time.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Shoulder_Circles/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Shoulder Raise',
      array['Shoulders', 'Lats'],
      'Relax your arms to your sides and raise your shoulders up toward your ears, then back down.',
      array['Relax your arms to your sides and raise your shoulders up toward your ears, then back down.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Shoulder_Raise/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Shoulder Stretch',
      array['Shoulders'],
      'Reach your left arm across your body and hold it straight.',
      array['Reach your left arm across your body and hold it straight.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Shoulder_Stretch/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Side Wrist Pull',
      array['Shoulders', 'Forearms', 'Lats'],
      'This stretch works best standing. Cross your left arm over the midline of your body and hold the left wrist in your right hand down at the level of your hips. Start the stretch with a bent left arm.',
      array['This stretch works best standing. Cross your left arm over the midline of your body and hold the left wrist in your right hand down at the level of your hips. Start the stretch with a bent left arm.', 'Slowly straighten, pull, and lift it up to shoulder height, as pictured. Feel this stretch originate in your back, not your shoulders, and don''t pull too hard on the shoulders joint. Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Side_Wrist_Pull/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'Upward Stretch',
      array['Shoulders', 'Chest', 'Lats'],
      'Extend both hands straight above your head, palms touching.',
      array['Extend both hands straight above your head, palms touching.', 'Slowly push your hands up and back, keeping your back straight.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Upward_Stretch/0.jpg',
      null,
      30
    ),
    (
      shoulder_cat_id,
      'External Rotation with Band',
      array['Shoulders'],
      'Choke the band around a post. The band should be at the same height as your elbow. Stand with your left side to the band a couple of feet away.',
      array['Choke the band around a post. The band should be at the same height as your elbow. Stand with your left side to the band a couple of feet away.', 'Grasp the end of the band with your right hand, and keep your elbow pressed firmly to your side. We recommend you hold a pad or foam roll in place with your elbow to keep it firmly in position.', 'With your upper arm in position, your elbow should be flexed to 90 degrees with your hand reaching across the front of your torso. This will be your starting position.', 'Execute the movement by rotating your arm in a backhand motion, keeping your elbow in place.', 'Continue as far as you are able, pause, and then return to the starting position.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/External_Rotation_with_Band/0.jpg',
      null,
      35
    ),
    (
      shoulder_cat_id,
      'Internal Rotation with Band',
      array['Shoulders'],
      'Choke the band around a post. The band should be at the same height as your elbow. Stand with your right side to the band a couple of feet away.',
      array['Choke the band around a post. The band should be at the same height as your elbow. Stand with your right side to the band a couple of feet away.', 'Grasp the end of the band with your right hand, and keep your elbow pressed firmly to your side. We recommend you hold a pad or foam roll in place with your elbow to keep it firmly in position.', 'With your upper arm in position, your elbow should be flexed to 90 degrees with your hand reaching away from your torso. This will be your starting position.', 'Execute the movement by rotating your arm in a forehand motion, keeping your elbow in place.', 'Continue as far as you are able, pause, and then return to the starting position.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Internal_Rotation_with_Band/0.jpg',
      null,
      35
    ),
    (
      shoulder_cat_id,
      'Band Pull Apart',
      array['Shoulders', 'Middle Back', 'Traps'],
      'Begin with your arms extended straight out in front of you, holding the band with both hands.',
      array['Begin with your arms extended straight out in front of you, holding the band with both hands.', 'Initiate the movement by performing a reverse fly motion, moving your hands out laterally to your sides.', 'Keep your elbows extended as you perform the movement, bringing the band to your chest. Ensure that you keep your shoulders back during the exercise.', 'Pause as you complete the movement, returning to the starting position under control.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Band_Pull_Apart/0.jpg',
      null,
      35
    ),
    (
      shoulder_cat_id,
      'Back Flyes - With Bands',
      array['Shoulders', 'Middle Back', 'Triceps'],
      'Run a band around a stationary post like that of a squat rack.',
      array['Run a band around a stationary post like that of a squat rack.', 'Grab the band by the handles and stand back so that the tension in the band rises.', 'Extend and lift the arms straight in front of you. Tip: Your arms should be straight and parallel to the floor while perpendicular to your torso. Your feet should be firmly planted on the floor spread at shoulder width. This will be your starting position.', 'As you exhale, move your arms to the sides and back. Keep your arms extended and parallel to the floor. Continue the movement until the arms are extended to your sides.', 'After a pause, go back to the original position as you inhale.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Back_Flyes_-_With_Bands/0.jpg',
      null,
      35
    ),
    (
      shoulder_cat_id,
      'Lateral Raise - With Bands',
      array['Shoulders'],
      'To begin, stand on an exercise band so that tension begins at arm''s length. Grasp the handles using a pronated (palms facing your thighs) grip that is slightly less than shoulder width. The handles should be resting o...',
      array['To begin, stand on an exercise band so that tension begins at arm''s length. Grasp the handles using a pronated (palms facing your thighs) grip that is slightly less than shoulder width. The handles should be resting on the sides of your thighs. Your arms should be extended with a slight bend at the elbows and your back should be straight. This will be your starting position.', 'Use your side shoulders to lift the handles to the sides as you exhale. Continue to lift the handles until they are slightly above parallel. Tip: As you lift the handles, slightly tilt the hand as if you were pouring water and keep your arms extended. Also, keep your torso stationary and pause for a second at the top of the movement.', 'Lower the handles back down slowly to the starting position. Inhale as you perform this portion of the movement.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Lateral_Raise_-_With_Bands/0.jpg',
      null,
      35
    ),
    (
      shoulder_cat_id,
      'Shoulder Press - With Bands',
      array['Shoulders', 'Triceps'],
      'To begin, stand on an exercise band so that tension begins at arm''s length. Grasp the handles and lift them so that the hands are at shoulder height at each side.',
      array['To begin, stand on an exercise band so that tension begins at arm''s length. Grasp the handles and lift them so that the hands are at shoulder height at each side.', 'Rotate the wrists so that the palms of your hands are facing forward. Your elbows should be bent, with the upper arms and forearms in line to the torso. This is your starting position.', 'As you exhale, lift the handles up until your arms are fully extended overhead.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Shoulder_Press_-_With_Bands/0.jpg',
      null,
      35
    ),
    (
      neck_cat_id,
      'Chin To Chest Stretch',
      array['Neck', 'Traps'],
      'Get into a seated position on the floor.',
      array['Get into a seated position on the floor.', 'Place both hands at the rear of your head, fingers interlocked, thumbs pointing down and elbows pointing straight ahead. Slowly pull your head down to your chest. Hold for 20-30 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Chin_To_Chest_Stretch/0.jpg',
      null,
      30
    ),
    (
      neck_cat_id,
      'Neck-SMR',
      array['Neck'],
      'Using a muscle roller or a rolling pin, place the roller behind your head and against your neck. Make sure that you do not place the roller directly against the spine, but turned slightly so that the roller is pressed...',
      array['Using a muscle roller or a rolling pin, place the roller behind your head and against your neck. Make sure that you do not place the roller directly against the spine, but turned slightly so that the roller is pressed against the muscles to either side of the spine. This will be your starting position.', 'Starting at the top of your neck, slowly roll down the muscles of your neck, pausing at points of tension for 10-30 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Neck-SMR/0.jpg',
      null,
      30
    ),
    (
      neck_cat_id,
      'Side Neck Stretch',
      array['Neck'],
      'Start with your shoulders relaxed, gently tilt your head towards your shoulder.',
      array['Start with your shoulders relaxed, gently tilt your head towards your shoulder.', 'Assist stretch with a gentle pull on the side of the head.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Side_Neck_Stretch/0.jpg',
      null,
      30
    ),
    (
      neck_cat_id,
      'Isometric Neck Exercise - Front And Back',
      array['Neck'],
      'With your head and neck in a neutral position (normal position with head erect facing forward), place both of your hands on the front side of your head.',
      array['With your head and neck in a neutral position (normal position with head erect facing forward), place both of your hands on the front side of your head.', 'Now gently push forward as you contract the neck muscles but resisting any movement of your head. Start with slow tension and increase slowly. Keep breathing normally as you execute this contraction.', 'Hold for the recommended number of seconds.', 'Now release the tension slowly.', 'Rest for the recommended amount of time and repeat with your hands placed on the back side of your head.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Isometric_Neck_Exercise_-_Front_And_Back/0.jpg',
      null,
      35
    ),
    (
      neck_cat_id,
      'Isometric Neck Exercise - Sides',
      array['Neck'],
      'With your head and neck in a neutral position (normal position with head erect facing forward), place your left hand on the left side of your head.',
      array['With your head and neck in a neutral position (normal position with head erect facing forward), place your left hand on the left side of your head.', 'Now gently push towards the left as you contract the left neck muscles but resisting any movement of your head. Start with slow tension and increase slowly. Keep breathing normally as you execute this contraction.', 'Hold for the recommended number of seconds.', 'Now release the tension slowly.', 'Rest for the recommended amount of time and repeat with your right hand placed on the right side of your head.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Isometric_Neck_Exercise_-_Sides/0.jpg',
      null,
      35
    ),
    (
      neck_cat_id,
      'Lying Face Down Plate Neck Resistance',
      array['Neck'],
      'Lie face down with your whole body straight on a flat bench while holding a weight plate behind your head. Tip: You will need to position yourself so that your shoulders are slightly above the end of a flat bench in o...',
      array['Lie face down with your whole body straight on a flat bench while holding a weight plate behind your head. Tip: You will need to position yourself so that your shoulders are slightly above the end of a flat bench in order for the upper chest, neck and face to be off the bench. This will be your starting position.', 'While keeping the plate secure on the back of your head slowly lower your head (as in saying "yes") as you breathe in.', 'Raise your head back up to the starting position in a semi-circular motion as you breathe out. Hold the contraction for a second.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Lying_Face_Down_Plate_Neck_Resistance/0.jpg',
      null,
      35
    ),
    (
      neck_cat_id,
      'Lying Face Up Plate Neck Resistance',
      array['Neck'],
      'Lie face up with your whole body straight on a flat bench while holding a weight plate on top of your forehead. Tip: You will need to position yourself so that your shoulders are slightly above the end of a flat bench...',
      array['Lie face up with your whole body straight on a flat bench while holding a weight plate on top of your forehead. Tip: You will need to position yourself so that your shoulders are slightly above the end of a flat bench in order for the traps, neck and head to be off the bench. This will be your starting position.', 'While keeping the plate secure on your forehead slowly lower your head back in a semi-circular motion as you breathe in.', 'Raise your head back up to the starting position in a semi-circular motion as you breathe out. Hold the contraction for a second.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Lying_Face_Up_Plate_Neck_Resistance/0.jpg',
      null,
      35
    ),
    (
      neck_cat_id,
      'Seated Head Harness Neck Resistance',
      array['Neck'],
      'Place a neck strap on the floor at the end of a flat bench. Once you have selected the weights, sit at the end of the flat bench with your feet wider than shoulder width apart from each other. Your toes should be poin...',
      array['Place a neck strap on the floor at the end of a flat bench. Once you have selected the weights, sit at the end of the flat bench with your feet wider than shoulder width apart from each other. Your toes should be pointed out.', 'Slowly move your torso forward until it is almost parallel with the floor. Using both hands, securely position the neck strap around your head. Tip: Make sure the weights are still lying on the floor to prevent any strain on the neck. Now grab the weight with both hands while elevating your torso back until it is almost perpendicular to the floor. Note: Your head and torso needs to be slightly tilted forward to perform this exercise.', 'Now place both hands on top of your knees. This is the starting position.', 'Slowly lower your neck down until your chin touches the upper part of your chest while breathing in.', 'While exhaling, bring your neck back to the starting position.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Seated_Head_Harness_Neck_Resistance/0.jpg',
      null,
      35
    ),
    (
      neck_cat_id,
      'Shoulder Circles',
      array['Shoulders', 'Traps'],
      'With shoulders relaxed and arms resting loosely at your sides (or in your lap if you''re seated), gently roll your shoulders forward, up, back, and down.',
      array['With shoulders relaxed and arms resting loosely at your sides (or in your lap if you''re seated), gently roll your shoulders forward, up, back, and down.', 'Reverse direction. You can do this exercise alternating shoulders or both at the same time.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Shoulder_Circles/0.jpg',
      null,
      30
    ),
    (
      neck_cat_id,
      'Upper Back Stretch',
      array['Middle Back'],
      'Clasp fingers together with your thumbs pointing down, round your shoulders as you reach your hands forward.',
      array['Clasp fingers together with your thumbs pointing down, round your shoulders as you reach your hands forward.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1365-GSDioYu.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      neck_cat_id,
      'Scapular Pull-Up',
      array['Traps', 'Lats', 'Middle Back'],
      'Take a pronated grip on a pull-up bar.',
      array['Take a pronated grip on a pull-up bar.', 'From a hanging position, raise yourself a few inches without using your arms. Do this by depressing your shoulder girdle in a reverse shrugging motion.', 'Pause at the completion of the movement, and then slowly return to the starting position before performing more repetitions.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0688-uTBt1HV.gif',
      '© Gym visual — https://gymvisual.com/',
      35
    ),
    (
      neck_cat_id,
      'Rhomboids-SMR',
      array['Middle Back', 'Traps'],
      'Lay down with your back on the floor. Place a foam roll underneath your upper back, and cross your arms in front of you, protracting your shoulders. This will be your starting position.',
      array['Lay down with your back on the floor. Place a foam roll underneath your upper back, and cross your arms in front of you, protracting your shoulders. This will be your starting position.', 'Raise your hips off of the ground, placing your weight onto the foam roll. Shift your weight to one side at a time, rolling over your middle and upper back. Pause at points of tension for 10-30 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Rhomboids-SMR/0.jpg',
      null,
      30
    ),
    (
      arms_cat_id,
      'Brachialis-SMR',
      array['Biceps'],
      'Lie on your side, with your upper arm against the foam roller. The upper arm should be more or less aligned with your body, with the outside of the bicep pressed against the foam roller.',
      array['Lie on your side, with your upper arm against the foam roller. The upper arm should be more or less aligned with your body, with the outside of the bicep pressed against the foam roller.', 'Raise your hips off of the floor, supporting your weight on your arm and on your feet. Hold for 10-30 seconds, and then switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Brachialis-SMR/0.jpg',
      null,
      30
    ),
    (
      arms_cat_id,
      'Kneeling Forearm Stretch',
      array['Forearms'],
      'Start by kneeling on a mat with your palms flat and your fingers pointing back toward your knees.',
      array['Start by kneeling on a mat with your palms flat and your fingers pointing back toward your knees.', 'Slowly lean back keeping your palms flat on the floor until you feel a stretch in your wrists and forearms. Hold for 20-30 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Kneeling_Forearm_Stretch/0.jpg',
      null,
      30
    ),
    (
      arms_cat_id,
      'Overhead Triceps',
      array['Triceps', 'Lats'],
      'Sit upright on the floor with your partner behind you. Raise one arm straight up, and flex the elbow, attempting to touch your hand to your back. Your parner should hold your elbow and wrist. This will be your startin...',
      array['Sit upright on the floor with your partner behind you. Raise one arm straight up, and flex the elbow, attempting to touch your hand to your back. Your parner should hold your elbow and wrist. This will be your starting position.', 'Attempt to extend the arm straight into the air as your partner prevents you from doing actually doing so.', 'After 10-20 seconds, relax the arm and allow your partner to further stretch the tricep by applying gentle pressure to the wrist. Hold for 10-20 seconds, and then switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Overhead_Triceps/0.jpg',
      null,
      30
    ),
    (
      arms_cat_id,
      'Seated Biceps',
      array['Biceps', 'Chest', 'Shoulders'],
      'Sit on the floor with your knees bent and your partner standing behind you. Extend your arms straight behind you with your palms facing each other. Your partner will hold your wrists for you. This will be the starting...',
      array['Sit on the floor with your knees bent and your partner standing behind you. Extend your arms straight behind you with your palms facing each other. Your partner will hold your wrists for you. This will be the starting position.', 'Attempt to flex your elbows, while your partner prevents any actual movement.', 'After 10-20 seconds, relax your arms while your partner gently pulls your wrists up to stretch your biceps. Be sure to let your partner know when the stretch is appropriate to prevent injury or overstretching.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Seated_Biceps/0.jpg',
      null,
      30
    ),
    (
      arms_cat_id,
      'Standing Biceps Stretch',
      array['Biceps', 'Chest', 'Shoulders'],
      'Clasp your hands behind your back with your palms together, straighten arms and then rotate them so your palms face downward.',
      array['Clasp your hands behind your back with your palms together, straighten arms and then rotate them so your palms face downward.', 'Raise your arms up and hold until you feel a stretch in your biceps.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Biceps_Stretch/0.jpg',
      null,
      30
    ),
    (
      arms_cat_id,
      'Tricep Side Stretch',
      array['Triceps', 'Shoulders'],
      'Bring right arm across your body and over your left shoulder, holding your elbow with your left hand, until you feel a stretch in your tricep. Then repeat for your other arm.',
      array['Bring right arm across your body and over your left shoulder, holding your elbow with your left hand, until you feel a stretch in your tricep. Then repeat for your other arm.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Tricep_Side_Stretch/0.jpg',
      null,
      30
    ),
    (
      arms_cat_id,
      'Triceps Stretch',
      array['Triceps', 'Lats'],
      'Reach your hand behind your head, grasp your elbow and gently pull. Hold for 10 to 20 seconds, then switch sides.',
      array['Reach your hand behind your head, grasp your elbow and gently pull. Hold for 10 to 20 seconds, then switch sides.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0817-uOV3Itw.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      arms_cat_id,
      'Wrist Circles',
      array['Forearms'],
      'Start by standing straight with your feet being shoulder width apart from each other. Elevate your arms to the side of you until they are fully extended and parallel to the floor at a height that is evenly aligned wit...',
      array['Start by standing straight with your feet being shoulder width apart from each other. Elevate your arms to the side of you until they are fully extended and parallel to the floor at a height that is evenly aligned with your shoulders. Tip: Your torso and arms should form the letter "T: Your palms should be facing down. This is the starting position.', 'Keeping your entire body stationary except for the wrists, begin to rotate both wrists forward in a circular motion. Tip: Pretend that you are trying to draw circles by using your hands as the brush. Breathe normally as you perform this exercise.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1428-2zNKRUB.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      arms_cat_id,
      'Bench Dips',
      array['Triceps', 'Chest', 'Shoulders'],
      'For this exercise you will need to place a bench behind your back. With the bench perpendicular to your body, and while looking away from it, hold on to the bench on its edge with the hands fully extended, separated a...',
      array['For this exercise you will need to place a bench behind your back. With the bench perpendicular to your body, and while looking away from it, hold on to the bench on its edge with the hands fully extended, separated at shoulder width. The legs will be extended forward, bent at the waist and perpendicular to your torso. This will be your starting position.', 'Slowly lower your body as you inhale by bending at the elbows until you lower yourself far enough to where there is an angle slightly smaller than 90 degrees between the upper arm and the forearm. Tip: Keep the elbows as close as possible throughout the movement. Forearms should always be pointing down.', 'Using your triceps to bring your torso up again, lift yourself back to the starting position.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bench_Dips/0.jpg',
      null,
      35
    ),
    (
      arms_cat_id,
      'Body Tricep Press',
      array['Triceps'],
      'Position a bar in a rack at chest height.',
      array['Position a bar in a rack at chest height.', 'Standing, take a shoulder width grip on the bar and step a yard or two back, feet together and arms extended so that you are leaning on the bar. This will be your starting position.', 'Begin by flexing the elbow, lowering yourself towards the bar.', 'Pause, and then reverse the motion by extending the elbows.', 'Progress from bodyweight by adding chains over your shoulders.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Body_Tricep_Press/0.jpg',
      null,
      35
    ),
    (
      arms_cat_id,
      'Body-Up',
      array['Triceps', 'Abdominals', 'Forearms'],
      'Assume a plank position on the ground. You should be supporting your bodyweight on your toes and forearms, keeping your torso straight. Your forearms should be shoulder-width apart. This will be your starting position.',
      array['Assume a plank position on the ground. You should be supporting your bodyweight on your toes and forearms, keeping your torso straight. Your forearms should be shoulder-width apart. This will be your starting position.', 'Pressing your palms firmly into the ground, extend through the elbows to raise your body from the ground. Keep your torso rigid as you perform the movement.', 'Slowly lower your forearms back to the ground by allowing the elbows to flex.', 'Repeat.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0137-U6G2gk9.gif',
      '© Gym visual — https://gymvisual.com/',
      35
    ),
    (
      arms_cat_id,
      'Band Skull Crusher',
      array['Triceps'],
      'Secure a band to the base of a rack or the bench. Lay on the bench so that the band is lined up with your head.',
      array['Secure a band to the base of a rack or the bench. Lay on the bench so that the band is lined up with your head.', 'Take hold of the band, raising your elbows so that the upper arm is perpendicular to the floor. With the elbow flexed, the band should be above your head. This will be your starting position.', 'Extend through the elbow to straighten your arm, keeping your upper arm in place. Pause at the top of the motion, and return to the starting position.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Band_Skull_Crusher/0.jpg',
      null,
      35
    ),
    (
      arms_cat_id,
      'Standing Towel Triceps Extension',
      array['Triceps'],
      'To begin, stand up with both arms fully extended above the head holding one end of a towel with both hands. Your elbows should be in and the arms perpendicular to the floor with the palms facing each other while your ...',
      array['To begin, stand up with both arms fully extended above the head holding one end of a towel with both hands. Your elbows should be in and the arms perpendicular to the floor with the palms facing each other while your feet should be shoulder width apart from each other. This is the starting position.', 'Now communicate with your partner so that he/she can grip the other side of the towel to apply resistance. Keeping your upper arms close to your head (elbows in) and perpendicular to the floor, lower the resistance in a semicircular motion behind your head until your forearms touch your biceps. Tip: The upper arms should remain stationary and only the forearms should move. Breathe in as you perform this step.', 'Go back to the starting position by using the triceps to raise the towel. Breathe out as you perform this step.', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Towel_Triceps_Extension/0.jpg',
      null,
      35
    ),
    (
      arms_cat_id,
      'Standing Olympic Plate Hand Squeeze',
      array['Forearms', 'Biceps'],
      'To begin, stand straight while holding a weight plate by the ridge at arm''s length in each hand using a neutral grip (palms facing in). You feet should be shoulder width apart from each other. This will be your starti...',
      array['To begin, stand straight while holding a weight plate by the ridge at arm''s length in each hand using a neutral grip (palms facing in). You feet should be shoulder width apart from each other. This will be your starting position.', 'Lower the plates until the fingers are nearly extended but can still hold weights. Inhale as you lower the plates.', 'Now raise the plates back to the starting position as you exhale by closing your hands.', 'Repeat for the recommended amount of repetitions prescribed in your program.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Standing_Olympic_Plate_Hand_Squeeze/0.jpg',
      null,
      35
    ),
    (
      arms_cat_id,
      'Wrist Roller',
      array['Forearms', 'Shoulders'],
      'To begin, stand straight up grabbing a wrist roller using a pronated grip (palms facing down). Your feet should be shoulder width apart.',
      array['To begin, stand straight up grabbing a wrist roller using a pronated grip (palms facing down). Your feet should be shoulder width apart.', 'Slowly lift both arms until they are fully extended and parallel to the floor in front of you. Note: Make sure the rope is not wrapped around the roller. Your entire body should be stationary except for the forearms. This is the starting position.', 'Rotate one wrist at a time in an upward motion to bring the weight up to the bar by rolling the rope around the roller.', 'Once the weight has reached the bar, slowly begin to lower the weight back down by rotating the wrist in a downward motion until the weight reaches the starting position.', 'Repeat for the prescribed amount of repetitions in your program.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0859-bd5b860.gif',
      '© Gym visual — https://gymvisual.com/',
      35
    ),
    (
      arms_cat_id,
      'Plate Pinch',
      array['Forearms'],
      'Grab two wide-rimmed plates and put them together with the smooth sides facing outward',
      array['Grab two wide-rimmed plates and put them together with the smooth sides facing outward', 'Use your fingers to grip the outside part of the plate and your thumb for the other side thus holding both plates together. This is the starting position.', 'Squeeze the plate with your fingers and thumb. Hold this position for as long as you can.', 'Repeat for the recommended amount of sets prescribed in your program.', 'Switch arms and repeat the movements.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Plate_Pinch/0.jpg',
      null,
      35
    ),
    (
      arms_cat_id,
      'Reverse Plate Curls',
      array['Biceps', 'Forearms'],
      'Start by standing straight with a weighted plate held by both hands and arms fully extended. Use a pronated grip (palms facing down) and make sure your fingers grab the rough side of the plate while your thumb grabs t...',
      array['Start by standing straight with a weighted plate held by both hands and arms fully extended. Use a pronated grip (palms facing down) and make sure your fingers grab the rough side of the plate while your thumb grabs the smooth side. Note: For the best results, grab the weighted plate at an 11:00 and 1:00 o''clock position.', 'Your feet should be shoulder width apart from each other and the weighted plate should be near the groin area. This is the starting position.', 'Slowly lift the plate up while keeping the elbows in and the upper arms stationary until your biceps and forearms touch while exhaling. The plate should be evenly aligned with your torso at this point.', 'Feel the contraction for a second and begin to lower the weight back down to the starting position while inhaling', 'Repeat for the recommended amount of repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Reverse_Plate_Curls/0.jpg',
      null,
      35
    ),
    (
      arms_cat_id,
      'Chin-Up',
      array['Lats', 'Biceps', 'Forearms', 'Middle Back'],
      'Grab the pull-up bar with the palms facing your torso and a grip closer than the shoulder width.',
      array['Grab the pull-up bar with the palms facing your torso and a grip closer than the shoulder width.', 'As you have both arms extended in front of you holding the bar at the chosen grip width, keep your torso as straight as possible while creating a curvature on your lower back and sticking your chest out. This is your starting position. Tip: Keeping the torso as straight as possible maximizes biceps stimulation while minimizing back involvement.', 'As you breathe out, pull your torso up until your head is around the level of the pull-up bar. Concentrate on using the biceps muscles in order to perform the movement. Keep the elbows close to your body. Tip: The upper torso should remain stationary as it moves through space and only the arms should move. The forearms should do no other work other than hold the bar.', 'After a second of squeezing the biceps in the contracted position, slowly lower your torso back to the starting position; when your arms are fully extended. Breathe in as you perform this portion of the movement.', 'Repeat this motion for the prescribed amount of repetitions.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1326-T2mxWqc.gif',
      '© Gym visual — https://gymvisual.com/',
      35
    ),
    (
      legs_cat_id,
      'Bodyweight Walking Lunge',
      array['Quadriceps', 'Calves', 'Glutes', 'Hamstrings'],
      'Begin standing with your feet shoulder width apart and your hands on your hips.',
      array['Begin standing with your feet shoulder width apart and your hands on your hips.', 'Step forward with one leg, flexing the knees to drop your hips. Descend until your rear knee nearly touches the ground. Your posture should remain upright, and your front knee should stay above the front foot.', 'Drive through the heel of your lead foot and extend both knees to raise yourself back up.', 'Step forward with your rear foot, repeating the lunge on the opposite leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Bodyweight_Walking_Lunge/0.jpg',
      null,
      35
    ),
    (
      legs_cat_id,
      'Split Squats',
      array['Hamstrings', 'Calves', 'Glutes', 'Quadriceps'],
      'Being in a standing position. Jump into a split leg position, with one leg forward and one leg back, flexing the knees and lowering your hips slightly as you do so.',
      array['Being in a standing position. Jump into a split leg position, with one leg forward and one leg back, flexing the knees and lowering your hips slightly as you do so.', 'As you descend, immediately reverse direction, standing back up and jumping, reversing the position of your legs. Repeat 5-10 times on each leg.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/2368-9E25EOx.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      legs_cat_id,
      'Sit Squats',
      array['Quadriceps', 'Abductors', 'Glutes', 'Hamstrings'],
      'Stand with your feet shoulder width apart. This will be your starting position.',
      array['Stand with your feet shoulder width apart. This will be your starting position.', 'Begin the movement by flexing your knees and hips, sitting back with your hips.', 'Continue until you have squatted a portion of the way down, but are above parallel, and quickly reverse the motion until you return to the starting position. Repeat for 5-10 repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Sit_Squats/0.jpg',
      null,
      30
    ),
    (
      legs_cat_id,
      'Flutter Kicks',
      array['Glutes', 'Hamstrings'],
      'On a flat bench lie facedown with the hips on the edge of the bench, the legs straight with toes high off the floor and with the arms on top of the bench holding on to the front edge.',
      array['On a flat bench lie facedown with the hips on the edge of the bench, the legs straight with toes high off the floor and with the arms on top of the bench holding on to the front edge.', 'Squeeze your glutes and hamstrings and straighten the legs until they are level with the hips. This will be your starting position.', 'Start the movement by lifting the left leg higher than the right leg.', 'Then lower the left leg as you lift the right leg.', 'Continue alternating in this manner (as though you are doing a flutter kick in water) until you have done the recommended amount of repetitions for each leg. Make sure that you keep a controlled movement at all times. Tip: You will breathe normally as you perform this movement.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/0459-UVo2Qs2.gif',
      '© Gym visual — https://gymvisual.com/',
      35
    ),
    (
      legs_cat_id,
      'Glute Kickback',
      array['Glutes', 'Hamstrings'],
      'Kneel on the floor or an exercise mat and bend at the waist with your arms extended in front of you (perpendicular to the torso) in order to get into a kneeling push-up position but with the arms spaced at shoulder wi...',
      array['Kneel on the floor or an exercise mat and bend at the waist with your arms extended in front of you (perpendicular to the torso) in order to get into a kneeling push-up position but with the arms spaced at shoulder width. Your head should be looking forward and the bend of the knees should create a 90-degree angle between the hamstrings and the calves. This will be your starting position.', 'As you exhale, lift up your right leg until the hamstrings are in line with the back while maintaining the 90-degree angle bend. Contract the glutes throughout this movement and hold the contraction at the top for a second. Tip: At the end of the movement the upper leg should be parallel to the floor while the calf should be perpendicular to it.', 'Go back to the initial position as you inhale and now repeat with the left leg.', 'Continue to alternate legs until all of the recommended repetitions have been performed.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Glute_Kickback/0.jpg',
      null,
      35
    ),
    (
      legs_cat_id,
      'Leg Lift',
      array['Glutes', 'Hamstrings'],
      'While standing up straight with both feet next to each other at around shoulder width, grab a sturdy surface such as the sides of a squat rack or the top of a chair to brace yourself and keep balance.',
      array['While standing up straight with both feet next to each other at around shoulder width, grab a sturdy surface such as the sides of a squat rack or the top of a chair to brace yourself and keep balance.', 'With or without an ankle weight, lift one leg behind you as if performing a leg curl but standing up while keeping the other leg straight. Breathe out as you perform this movement.', 'Slowly bring the raised leg back to the floor as you breathe in.', 'Repeat for the recommended amount of repetitions.', 'Repeat the movement with the opposite leg.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Leg_Lift/0.jpg',
      null,
      35
    ),
    (
      legs_cat_id,
      'Prone Manual Hamstring',
      array['Hamstrings'],
      'You will need a partner for this exercise. Lay face down with your legs straight. Your assistant will place their hand on your heel.',
      array['You will need a partner for this exercise. Lay face down with your legs straight. Your assistant will place their hand on your heel.', 'To begin, flex the knee to curl your leg up. Your partner should provide resistance, starting light and increasing the pressure as the movement is completed. Communicate with your partner to monitor appropriate resistance levels.', 'Pause at the top, returning the leg to the starting position as your partner provides resistance going the other direction.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Prone_Manual_Hamstring/0.jpg',
      null,
      35
    ),
    (
      legs_cat_id,
      'Platform Hamstring Slides',
      array['Hamstrings', 'Glutes'],
      'For this movement a wooden floor or similar is needed. Lay on your back with your legs extended. Place a gym towel or a light weight underneath your heel. This will be your starting position.',
      array['For this movement a wooden floor or similar is needed. Lay on your back with your legs extended. Place a gym towel or a light weight underneath your heel. This will be your starting position.', 'Begin the movement by flexing the knee, keeping your other leg straight.', 'Continue bringing the heel closer to you, sliding it on the floor.', 'At full knee flexion, reverse the movement to return to the starting position.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Platform_Hamstring_Slides/0.jpg',
      null,
      35
    ),
    (
      legs_cat_id,
      'Natural Glute Ham Raise',
      array['Hamstrings', 'Calves', 'Glutes', 'Lower Back'],
      'Using the leg pad of a lat pulldown machine or a preacher bench, position yourself so that your ankles are under the pads, knees on the seat, and you are facing away from the machine. You should be upright and maintai...',
      array['Using the leg pad of a lat pulldown machine or a preacher bench, position yourself so that your ankles are under the pads, knees on the seat, and you are facing away from the machine. You should be upright and maintaining good posture.', 'This will be your starting position. Lower yourself under control until your knees are almost completely straight.', 'Remaining in control, raise yourself back up to the starting position.', 'If you are unable to complete a rep, use a band, a partner, or push off of a box to aid in completing a repetition.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Natural_Glute_Ham_Raise/0.jpg',
      null,
      35
    ),
    (
      legs_cat_id,
      'Hip Flexion with Band',
      array['Quadriceps'],
      'Secure one end of the band to the lower portion of a post and attach the other to one ankle.',
      array['Secure one end of the band to the lower portion of a post and attach the other to one ankle.', 'Face away from the attachment point of the band.', 'Keeping your head and your chest up, raise your knee up to 90 degrees and pause.', 'Return the leg to the starting position.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Hip_Flexion_with_Band/0.jpg',
      null,
      35
    ),
    (
      legs_cat_id,
      'The Straddle',
      array['Hamstrings', 'Adductors', 'Calves'],
      'Begin in a seated, upright position. Start by extending your legs in front of you in a V.',
      array['Begin in a seated, upright position. Start by extending your legs in front of you in a V.', 'With your hands on the floor, lean forward as far as possible. Hold for 10 to 20 seconds.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/The_Straddle/0.jpg',
      null,
      30
    ),
    (
      legs_cat_id,
      'World''s Greatest Stretch',
      array['Hamstrings', 'Calves', 'Glutes', 'Quadriceps'],
      'This is a three-part stretch. Begin by lunging forward, with your front foot flat on the ground and on the toes of your back foot. With your knees bent, squat down until your knee is almost touching the ground. Keep y...',
      array['This is a three-part stretch. Begin by lunging forward, with your front foot flat on the ground and on the toes of your back foot. With your knees bent, squat down until your knee is almost touching the ground. Keep your torso erect, and hold this position for 10-20 seconds.', 'Now, place the arm on the same side as your front leg on the ground, with the elbow next to the foot. Your other hand should be placed on the ground, parallel to your lead leg, to help support you during this portion of the stretch.', 'After 10-20 seconds, place your hands on either side of your front foot. Raise the toes of the front foot off of the ground, and straighten your leg. You may need to reposition your rear leg to do so. Hold for 10-20 seconds, and then repeat the entire sequence for the other side.'],
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos/1604-DFGXwZr.gif',
      '© Gym visual — https://gymvisual.com/',
      30
    ),
    (
      legs_cat_id,
      'Groiners',
      array['Adductors'],
      'Begin in a pushup position on the floor. This will be your starting position.',
      array['Begin in a pushup position on the floor. This will be your starting position.', 'Using both legs, jump forward landing with your feet next to your hands. Keep your head up as you do so.', 'Return to the starting position and immediately repeat the movement, continuing for 10-20 repetitions.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Groiners/0.jpg',
      null,
      30
    ),
    (
      legs_cat_id,
      'Lying Bent Leg Groin',
      array['Adductors'],
      'Lie on your back with your knees bent and the soles of the feet pressed together. Have your partner hold your knees. This will be your starting position.',
      array['Lie on your back with your knees bent and the soles of the feet pressed together. Have your partner hold your knees. This will be your starting position.', 'Attempt to squeeze your knees together, while your partner prevents any movement from occurring.', 'After 10-20 seconds, relax your muscles as your partner gently pushes your knees towards the floor. Be sure to inform your helper when the stretch is adequate to prevent injury or overstretching.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Lying_Bent_Leg_Groin/0.jpg',
      null,
      30
    ),
    (
      legs_cat_id,
      'Side Lying Groin Stretch',
      array['Adductors', 'Hamstrings'],
      'Start off by lying on your right side and bend your right knee in front of you to stabilize the torso.',
      array['Start off by lying on your right side and bend your right knee in front of you to stabilize the torso.', 'Rest your head on your right hand or shoulder. Lift your left leg upward and hold it by the back of the knee (easier) or the foot (harder).', 'Pull your left knee in toward your left shoulder and simultaneously press your foot or knee down to the floor. To intensify this stretch, straighten your left leg. Switch sides.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Side_Lying_Groin_Stretch/0.jpg',
      null,
      30
    ),
    (
      legs_cat_id,
      'Trail Running/Walking',
      array['Quadriceps', 'Calves', 'Glutes', 'Hamstrings'],
      'Running or hiking on trails will get the blood pumping and heart beating almost immediately. Make sure you have good shoes. While you use the muscles in your calves and buttocks to pull yourself up a hill, the knees, ...',
      array['Running or hiking on trails will get the blood pumping and heart beating almost immediately. Make sure you have good shoes. While you use the muscles in your calves and buttocks to pull yourself up a hill, the knees, joints and ankles absorb the bulk of the pounding coming back down. Take smaller steps as you walk downhill, keep your knees bent to reduce the impact and slow down to avoid falling.', 'A 150 lb person can burn over 200 calories for 30 minutes walking uphill, compared to 175 on a flat surface. If running the trail, a 150 lb person can burn well over 500 calories in 30 minutes.'],
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Trail_Running_Walking/0.jpg',
      null,
      35
    )
  on conflict do nothing;
end $$;
