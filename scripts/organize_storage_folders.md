# Script: Organize Storage Folders

## Purpose

This script helps organize existing video files in the Supabase Storage `videos` bucket into the required folder structure.

## Current State

The `videos` bucket currently has files at the root level:
- `family_v.mp4`
- `wellness_v.mp4`
- `guests_v.mp4`
- `investor_v.mp4`
- `architecture_v.mp4`
- `v_family_fix.mp4`
- `v_wellness_fix.mp4`
- `v_guests_fix.mp4`
- `v_investor_fix.mp4`
- `v_architecture_fix.mp4`

## Required Folder Structure

```
videos/
├── family/
├── wellness/
├── guests/
├── investor/
└── architecture/
```

## Steps to Organize

### Option 1: Via Supabase Dashboard (Manual)

1. **Create folders** (if they don't exist):
   - Go to Storage → videos bucket
   - Create folders: `family`, `wellness`, `guests`, `investor`, `architecture`

2. **Move files** into appropriate folders:
   - Move `family_v.mp4` and `v_family_fix.mp4` → `family/`
   - Move `wellness_v.mp4` and `v_wellness_fix.mp4` → `wellness/`
   - Move `guests_v.mp4` and `v_guests_fix.mp4` → `guests/`
   - Move `investor_v.mp4` and `v_investor_fix.mp4` → `investor/`
   - Move `architecture_v.mp4` and `v_architecture_fix.mp4` → `architecture/`

3. **Rename files** to follow naming convention:
   - `family_v.mp4` → `family/family_01.mp4`
   - `v_family_fix.mp4` → `family/family_02.mp4`
   - (Repeat for other scenarios)

### Option 2: Via Supabase CLI (Automated)

```bash
#!/bin/bash

# Set your Supabase project details
PROJECT_REF="smyfjmdjzfwdehynwfep"
BUCKET="videos"

# Create folders (folders are created automatically when uploading to a path)

# Download existing files
supabase storage download $BUCKET/family_v.mp4 ./temp/family_v.mp4
supabase storage download $BUCKET/v_family_fix.mp4 ./temp/v_family_fix.mp4
supabase storage download $BUCKET/wellness_v.mp4 ./temp/wellness_v.mp4
supabase storage download $BUCKET/v_wellness_fix.mp4 ./temp/v_wellness_fix.mp4
supabase storage download $BUCKET/guests_v.mp4 ./temp/guests_v.mp4
supabase storage download $BUCKET/v_guests_fix.mp4 ./temp/v_guests_fix.mp4
supabase storage download $BUCKET/investor_v.mp4 ./temp/investor_v.mp4
supabase storage download $BUCKET/v_investor_fix.mp4 ./temp/v_investor_fix.mp4
supabase storage download $BUCKET/architecture_v.mp4 ./temp/architecture_v.mp4
supabase storage download $BUCKET/v_architecture_fix.mp4 ./temp/v_architecture_fix.mp4

# Upload to new folder structure
supabase storage upload $BUCKET/family/family_01.mp4 ./temp/family_v.mp4
supabase storage upload $BUCKET/family/family_02.mp4 ./temp/v_family_fix.mp4
supabase storage upload $BUCKET/wellness/wellness_01.mp4 ./temp/wellness_v.mp4
supabase storage upload $BUCKET/wellness/wellness_02.mp4 ./temp/v_wellness_fix.mp4
supabase storage upload $BUCKET/guests/guests_01.mp4 ./temp/guests_v.mp4
supabase storage upload $BUCKET/guests/guests_02.mp4 ./temp/v_guests_fix.mp4
supabase storage upload $BUCKET/investor/investor_01.mp4 ./temp/investor_v.mp4
supabase storage upload $BUCKET/investor/investor_02.mp4 ./temp/v_investor_fix.mp4
supabase storage upload $BUCKET/architecture/architecture_01.mp4 ./temp/architecture_v.mp4
supabase storage upload $BUCKET/architecture/architecture_02.mp4 ./temp/v_architecture_fix.mp4

# Delete old files from root
supabase storage delete $BUCKET/family_v.mp4
supabase storage delete $BUCKET/v_family_fix.mp4
supabase storage delete $BUCKET/wellness_v.mp4
supabase storage delete $BUCKET/v_wellness_fix.mp4
supabase storage delete $BUCKET/guests_v.mp4
supabase storage delete $BUCKET/v_guests_fix.mp4
supabase storage delete $BUCKET/investor_v.mp4
supabase storage delete $BUCKET/v_investor_fix.mp4
supabase storage delete $BUCKET/architecture_v.mp4
supabase storage delete $BUCKET/v_architecture_fix.mp4

# Clean up temp files
rm -rf ./temp

echo "✅ Storage folders organized successfully!"
```

### Option 3: Via Supabase Storage API (JavaScript)

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://smyfjmdjzfwdehynwfep.supabase.co',
  'YOUR_SUPABASE_ANON_KEY'
)

