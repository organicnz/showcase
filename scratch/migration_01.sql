-- NOTE: This migration has been superseded by the official migration:
-- supabase/migrations/20250101000000_create_scenarios_and_videos_tables.sql
-- 
-- The official migration includes all the schema definitions below plus:
-- - Required indexes (idx_scenarios_active_order, idx_videos_scenario_active_order, idx_videos_active)
-- - Table and column comments for documentation
-- 
-- This file is kept for reference only.

-- Scenarios
create table if not exists scenarios (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique not null,
  order_index int default 0,
  active boolean default true,
  created_at timestamptz default now()
);

-- Videos
create table if not exists videos (
  id uuid primary key default gen_random_uuid(),
  scenario_id uuid references scenarios(id) on delete cascade,
  title text,
  storage_path text not null,  -- Supabase Storage path
  duration_sec int,
  order_index int default 0,
  active boolean default true,
  created_at timestamptz default now()
);

-- Enable RLS
alter table scenarios enable row level security;
alter table videos enable row level security;

-- Policies for public read access
drop policy if exists "Allow public read access for scenarios" on scenarios;
create policy "Allow public read access for scenarios"
  on scenarios for select
  using (active = true);

drop policy if exists "Allow public read access for videos" on videos;
create policy "Allow public read access for videos"
  on videos for select
  using (active = true);

-- Enable Realtime
alter table scenarios replica identity full;
alter table videos replica identity full;

-- Check if tables are in the publication
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'scenarios') then
    alter publication supabase_realtime add table scenarios;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'videos') then
    alter publication supabase_realtime add table videos;
  end if;
end $$;
