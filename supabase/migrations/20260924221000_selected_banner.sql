-- Selected banner persistence: the حسابي grid's "اختيار" button stores the
-- chosen banner key on profiles.selected_banner; get_public_profile now
-- returns it so other users see the same banner.
--
-- set_selected_banner is SECURITY DEFINER, owner-only (auth.uid()), and
-- re-validates the key against get_my_banners — a player can only select
-- a banner they have actually unlocked (profiles UPDATE is revoked for
-- clients, so this RPC is the only write path).

alter table profiles
  add column if not exists selected_banner text;

drop function if exists public.get_public_profile(uuid);

create or replace function public.get_public_profile(p_user_id uuid)
returns table(
  user_id uuid,
  display_name text,
  xp integer,
  streak integer,
  league text,
  created_at timestamp with time zone,
  completed_lessons bigint,
  week_xp integer,
  selected_banner text
)
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  return query
  select
    pr.id,
    coalesce(pr.display_name, 'البطل'),
    pr.xp,
    pr.streak,
    pr.league,
    pr.created_at,
    (
      select count(*)::bigint
      from user_lesson_progress ulp
      where ulp.user_id = pr.id
    ),
    coalesce((
      select sum(x.amount)::integer
      from xp_events x
      where x.user_id = pr.id
        and x.created_at >= public.league_week_start()
        and x.created_at < public.league_week_end()
    ), 0),
    pr.selected_banner
  from profiles pr
  where pr.id = p_user_id;
end;
$function$;

create or replace function public.set_selected_banner(p_banner text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_uid uuid := auth.uid();
  v_unlocked boolean;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;
  if p_banner is null or p_banner not in ('first', 'second', 'third', 'fourth') then
    raise exception 'invalid banner key';
  end if;
  select b.unlocked into v_unlocked
  from get_my_banners(v_uid) b
  where b.banner_key = p_banner;
  if not coalesce(v_unlocked, false) then
    raise exception 'banner not unlocked';
  end if;
  update profiles set selected_banner = p_banner where id = v_uid;
  if not found then
    raise exception 'profile not found';
  end if;
end;
$$;
