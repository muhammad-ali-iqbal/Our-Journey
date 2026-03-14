-- Run this in Supabase Dashboard → SQL Editor → New Query

-- Memories table
create table memories (
  id           text primary key,
  title        text not null,
  story        text default '',
  location_name text default '',
  lat          float8,
  lng          float8,
  date         text not null,
  image_paths  text default '[]',
  quiz         text,
  is_unlocked  boolean default false,
  created_at   text not null
);

-- Allow anyone to read/write (single shared app, no auth needed)
alter table memories enable row level security;

create policy "Allow all" on memories
  for all using (true) with check (true);

-- Storage bucket for photos
insert into storage.buckets (id, name, public)
values ('memories', 'memories', true);

create policy "Allow all storage" on storage.objects
  for all using (bucket_id = 'memories') with check (bucket_id = 'memories');
