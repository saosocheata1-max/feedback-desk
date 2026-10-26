-- Feedback Desk setup: run once in Supabase → SQL Editor
create table if not exists public.members (
  id text primary key,
  name text not null,
  role text not null default 'member' check (role in ('member','reviewer')),
  pin_hash text,
  created_at timestamptz not null default now()
);

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  author_id text references public.members(id) on delete set null,
  author_name text,
  date date not null default current_date,
  created_at timestamptz not null default now(),
  text text default '',
  images text[] default '{}',
  voice text,
  status text not null default 'new' check (status in ('new','progress','tackled')),
  tackled_by text,
  tackled_at timestamptz,
  note text default ''
);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.members, public.feedback to anon, authenticated;

alter table public.members enable row level security;
alter table public.feedback enable row level security;

drop policy if exists "team members access" on public.members;
create policy "team members access" on public.members for all to anon, authenticated using (true) with check (true);
drop policy if exists "team feedback access" on public.feedback;
create policy "team feedback access" on public.feedback for all to anon, authenticated using (true) with check (true);

insert into public.members (id, name, role, created_at) values
  ('cheata','Cheata','reviewer', now()),
  ('anthony','Anthony','reviewer', now() + interval '1 second'),
  ('thomith','Thomith','member', now() + interval '2 seconds'),
  ('kd','KD','member', now() + interval '3 seconds'),
  ('rith','Rith','member', now() + interval '4 seconds')
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit)
values ('feedback-media','feedback-media', true, 26214400)
on conflict (id) do nothing;

drop policy if exists "team media upload" on storage.objects;
create policy "team media upload" on storage.objects for insert to anon, authenticated with check (bucket_id = 'feedback-media');
drop policy if exists "team media read" on storage.objects;
create policy "team media read" on storage.objects for select to anon, authenticated using (bucket_id = 'feedback-media');
drop policy if exists "team media delete" on storage.objects;
create policy "team media delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'feedback-media');

do $$ begin
  begin alter publication supabase_realtime add table public.feedback; exception when others then null; end;
  begin alter publication supabase_realtime add table public.members; exception when others then null; end;
end $$;

select 'Setup complete' as result, (select count(*) from public.members) as accounts;
