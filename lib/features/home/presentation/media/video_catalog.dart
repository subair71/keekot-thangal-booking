// Curated from @keekkott_bungalow_online on 2026-10-10.
// Add verified channel video IDs here to refresh the gallery.
class MaqamVideo {
  const MaqamVideo(this.id, this.title, this.isShort, {this.englishTitle});
  final String id;
  final String title;
  final bool isShort;
  final String? englishTitle;
  Uri get watchUri => Uri.https('www.youtube.com', '/watch', {'v': id});
  String get thumbnailUrl => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
}

const maqamVideos = <MaqamVideo>[
  MaqamVideo(
    "JYaokXAxFYs",
    "ശൈഖ് അബ്ദുൽ ഖാദർ ജീലാനി (റ) ആണ്ട് നേർച്ച, റബീഉൽ ആഖിർ 11",
    true,
  ),
  MaqamVideo("SSmcKYSFLzI", "യാ ഖ്വാജാ (റ) ♥️👑💚", true),
  MaqamVideo(
    "mKi3AVgAyoM",
    "​എന്നാലുമെന്റെ നൂറൂ് കരുണതൻ അരുവിയാ, അണയാത്ത പ്രകാശം...💚",
    true,
  ),
  MaqamVideo(
    "jwoZ07ckJpE",
    "രിഫാഈ റാത്തീബിലേക്കും ഏവർക്കും ഹൃദ്യമായ സ്വാഗതം!സെപ്റ്റംബർ 07 (തിങ്കൾ) - 7:30 PM▪️ രിഫാഈ റാത്തീബ്",
    true,
  ),
  MaqamVideo(
    "zISQK7HaCPQ",
    "ഖൽബിലുണ്ട് എന്റെ നബി 😘ഹൃദയം നിറഞ്ഞ നബിദിനാശംസകൾ💚❤️!",
    true,
  ),
  MaqamVideo(
    "Bs14hVESlTM",
    "കീക്കോട്ട് ബംഗ്ലാവ്, 2026 ഓഗസ്റ്റ് 08, 09 തീയതികളിൽ നടന്ന 13-ാമത് ഉറൂസിന്റെ സമാപന വേദിയിൽ നിന്ന്",
    true,
  ),
  MaqamVideo(
    "id1ttz7P9K8",
    "Day 2, keekot _ കീക്കോട്ട്",
    false,
    englishTitle: "Day 2 · Keekkott",
  ),
  MaqamVideo(
    "aI3QiR2ErVs",
    "കീക്കോട്ടിന്റെ  സ്നേഹാദരവ്",
    false,
    englishTitle: "A tribute from Keekkott",
  ),
  MaqamVideo(
    "xrsTvpbTsO0",
    "കീക്കോട്ട് സയ്യിദ് ആറ്റക്കോയ തങ്ങൾ മഖാം |കീക്കോട്ട് ബംഗ്ലാവ്",
    false,
    englishTitle: "Keekkott Attakoya Thangal Maqam",
  ),
  MaqamVideo(
    "mQ9lQkqI2MA",
    "CHAL CHAL KEEKKOTTE | Keekkott Sayyid Attakoya Thangal Maqam | azhar rabbani kalloor",
    false,
    englishTitle: "Chal Chal Keekkotte · Azhar Rabbani Kalloor",
  ),
  MaqamVideo(
    "MjukZONIVlo",
    "Ahlunnabiyore veed | Keekkott Sayyid Attakoya Thangal Maqam | azhar rabbani kalloor",
    false,
    englishTitle: "Ahlunnabiyore Veed · Azhar Rabbani Kalloor",
  ),
  MaqamVideo(
    "-RQeyOf4Nss",
    "Keekkott Bungalow  | inauguration | day 2. ആറ്റക്കോയ തങ്ങൾ മഖാം ഉദ്ഘാടനം ​",
    false,
    englishTitle: "Keekkott Bungalow inauguration · Day 2",
  ),
];
