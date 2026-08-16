-- Create workflow_states table
create table if not exists public.workflow_states (
  id uuid primary key default gen_random_uuid(),
  workflow_name text not null,
  current_step_index int not null default 0,
  completed_steps text[] not null default '{}',
  status text not null default 'pending',
  updated_at timestamptz default now()
);

-- Enable RLS
alter table public.workflow_states enable row level security;

-- Policies
create policy "Enable all for authenticated users" on public.workflow_states
  for all using (auth.role() = 'authenticated');

create policy "Enable select for anon users" on public.workflow_states
  for select using (true);
