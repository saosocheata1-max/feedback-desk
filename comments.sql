create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  feedback_id uuid not null references public.feedback(id) on delete cascade,
  author_id text references public.members(id) on delete set null,
  author_name text,
  text text default '',
  voice text,
  created_at timestamptz not null default now()
);

grant select, insert, update, delete on public.comments to anon, authenticated;
alter table public.comments enable row level security;
drop policy if exists "team comments access" on public.comments;
create policy "team comments access" on public.comments for all to anon, authenticated using (true) with check (true);

do $$ begin
  begin alter publication supabase_realtime add table public.comments; exception when others then null; end;
end $$;

select 'Comments ready' as result;
