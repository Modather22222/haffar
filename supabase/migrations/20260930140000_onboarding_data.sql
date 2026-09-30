-- Everything collected during onboarding now reaches the profile:
--   screen 4  weak subjects      -> weak_subject_ids
--   screen 6  referral source    -> referral_source
--   screen 7  target exam score  -> target_score
--   screen 7  notifications      -> notifications_enabled
--   screen 10 plan choice        -> plan_choice
--   screen 12 gender             -> gender
--   screen 15 completion flag    -> has_completed_onboarding
-- (display name / school / state were already stored.)

alter table public.profiles
  add column if not exists referral_source text,
  add column if not exists target_score integer,
  add column if not exists plan_choice text,
  add column if not exists gender text,
  add column if not exists weak_subject_ids text[],
  add column if not exists notifications_enabled boolean not null default false,
  add column if not exists has_completed_onboarding boolean not null default false;

-- Postgres forbids changing a function's parameter list, so drop first.
drop function if exists public.update_own_profile(text, boolean, text, text);

create or replace function public.update_own_profile(
  p_display_name text default null,
  p_has_completed_onboarding boolean default null,
  p_school_name text default null,
  p_from_state text default null,
  p_referral_source text default null,
  p_target_score integer default null,
  p_plan_choice text default null,
  p_gender text default null,
  p_weak_subject_ids text[] default null,
  p_notifications_enabled boolean default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'not authorized';
  end if;
  -- Every param keeps the stored value when null/empty, so partial pushes
  -- (e.g. login before the whole onboarding synced) never wipe data.
  update profiles
  set display_name = coalesce(p_display_name, display_name),
      has_completed_onboarding = coalesce(p_has_completed_onboarding, has_completed_onboarding),
      school_name = coalesce(nullif(p_school_name, ''), school_name),
      from_state = coalesce(nullif(p_from_state, ''), from_state),
      referral_source = coalesce(nullif(p_referral_source, ''), referral_source),
      target_score = coalesce(p_target_score, target_score),
      plan_choice = coalesce(nullif(p_plan_choice, ''), plan_choice),
      gender = coalesce(nullif(p_gender, ''), gender),
      weak_subject_ids = coalesce(p_weak_subject_ids, weak_subject_ids),
      notifications_enabled = coalesce(p_notifications_enabled, notifications_enabled),
      updated_at = now()
  where id = auth.uid();
end;
$$;

revoke all on function public.update_own_profile(
  text, boolean, text, text, text, integer, text, text, text[], boolean
) from public, anon;
grant execute on function public.update_own_profile(
  text, boolean, text, text, text, integer, text, text, text[], boolean
) to authenticated;
