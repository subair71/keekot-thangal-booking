# Sanctuary Heritage redesign review

Base: `main` at `59a7ded` (includes request-abuse protection and custom-domain pass fixes).
Branch: `design/sanctuary-heritage`. Do not merge or deploy before design approval.

## Visual reference

Uses the supplied `stitch_keekkott_bungalow_visitor_portal.zip` (`screen.png`, `code.html`, `DESIGN.md`). The explicit requested ivory/cream palette takes priority over the mockup's alternate mint canvas. Playfair Display is bundled with its SIL Open Font License; existing Plus Jakarta Sans and Noto Sans Malayalam remain bundled.

The existing hero asset, approved bilingual copy, banners, videos/Shorts, guidelines, location links, contact form and Malayalam sharing remain in place. Mock religious claims, fixed opening hours, sample availability, wallet integrations and programme examples are not imported.

## Shared application styling

Sanctuary green, forest, sage, brass, ivory and cream tokens drive the global Material theme and shared cards, headings, buttons, inputs, selectors, dialogs, menus, navigation, tables, loading and empty states. Malayalam has a minimum 1.6 line height. Operational screens inherit these controls without changing their authorization or data handling. Pass QR modules remain high-contrast black on white, with a brass pass border.

## Booking integration

The home card reads `configurationProvider`, `closedDaysProvider` and `availabilityProvider(day)`. Dates are limited to the existing configured window and closed dates are disabled. It displays actual date-specific hours, duration, slot status and remaining capacity; visitors are bounded by the existing maximum. Partly occupied available slots show a limited label.

A valid selection is passed through `draftProvider.select` to the unchanged `/book/confirmation` route. Existing login redirects, OTP, server holds, phone limits, admin exceptions, staff/visitor identity handling and server-side booking checks still apply. A capacity refresh or visitor-count change invalidates an unsuitable selection. No writes occur while browsing availability.

Desktop uses a bounded sticky panel only when the panel fits the viewport and the adjacent content provides room. Taller panels and mobile layouts remain in normal flow. Slot lists scroll independently to keep the card manageable.

## Functional inventory retained

- Visitor: login/OTP, date/slot selection, visitor details, confirmation, bookings, pass, download, cancellation, WhatsApp sharing.
- Admin: login, dashboard, booking/export, slots, blocked days/slots, date hours, settings, khadim management, assignments and availability.
- Khadim: login, assignments, availability, visitor booking, QR scanner and visit verification.
- Infrastructure: routes, Firebase repositories/functions, security rules, App Check, analytics and dependency versions.

## Review limits

Automated widget coverage uses fake repositories. Live OTP delivery, production App Check, physical-camera QR scanning, WhatsApp handoff and real iOS/Android device behavior require a review deployment and authorized test accounts. Never create real visitor bookings just to validate this visual branch.

## Validation completed

- Flutter analysis: no issues.
- Flutter suite: 102 tests passed. The 29 responsive/localization tests were rerun successfully after the final large-text header refinement.
- Backend unit tests: 34 passed.
- Firestore/Auth emulator integration tests: 27 passed, including atomic phone limits/admin exceptions, date-specific hours, request limits, assignment concurrency, authorization and rules.
- Release web build: passed with development configuration; no production deployment.
- Render inspection: desktop and mobile home, enlarged Malayalam header, admin assignments, khadim dashboard and visitor pass. Automated renders cover additional login, availability, confirmation and export screens.

The existing CI workflow also runs for this branch, using its Java 21 emulator environment. Deployment retains its `main`-only guard.
