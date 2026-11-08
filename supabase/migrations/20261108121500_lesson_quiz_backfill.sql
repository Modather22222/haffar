-- Lesson quiz delivery is now fully admin-configured: the built-in
-- 3-questions / 10-for-english fallback leaves the Dart engine.
--
-- 1) Backfill: every existing lesson gets the value it served so far
--    (english 10, everything else 3) so the removed fallback changes
--    nothing for students — the same numbers now live in the DB and are
--    editable per lesson from the admin exercise settings card.
-- 2) New lessons (admin_create_lesson inserts omit quiz_size) start at 3
--    and are adjusted from the card. English is no longer special-cased:
--    set or pin whatever fits.
update public.lessons
  set quiz_size = 10
  where subject_id = 'english'
    and quiz_size is null;

update public.lessons
  set quiz_size = 3
  where quiz_size is null;

alter table public.lessons
  alter column quiz_size set default 3;
