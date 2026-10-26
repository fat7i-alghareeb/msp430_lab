/// Folding Arabic down to the letters a comparison should actually see.
///
/// «مدرسة» typed with diacritics, «المدرسة» with the article, «مدرسه» with a
/// plain haa are one word to a reader and three to `==`. Use this wherever
/// Arabic text is compared or matched locally (a filter, recent searches,
/// the mock layer) — one folding rule, applied everywhere the same way.
///
/// It is deliberately **not** a search engine: no stemming, no edit
/// distance, no synonyms. Those belong to the server.
class ArabicText {
  ArabicText._();

  static final RegExp _marks = RegExp('[ً-ْٰـ]');
  static final RegExp _alef = RegExp('[آأإٱ]');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Strips diacritics and kashida, folds the alef, taa marbuta, alef
  /// maqsura and hamza carriers, lowercases, and collapses whitespace.
  ///
  /// The definite article is dropped only when something is left of the word
  /// after it: «ال» on its own is not an article, it is the whole query.
  static String normalize(String? raw) {
    if (raw == null) return '';
    final folded = raw
        .replaceAll(_marks, '')
        .replaceAll(_alef, 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .toLowerCase()
        .trim()
        .replaceAll(_whitespace, ' ');
    return folded.startsWith('ال') && folded.length > 3
        ? folded.substring(2)
        : folded;
  }
}
