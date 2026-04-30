# Supabase Migrations

This directory contains database migrations for the Meshchersky Park Showcase App.

## Migration History

### 20250101000000_create_scenarios_and_videos_tables.sql

**Status:** ✅ Applied

**Description:** Initial database schema creation for the Showcase App.

**Changes:**
- Created `scenarios` table with fields:
  - `id` (UUID, primary key)
  - `title` (TEXT, required)
  - `slug` (TEXT, unique, required)
  - `order_index` (INTEGER, default 0)
  - `active` (BOOLEAN, default true)
  - `created_at` (TIMESTAMPTZ, default NOW())

- Created `videos` table with fields:
  - `id` (UUID, primary key)
  - `scenario_id` (UUID, foreign key to scenarios.id)
  - `title` (TEXT, nullable)
  - `storage_path` (TEXT, required)
  - `duration_sec` (INTEGER, nullable)
  - `order_index` (INTEGER, default 0)
  - `active` (BOOLEAN, default true)
  - `created_at` (TIMESTAMPTZ, default NOW())

- Created indexes:
  - `idx_scenarios_active_order` on `scenarios(active, order_index)`
  - `idx_videos_scenario_active_order` on `videos(scenario_id, active, order_index)`
  - `idx_videos_active` on `videos(active)`

- Configured foreign key constraint:
  - `videos.scenario_id` → `scenarios.id` with CASCADE delete

- Enabled Row Level Security (RLS) with public read policies for active content
- Enabled Realtime for live updates
- Added table and column comments for documentation

**Requirements Satisfied:** 4.1, 4.2, 4.6

## Applying Migrations

Migrations are applied using the Supabase MCP server:

```bash
# Apply migration via MCP
mcp_supabase_showcase_apply_migration \
  --project_id smyfjmdjzfwdehynwfep \
  --name migration_name \
  --query "$(cat migration_file.sql)"
```

## Database Schema

### Entity Relationship Diagram

```
┌─────────────────────┐
│     scenarios       │
├─────────────────────┤
│ id (PK)             │
│ title               │
│ slug (UNIQUE)       │
│ order_index         │
│ active              │
│ created_at          │
└─────────────────────┘
          │
          │ 1:N
          │
          ▼
┌─────────────────────┐
│      videos         │
├─────────────────────┤
│ id (PK)             │
│ scenario_id (FK)    │◄── CASCADE DELETE
│ title               │
│ storage_path        │
│ duration_sec        │
│ order_index         │
│ active              │
│ created_at          │
└─────────────────────┘
```

## Verification

To verify the schema was created correctly:

```sql
-- List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- List all indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND tablename IN ('scenarios', 'videos');

-- Verify foreign key constraints
SELECT constraint_name, table_name, column_name, delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.referential_constraints rc 
  ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'videos';
```

## Project Information

- **Project Name:** Showcase
- **Project ID:** smyfjmdjzfwdehynwfep
- **Region:** eu-central-1
- **Database Version:** PostgreSQL 17.6.1.105
