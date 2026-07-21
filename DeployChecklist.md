# BeautyHub Deployment Readiness — Review Log

Review date: 2026-07-22

## Findings from the code review

- **Backend**: `beautyhub-api` only runs locally (native Windows Postgres service). `ApiConfig.baseUrl` (`lib/core/config/api_config.dart`) has no production value — defaults to `10.0.2.2:3000`/`localhost:3000`. No Dockerfile/fly.toml/render.yaml for cloud hosting.
- **Cleartext traffic**: `android/app/src/main/AndroidManifest.xml` has `usesCleartextTraffic="true"`, flagged as dev-only.
- **Password reset email**: `AuthService.requestPasswordReset` (`beautyhub-api/src/auth/auth.service.ts`) calls a `MailerService`, but dev builds just echo the reset code — no real mail provider wired up.
- **Release signing**: `android/app/build.gradle.kts` signs release builds with the **debug keystore** (`TODO: Add your own signing config`) — will be rejected by Play Console as-is.
- **iOS signing**: not set up yet (expected at this stage).
- **Terms & privacy**: placeholder (`_comingSoon`) in `profile_screen.dart` — both stores require a real privacy policy URL.
- **Account deletion**: no self-service account deletion — required by Apple Guideline 5.1.1(v) for apps with account creation. `AuthRepository` only has `signOut()`.
- **Payments / Notifications**: both "coming soon" placeholders in the Profile screen.
- **Tests**: `flutter analyze` is clean; `flutter test` covers auth flow, home screen, api client, mock booking repo — no coverage for booking flow, salon detail, or forgot-password.
- **CI**: `.github/` is empty — nothing enforces `analyze`/`test` automatically.
- **Crash reporting / analytics**: none integrated (no Crashlytics/Sentry).
- **App icon / launch screen**: not verified whether these are still Flutter defaults.
- **Build flavors**: none — only a single `--dart-define` override, no dev/staging/prod separation.

## Questions asked and answers given

**Q1. Where will beautyhub-api actually run in production?**
Options offered: Not decided yet / Already have a target host / Deploy later, ship app store beta against local-staging first.
**Answer:** *"based on the app I created, which hosting provider is best for early versions with not as many users?"* (asked for a recommendation)
**Recommendation given:** **Railway** — auto-detects the NestJS app, managed Postgres add-on in the same project, usage-based pricing from ~$5/mo, no cold starts. **Render** as a fallback (free tier available but has cold starts). Fly.io/raw VPS ruled out as more ops overhead than a solo MVP needs right now.
*(Not yet provisioned — still an open action item.)*

**Q2. Is in-app payment required for the v1 launch, or is this a pay-at-the-venue booking model?**
Options offered: Pay at venue (recommended) / In-app payment required at launch.
**Answer:** **In-app payment required at launch.**

**Q3. Which platforms are you targeting for the first release?**
Options offered: Android first, iOS later / Both simultaneously / Internal-closed testing only for now.
**Answer:** **Both simultaneously.**

**Q4. Booking confirmations/reminders — is push notification support required before launch, or can it stay a post-MVP placeholder?**
Options offered: Defer to post-MVP (recommended) / Required for v1.
**Answer:** **Defer to post-MVP** (keep the "Notifications" placeholder as-is for v1).

**Q5. iOS builds require Xcode/macOS for signing and App Store submission. Do you have access to a Mac (or a cloud Mac CI service)?**
Options offered: No Mac access yet / Have a Mac available / Already using a cloud Mac CI.
**Answer:** **No Mac access yet.** → Need a cloud Mac CI (Codemagic recommended — free tier, native `flutter build ipa` support) before any iOS signing work can start.

**Q6. Which payment processor do you want to integrate?**
Options offered: Not decided / want a recommendation / Stripe / Already chosen a provider.
**Answer:** **Stripe.**

## Resulting action checklist

### Backend
- [ ] Provision Railway (Postgres + web service for `beautyhub-api`)
- [ ] Point `ApiConfig.baseUrl` at the Railway URL via `--dart-define=API_BASE_URL=...` (or add dev/staging/prod build flavors)
- [ ] Wire a real mailer provider (Resend/SendGrid/Postmark) for password-reset emails
- [ ] Migrate Postgres schema to Railway via Prisma
- [ ] Remove `usesCleartextTraffic="true"` once the API is HTTPS

