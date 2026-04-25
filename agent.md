# agent.md — Meshchersky Park Showcase App

## Project Overview

**Product:** Sales office presentation player for a premium residential complex in Meshchersky Park, Moscow.

**Purpose:** A tablet-controlled app that plays curated video scenarios on a large display screen during client meetings. The sales manager selects a life scenario profile on the tablet — the screen responds with the matching content. No sales pressure, quiet luxury, privacy-first.

**Client:** ООО «СПК-М» (Логинов Артём Михайлович)
**Developer:** Тарлан Исаев (Swift / iOS lead)
**Design:** Женя Миловидов (UI/UX)
**PM:** Женя Южакова

---

## Tech Stack

| Layer | Technology |
|---|---|
| iOS / iPadOS | Swift 6.3, SwiftUI, @Observable, strict concurrency |
| UI Design Language | Liquid Glass (iOS/iPadOS 26) |
| Android | SKIP 1.0+ (Swift → Kotlin / Jetpack Compose) |
| Backend | Supabase (shared instance) |
| Database backups | GitHub Actions CI/CD (scheduled) |
| Deployment iOS | TestFlight → install |
| Deployment Android | APK sideload (no store) |
| Screen mirroring | Wireless (AirPlay / Cast from tablet to TV) |
| Testing | Simultaneous macOS/iPadOS + Android Emulator |

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 SUPABASE BACKEND                 │
│  DB: scenarios, videos, categories, metadata    │
│  Storage: video files (CDN)                     │
│  Auth: admin only (CMS access)                  │
│  CI/CD: GitHub Actions → scheduled backups      │
└────────────────┬────────────────────────────────┘
                 │
     ┌───────────┴───────────┐
     │                       │
┌────▼─────┐          ┌──────▼──────┐
│  iOS App  │          │ Android App │
│ Swift 6.3 │◄── SKIP ─│ Jetpack    │
│ SwiftUI   │          │ Compose    │
│ iPad UI   │          │            │
└────┬──────┘          └──────┬─────┘
     │                        │
     └───────────┬────────────┘
                 │ Wireless mirror
          ┌──────▼──────┐
          │  TV Screen  │
          │ Office wall │
          └─────────────┘
```

---

## App Structure (Screens)

### 1. Main Screen (`/`)
- Grid of life scenario cards
- Tap scenario → plays video on mirrored screen
- Manager-facing UI (tablet)

### 2. Library (`/library`)
- Full catalog of videos grouped by scenario
- Filter by category
- Tap to play on external display

### 3. Video Player (`/player`)
- Fullscreen on external display
- Controls remain on tablet only
- Autoplay next in scenario queue

### 4. Service States
- Loading / offline / no content
- Empty state with placeholder

---

## Content Structure

```
Scenarios (5 base)
└── Videos (4–5 per scenario = 20–25 total)
    ├── Duration: max 30 seconds each
    ├── Hosted: Supabase Storage
    └── Categories: family, wellness, privacy, investment, architecture
```

### Life Scenarios
| ID | Scenario | Target |
|---|---|---|
| 01 | Family with children | School, playground, safety, community |
| 02 | Wellness & silence | Spa, forest walks, no city noise |
| 03 | Guests & hotel | Hotel room booking instead of guest suite |
| 04 | Investor | Liquidity, limited supply, unique location |
| 05 | Architecture & space | Materials, light, panoramic glazing |

---

## CMS (Admin)

- **Platform:** Supabase Dashboard
- **Access:** Admin only (no custom UI needed at this stage)
- **Operations:** Upload video, assign scenario, set order, toggle active
- **Update frequency:** Rare (content mostly static post-launch)

---

---

## Skip Bleeding Edge Implementation

### 1. Modular Architecture (Swift Package based)
- **ShowcaseCore**: Shared logic, models, and Supabase client.
- **ShowcaseUI**: Shared SwiftUI components mapped to Compose via SkipUI.
- **ShowcaseApp**: The main entry point for iOS and Android.

### 2. State Management
- Use the **Observation framework (`@Observable`)** for modern, reactive UI state.
- Adapt for Skip's transpilation to ensure efficient recomposition in Jetpack Compose.

### 3. Concurrency
- **Swift 6 Strict Concurrency**: All network calls and database interactions must be isolated to Actors or use `Sendable` types to prevent data races.
- **Async/Await**: Preferred over callbacks for all asynchronous operations.

### 4. Supabase Integration
- Use the official **Supabase-Swift** library (or a Skip-compatible wrapper if needed).
- Direct DB interactions via PostgREST and Storage for high-speed video streaming.

---

## Supabase Schema (draft)

```sql
-- Scenarios
create table scenarios (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique not null,
  order_index int default 0,
  active boolean default true
);

-- Videos
create table videos (
  id uuid primary key default gen_random_uuid(),
  scenario_id uuid references scenarios(id),
  title text,
  storage_path text not null,  -- Supabase Storage path
  duration_sec int,
  order_index int default 0,
  active boolean default true,
  created_at timestamptz default now()
);
```

---

## GitHub CI/CD — Backup Pipeline

```yaml
# .github/workflows/backup.yml
name: Supabase Backup
on:
  schedule:
    - cron: '0 2 * * *'  # daily at 02:00 UTC
jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Dump Supabase DB
        env:
          SUPABASE_DB_URL: ${{ secrets.SUPABASE_DB_URL }}
        run: |
          pg_dump $SUPABASE_DB_URL > backup_$(date +%Y%m%d).sql
      - name: Commit backup
        run: |
          git config user.email "ci@bot"
          git config user.name "CI Bot"
          git add backups/
          git commit -m "backup: $(date +%Y-%m-%d)"
          git push
```

---

## Milestones

| # | Deliverable | Month | Status |
|---|---|---|---|
| 1 | Architecture + Supabase backend | Month 1 | 🔄 In progress |
| 2 | SwiftUI screens (4–5) + SKIP setup | Month 1 | 🔄 In progress |
| 3 | CI/CD backups | Month 1 | ⏳ Planned |
| 4 | Content library + Supabase integration | Month 2 | ⏳ Planned |
| 5 | CMS setup | Month 2 | ⏳ Planned |
| 6 | QA on iOS + Android | Month 2 | ⏳ Planned |
| 7 | Deploy + onboarding in Moscow | Month 2 | ⏳ Planned |
| 8 | 1-month warranty support | Month 3 | Free |

---

## Budget

| Phase | Amount |
|---|---|
| Invoice #1 (iteration 1 + onboarding visit) | 175 000 ₽ |
| Invoice #2 (iteration 2) | 125 000 ₽ |
| **Total** | **300 000 ₽** |
| Design (separate) | 300 000 ₽ |
| **Project total** | **600 000 ₽** |

---

## Key Constraints

- **Deadline:** End of May 2026 (sales office opening)
- **Offline:** Not required — office has stable internet
- **Screen connection:** Wireless only (no HDMI)
- **Apple review:** TestFlight bypasses App Store review — use for launch
- **Android deploy:** APK sideload, no Google Play needed
- **No auth for end users** — app is always-on in sales office
- **Content updates:** Rare, handled by admin via Supabase Dashboard

---

## Contacts

| Role | Name | Notes |
|---|---|---|
| Client | Логинов Артём Михайлович (Тема) | ИП, ИНН 112104547785 |
| PM | Женя Южакова | Main contact |
| iOS Dev | Тарлан Исаев | ИНН 761900751270, ТБанк |
| Design | Женя Миловидов | UI/UX, effects |
