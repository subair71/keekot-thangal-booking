# Keekkott Maqam redesign

Branch: work/booking-updates-2026-10-10

Emerald, ivory and warm gold visitor experience with a full-width illustrated hero, dynamic visiting details, a Maqam introduction, live availability, a three-step visit guide, etiquette, directions, family preparation, expandable FAQs and booking calls to action. The shared theme carries into booking, passes and administration. Booking and Firebase domain logic are unchanged.

## Editorial approach

Location and naming follow the existing project. Copy focuses on preparing for ziyarat, remembrance, dua and respectful conduct. No unsupported founder dates, lineage, historical chronology, event schedules, medical claims or visitor counts are included. Hours, duration, arrival guidance, contact details, directions and availability continue to come from configuration and repositories.

## Hero asset

`assets/brand/maqam-hero.png` was created using the built-in image generation tool. It is a concept illustration, explicitly labelled on the page, not a photograph or verified architectural rendering of Keekkott Maqam. Replace with an authorized site photograph when available.

Prompt: Wide website hero for a Kerala maqam visitor booking site. A painterly architectural illustration of an imagined peaceful Kerala Muslim shrine courtyard, ivory plaster arched verandah, traditional tiled roof, small muted green dome, coconut palms, warm early morning golden light, soft atmospheric grain. Architecture concentrated on the right with deep emerald foliage and uncluttered shadow on the left for white copy. Warm ivory, forest green and subdued gold. No people, text, calligraphy, lettering or watermark. Concept illustration, not a factual depiction of a real shrine.

## Verification

Existing responsive widget coverage updated for the new heading, FAQ expansion and booking call to action at seven widths. Dart formatting and Git whitespace checks passed. Flutter analysis, widget tests, visual captures and the release build remain unverified: automatic approval review blocked Flutter bootstrap after an attempted cloud metadata endpoint request. The pending setup was stopped. Run those checks in the established development or CI environment before merging. Automatic review also blocked pushing to the public repository pending explicit user authorization; the change is committed locally. Production booking, OTP and Firebase behavior are outside the visual test scope.
