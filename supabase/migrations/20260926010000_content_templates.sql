-- ---------------------------------------------------------------------------
-- content_templates - reusable lesson-content templates saved by admins.
--
-- From the lesson editor the admin can save the current content as a named
-- template; saved templates can then be reused anywhere: seeded into new
-- lessons (add-lesson picker) or inserted at the cursor (block sheet), and
-- deleted again from either place. Admin-only through fn_is_admin() RLS;
-- anon has no access at all.
-- ---------------------------------------------------------------------------

create table if not exists public.content_templates (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  markdown text not null,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table public.content_templates enable row level security;

drop policy if exists content_templates_admin_select on public.content_templates;
create policy content_templates_admin_select on public.content_templates
  for select
  to authenticated
  using (public.fn_is_admin());

drop policy if exists content_templates_admin_insert on public.content_templates;
create policy content_templates_admin_insert on public.content_templates
  for insert
  to authenticated
  with check (public.fn_is_admin());

drop policy if exists content_templates_admin_delete on public.content_templates;
create policy content_templates_admin_delete on public.content_templates
  for delete
  to authenticated
  using (public.fn_is_admin());

grant select, insert, delete on public.content_templates to authenticated;
revoke all on public.content_templates from anon;
