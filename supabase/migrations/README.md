# Supabase migrations

SQL files in this directory mirror the cloud migration history for project
`qfngbhrlqyojfwoadher`.

## Layout

```
supabase/migrations/
  20260924123649_public_profile_rpc.sql
  20260924125500_p0_security_hardening.sql
  20260924_p0_xp_aggregate_and_reset.sql
```

Earlier migrations (content schema, user progress, quiz attempts, hearts/XP)
exist only in the Supabase dashboard migration history. To pull a full local
snapshot:

```bash
supabase db dump --db-url "$SUPABASE_DB_URL" > supabase/migrations/$(date +%Y%m%d%H%M%S)_baseline.sql
```

## Conventions

- One logical change per file, named `YYYYMMDDHHMMSS_description.sql`.
- Apply with `supabase db push` (CLI) or the dashboard SQL editor.
- Always `revoke ... from public, anon` on new SECURITY DEFINER functions and
  `grant execute ... to authenticated` for user-facing RPCs.
- Never grant client INSERT/UPDATE/DELETE on economy tables (`profiles`,
  `xp_events`, `heart_events`) — use definer functions instead.
