# Stitch mobile sanctuary implementation

Based on main `9c82202` (retains token numbers on passes and the existing Firebase booking flow). Mobile composition is enabled below 768 logical pixels; the existing tablet and desktop page is retained.

## Reference and changes

The supplied `screen.png`, `code.html` and `DESIGN.md` define the mobile layout. All ten sections are represented: compact fixed header/status strip, heritage hero, live booking, media archive, three steps, programmes, etiquette grid, FAQ, location/contact, and five fixed navigation destinations. Seven images were downloaded from the exact image URLs in the supplied HTML and bundled under `assets/brand/stitch/`.

Mobile navigation maps Remembrance, Etiquette and Heritage to anchored sections; Book Slot opens the existing booking route. My Pass uses authenticated pass retrieval. Profile opens mobile login for visitors who are signed out, or the existing account drawer for signed-in visitors. Notifications, staff tools, sign-out, contact and the original video gallery remain available.

The mobile selector reads configuration, closed days and polled availability. It retains selection across navigation, clamps the visitor count to backend limits, displays disabled closed/full/past slots, and revalidates the selection whenever capacity changes. Proceed writes the existing draft and enters existing login/confirmation, server-side holds and atomic booking confirmation. No booking writes happen during browsing. Confirmation now also guards against a repeated submit while busy.

## Language display

English mode shows English interface text without Malayalam subtitles or mixed-language labels. The language switch remains discoverable in both languages. Selecting Malayalam retains the translated interface and Malayalam captions.

## Intentional data-dependent differences

- Configured dates, slot durations, capacity and visiting hours replace the mock October 2024 values. Status uses server time and schedule data; it says “Within visiting hours” rather than claiming to observe a physical gate.
- The mobile archive uses the existing catalogue's six long-form YouTube recordings (Shorts excluded). Video IDs, channel ownership and thumbnails were checked against YouTube oEmbed on 2026-10-28. The featured player and selection cards share the same recording; the direct Watch on YouTube action targets that recording's canonical watch URL. Original titles are retained for Malayalam mode with concise English display titles in English mode. Mock walkthrough titles, durations and chapter timestamps have been removed because they do not describe these recordings. The original full gallery remains accessible.
- No Wallet integration or atomic reschedule API exists. Pass PDF download, sharing, retrieval and cancellation remain functional. Copy explains cancellation followed by a new booking and does not advertise unsupported Wallet actions.
- The location button prefers a valid configured HTTP(S) map URL, falling back to the existing app's map destination. The reference's map image is an illustration, not a live geocoded map.
- Programme and assistance text follows the user-supplied design and is isolated in the editorial content provider. It does not alter administrative booking schedules or infer Gregorian dates from Hijri dates.

## Validation

Validated with Flutter 3.47.8 / Dart 3.13.7: static analysis clean, all 105 Flutter tests passed, Dart formatting clean, and release web build with development configuration passed. Tests use fake repositories and never send real OTPs or create production bookings. Test captures cover 320, 375 and 430px mobile layouts, section details, larger bilingual text and the existing booking/pass screens. New behavioural tests cover stale capacity, selection persistence, login redirect, anchor navigation and single-open FAQ behaviour.

YouTube follow-up validation: all 107 Flutter tests passed, including long-form filtering, selected-video playback/link routing, and external-launch failure feedback. Static analysis and formatting are clean; the development-configured release web build passed. YouTube oEmbed confirmed all six catalogue watch links and channel ownership.
