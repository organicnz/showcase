---
name: supabase-video-cdn-streaming
description: Video asset optimization, Supabase Storage CDN delivery, and AVPlayer streaming standards. Use when managing video encoding (H.265 / <5 Mbps / faststart), storage folder hierarchies, multi-tier URLCache prefetching, and seamless presentation streaming for office TV displays.
---

# Supabase Video CDN & Streaming Architecture

This skill governs the ingestion, encoding, storage structure, and client-side playback pipeline for all high-definition video assets in the Showcase application.

Because the system runs sales presentations for high-net-worth clients in Meshchersky Park, playback must start with **zero perceptible latency**, zero buffering spinners, and fluid cross-fades.

---

## 1. Video Encoding & Ingestion Specifications

All video assets uploaded to Supabase Storage MUST strictly adhere to the following specifications:

| Parameter | Specification | Purpose |
|---|---|---|
| **Codec** | H.265 (HEVC) with H.264 Fallback | Maximum visual fidelity per bit on Apple Silicon & Android |
| **Bitrate** | Target 3.5 – 4.5 Mbps (Max 5.0 Mbps) | Rapid streaming without bandwidth saturation on Wi-Fi |
| **Resolution** | 1080p (1920×1080) @ 30fps or 60fps | Optimal balance for iPad preview and large 4K TV scaling |
| **Clip Duration** | Max 30 seconds per clip | Concise, punchy storytelling per scenario node |
| **Container** | MP4 (`.mp4`) with `faststart` | Moves `moov` atom to header for immediate playback initiation |
| **Audio** | AAC-LC, Stereo, 160 kbps, 48 kHz | Clean, immersive ambient sound |

### Recommended FFmpeg Encoding Command:
```bash
ffmpeg -i input_master.mov \
  -c:v libx265 -crf 22 -preset slow \
  -tag:v hvc1 \
  -maxrate 4.8M -bufsize 9.6M \
  -c:a aac -b:a 160k -ar 48000 \
  -movflags +faststart \
  optimized_video.mp4
```

---

## 2. Supabase Storage Folder Hierarchy

Assets in the `videos` bucket must follow a deterministic, slug-based folder structure:

```
videos/
├── family/
│   ├── 01_school_grounds.mp4
│   ├── 02_playground_safety.mp4
│   └── 03_park_trails.mp4
├── wellness/
│   ├── 01_spa_sanctuary.mp4
│   └── 02_forest_run.mp4
├── hotel/
│   └── 01_concierge_service.mp4
├── investor/
│   └── 01_capital_growth.mp4
└── architecture/
    ├── 01_facade_stone.mp4
    └── 02_panoramic_light.mp4
```

### Storage Headers:
Set immutable CDN caching headers on all uploaded video files:
`Cache-Control: public, max-age=31536000, immutable`

---

## 3. Client Caching & Two-Tier Prefetching

To avoid re-downloading media across repeated client sessions, configure a robust `URLCache` in `ShowcaseApp`:

```swift
public func configureMediaCache() {
    // 256 MB RAM, 2 GB Local Disk Cache
    let memoryCapacity = 256 * 1024 * 1024
    let diskCapacity = 2 * 1024 * 1024 * 1024
    let cache = URLCache(
        memoryCapacity: memoryCapacity,
        diskCapacity: diskCapacity,
        diskPath: "showcase_video_cache"
    )
    URLCache.shared = cache
}
```

### Intelligent Prefetch Pipeline:
1. **Scenario Grid Load:** Fetch scenario metadata and prefetch cover image thumbnails into memory.
2. **Scenario Selection:** When a scenario card is tapped, instantiate an `AVPlayerItem` for the first video clip (`order_index: 0`) and immediately start pre-buffering.
3. **Queue Lookahead:** When video `N` is playing at `duration - 5s`, initialize the player item for video `N + 1` in the background.

---

## 4. Playback Engine Implementation (`NativeVideoPlayerView`)

Ensure the player view properly coordinates external screen streaming (AirPlay / Cast) while keeping controls on the tablet:

```swift
import SwiftUI
import AVKit

public struct VideoPlayerContainer: View {
    let videoURL: URL
    @State private var player: AVPlayer?

    public init(videoURL: URL) {
        self.videoURL = videoURL
    }

    public var body: some View {
        ZStack {
            if let player = player {
                NativeVideoPlayerView(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(Color.gold)
            }
        }
        .onAppear {
            let item = AVPlayerItem(url: videoURL)
            let newPlayer = AVPlayer(playerItem: item)
            newPlayer.automaticallyWaitsToMinimizeStalling = true
            newPlayer.play()
            self.player = newPlayer
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
```

---

## 5. Network Resilience & Offline Fallbacks

* **Network Stalls:** Monitor `AVPlayerItem.playbackBufferEmptyObserver` and show a subtle glass blur over the last rendered frame instead of an abrupt black screen.
* **Connectivity Recovery:** Re-verify Supabase CDN health via `SupabaseManager.shared.checkHealth()` before showing the `ServiceStateView.offline` overlay.
