-- Per-lesson / per-unit XP economy settings (admin-editable).
-- Defaults reproduce the previous economy: lesson 100 base − 5 per wrong,
-- unit 150 base − 18 per wrong. Per-question rewards (xp_reward) now add
-- on top for correct main-pass answers:
--   XP = base + Σ question rewards of correct main-pass answers − penalty × wrong
alter table public.lessons
  add column if not exists xp_base integer not null default 100
    check (xp_base between 0 and 9999),
  add column if not exists wrong_penalty integer not null default 5
    check (wrong_penalty between 0 and 999);

alter table public.units
  add column if not exists xp_base integer not null default 150
    check (xp_base between 0 and 9999),
  add column if not exists wrong_penalty integer not null default 18
    check (wrong_penalty between 0 and 999);
