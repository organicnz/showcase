-- Migration: Create scenarios and videos tables
-- Created: 2025-01-01
-- Description: Initial database schema for Meshchersky Park Showcase App

-- Create scenarios table
CREATE TABLE IF NOT EXISTS scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    order_index INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create videos table
CREATE TABLE IF NOT EXISTS videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scenario_id UUID NOT NULL REFERENCES scenarios(id) ON DELETE CASCADE,
    title TEXT,
    storage_path TEXT NOT NULL,
    duration_sec INTEGER,
    order_index INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for optimized queries
CREATE INDEX IF NOT EXISTS idx_scenarios_active_order 
    ON scenarios(active, order_index);

CREATE INDEX IF NOT EXISTS idx_videos_scenario_active_order 
    ON videos(scenario_id, active, order_index);

CREATE INDEX IF NOT EXISTS idx_videos_active 
    ON videos(active);

-- Enable Row Level Security (RLS)
ALTER TABLE scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for public read access to active content
DROP POLICY IF EXISTS "Allow public read access for active scenarios" ON scenarios;
CREATE POLICY "Allow public read access for active scenarios"
    ON scenarios FOR SELECT
    USING (active = true);

DROP POLICY IF EXISTS "Allow public read access for active videos" ON videos;
CREATE POLICY "Allow public read access for active videos"
    ON videos FOR SELECT
    USING (active = true);

-- Enable Realtime for live updates
ALTER TABLE scenarios REPLICA IDENTITY FULL;
ALTER TABLE videos REPLICA IDENTITY FULL;

-- Add tables to Realtime publication
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'scenarios'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE scenarios;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'videos'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE videos;
    END IF;
END $$;

-- Add helpful comments
COMMENT ON TABLE scenarios IS 'Life scenario categories for the Meshchersky Park Showcase App';
COMMENT ON TABLE videos IS 'Video assets associated with scenarios';
COMMENT ON COLUMN scenarios.slug IS 'URL-friendly identifier for the scenario';
COMMENT ON COLUMN scenarios.order_index IS 'Display order (ascending)';
COMMENT ON COLUMN videos.storage_path IS 'Path to video file in Supabase Storage';
COMMENT ON COLUMN videos.scenario_id IS 'Foreign key to scenarios table with CASCADE delete';