### Stripe integration
- [ ] Backend: Stripe account, webhook endpoint, `PaymentIntent` creation on booking creation, confirm-on-webhook booking status, refund on cancel
- [ ] Flutter: add `flutter_stripe`, new `Payment` domain entity + repository, wire PaymentSheet into the booking flow
- [ ] Decide currency/locale for `formatters.dart` (currently unset)
- [ ] Replace "Payment methods" placeholder in `profile_screen.dart` with real saved-card management or drop it

### Release signing & builds
- [x] Android: generate a real upload keystore, wire into `build.gradle.kts` — done 2026-07-22. `android/app/upload-keystore.jks` (alias `upload`) generated, `android/key.properties` created (gitignored, already covered by existing `.gitignore` patterns), `build.gradle.kts` release signing config now reads from it. Verified: built `app-release.apk` and confirmed its cert SHA-256 matches the new keystore. **Backed up 2026-07-22** to `D:\DevCaches\keystores\beautyhub\` (checksum-verified copy of both files). This is still the same physical drive as the repo — for real disaster recovery, also copy that folder to a password manager, external drive, or cloud storage.
- [ ] iOS: set up Codemagic (or similar cloud Mac CI) for certs, provisioning, TestFlight uploads
  - [x] `codemagic.yaml` added 2026-07-22 — unsigned build (`flutter build ios --release --no-codesign` on a Mac mini M2 instance, runs `analyze`+`test` first), triggered on push to `main`. Proves the iOS build pipeline compiles without needing Apple Developer enrollment yet.
  - [ ] **Manual step (needs your Codemagic login):** sign up at codemagic.io, connect via GitHub OAuth, select the BeautyHub repo — it will auto-detect `codemagic.yaml`.
  - [ ] Enroll in Apple Developer Program ($99/yr, apple.com/developer) — not enrolled yet as of this review; can take 24-48h to clear.
  - [ ] Once enrolled: add Codemagic's iOS code signing (App Store Connect API key integration), switch the build script to `flutter build ipa --release`, and decide then whether to auto-publish to TestFlight (deferred by choice — building a downloadable `.ipa` first was preferred over auto-publish).

### Store compliance
- [ ] Real Privacy Policy + Terms page
- [ ] Self-service account deletion (`AuthRepository` needs a `deleteAccount()`-style method)
- [ ] Play Console: Data Safety form (now must disclose financial info), content rating, feature graphic, screenshots
- [ ] App Store Connect: App Privacy label (disclose Stripe SDK data collection), screenshots, age rating, export compliance
- [ ] Confirm final app icon/launch screen aren't still Flutter defaults

### Quality gates
- [x] Add CI (`.github/workflows`) running `flutter analyze` + `flutter test` — done 2026-07-22. `.github/workflows/ci.yml` runs on push to `main` and on PRs, pinned to Flutter 3.35.5 stable. Pushed to `origin/main` and verified green: [run #1, success](https://github.com/kmeister-son/BeautyHub/actions/runs/29876781306).
  - [x] **Done 2026-07-22:** added a `build-android` job to `ci.yml` (runs only on push, after `analyze-and-test` passes). Reconstructs `android/key.properties` and `upload-keystore.jks` from four GitHub Actions secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`, set via `gh secret set` from the local backup files — never pasted into chat), then runs `flutter build appbundle --release` and uploads `app-release.aab` as a workflow artifact.
    - Hit and fixed one real issue: the job initially used JDK 11 (matching the app's `compileOptions`), but the Android Gradle Plugin needs **JDK 17 to run Gradle itself** — a separate concern from the app's own bytecode target, which stays at 11. Fixed in commit `38ca0a7`.
    - Verified green end-to-end: [run 29877793439, both jobs success](https://github.com/kmeister-son/BeautyHub/actions/runs/29877793439).
    - Still just an artifact, not published anywhere — auto-upload to Play Console (needs a service-account JSON secret) is a separate future step, not yet requested.
- [ ] Add tests for booking flow, salon detail screen, forgot-password screen
- [ ] Add crash reporting (Sentry or Firebase Crashlytics)

### Already fine / correctly deferred
- Push notifications — deferred to post-MVP per decision above
- `flutter analyze` is clean; `ApiClient` already has timeout/retry/401-refresh handling
