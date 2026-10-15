# Validation — October 14, 2026

## Verified

- Built on **macOS arm64, Xcode 27.0 (27A266a), Swift 6.4 toolchain**, with the iPhoneSimulator 27.0 SDK. Project uses Swift 5 language mode and targets iOS 17+.
- Initial simulator Debug build: **BUILD SUCCEEDED**.
- Final clean simulator Debug build, including Assets.xcassets/AppIcon and the corrected excluded-interval count: **BUILD SUCCEEDED**. Both arm64 and x86_64 simulator slices compiled. Signing disabled, no third-party dependencies.
- All **seven unit tests passed with zero failures** on an isolated iPhone 18 Pro / iOS 27 simulator in the initial run. These tested empty history, sparse history/fallback, median and duplicate/future dates, interval bounds/variation, overdue forecasts, latest-12 history, and actual on-disk SwiftData reopen/export encoding/revocation flags/deletion.
- After that passing run, the excluded-interval count was corrected so history older than the latest 12 is not labeled out-of-bounds. Its assertion and assertions for all revoke flags were added to the tests. The final test sources compiled in the retry, but that retry did not execute its suites; these added assertions are not claimed as passing.
- Info.plist, PrivacyInfo.xcprivacy and project.pbxproj passed `plutil -lint`.
- Source archive integrity checked; includes source, shared scheme, tests, icon, instructions and these validation notes.

`Verification/build-summary.txt` and `Verification/initial-unit-tests.txt` contain compact evidence excerpts.

## Incomplete / not verified

The first Xcode test invocation completed the unit suite, then the XCUITest runner stalled after “Running tests…” without starting its UI test method. It was interrupted. A second attempt restarted the dedicated simulator and disabled parallel testing. It compiled the final app and test targets but stalled before executing the suites and was interrupted. Neither overall test invocation is reported as a passing full test run. Other already running simulators were left untouched.

The included UI smoke test is therefore **unverified**. It is intended to finish onboarding, save a daily log, relaunch to confirm persistence, and visit all five tabs. No claim is made that those UI steps passed. No app-screen visual QA or end-to-end export, sharing controls, notification or full-reset UI checks are claimed.

Direct launch checks were also attempted. One launch interrupted by the simulator restart returned Mach error -308 (server died). The final direct launch returned `com.bloom.private.bloom: 74447`, confirming that the simulator started the app process. Its screen and interactive behavior were not verified before shutting down the isolated test simulator. Re-run the UI smoke test from Xcode on a responsive clean simulator before real use.

Physical iPhone installation/signing, biometric/passcode flows, locked-device file protection, app-switcher concealment, notification delivery, accessibility/large text/small-screen layouts, timezone transitions and reproductive-health prediction accuracy remain unverified. No App Store archive or upload was made.

The uncertainty range is a transparent heuristic, not a medically validated confidence interval. Ovulation/fertility output is for awareness only and must never be used to prevent pregnancy. Partner Mode is a local owner-controlled preview; remote synchronization is not implemented.

## Reproduce

Open `Bloom.xcodeproj` on a Mac with Xcode and an installed iOS simulator runtime. Select Bloom and an iPhone simulator; use Product → Build, Run, then Test. Start with a clean test installation for the UI test. On a simulator without device authentication, turn optional app lock off in onboarding; this is a user-visible choice, not a test-only bypass. See README.md for command-line equivalents and physical-device signing instructions.

Xcode builds and iPhone Simulator tests require macOS. They cannot be performed on a Windows or Linux machine with this source alone.
