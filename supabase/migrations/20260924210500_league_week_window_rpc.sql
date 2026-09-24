-- League countdown window: one RPC the client uses to anchor the
-- دوري حفّار countdown (same pattern as get_hearts: server NOW() +
-- target timestamp → client ticks locally against elapsed device time).

create or replace function public.league_week_window()
returns table(
  week_start timestamp with time zone,
  week_end timestamp with time zone,
  server_now timestamp with time zone
)
language sql
stable
set search_path to 'public'
as $$
  select
    public.league_week_start(),
    public.league_week_end(),
    now();
$$;
