# Deployment Guide - Meshchersky Park Showcase App

## 📋 Pre-Deployment Checklist

### Content Preparation
- [ ] All 20-25 videos uploaded to Supabase Storage
- [ ] Video metadata added to database
- [ ] All videos tested and playable
- [ ] Scenarios verified (5 total)

### Testing
- [ ] iOS/iPadOS testing complete
- [ ] Android testing complete
- [ ] External display mirroring tested
- [ ] Network connectivity tested
- [ ] Video playback performance verified

### Infrastructure
- [ ] Supabase project healthy
- [ ] Database backups configured
- [ ] Storage bucket accessible
- [ ] API keys valid

## 🍎 iOS/iPadOS Deployment

### Build for TestFlight

1. **Open in Xcode:**
```bash
open Package.swift
```

2. **Select Target:**
   - Select `Showcase` scheme
   - Choose "Any iOS Device (arm64)"

3. **Configure Signing:**
   - Go to Signing & Capabilities
   - Select your development team
   - Enable "Automatically manage signing"

4. **Archive the App:**
   - Product → Archive
   - Wait for archive to complete

5. **Upload to TestFlight:**
   - Click "Distribute App"
   - Select "TestFlight & App Store"
   - Follow the upload wizard
   - Wait for processing (10-30 minutes)

6. **Invite Testers:**
   - Go to App Store Connect
   - Select your app
   - Go to TestFlight tab
   - Add internal testers (client team)
   - Send invitations

### Install on Device

**Option A: TestFlight (Recommended)**
1. Install TestFlight app from App Store
2. Open invitation email on device
3. Tap "View in TestFlight"
4. Install the app

**Option B: Direct Install (Development)**
1. Connect iPad to Mac
2. Open Xcode
3. Select connected device
4. Click Run (⌘R)

## 🤖 Android Deployment

### Build APK

1. **Navigate to Android directory:**
```bash
cd Android
```

2. **Build debug APK (for testing):**
```bash
./gradlew assembleDebug
```

Output: `Android/app/build/outputs/apk/debug/app-debug.apk`

3. **Build release APK (for production):**
```bash
./gradlew assembleRelease
```

Output: `Android/app/build/outputs/apk/release/app-release.apk`

### Sign the APK (Production)

1. **Generate keystore (first time only):**
```bash
keytool -genkey -v -keystore showcase-release.keystore \
  -alias showcase -keyalg RSA -keysize 2048 -validity 10000
```

2. **Sign the APK:**
```bash
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore showcase-release.keystore \
  app/build/outputs/apk/release/app-release-unsigned.apk showcase
```

3. **Align the APK:**
```bash
zipalign -v 4 app-release-unsigned.apk showcase-release.apk
```

### Install on Android Device

**Option A: ADB Install**
```bash
adb install app-release.apk
```

**Option B: Manual Install**
1. Copy APK to device (USB, email, cloud)
2. Open file manager on device
3. Tap the APK file
4. Allow "Install from unknown sources" if prompted
5. Tap "Install"

## 🖥 On-Site Installation (Moscow Sales Office)

### Equipment Needed
- iPad (iOS 17+) or Android tablet
- Large display TV with wireless mirroring support
- Stable WiFi connection
- Power adapters and cables

### Installation Steps

#### 1. Network Setup
```bash
# Test network connectivity
ping supabase.com
ping smyfjmdjzfwdehynwfep.supabase.co
```

- Connect tablet to office WiFi
- Verify internet speed (minimum 10 Mbps)
- Test video streaming from Supabase

#### 2. App Installation
- Install app via TestFlight (iOS) or APK (Android)
- Launch app and verify content loads
- Check all 5 scenarios appear
- Verify video counts match expected

#### 3. External Display Setup

**For iPad (AirPlay):**
1. Ensure TV supports AirPlay or has Apple TV
2. Connect TV to same WiFi network
3. Open Control Center on iPad
4. Tap Screen Mirroring
5. Select the TV
6. Test video playback

**For Android (Cast):**
1. Ensure TV supports Chromecast
2. Connect TV to same WiFi network
3. Open app
4. Tap Cast icon
5. Select the TV
6. Test video playback

#### 4. Kiosk Mode Setup

**iOS Guided Access:**
1. Settings → Accessibility → Guided Access
2. Enable Guided Access
3. Set passcode
4. Open Showcase app
5. Triple-click side button
6. Tap "Start"

**Android Kiosk Mode:**
1. Settings → Security → Screen pinning
2. Enable screen pinning
3. Open Showcase app
4. Tap Recent apps
5. Tap app icon → Pin

