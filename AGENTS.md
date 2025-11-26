# MediFastApp AI Collaboration Guide

This handbook sets the guardrails for AI-assisted development within the MediFast iOS project. It defines how 

agents research, plan, and execute tasks while preserving the app’s lightweight, offline-first philosophy. Treat every guideline here as additive to Xcode best practices and the project README.


## 1. Purpose & Scope
- Support iterative improvements to the SwiftUI app without disrupting the team’s workflow.
- Apply these rules to code, assets, or documentation inside `MediFastApp` and related targets.
- When in doubt, stop and ask—collaboration beats assumption.

## 2. Collaboration Principles
- **Analyze → Plan → Approve → Implement.** Always surface your intent before touching code.
- The human developer controls simulators, previews, builds, and device installs. Ask rather than launching anything automatically.
- Summaries should highlight impact, touchpoints, and any follow-up needed for verification.

## 3. Environment & Tooling Norms
- Primary stack: Swift 5.9+, SwiftUI, Xcode 15+. Confirm compatibility if suggesting platform features.
- Follow the code style already present (spacing, casing, extensions). If unsure, point to the file you mirrored.
- Before introducing scripts or tools (SwiftLint, formatters, etc.), explain the motivation and wait for approval.
- Asset updates belong in `MediFastApp/BrandAssets`. Share changes so icons or image sets can be refreshed intentionally.

## 4. Architecture Snapshot
- The app embraces a simple MV\* split: lightweight `Models`, focused SwiftUI `Views`, and small `ViewModels` under `Features`.
- `RootTabView` coordinates the three primary tabs (Meditate, Breathe, Fast). Respect this entry point when adding flows.
- Shared utilities live in `Shared/` and `Storage/`. Prefer extending existing helpers over creating parallel abstractions.
- Keep responsibilities narrow; a new type should have one reason to change.

## 5. UI & Interaction Guidelines
- Reuse existing view components, modifiers, and layouts before designing new ones.
- When something must be new, lean on SwiftUI primitives and match the existing look via `Theme` and `Appearance`.
- Interfaces skew minimal and dense—keep controls compact, timers legible, and avoid superfluous chrome.
- Focus Mode and timers rely on the screen staying active; never assume background execution.
- Maintain accessibility: label custom controls and preserve large, readable typography.

## 6. State, Timing & Persistence
- Use the `StorageProtocol` abstractions (`UserDefaultsStorage`, keyed APIs) for persistence. Do not talk directly to `UserDefaults` unless expanding existing storage helpers.
- Timers should use the established utilities (`TimelineView`, `TimeFormatter`) to keep behavior consistent across tabs.
- Guard foreground-only assumptions: document any scenario that might break if the app is backgrounded.
- Version storage keys when adding new persisted data to avoid corrupting existing user records.

## 7. Audio, Haptics & Feedback
- Optional sound cues flow through `AudioPlayer` and `Sounds`. If adding assets, note the filenames required.
- Haptic interactions should wire through the existing haptics helper to preserve consistent feedback strength.
- Never assume an asset exists—fall back gracefully and document any manual steps a human must take.

## 8. Feature-Specific Notes
- **Meditation:** Observe preset structures, warm-up timing, midpoint bell logic, and streak tracking. Reuse the streak utilities if extending streak behavior.
- **Breathing:** The round lifecycle (breathing → retention → recovery) is sequential; maintain the state machine and result summaries.
- **Fasting:** Active fasts, history entries, and stats rely on accurate duration math. Coordinate with `TimeMath` helpers and respect midnight crossing logic.

## 9. Privacy & Offline Constraints
- The app is deliberately offline: no networking, cloud sync, HealthKit, or notifications. Any proposal that touches external services requires explicit buy-in first.
- Store everything locally and keep user data lightweight. Make any privacy-sensitive considerations explicit in your summary.

## 10. Testing & Verification
- Existing unit tests are minimal. Align with the human team before creating or modifying tests.
- After implementing code changes, describe recommended manual checks (e.g., “Run a simulated 10-minute fast and confirm streak persists”).
- If a test gap blocks confidence, call it out rather than guessing.

## 11. Documentation & Assets
- Update docs only after explaining the intent and obtaining approval. This includes `README.md`, in-app help, or localized text.
- When asset tweaks are required (icons, sounds), list the files and the manual actions a human needs to perform.

## 12. Change Workflow Checklist
1. Review relevant files and note existing patterns.
2. Draft a concise plan (files, behaviors, risks) and wait for a human green light.
3. Implement the approved scope, keeping changes focused and reversible.
4. Validate compilation steps conceptually, then request the user to run builds or tests as needed.
5. Summarize outcomes, outstanding work, and recommended follow-ups.

By adhering to these conventions, AI contributors help keep MediFastApp calm, predictable, and easy to maintain—mirroring the experience the app aims to deliver for its users.
