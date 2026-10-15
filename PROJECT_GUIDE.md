# Bloom — native iPhone edition

An original SwiftUI period and wellbeing journal, built for iPhone with SwiftData persistence and Swift Charts. Minimum deployment target: iOS 17. No packages, API keys, accounts, or backend required.

The earlier conversation referenced `bloom-iphone-prototype.zip`, but the local project mirror and available conversation attachments contained no prototype files. This is a native rebuild from the documented feature requirements, with original styling, rather than a source-level port. Synced reference material under `sources/` was left untouched.

## Open and run

1. On a Mac with Xcode 15 or later (verified development toolchain: Xcode 27.0), open `Bloom.xcodeproj`.
2. Select the **Bloom** scheme, choose an installed iPhone Simulator, and press Run (⌘R).
3. For your own iPhone, choose your development team in Signing & Capabilities, use your own unique bundle identifier, connect your phone, and select it as the destination. A simulator build is not an installable signed iPhone archive.
4. Finish onboarding. No sample data is inserted. If your simulator has no device authentication configured, turn **Lock when leaving Bloom** off during onboarding. On a real iPhone, keep it on and set a device passcode.
5. Use Today → Check in to log a day. Calendar lets you edit historical entries. Mark **First day of a new period** only once per period, and select a nonzero flow.

Build without signing:

```sh
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/BloomDerived CODE_SIGNING_ALLOWED=NO build
```

Run tests on a clean simulator (replace the destination with an installed iPhone):

```sh
xcodebuild -project Bloom.xcodeproj -scheme Bloom \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -parallel-testing-enabled NO \
  -derivedDataPath /tmp/BloomDerived CODE_SIGNING_ALLOWED=NO test
```

Unit tests cover prediction edge cases, actual SwiftData disk persistence, export encoding, revocation flags, and deletion. The UI smoke test expects a fresh install, deliberately turns off optional app lock via onboarding, saves an entry, relaunches to check persistence, and visits the tabs. It does not bypass authentication. Reset only a dedicated test simulator or uninstall only this app before repeating the UI test; this destroys its test data.

Xcode builds and iPhone Simulator tests require macOS and installed Xcode/iOS runtimes. This delivery was developed on a Mac; see `VALIDATION.md` for actual results and outstanding device checks.

## Included

- Onboarding with optional name, cycle length, optional last period start, estimate acknowledgement, and app-lock choice.
- Daily flow, explicit period starts, nine symptoms, mood, private journal, editing and per-day deletion.
- Month calendar with actual bleeding and possible next start dates; future entry editing is disabled.
- History-based period forecast with a visible uncertainty range, overdue state, and transparent assumptions.
- Opt-in rough ovulation/fertility estimates after three usable completed cycles; strong non-contraception warning.
- Cycle length charts and symptom counts; searchable journal.
- Device authentication on launch/return, app-switcher privacy cover, local protected storage, backup exclusion, no network client or analytics.
- Optional daily local notification at 8 PM, with neutral wording. Delivery and permissions depend on iOS settings.
- Owner-controlled granular Partner Mode **local preview** with explicit approval for individual journal entries and revoke-all.
- JSON export via the system document picker; full local deletion and reminder cancellation. Export import is not implemented.
- Original cream, mulberry and sage styling, serif typography, native controls, and a custom procedural flower app icon.

## Partner Mode: exact scope

This release does **not** connect two iPhones. No remote accounts, invitation tokens, CloudKit sharing, or server exist. Partner Mode is an owner-opened preview on the same unlocked device, clearly labeled throughout. It is not an account boundary and should not be used to hand an unlocked owner app to an untrusted person.

All permissions default off: predicted period window, today's flow, today's symptoms, today's mood, and individually approved journal entries. Both the journal category and each entry approval must be on. Revoking disables every category and clears every entry approval; re-enabling starts with no shared categories. Revocation cannot undo what someone has seen or copied. No health export is ever created by partner preview.

