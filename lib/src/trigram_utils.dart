/// Get dictionary with trigrams as its keys,
/// and their occurrence count as values.
Map<String, int> getCleanTrigramsAsDictionary(String text) {
  final List<String> trigrams = getCleanTrigrams(text);
  int index = trigrams.length;
  final Map<String, int> dictionary = {};
  String trigram;
  while (index-- > 0) {
    trigram = trigrams[index];
    dictionary.update(trigram, (occurrence) => occurrence++, ifAbsent: () => 1);
    // if (dictionary.containsKey(trigram)) {
    //   dictionary[trigram]++;
    // } else {
    //   dictionary[trigram] = 1;
    // }
  }
  return dictionary;
}

/// Get clean, padded, trigrams.
List<String> getCleanTrigrams(String text) {
  return _makeTrigrams(' ' + _clean(text) + ' ');
}

//Get list of trigrams for given string
List<String> _makeTrigrams(String value) {
  final trigrams = <String>[];
  int index;
  if (value == null || value.isEmpty) return trigrams;
  index = value.length - 3 + 1;
  if (index < 1) return trigrams;
  while (index-- > 0) {
    trigrams.add(value.substring(index, index + 3));
  }
  return trigrams;
}

// Removed general non-important (as in, for language detection) punctuation
// marks, symbols, and numbers.
String _clean(String value) {
  if (value == null || value.isEmpty) {
    return '';
  }
  return value
      .replaceAll(RegExp(r"[\u0021-\u0040]+"), ' ')
      .replaceAll(RegExp(r"\s+"), ' ')
      .trim()
      .toLowerCase();
}
