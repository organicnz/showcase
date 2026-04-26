# Requirements Document

## Introduction

The Meshchersky Park Showcase App is a production-ready tablet-controlled video presentation system for a premium residential complex sales office in Moscow. The system enables sales managers to select life scenario profiles on a tablet, which triggers playback of curated video content on a wirelessly-mirrored large display screen. The application prioritizes quiet luxury, privacy-first design, and seamless wireless presentation without sales pressure.

The system consists of native iOS/iPadOS and Android applications built with Swift 6.3 + SwiftUI (transpiled to Android via SKIP 1.0+), backed by Supabase for database and video storage, with automated daily backups via GitHub Actions CI/CD.

## Glossary

- **Showcase_App**: The native mobile application (iOS/iPadOS/Android) that runs on the sales manager's tablet
- **Video_Player**: The fullscreen video playback component that displays on the external mirrored screen
- **Scenario**: A life scenario category (family, wellness, guests, investor, architecture) containing 4-5 related videos
- **Video**: A single video asset (max 30 seconds) stored in Supabase Storage and associated with one Scenario
- **Supabase_Backend**: The backend system providing PostgreSQL database, file storage, and CDN for video delivery
- **External_Display**: The large TV screen in the sales office that receives wireless mirrored content from the tablet
- **Admin**: The authorized user who manages content via Supabase Dashboard (no custom CMS UI)
- **Sales_Manager**: The end user who operates the tablet to select and play scenarios for clients
- **SKIP_Transpiler**: The SKIP 1.0+ framework that transpiles Swift code to Kotlin/Jetpack Compose for Android
- **Backup_Pipeline**: The GitHub Actions workflow that performs daily automated database backups

## Requirements

### Requirement 1: Scenario Selection and Video Playback

**User Story:** As a Sales_Manager, I want to select a life scenario from a grid on my tablet, so that the matching video content plays on the large display screen for my client to view.

#### Acceptance Criteria

1. THE Showcase_App SHALL display a grid of 5 Scenario cards on the Main Screen
2. WHEN a Sales_Manager taps a Scenario card, THE Showcase_App SHALL retrieve the associated Video list from Supabase_Backend
3. WHEN the Video list is retrieved, THE Video_Player SHALL begin playback of the first Video on the External_Display
4. WHILE a Video is playing, THE Showcase_App SHALL display playback controls on the tablet only (not on External_Display)
5. WHEN a Video completes playback, THE Video_Player SHALL automatically play the next Video in the Scenario queue
6. THE Video_Player SHALL display content fullscreen on the External_Display without UI overlays

### Requirement 2: Video Library Catalog

**User Story:** As a Sales_Manager, I want to browse the complete video catalog organized by scenario, so that I can select specific videos to show clients rather than playing entire scenario sequences.

#### Acceptance Criteria

1. THE Showcase_App SHALL provide a Library screen accessible from the Main Screen
2. THE Library screen SHALL display all active Videos grouped by their associated Scenario
3. WHERE a Sales_Manager applies a category filter, THE Library screen SHALL display only Videos matching the selected Scenario
4. WHEN a Sales_Manager taps a Video in the Library, THE Video_Player SHALL play that Video on the External_Display
5. THE Library screen SHALL display Video metadata including title and duration for each Video

### Requirement 3: Wireless Screen Mirroring

**User Story:** As a Sales_Manager, I want the tablet to wirelessly mirror video content to the large display, so that I can control playback from the tablet while clients view content on the big screen.

#### Acceptance Criteria

1. THE Showcase_App SHALL support wireless screen mirroring via AirPlay on iOS/iPadOS
2. THE Showcase_App SHALL support wireless screen mirroring via Cast on Android
3. WHEN the External_Display is connected, THE Video_Player SHALL render fullscreen video content on the External_Display
4. WHILE the External_Display is connected, THE Showcase_App SHALL render playback controls on the tablet screen only
5. IF the External_Display connection is lost, THEN THE Showcase_App SHALL display a connection error message on the tablet

### Requirement 4: Content Management via Supabase

**User Story:** As an Admin, I want to manage video content and scenarios through Supabase Dashboard, so that I can upload new videos, organize scenarios, and control what content is active without requiring a custom CMS interface.

#### Acceptance Criteria

1. THE Supabase_Backend SHALL store Scenario metadata in a scenarios table with fields: id, title, slug, order_index, active
2. THE Supabase_Backend SHALL store Video metadata in a videos table with fields: id, scenario_id, title, storage_path, duration_sec, order_index, active, created_at
3. THE Supabase_Backend SHALL store Video files in Supabase Storage with CDN delivery
4. WHEN an Admin uploads a Video file to Supabase Storage, THE Supabase_Backend SHALL accept video files and generate a storage_path
5. WHEN an Admin sets a Scenario or Video active field to false, THE Showcase_App SHALL exclude that content from display
6. THE Showcase_App SHALL retrieve only active Scenarios and Videos ordered by order_index ascending

