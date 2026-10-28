# Sanctuary Heritage mobile review

The mobile visitor and staff screens now use the home screen's forest panels, cream cards, ivory fields, brass accents and editorial typography. The mobile identity uses the web name, **Keekkott Sayyid Attakoya Thangal**, with **Online Booking** beneath it. Application metadata uses the exact web title, **Keekkott Sayyid Attakoya Thangal | Online Booking**.

Branch: `design/mobile-sanctuary-all-screens`, based on main `8df72eb0031c95e1098251199357347bb84f1011`. This change is for review; it does not merge or deploy the app.

## Route and component audit

| Area | Routes / entry points | Result |
| --- | --- | --- |
| Sanctuary content | `/`, home section links, `/information` | Existing heritage, programmes, etiquette, FAQ and location content retained; shared typography and navigation |
| Visitor authentication | `/login`, `/auth` redirect | Cream mobile form, readable phone/OTP fields, consent, resend, busy and error states |
| Staff authentication | `/admin/login`, `/khadim/login`, `/khadim-login` redirect | Same visual system; Malayalam field labels, actions, helpers and password controls |
| Booking selection | `/book`, `/book/select-slot` redirect | Compact date chips, period filters, two-column slots, single-column large-text fallback, live configuration limits and visitor stepper |
| Confirmation | `/book/confirmation` | Booking summary, wrapping hold countdown, visitor/staff-assisted details, validation, retry/expired states and existing change-time action |
| Success and pass | `/book/success/:id`, `/booking/:id`, `/pass/:id` | Ivory ticket with brass outline; existing QR, token, visitor, Khadim, PDF, WhatsApp and cancellation actions |
| Booking history | `/my-bookings` | Wrapping upcoming/past controls, booking cards and empty states |
| Contact and notifications | `/contact`, `/notifications` | Shared surfaces, form feedback, existing opt-in and booking links |
| Media | Home archive, gallery and player dialog | Existing full-length YouTube IDs/links retained; readable mobile recording cards and English titles in English mode |
| Administration | `/admin`, `/admin/bookings` | Compact mobile navigation/export accordions, responsive dashboard cards and booking search/actions |
| Schedules | `/admin/slots`, `/admin/settings` | Date hours, capacity, closures, block/reopen, retry and configuration controls styled and translated |
| Khadim management | `/admin/khadims` | Complete account cards preserve phone, enabled state, permissions, edit/reset and deletion actions |
| Assignments | `/admin/assignments`, `/khadim` | Existing filters, assignments, reassign dialog, progress and completion actions preserved |
| Availability | `/admin/availability`, `/khadim/availability` | Schedule forms and availability cards share the mobile theme |
| Gate | `/admin/gate`, scanner dialog | Scanner, manual token entry and real validation results retained; scrollable instructions/error state |
| Account and navigation | Header profile/pass, drawer, bottom navigation | Existing account details and sign-out; full web branding; natural-height bilingual header |
| Errors and access | `/access-denied`, unknown route | Styled, translated messages and return-home action |

The audited codebase already used booking/assignment cards rather than wide data tables. Khadim account rows were converted into cards so all fields and actions remain visible at narrow widths.

## State, language and responsive behaviour

- Shared mobile theme is scoped below 768 logical pixels. Desktop layouts and segmented controls remain available.
- Header and bottom navigation sit outside page scrolling. While the keyboard is open, the header compacts and bottom navigation hides to keep the form usable.
- English UI contains no Malayalam subtitles. The language toggle deliberately names the alternative language. Original visitor names, identifiers and contact data are preserved.
- Malayalam uses Noto Sans Malayalam, wrapping field labels and comfortable line height. Existing validation errors retranslate when language changes.
- Date, slot, visitor count and period selection survive route navigation. Visitor name/address/phone remain in memory between booking steps and clear on account change or successful confirmation.
- These UI drafts do not create reservations. The existing server hold, request ID, confirmation, availability and permission checks remain authoritative. No backend, Firebase rules or booking API implementation was changed.

## Screenshots

These are actual Flutter widget renders using bundled fonts and isolated test repositories. The visible **DEMO · Test data only** strip identifies fixtures. Pass QR codes in these screenshots are not production passes. English captures are 375 logical pixels wide; Malayalam captures are 430.

| English | Malayalam / additional states |
| --- | --- |
| [Home](mobile-sanctuary/home-en.png) | [Confirmation](mobile-sanctuary/confirmation-ml.png) |
| [Visitor login](mobile-sanctuary/login-en.png) | [Date-specific settings](mobile-sanctuary/settings-ml.png) |
| [OTP verification](mobile-sanctuary/otp-en.png) | [Khadim visits](mobile-sanctuary/khadim-ml.png) |
| [Date selection](mobile-sanctuary/booking-en.png) | [Notifications](mobile-sanctuary/notifications-ml.png) |
| [Time slots](mobile-sanctuary/slots-en.png) | [Cancellation dialog](mobile-sanctuary/cancellation-en.png) |
| [Visitor details](mobile-sanctuary/visitor-details-en.png) | [Digital pass and actions](mobile-sanctuary/pass-qr-en.png) |
| [Admin dashboard](mobile-sanctuary/admin-en.png) | [Contact form](mobile-sanctuary/contact-en.png) |

All 25 reachable routes are rendered and scrolled in `test/mobile_route_audit_test.dart` at 320/375 English, 430 Malayalam and 320 Malayalam with 200% text. Existing tests retain tablet/desktop coverage through 1920 pixels. Representative screenshots were visually checked against the implemented mobile home for colours, typography, spacing, cards, navigation and controls.

## Validation

- `flutter analyze --no-pub`: clean.
- `flutter test --no-pub`: 215 passing tests, including 108 new route/interaction checks.
- Screenshot audit: 108 passing checks with `--dart-define=CAPTURE_QA=true`.
- Release web build with `config/development.json`: passes, including the Wasm dry run.
- Existing booking, OTP, permission, duplicate submission, capacity refresh, QR verification and PDF/export tests remain in the suite.
- New interaction coverage checks state retention, English gallery text, translated validation, and a 320 × 640 viewport with 200% text and a 280px keyboard inset.

To reproduce the screenshot audit:

```sh
CI=true flutter test --no-pub test/mobile_route_audit_test.dart --dart-define=CAPTURE_QA=true
```

Generated captures are in `build/qa`; selected review captures are committed alongside this document. CI also retains the complete responsive screenshot set as an artifact.

## Boundaries and remaining device checks

- This repository builds the Flutter web/mobile responsive app. Physical-device camera permissions, actual SMS delivery, live contact submission and OS sharing/download behaviour require a staging/device check. Automated tests use fakes and do not create live bookings or send messages.
- The existing account flow exposes account information and sign-out; there is no separate profile editor. Change date/time remains the existing pre-confirmation flow. This change adds neither a post-confirmation rescheduling API nor Wallet actions.
- Full-length YouTube links are unchanged. Web embeds retain their current player; the existing non-web adapter uses the direct YouTube fallback. Remote thumbnail loading is blocked in widget tests, where the honest fallback appears.
- The existing PDF test emits a Courier Unicode warning; the PDF export test still passes. This redesign does not change the PDF-generation backend or template.
