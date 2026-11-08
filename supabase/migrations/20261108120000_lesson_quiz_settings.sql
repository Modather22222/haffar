-- Per-lesson exercise (تمرين الدرس) delivery settings, admin-editable.
--
-- quiz_size : number of questions the student's lesson quiz shows.
--             NULL = built-in default (3 — or 10 for the english subject).
-- quiz_ids  : admin-pinned question ids (questions.id) in display order.
--             When non-empty it overrides quiz_size: the student sees
--             exactly these questions, in this order. NULL/empty = the
--             automatic QuizBuilder selection (random, prefers unseen).
--
-- Additive only: the live app never references the new columns, so
-- currently installed builds keep working unchanged.
alter table public.lessons
  add column if not exists quiz_size integer
    check (quiz_size between 1 and 200),
  add column if not exists quiz_ids text[];

comment on column public.lessons.quiz_size is
  'Admin-set number of questions shown in تمرين الدرس. NULL = built-in default (3, or 10 for english).';
comment on column public.lessons.quiz_ids is
  'Admin-pinned question ids for تمرين الدرس in display order. Non-empty overrides quiz_size.';
