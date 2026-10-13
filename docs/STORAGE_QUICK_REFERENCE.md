# Storage Quick Reference

## Bucket Info

- **Bucket**: `videos`
- **Project**: `smyfjmdjzfwdehynwfep`
- **Region**: `eu-central-1`
- **Access**: Public read

## Folder Structure

```
videos/
├── family/
├── wellness/
├── guests/
├── investor/
└── architecture/
```

## CDN URL Pattern

```
https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/{path}
```

## Valid Storage Paths

✅ `family/family_01.mp4`  
✅ `wellness/wellness_02.mp4`  
✅ `guests/guests_01.mp4`  
✅ `investor/investor_01.mp4`  
✅ `architecture/architecture_01.mp4`  

❌ `family_01.mp4` (missing folder)  
❌ `videos/family/family_01.mp4` (includes bucket name)  

## Upload via Dashboard

1. Storage → `videos` bucket
2. Navigate to folder (e.g., `family/`)
3. Upload file
4. Update database record

## Upload via CLI

```bash
supabase storage upload videos/family/family_01.mp4 ./local/video.mp4
```

## Upload via API

```javascript
const { data, error } = await supabase.storage
  .from('videos')
  .upload('family/family_01.mp4', file, {
    cacheControl: '3600',
    upsert: false
  })
```

## Database Update

```sql
UPDATE videos 
SET storage_path = 'family/family_01.mp4'
WHERE id = 'video-uuid';
```

## Verification

```sql
-- Check all videos
SELECT * FROM videos_with_cdn_urls;

-- Test CDN URL
SELECT 
  storage_path,
  'https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/' || storage_path as cdn_url
FROM videos
WHERE storage_path NOT LIKE 'http%';
```

## Common Issues

**404 on CDN URL**: File doesn't exist in storage  
**Validation error**: Path doesn't start with valid folder  
**Access denied**: Bucket not set to public  

## Support

See full documentation:
- `docs/STORAGE_FOLDER_STRUCTURE.md`
- `docs/guides/ORGANIZE_STORAGE_FOLDERS.md`
