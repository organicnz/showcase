-- Migration: Configure Supabase Storage folder structure for videos
-- Task: 1.2 Configure Supabase Storage bucket
-- Requirements: 4.3, 4.4

-- The videos bucket already exists with public read access
-- This migration documents the required folder structure and provides
-- helper functions to validate storage paths

-- Required folder structure in videos bucket:
-- videos/
--   ├── family/
--   ├── wellness/
--   ├── guests/
--   ├── investor/
--   └── architecture/

-- Create a function to validate video storage paths
CREATE OR REPLACE FUNCTION validate_video_storage_path()
RETURNS TRIGGER AS $$
BEGIN
  -- Ensure storage_path follows the folder structure pattern
  IF NEW.storage_path IS NOT NULL AND NEW.storage_path NOT LIKE 'http%' THEN
    -- Check if path starts with a valid scenario folder
    IF NEW.storage_path !~ '^(family|wellness|guests|investor|architecture)/' THEN
      RAISE EXCEPTION 'Invalid storage_path: must start with a valid scenario folder (family/, wellness/, guests/, investor/, or architecture/)';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate storage paths on insert/update
DROP TRIGGER IF EXISTS validate_video_storage_path_trigger ON videos;
CREATE TRIGGER validate_video_storage_path_trigger
  BEFORE INSERT OR UPDATE ON videos
  FOR EACH ROW
  EXECUTE FUNCTION validate_video_storage_path();

-- Add comment documenting the folder structure
COMMENT ON COLUMN videos.storage_path IS 
  'Path to video file in Supabase Storage. Must follow folder structure: {scenario_slug}/{filename}.mp4 (e.g., family/family_01.mp4)';

-- Create a view to show videos with their full CDN URLs
CREATE OR REPLACE VIEW videos_with_cdn_urls AS
SELECT 
  v.id,
  v.scenario_id,
  s.slug as scenario_slug,
  v.title,
  v.storage_path,
  CASE 
    WHEN v.storage_path LIKE 'http%' THEN v.storage_path
    ELSE 'https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/' || v.storage_path
  END as cdn_url,
  v.duration_sec,
  v.order_index,
  v.active,
  v.created_at
FROM videos v
JOIN scenarios s ON v.scenario_id = s.id
ORDER BY s.order_index, v.order_index;

COMMENT ON VIEW videos_with_cdn_urls IS 
  'View showing videos with their full CDN URLs for easy reference';