async function organizeStorageFolders() {
  const fileMappings = [
    { old: 'family_v.mp4', new: 'family/family_01.mp4' },
    { old: 'v_family_fix.mp4', new: 'family/family_02.mp4' },
    { old: 'wellness_v.mp4', new: 'wellness/wellness_01.mp4' },
    { old: 'v_wellness_fix.mp4', new: 'wellness/wellness_02.mp4' },
    { old: 'guests_v.mp4', new: 'guests/guests_01.mp4' },
    { old: 'v_guests_fix.mp4', new: 'guests/guests_02.mp4' },
    { old: 'investor_v.mp4', new: 'investor/investor_01.mp4' },
    { old: 'v_investor_fix.mp4', new: 'investor/investor_02.mp4' },
    { old: 'architecture_v.mp4', new: 'architecture/architecture_01.mp4' },
    { old: 'v_architecture_fix.mp4', new: 'architecture/architecture_02.mp4' },
  ]

  for (const mapping of fileMappings) {
    // Download file
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('videos')
      .download(mapping.old)

    if (downloadError) {
      console.error(`Error downloading ${mapping.old}:`, downloadError)
      continue
    }

    // Upload to new location
    const { error: uploadError } = await supabase.storage
      .from('videos')
      .upload(mapping.new, fileData, {
        cacheControl: '3600',
        upsert: false
      })

    if (uploadError) {
      console.error(`Error uploading ${mapping.new}:`, uploadError)
      continue
    }

    // Delete old file
    const { error: deleteError } = await supabase.storage
      .from('videos')
      .remove([mapping.old])

    if (deleteError) {
      console.error(`Error deleting ${mapping.old}:`, deleteError)
    } else {
      console.log(`✅ Moved ${mapping.old} → ${mapping.new}`)
    }
  }

  console.log('✅ Storage folders organized successfully!')
}

organizeStorageFolders()
```

## Update Database Records

After organizing the storage files, update the database records to reflect the new paths:

```sql
-- Update storage paths for videos that currently reference external URLs
-- This assumes you want to use the newly organized local files

-- Family videos
UPDATE videos 
SET storage_path = 'family/family_01.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'family')
  AND order_index = 0;

UPDATE videos 
SET storage_path = 'family/family_02.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'family')
  AND order_index = 1;

-- Wellness videos
UPDATE videos 
SET storage_path = 'wellness/wellness_01.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'wellness')
  AND order_index = 0;

UPDATE videos 
SET storage_path = 'wellness/wellness_02.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'wellness')
  AND order_index = 1;

-- Guests videos
UPDATE videos 
SET storage_path = 'guests/guests_01.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'guests')
  AND order_index = 0;

UPDATE videos 
SET storage_path = 'guests/guests_02.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'guests')
  AND order_index = 1;

-- Investor videos
UPDATE videos 
SET storage_path = 'investor/investor_01.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'investor')
  AND order_index = 0;

UPDATE videos 
SET storage_path = 'investor/investor_02.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'investor')
  AND order_index = 1;

-- Architecture videos
UPDATE videos 
SET storage_path = 'architecture/architecture_01.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'architecture')
  AND order_index = 0;

UPDATE videos 
SET storage_path = 'architecture/architecture_02.mp4'
WHERE scenario_id = (SELECT id FROM scenarios WHERE slug = 'architecture')
  AND order_index = 1;
```

## Verification

After organizing, verify the structure:

```sql
-- Check all videos have correct storage paths
SELECT 
  s.slug as scenario,
  v.title,
  v.storage_path,
  v.order_index,
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

## Test CDN URLs

Test that the CDN URLs are accessible:

```bash
# Test family video
curl -I https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/family/family_01.mp4

# Test wellness video
curl -I https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/wellness/wellness_01.mp4

# Should return 200 OK if files exist and are accessible
```

## Notes

- The validation trigger will prevent inserting videos with invalid storage paths
- External URLs (starting with `http`) are still allowed for backward compatibility
- The `videos_with_cdn_urls` view provides easy access to full CDN URLs
- Folders are created automatically when uploading files to a path

## Troubleshooting

**Issue**: Files not accessible after moving
- **Solution**: Verify bucket is set to public read access
- **Check**: `SELECT * FROM storage.buckets WHERE id = 'videos';`

**Issue**: Validation trigger blocks updates
- **Solution**: Ensure storage_path follows the pattern `{scenario_slug}/{filename}.mp4`
- **Valid**: `family/family_01.mp4`
- **Invalid**: `family_01.mp4` (missing folder)

**Issue**: CDN URLs return 404
- **Solution**: Verify files exist in storage using Supabase Dashboard
- **Check**: Storage → videos bucket → verify folder structure