A true two-phone version needs authenticated identities, owner-approved invitations, server-side field authorization, encryption and key lifecycle, expiration/revocation enforced on every request, retention policies, and a security review before release. This project makes no claim of remote synchronization.

## Prediction limitations

Bloom computes local calendar-day intervals between explicit starts, deduplicates days, ignores future starts, and uses the latest 12 intervals of 15–90 days. These are calculation bounds, **not medical normality thresholds**. It uses the median cycle length; with no completed cycle, it uses the owner's preference (default 28). Excluded intervals are reported.

The uncertainty radius is the greater of the maximum observed deviation from the median plus two days, or seven days with fewer than three intervals / three days otherwise. This is an unvalidated heuristic, not a calibrated probability or clinical confidence interval. Bloom never rolls an overdue forecast forward as though an unlogged period happened. Only the next cycle is estimated.

If enabled, estimated ovulation is 14 days before the next predicted period, with an illustrative fertile window from five days before through one day after that estimate. Ovulation can vary or be absent. Those dates do not define infertile or safe days. Predictions may be particularly misleading with irregular cycles, hormonal contraception, pregnancy, postpartum changes, or perimenopause.

**Never use Bloom to prevent pregnancy. It is not a medical device, diagnostic system, fertility confirmation tool, or substitute for medical care.**

Reference: [ACOG — Fertility Awareness-Based Methods of Family Planning](https://www.acog.org/womens-health/faqs/fertility-awareness-based-methods-of-family-planning). The Bloom heuristic itself has not been clinically validated and is not endorsed by ACOG.

## Privacy and data handling

The SwiftData configuration explicitly disables CloudKit. Data lives in Application Support/Bloom, created with complete iOS file protection and excluded from backups. Device authentication uses LocalAuthentication with device-passcode fallback, never a custom stored PIN. The app hides its content while inactive/backgrounded and requires unlocking again on return when enabled. Biometrics, passcode fallback, and file protection must also be checked on a real locked iPhone; a simulator cannot establish hardware security guarantees.

Exports contain readable, unencrypted health information. Save them only where you intend to keep a copy. Bloom cannot revoke exports, screenshots, or other outside copies. Logical deletion removes all local model entries and resets preferences, sharing and reminders; it does not promise forensic erasure from storage blocks. The OS notification prompt is requested only when the owner enables reminders. Notification wording contains no menstrual information.

No HealthKit, microphone, location, tracking, contacts, or photo access is requested. The privacy manifest declares no tracking or collection by the developer. Review App Store privacy disclosures, regional requirements and the final shipped binary before distribution. No App Store submission, signing identity, or paid subscription is included.

## Source layout

`BloomApp.swift`: storage and privacy gate; `Models.swift`: SwiftData and export schema; `PredictionEngine.swift`: pure date calculations; `Services.swift`: authentication, reminders and document export; view files: onboarding, five owner tabs, daily editor and partner preview. `BloomTests` and `BloomUITests` hold automated checks.

The project file is checked in and ready to open. `python3 scripts/generate_project.py` regenerates its deterministic structure if source files are added; no generator is required to open or build the project.

## Manual release checks

- Test Face ID denial/cancellation, device-passcode fallback, relock, and app-switcher cover on a physical iPhone.
- Test large Dynamic Type, VoiceOver, a small iPhone screen, timezone changes and calendar-month boundaries.
- Verify entries and journal edits after force-quit/relaunch; verify delete-all returns to empty onboarding.
- Exercise every partner permission combination and revoke/re-enable; no unapproved journal entry may appear.
- Enable/deny notifications, inspect neutral lock-screen wording, then disable/delete and check pending reminders are gone.
- Save an export in Files and inspect it; understand that deleting Bloom cannot delete that copy.
- Validate predictions against real consenting-user data before relying on planning estimates. Do not use them as contraception.
