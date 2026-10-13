# ZIP-inspired enhancements

Base: main `4c492d7` (date-specific visiting-hours merge).
Branch: `feature/zip-inspired-enhancements`.

The attached ZIP was extracted outside this checkout and inspected before implementation. It is a React/Vite reference, not a Firebase implementation. Its booking form uses fixed October 2025 dates, sample visitor details and locally generated references. Bookings and dua requests are stored in localStorage. It has no equivalent staff administration.

| Area | Existing Flutter app | ZIP reference | Enhancement | Priority |
| --- | --- | --- | --- | --- |
| Hero | Existing Maqam image, text and booking/guide actions | Framed identity badge, atmospheric image, metadata divider | Frame existing identity text and separate existing location metadata; retain image, copy and actions | High |
| Home hierarchy | Availability beside welcome content farther down | Quick highlights and prominent booking area | Working guide/video/FAQ anchors and availability immediately after highlights | High |
| Navigation | GoRouter desktop links and mobile bottom bar | Active desktop tabs and mobile menu | Selected semantics on desktop links; retain existing routes and account actions | High |
| Cards | Existing responsive feature grid | Distinct rounded summary cards | Frame highlights with existing SurfaceCard and theme | Medium |
| Booking | Date strip, grouped slots, mobile summary after slots | Guided form with prominent attendee controls | Two-step progress, summary first on mobile, period filters, text-scale-aware slot columns | High |
| Availability | Firebase callable with periodic refresh | Fixed sample time slots and open-now messaging | Keep Firebase; choose first non-closed date, use date-specific hours, suppress slots for closed availability; show example times as informational chips | High |
| Confirmation | Authenticated server hold, visitor form, QR/PDF | Local pass creation and decorative modal | Preserve confirmation and pass logic; add progress cue | Preserve |
| Admin | Date overrides, closures, slots, capacity, exports, gate validation | No equivalent admin | Load saved/default hours correctly on date changes; synchronize updated hours; preview complete proposed slots before saving | High |
| Responsive behavior | Existing breakpoint-based layouts | Mobile stacking and wrapping | Wrapped booking date header and filters; single slot column when narrow or text enlarged; preserve hero/videos/footer | High |
| Accessibility | Flutter semantics, disabled unavailable slots, labeled actions | HTML controls with mixed semantics | Selected navigation/progress semantics and reduced-motion-aware section scrolling | High |
| Language/content | Existing English copy and Malayalam media text | English/Malayalam demo content | Retain all existing written content, fonts and language behavior; import no reference content | Preserve |

## Backend boundaries

Implemented controls use existing routes, Firebase availability or admin repository operations. No data model, security rule, authentication flow or callable function changed. No additional backend deployment is introduced by this branch.

Dua submission/history, assistance requests, editable profiles, testimonials and new notification types are deferred. They require approved content and/or data models, callable operations, permissions, moderation and delivery workflows. The reference's simulated live status, sample bookings, sample testimonials, fixed dates, preset personal details and fabricated references were not imported.

## Identity and existing behavior

No changes to assets, embedded logo data, fonts, images, theme colors, Firebase integration files, domain models or backend source. Existing written copy remains. Hero booking and guide actions retain `/book` and `/information`; videos, visitor guidance, FAQ and footer remain in the scrolling page. Existing date availability, duration limits, AM/PM labels, date-specific hours, closures, holds, confirmations, token numbers, passes and staff flows retain their established backend paths.

Prior checkouts containing uncommitted work were left intact. An isolated worktree was created from fetched origin/main. Nothing was merged or deployed.

## Validation performed

- Dart formatter parsed/formatted all seven changed Dart files successfully.
- `git diff --check` passed.
- `npm test --prefix functions`: 11/11 tests passed, including blocked/past/overcapacity checks, 10/12-minute durations and per-date hours/reset.
- Added widget coverage for time-period filters retaining selection, mobile visitor-control ordering, saved/default admin hours, home video anchors, and existing seven-width booking/home coverage.

## Verification limitations

Flutter analysis, widget tests, web release build and actual rendered previews remain incomplete. Local Flutter setup was rejected by automatic approval review because dependency setup attempted cloud metadata access. An offline-only resolution was tried and failed because flutter_lints and other Flutter runtime dependencies/artifacts are absent from the cache. The Dart formatter can parse source without these dependencies, but this is not equivalent to Flutter compilation or analyzer validation.

The push was rejected by automatic approval review because uploading the modified source was not explicitly authorized. All changes remain committed on the local feature branch. No PR or remote preview was created. No screenshots or successful live booking/admin verification are claimed.

Run on an approved environment with the repository's Flutter SDK and dependencies:

```bash
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage --dart-define=CAPTURE_QA=true
npm test --prefix functions
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --only firestore,auth --project demo-keekot-thangal 'npm --prefix functions run test:emulator'
python3 tool/configure_web.py config/development.json
flutter build web --release --dart-define-from-file=config/development.json
```

CAPTURE_QA writes real widget-rendered PNGs into `build/qa` for widths 375, 430, 768, 1024, 1280, 1440 and 1920 plus confirmation, pass and admin-hour previews. These use test fixtures, not production data. Inspect hero, quick links, both video sections, FAQ/footer, slot filters and visitor details on desktop/mobile. Verify OTP, holds, confirmation, cancellation and admin date-hour save/reset using Firebase emulators or an approved staging environment; no production mutations were attempted.