### Requirement 5: Cross-Platform Native Applications

**User Story:** As a developer, I want to build the application once in Swift and deploy to both iOS and Android platforms, so that I can maintain a single codebase while delivering native performance on both platforms.

#### Acceptance Criteria

1. THE Showcase_App SHALL be implemented in Swift 6.3 with SwiftUI for iOS/iPadOS
2. THE SKIP_Transpiler SHALL transpile Swift code to Kotlin and Jetpack Compose for Android
3. THE Showcase_App SHALL use a modular Swift Package architecture with ShowcaseCore, ShowcaseUI, and ShowcaseApp modules
4. THE Showcase_App SHALL use @Observable state management for reactive UI updates
5. THE Showcase_App SHALL enforce Swift 6 strict concurrency with Sendable types and Actor isolation for network operations
6. THE Showcase_App SHALL use async/await for all asynchronous operations (no callbacks)

### Requirement 6: Automated Database Backups

**User Story:** As an Admin, I want the database to be automatically backed up daily, so that I can recover content and configuration in case of data loss without manual intervention.

#### Acceptance Criteria

1. THE Backup_Pipeline SHALL execute daily at 02:00 UTC via GitHub Actions scheduled workflow
2. WHEN the Backup_Pipeline executes, THE Backup_Pipeline SHALL dump the Supabase PostgreSQL database to a SQL file
3. THE Backup_Pipeline SHALL name backup files with the format backup_YYYYMMDD.sql
4. WHEN the backup completes, THE Backup_Pipeline SHALL commit the backup file to the Git repository
5. IF the Backup_Pipeline fails, THEN THE Backup_Pipeline SHALL report the failure via GitHub Actions notifications

### Requirement 7: Deployment and Distribution

**User Story:** As a developer, I want to deploy the iOS app via TestFlight and the Android app via APK sideload, so that the sales office can install and use the application without requiring App Store or Google Play approval.

#### Acceptance Criteria

1. THE Showcase_App SHALL be distributed for iOS/iPadOS via TestFlight
2. THE Showcase_App SHALL be distributed for Android via APK sideload (no Google Play submission)
3. THE Showcase_App SHALL not require end-user authentication (always-on kiosk mode for sales office)
4. THE Showcase_App SHALL function with stable internet connectivity (no offline mode required)
5. WHERE the Showcase_App is installed on a tablet, THE Showcase_App SHALL be ready for immediate use without login or setup

### Requirement 8: Content Constraints and Performance

**User Story:** As a Sales_Manager, I want videos to load and play quickly without buffering, so that client presentations remain smooth and professional.

#### Acceptance Criteria

1. THE Showcase_App SHALL support a content library of 20-25 Videos total
2. THE Showcase_App SHALL support 5 Scenarios with 4-5 Videos each
3. THE Showcase_App SHALL enforce a maximum Video duration of 30 seconds per Video
4. WHEN a Video is selected for playback, THE Video_Player SHALL begin playback within 2 seconds on stable internet
5. WHILE a Video is playing, THE Video_Player SHALL maintain smooth playback without buffering on stable internet (>5 Mbps)

### Requirement 9: Service States and Error Handling

**User Story:** As a Sales_Manager, I want clear feedback when content is loading or unavailable, so that I understand the application state and can take appropriate action.

#### Acceptance Criteria

1. WHEN the Showcase_App is loading content from Supabase_Backend, THE Showcase_App SHALL display a loading indicator
2. IF the Supabase_Backend is unreachable, THEN THE Showcase_App SHALL display an offline error message
3. IF no Scenarios or Videos are available, THEN THE Showcase_App SHALL display an empty state with placeholder content
4. WHEN a Video fails to load, THE Video_Player SHALL display an error message and skip to the next Video in the queue
5. THE Showcase_App SHALL log errors to the console for debugging purposes

### Requirement 10: UI Design Language

**User Story:** As a Sales_Manager, I want the application interface to reflect the premium brand aesthetic of the residential complex, so that the presentation tool matches the quality of the product being sold.

#### Acceptance Criteria

1. THE Showcase_App SHALL implement the Liquid Glass design language for iOS/iPadOS 26
2. THE Showcase_App SHALL use SwiftUI components that transpile cleanly to Jetpack Compose via SKIP
3. THE Showcase_App SHALL maintain visual consistency between iOS and Android platforms
4. THE Showcase_App SHALL use typography, spacing, and color schemes appropriate for a luxury real estate context
5. THE Showcase_App SHALL ensure all UI elements are touch-optimized for tablet interaction

