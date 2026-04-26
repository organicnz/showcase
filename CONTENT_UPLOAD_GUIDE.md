# Video Content Upload Guide

This guide explains how to upload video content to the Showcase app.

## 📋 Prerequisites

- Access to Supabase Dashboard: https://supabase.com/dashboard/project/smyfjmdjzfwdehynwfep
- Video files ready (MP4, MOV, or WebM format)
- Max 30 seconds per video
- 4-5 videos per scenario (20-25 total)

## 🎬 Video Requirements

### Technical Specs
- **Format:** MP4 (H.264), MOV, or WebM
- **Duration:** Maximum 30 seconds
- **Resolution:** 1920x1080 (Full HD) recommended
- **Aspect Ratio:** 16:9
- **File Size:** Under 50MB per video (for smooth streaming)
- **Frame Rate:** 30fps or 60fps

### Content Guidelines
- High-quality, professional footage
- Matches the life scenario theme
- No audio required (silent luxury aesthetic)
- Smooth, cinematic shots
- Consistent color grading across scenarios

## 📁 File Naming Convention

Organize videos by scenario folder:

```
family/
  01_playground.mp4
  02_school.mp4
  03_community.mp4
  04_safety.mp4

wellness/
  01_spa.mp4
  02_forest_walk.mp4
  03_meditation.mp4
  04_silence.mp4

guests/
  01_hotel_room.mp4
  02_concierge.mp4
  03_privacy.mp4
  04_luxury.mp4

investor/
  01_location.mp4
  02_limited_supply.mp4
  03_liquidity.mp4
  04_returns.mp4

architecture/
  01_materials.mp4
  02_light.mp4
  03_glazing.mp4
  04_space.mp4
```

## 🚀 Upload Methods

### Method 1: Supabase Dashboard (Recommended for non-technical users)

1. **Login to Supabase:**
   - Go to: https://supabase.com/dashboard/project/smyfjmdjzfwdehynwfep
   - Navigate to **Storage** in the left sidebar

2. **Open videos bucket:**
   - Click on the `videos` bucket

3. **Create scenario folders:**
   - Click "Create folder"
   - Create folders: `family`, `wellness`, `guests`, `investor`, `architecture`

4. **Upload videos:**
   - Open each scenario folder
   - Click "Upload file"
   - Select video files
   - Wait for upload to complete

5. **Get storage paths:**
   - After upload, note the path for each video
   - Example: `family/01_playground.mp4`

### Method 2: Supabase CLI (For developers)

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to project
supabase link --project-ref smyfjmdjzfwdehynwfep

# Upload videos
supabase storage upload videos/family/01_playground.mp4 ./videos/family/01_playground.mp4
```

### Method 3: MCP Tools (Via Kiro)

Ask Kiro to upload files using MCP Supabase tools:
```
Upload the video file family/01_playground.mp4 to the videos bucket
```

## 📝 Add Video Metadata to Database

After uploading videos, add their metadata to the database.

### Scenario IDs (from database)
```
Family with children:    2254f6b2-e186-40e0-844a-b8e5c308ef6f
Wellness & silence:      db2c301f-cc18-4781-bbe4-57ac6098c4c2
Guests & hotel:          6a3963c5-e79c-4fb7-9b77-c006c0eb12ac
Investor:                2ce91218-90c5-4dcc-8090-d3ccb116d0e5
Architecture & space:    5ae1e3a8-6dc5-4241-8d98-252648884468
```

### SQL Template

```sql
-- Example: Add a video for "Family with children" scenario
INSERT INTO videos (scenario_id, title, storage_path, duration_sec, order_index, active)
VALUES (
  '2254f6b2-e186-40e0-844a-b8e5c308ef6f',  -- Family scenario ID
  'Playground',                             -- Video title
  'family/01_playground.mp4',               -- Storage path
  28,                                       -- Duration in seconds
  1,                                        -- Display order
  true                                      -- Active status
);
```

### Bulk Insert Example

```sql
-- Insert all family videos at once
INSERT INTO videos (scenario_id, title, storage_path, duration_sec, order_index, active) VALUES
  ('2254f6b2-e186-40e0-844a-b8e5c308ef6f', 'Playground', 'family/01_playground.mp4', 28, 1, true),
  ('2254f6b2-e186-40e0-844a-b8e5c308ef6f', 'School', 'family/02_school.mp4', 30, 2, true),
  ('2254f6b2-e186-40e0-844a-b8e5c308ef6f', 'Community', 'family/03_community.mp4', 25, 3, true),
  ('2254f6b2-e186-40e0-844a-b8e5c308ef6f', 'Safety', 'family/04_safety.mp4', 27, 4, true);

-- Repeat for other scenarios...
```

### Using Supabase Dashboard SQL Editor

1. Go to **SQL Editor** in Supabase Dashboard
2. Click "New query"
3. Paste the INSERT statements
4. Click "Run" to execute

## ✅ Verification

### Check uploaded videos:
```sql
SELECT 
  s.title as scenario,
  v.title as video,
  v.storage_path,
  v.duration_sec,
  v.order_index,
  v.active
FROM videos v
JOIN scenarios s ON v.scenario_id = s.id
ORDER BY s.order_index, v.order_index;
```

### Test video URLs:
```sql
SELECT 
  title,
  'https://smyfjmdjzfwdehynwfep.supabase.co/storage/v1/object/public/videos/' || storage_path as url
FROM videos
WHERE active = true
ORDER BY order_index;
```

Copy a URL and paste it in your browser to verify the video plays.

## 🎯 Content Checklist

- [ ] 4-5 videos for **Family with children** scenario
- [ ] 4-5 videos for **Wellness & silence** scenario
- [ ] 4-5 videos for **Guests & hotel** scenario
- [ ] 4-5 videos for **Investor** scenario
- [ ] 4-5 videos for **Architecture & space** scenario
- [ ] All videos uploaded to correct folders
- [ ] All video metadata added to database
- [ ] All videos tested and playable
- [ ] Video durations recorded accurately
- [ ] Display order set correctly

## 🐛 Troubleshooting

### Video won't upload
- Check file size (must be under 500MB)
- Verify file format (MP4, MOV, WebM only)
- Check internet connection
- Try uploading smaller files first

### Video URL returns 404
- Verify storage path matches exactly
- Check bucket is public
- Confirm file was uploaded successfully
- Check for typos in path

### Video won't play in app
- Verify video format is compatible
- Check video codec (H.264 recommended)
- Test URL in browser first
- Check app logs for errors

## 📞 Support

For upload issues, contact:
- **Developer:** Тарлан Исаев
- **PM:** Женя Южакова

---

**Last Updated:** April 25, 2026
