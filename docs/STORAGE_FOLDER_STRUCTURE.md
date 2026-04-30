# Supabase Storage Folder Structure

## Overview

This document describes the folder structure for the `videos` storage bucket in Supabase, as required by Task 1.2 of the Meshchersky Park Showcase App implementation.

## Bucket Configuration

- **Bucket Name**: `videos`
- **Access**: Public read access
- **CDN Delivery**: Enabled via Supabase Storage CDN
- **Allowed MIME Types**: `video/mp4`, `video/quicktime`, `video/webm`
- **File Size Limit**: 500 MB per file

## Folder Structure

The `videos` bucket must follow this folder structure:

```
videos/
├── family/
│   ├── family_01.mp4
│   ├── family_02.mp4
│   └── ...
├── wellness/
│   ├── wellness_01.mp4
│   ├── wellness_02.mp4
│   └── ...
├── guests/
│   ├── guests_01.mp4
│   ├── guests_02.mp4
│   └── ...
├── investor/
│   ├── investor_01.mp4
│   ├── investor_02.mp4
│   └── ...
└── architecture/
    ├── architecture_01.mp4
    ├── architecture_02.mp4
    └── ...
```

## Folder Mapping to Scenarios

Each folder corresponds to a scenario slug in the database:

| Folder | Scenario Slug | Scenario Title |
|--------|---------------|----------------|
| `family/` | `family` | Семья с детьми (Family Living) |
| `wellness/` | `wellness` | Велнес и тишина (Wellness & Quiet) |
| `guests/` | `guests` | Гости и отель (Guests & Hospitality) |
| `investor/` | `investor` | Инвестор (Investor) |
| `architecture/` | `architecture` | Архитектура и пространство (Architecture & Space) |

## File Naming Convention

Video files should follow this naming pattern:

```
{scenario_slug}_{sequence_number}.mp4
```

Examples:
- `family_01.mp4`
- `wellness_02.mp4`
- `architecture_03.mp4`

## Storage Path in Database

When creating video records in the `videos` table, the `storage_path` field must reference the file path relative to the bucket root:

```sql
-- Example: Insert a video record
INSERT INTO videos (scenario_id, title, storage_path, duration_sec, order_index, active)
VALUES (
  (SELECT id FROM scenarios WHERE slug = 'family'),
  'Семейная идиллия',
  'family/family_01.mp4',  -- Relative path from bucket root
  30,
  0,
  true
);
```

## CDN URL Construction

The app constructs CDN URLs using this pattern:

```
https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/{storage_path}
```

Example:
- Storage path: `family/family_01.mp4`
- CDN URL: `https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/family/family_01.mp4`

## Uploading Videos

### Via Supabase Dashboard

1. Navigate to **Storage** in the Supabase Dashboard
2. Select the `videos` bucket
3. Create folders if they don't exist: `family`, `wellness`, `guests`, `investor`, `architecture`
4. Click on a folder (e.g., `family/`)
5. Click **Upload file**
6. Select your video file(s)
7. Ensure the file name follows the naming convention

### Via Supabase CLI

```bash
# Upload a video to the family folder
supabase storage upload videos/family/family_01.mp4 ./local/path/to/video.mp4

# Upload multiple videos
supabase storage upload videos/wellness/wellness_01.mp4 ./wellness_video_1.mp4
supabase storage upload videos/wellness/wellness_02.mp4 ./wellness_video_2.mp4
```

### Via Supabase JavaScript Client

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// Upload a video file
const { data, error } = await supabase.storage
  .from('videos')
  .upload('family/family_01.mp4', videoFile, {
    cacheControl: '3600',
    upsert: false
  })
```

## Migration from Root-Level Files

If you have existing video files at the root level of the bucket (e.g., `family_v.mp4`), you need to:

1. **Move files to appropriate folders** via Supabase Dashboard or CLI
2. **Update database records** to reflect new paths

Example migration SQL:

```sql
-- Update storage paths for existing videos
UPDATE videos 
SET storage_path = 'family/' || storage_path
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'family')
  AND storage_path NOT LIKE 'family/%'
  AND storage_path NOT LIKE 'http%';

UPDATE videos 
SET storage_path = 'wellness/' || storage_path
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'wellness')
  AND storage_path NOT LIKE 'wellness/%'
  AND storage_path NOT LIKE 'http%';

-- Repeat for other scenarios...
```

## Validation

The migration `20260429000000_configure_storage_folders.sql` includes a trigger that validates storage paths on insert/update to ensure they follow the folder structure.

Valid paths:
- ✅ `family/family_01.mp4`
- ✅ `wellness/wellness_02.mp4`
- ✅ `architecture/arch_video.mp4`

Invalid paths:
- ❌ `family_01.mp4` (missing folder)
- ❌ `videos/family/family_01.mp4` (includes bucket name)
- ❌ `invalid_folder/video.mp4` (invalid folder name)

## Verification Query

Use this query to verify all videos have correct storage paths:

```sql
SELECT 
  s.slug as scenario,
  v.title,
  v.storage_path,
  CASE 
    WHEN v.storage_path LIKE s.slug || '/%' THEN '✅ Valid'
    WHEN v.storage_path LIKE 'http%' THEN '⚠️ External URL'
    ELSE '❌ Invalid'
  END as status
FROM videos v
JOIN scenarios s ON v.scenario_id = s.id
WHERE v.active = true
ORDER BY s.order_index, v.order_index;
```

## Requirements Satisfied

This folder structure satisfies the following requirements:

- **Requirement 4.3**: Video files stored in Supabase Storage with CDN delivery
- **Requirement 4.4**: Organized folder structure for content management
- **Task 1.2**: Configure folder structure: family/, wellness/, guests/, investor/, architecture/

## Next Steps

After setting up the folder structure:

1. Upload video files to appropriate folders
2. Update database records with correct storage paths
3. Verify CDN URLs are accessible
4. Test video playback in the app

## Support

For issues with storage configuration, refer to:
- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Supabase Storage API Reference](https://supabase.com/docs/reference/javascript/storage)
