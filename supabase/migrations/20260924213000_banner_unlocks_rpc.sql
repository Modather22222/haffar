-- Per-banner unlock requirements, computed server-side from the same
-- thresholds the حسابي grid uses (single source of truth for the client):
--   first  → always unlocked
--   second → streak >= 10 AND completed lessons >= 20
--   third  → streak >= 30 AND completed lessons >= 40
-- fourth → streak >= 30 AND completed lessons >= 40
--
-- Unlocks are derived on read (streak/lessons can regress), never stored,
-- so no drift is possible. Lessons = user_lesson_progress row count, the
-- same source get_public_profile reports.

create or replace function public.get_my_banners(p_user_id uuid)
returns table(banner_key text, unlocked boolean)
language sql
stable
security definer
set search_path to 'public'
as $$
  with t as (
    select
      coalesce(
        (select pr.streak from profiles pr where pr.id = p_user_id),
        0
      ) as streak,
      coalesce(
        (select count(*) from user_lesson_progress ulp
         where ulp.user_id = p_user_id),
        0
      ) as lessons
  )
  select
    b.banner_key,
    case b.banner_key
      when 'first' then true
      when 'second' then t.streak >= 10 and t.lessons >= 20
      else t.streak >= 30 and t.lessons >= 40
    end as unlocked
  from t
  cross join (values ('first'), ('second'), ('third'), ('fourth'))
    as b(banner_key);
$$;
