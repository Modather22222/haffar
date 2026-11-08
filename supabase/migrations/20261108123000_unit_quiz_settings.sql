-- Per-unit exercise (تمرين الوحدة) delivery settings, admin-editable.
-- Mirrors the lesson quiz settings ('lesson_quiz_settings'):
--   quiz_size : questions shown per unit attempt. DEFAULT 10 = the value
--               every unit served so far; ADD COLUMN with default fills
--               existing rows automatically, so no backfill runs here.
--   quiz_ids  : admin-pinned question ids (questions.id) in display order;
--               non-empty overrides quiz_size exactly like lessons.
-- Additive only: live builds never reference these columns.
alter table public.units
  add column if not exists quiz_size integer
    default 10
    check (quiz_size between 1 and 200),
  add column if not exists quiz_ids text[];

comment on column public.units.quiz_size is
  'Admin-set number of questions shown in تمرين الوحدة. Pinned ids override.';
comment on column public.units.quiz_ids is
  'Admin-pinned question ids for تمرين الوحدة in display order. Non-empty overrides quiz_size.';