#### 5. Final Verification
- [ ] App launches automatically
- [ ] All scenarios visible
- [ ] Videos play smoothly
- [ ] External display works
- [ ] Controls remain on tablet
- [ ] Video queue auto-plays
- [ ] Network connection stable

### Troubleshooting

**App won't load content:**
- Check WiFi connection
- Verify Supabase project is active
- Check API keys in app
- Restart app

**Videos won't play:**
- Check video URLs in Supabase
- Verify storage bucket is public
- Test video URLs in browser
- Check device storage space

**External display not working:**
- Verify TV and tablet on same network
- Restart both devices
- Check TV wireless display settings
- Try different mirroring method

**App crashes:**
- Check device OS version (iOS 17+ / Android 10+)
- Clear app cache
- Reinstall app
- Check device logs

## 📱 Device Recommendations

### iOS/iPadOS
- **Minimum:** iPad (9th generation), iOS 17
- **Recommended:** iPad Pro 11" or 12.9", iPadOS 17+
- **Storage:** 64GB minimum
- **Network:** WiFi 6 support

### Android
- **Minimum:** Android 10, 4GB RAM
- **Recommended:** Samsung Galaxy Tab S9, Android 14
- **Storage:** 64GB minimum
- **Network:** WiFi 6 support

### Display
- **Size:** 55" - 75" TV
- **Resolution:** 4K (3840x2160)
- **Features:** AirPlay 2 or Chromecast built-in
- **Mounting:** Wall-mounted at eye level

## 🔄 Content Updates

### Adding New Videos

1. **Upload to Supabase Storage:**
```bash
# Via Supabase Dashboard
Storage → videos bucket → Upload file
```

2. **Add metadata to database:**
```sql
INSERT INTO videos (scenario_id, title, storage_path, duration_sec, order_index)
VALUES (
  'scenario-uuid-here',
  'Video Title',
  'scenario-slug/video-file.mp4',
  30,
  5
);
```

3. **Verify in app:**
- Open Settings tab
- Tap "Sync from Server"
- Check video count updated
- Test playback

### Updating Scenarios

```sql
-- Update scenario title
UPDATE scenarios
SET title = 'New Title'
WHERE slug = 'scenario-slug';

-- Reorder scenarios
UPDATE scenarios
SET order_index = 2
WHERE slug = 'wellness';
```

### Deactivating Content

```sql
-- Hide a video
UPDATE videos
SET active = false
WHERE id = 'video-uuid';

-- Hide a scenario
UPDATE scenarios
SET active = false
WHERE slug = 'investor';
```

## 🛠 Maintenance

### Daily
- Check app is running
- Verify external display connected
- Test one video playback

### Weekly
- Sync content from server
- Check for app updates
- Verify network connectivity
- Review video playback logs

### Monthly
- Update app if new version available
- Review content performance
- Check device storage
- Clean device cache

### Quarterly
- Full content audit
- Device software updates
- Network performance review
- Backup verification

## 📞 Support Contacts

### Client / Заказчик
- **Company:** ООО «СПК-М»
- **General Director:** Егоров Сергей Васильевич
- **OGRN:** 1217700506154
- **INN:** 7708399522

### Team / Команда
- **Launch, Content & Sales / Запуск, продвижение, контент и продажи:** Артём Михайлович Логинов
- **PM:** Евгения Южакова
- **Design/Dev / Дизайн/разработка:** Евгений Миловидов (UI/UX)
- **Design/Dev / Дизайн/разработка:** Тарлан Исаев (Swift / iOS)

## 🔐 Security Notes

- App requires no authentication (sales office only)
- All content is public (no sensitive data)
- Network traffic is encrypted (HTTPS)
- No user data collected
- No analytics or tracking

## 📊 Performance Targets

- **App launch:** < 3 seconds
- **Content load:** < 5 seconds
- **Video start:** < 2 seconds
- **Video playback:** 30 FPS, no buffering
- **Memory usage:** < 500MB
- **Storage usage:** < 2GB

## ✅ Launch Day Checklist

### Morning (Before Opening)
- [ ] Power on all devices
- [ ] Launch app on tablet
- [ ] Connect to external display
- [ ] Test all 5 scenarios
- [ ] Verify network connection
- [ ] Enable kiosk mode

### During Operation
- [ ] Monitor app stability
- [ ] Check display connection
- [ ] Assist sales team if needed
- [ ] Note any issues

### End of Day
- [ ] Leave app running (kiosk mode)
- [ ] Verify display still connected
- [ ] Check device battery/power
- [ ] Report any issues

---

**Deployment Date:** [To be scheduled]  
**Location:** Meshchersky Park Sales Office, Moscow  
**Go-Live:** End of May 2026
