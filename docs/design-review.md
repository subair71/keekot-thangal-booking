# Design implementation decisions

All five supplied screen.png files, all code.html references, and devotional_sanctuary/DESIGN.md were inspected before implementation.

The narrative color section takes precedence over the generated Material palette: emerald #064E3B, ivory #FDFBF7, cream #F9F6F0, outline #E7E2D9, gold #D97706. Newsreader headings and Plus Jakarta Sans interface type are bundled locally.

Desktop uses a centered 1280 px container, full header navigation, a split hero and live availability card, and a slot grid with a booking summary column. Mobile uses stacked surfaces and four-destination bottom navigation. The pass keeps the reference's receipt style and secure QR.

Reference HTML is design input only, not production code. Static example bookings, availability counts, phone numbers, management attribution, gate names, distances, facilities, and map coordinates in the references are not treated as verified operational facts. Production details belong in settings.
