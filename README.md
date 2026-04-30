# Meshchersky Park Showcase App

A premium tablet-controlled presentation app for the Meshchersky Park residential complex sales office in Moscow.

## 🎯 Project Overview

**Purpose:** Sales managers use a tablet to select life scenario profiles, which trigger curated video content on a large display screen during client meetings.

**Client:** ООО «СПК-М» (Логинов Артём Михайлович)  
**Developer:** Тарлан Исаев  
**Design:** Женя Миловидов  
**PM:** Женя Южакова

## 🛠 Tech Stack

- **iOS/iPadOS:** Swift 6.3.1, SwiftUI, @Observable, strict concurrency
- **Android:** SKIP 1.0+ (Swift → Kotlin/Jetpack Compose transpilation)
- **Backend:** Supabase (PostgreSQL + Storage)
- **CI/CD:** GitHub Actions (automated daily backups)
- **Deployment:** TestFlight (iOS) + APK sideload (Android)

## 📱 App Structure

### Screens
1. **Main Screen** (`/`) - Grid of 5 life scenario cards
2. **Library** (`/library`) - Full video catalog grouped by scenario
3. **Video Player** (`/player`) - Fullscreen playback on external display
4. **Settings** - App info and mirroring status

### Life Scenarios
1. **Family with children** - School, playground, safety, community
2. **Wellness & silence** - Spa, forest walks, no city noise
3. **Guests & hotel** - Hotel room booking instead of guest suite
4. **Investor** - Liquidity, limited supply, unique location
5. **Architecture & space** - Materials, light, panoramic glazing

## 🗄 Database Schema

```sql
-- Scenarios table
CREATE TABLE scenarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  order_index INT DEFAULT 0,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Videos table
CREATE TABLE videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id UUID REFERENCES scenarios(id) ON DELETE CASCADE,
  title TEXT,
  storage_path TEXT NOT NULL,
  duration_sec INT,
  order_index INT DEFAULT 0,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 🚀 Getting Started

### Prerequisites
- Xcode 16+ (for iOS development)
- Swift 6.3.1+
- Android Studio (for Android testing)
- SKIP CLI tools

### Environment Setup

1. Copy environment variables:
```bash
cp .env.example .env.local
```

2. Configure Supabase credentials in `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=https://smyfjmdjzfwdehynwfep.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sb_publishable_36vglboOi9AkwTwCw_BqMg_uWQE8NV_
```

### Build & Run

#### iOS/macOS
```bash
# Build the project
swift build

# Open in Xcode
open Package.swift

# Run on iOS Simulator or device
```

#### Android
```bash
cd Android
./gradlew assembleDebug
```

## 📦 Project Structure

```
showcase/
├── Sources/Showcase/
│   ├── ShowcaseApp.swift          # App entry point
│   ├── Models.swift                # Data models (Scenario, Video)
│   ├── SupabaseManager.swift      # Supabase client & API calls
│   ├── ViewModel.swift             # Observable state management
│   ├── ContentView.swift           # Main tab view
│   ├── LogoView.swift              # Premium logo component
│   └── Views/
│       ├── ScenarioGridView.swift  # Main scenario grid
│       ├── LibraryView.swift       # Video library
│       ├── VideoDetailView.swift   # Video player
│       ├── SettingsView.swift      # Settings screen
│       └── Components/
│           ├── ScenarioCard.swift  # Scenario card component
│           ├── VideoRow.swift      # Video list item
│           ├── LoadingView.swift   # Loading state
│           └── ErrorView.swift     # Error state
├── Android/                        # Android project (SKIP generated)
├── Darwin/                         # iOS/macOS specific files
├── .agents/                        # AI agent workflows and internal tools
│   └── workflows/                  # Agent-specific workflows
├── scripts/                        # Database & Storage helper scripts
├── logs/                           # Build and execution logs
├── assets/                         # Project assets (videos, photos, logos)
├── docs/                           # Documentation (guides, design, technical)
├── .github/workflows/
│   └── backup.yml                  # Daily database backup
├── AGENTS.md                       # Project overview for AI agents
├── README.md                       # Project overview for humans
└── Package.swift                   # Swift package definition
```

## 🎨 Design Language

**Liquid Glass (iOS/iPadOS 26)**
- Frosted glass effects with subtle gradients
- Premium golden accents
- Smooth animations and transitions
- Minimalist, luxury aesthetic

## 📊 Current Status

### ✅ Completed (Milestone 1)
- [x] Swift package structure with SKIP integration
- [x] Supabase backend setup (database + storage)
- [x] Database schema with RLS policies
- [x] 5 life scenarios seeded in database
- [x] SwiftUI screens (Main, Library, Video Player, Settings)
- [x] Observable state management with @Observable
- [x] Supabase client integration
- [x] Video storage bucket with public read access
- [x] GitHub Actions backup workflow
- [x] Android project structure

### 🔄 In Progress (Milestone 2)
- [ ] Upload video content (20-25 videos, max 30 sec each)
- [ ] Test video playback on iOS/iPadOS
- [ ] Test Android build and video playback
- [ ] External display mirroring (AirPlay/Cast)
- [ ] UI polish and animations

### ⏳ Planned (Milestone 3)
- [ ] QA testing on physical devices
- [ ] TestFlight deployment
- [ ] Android APK build for sideload
- [ ] On-site installation in Moscow sales office
- [ ] Staff training and handoff

## 🎥 Content Requirements

- **Total videos:** 20-25 (4-5 per scenario)
- **Duration:** Max 30 seconds each
- **Format:** MP4, MOV, or WebM
- **Storage:** Supabase Storage bucket `videos`
- **Naming convention:** `{scenario_slug}/{order_index}_{title}.mp4`

## 🔐 Security

- **RLS enabled** on all tables
- **Public read-only** access for active scenarios/videos
- **Storage policies** for public video access
- **No authentication** required for end users (sales office only)
- **Admin access** via Supabase Dashboard

## 📅 Timeline

- **Deadline:** End of May 2026 (sales office opening)
- **Month 1:** Architecture + backend + screens ✅
- **Month 2:** Content + testing + deployment 🔄
- **Month 3:** Warranty support

## 💰 Budget

| Phase | Amount |
|-------|--------|
| Invoice #1 (iteration 1 + onboarding) | 175,000 ₽ |
| Invoice #2 (iteration 2) | 125,000 ₽ |
| **Development Total** | **300,000 ₽** |
| Design (separate) | 300,000 ₽ |
| **Project Total** | **600,000 ₽** |

## 🔗 Links

- **Supabase Project:** https://smyfjmdjzfwdehynwfep.supabase.co
- **Supabase Dashboard:** https://supabase.com/dashboard/project/smyfjmdjzfwdehynwfep
- **SKIP Documentation:** https://skip.tools

## 📝 Notes

- App runs in kiosk mode in sales office (always-on)
- No App Store submission needed (TestFlight + APK sideload)
- Stable internet connection available in office
- Wireless screen mirroring only (no HDMI)
- Content updates are rare (handled via Supabase Dashboard)

## 🤝 Support

For issues or questions, contact:
- **Developer:** Тарлан Исаев (ИНН 761900751270)
- **PM:** Женя Южакова
- **Client:** Логинов Артём Михайлович (ИП, ИНН 112104547785)

---

Built with ❤️ using Swift 6.3.1, SwiftUI, and SKIP
