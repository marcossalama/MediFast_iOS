# MediFast (iOS)

Minimal, on‑device mindfulness app for iOS 17+ built with SwiftUI.

Tabs
- Meditate: presets, warm‑up, optional mid‑point bells, focus mode, streaks
- Breathe: guided rounds (Wim Hof–style) → breathing, retention, recovery
- Fast: start/stop timer, history, and simple stats

Philosophy
- 100% on device. No networking, iCloud, HealthKit, or notifications
- Foreground‑only timers (no background execution assumptions)
- Small, readable code with simple MV (Models, Views, ViewModels)

Requirements
- Xcode 15+
- iOS 17+ (simulator or device)

Build & Run
- Open `MediFastApp/MediFastApp.xcodeproj`
- Select scheme `MediFastApp`
- Choose an iOS 17+ simulator (e.g., iPhone 15/16)
- Run (Cmd+R)

Features
- Meditate
  - Presets: 5/10/20 min + Custom
  - Optional warm‑up (5–15s) and midpoint bells (every N minutes)
  - Focus Mode: full‑screen, progress + large timer, disables auto‑lock
  - Completion feedback: haptic + (optional) short sound when foregrounded
  - Persistence: completed sessions + simple day streaks
- Breathe (Wim Hof–style)
  - Rounds: configure rounds, breaths/round, and recovery hold seconds
  - Flow per round: Breathing (tap to count) → Retention (count‑up) → Recovery (count‑down)
  - Results summary: per‑round retention + best/average/total
  - Foreground‑only timing driven by TimelineView
- Fast
  - Start/Stop active fast with live HH:MM:SS counter
  - History log (start, end, duration)
  - Stats: last, longest, 7‑day average

Storage
- UserDefaults via a tiny storage abstraction (`StorageProtocol` + `UserDefaultsStorage`)
- Keys (versioned):
  - `meditation.settings.v1`, `meditation.sessions.v1`, `meditation.streaks.v1`
  - `fasting.active.v1`, `fasting.history.v1`
  - `breathing.settings.v1`, `breathing.history.v1`

Sounds (optional)
- Add short audio files to the app target if desired:
  - `bell_start.caf`, `bell_mid.caf`, `bell_end.caf`
  - If missing, playback no‑ops; haptics still provide cues

Tests
- `MediFastAppTests/TimeMathTests.swift`
  - Midnight crossing duration
  - Duration formatting over 24h

Accessibility & Design
- Minimal UI using system fonts and SF Symbols
- Large, legible timers; monospaced digits for time readouts
- Basic accessibility labels on key controls

Limitations
- Foreground‑only timers (no background tasks or notifications)
- No remote storage; data remains on device

Roadmap (short)
- Expand unit tests (streak logic, breathing state machine)
- Optional multi‑session breathing history
- Small polish passes on meditation and results screens

License
- TBD
