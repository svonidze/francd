import 'dart:async';
import 'dart:collection';

import 'package:franc/src/expressions.dart';
import 'package:franc/src/trigram_utils.dart' as trigram_utils;
import 'package:franc/src/trigrams.dart';

/// Detects language of text

class Franc {
  ///Maximum sample length.
  int maxLength;

  ///Minimum sample length.
  int minLength;

  /// The maximum distance to add when a given trigram does
  /// not exist in a trigram dictionary.
  int maxDifference;

  final Map<String, Map<String, Map<String, int>>> _languageModelData = {};

  Franc({
    this.maxLength = 2048,
    this.minLength = 10,
    this.maxDifference = 300,
  }) {
    // Construct trigram dictionaries
    trigramsByLanguage.forEach((script, languages) {
      _languageModelData[script] = {};
      languages.forEach((languageCode, trigramList) {
        final List<String> model = trigramList.split('|');
        int weight = model.length;
        final Map<String, int> trigrams = {};
        while (weight-- != 0) {
          trigrams[model[weight]] = weight;
        }
        _languageModelData[script]![languageCode] = trigrams;
      });
    });
  }

  /// Get a list of probable languages the given [text] is written in.
  /// Return an array containing language--distance map.

  Future<Map<String, double>> detectLanguages(String text) async {
    if (text.isEmpty || text.length < minLength) {
      return {"und": 1.0}; //und()
    }
    String inputText = text;
    if (text.length > maxLength) {
      inputText = text.substring(0, maxLength);
    }

    // Get the script which characters occur the most in `value`.
    final List<Object> script = _getTopScript(inputText, regExpByScript);

    // One languages exists for the most-used script.
    if (!_languageModelData.containsKey(script[0])) {
      //If no matches occurred, such as a digit only string,
      //or because the language is ignored, exit with `und`.
      if (script[1] == 0) return {"und": 1.0}; //und()
      return {script[0] as String: 1.0};
    }

    // Get all distances for a given script, and normalize the distance values.
    return _normalize(
      inputText,
      _getDistances(
        trigram_utils.getCleanTrigramsAsDictionary(inputText),
        _languageModelData[script[0]]!,
      ),
    );
  }

  /// From [scripts], get the most occurring expression for [value].
  /// Returns top script and its occurrence percentage.

  List<Object> _getTopScript(String value, Map<String, String> scripts) {
    double topCount = -1;
    String topScript = scripts.keys.first;
    scripts.forEach((script, regExpByScript) {
      final double count = _getOccurrence(value, regExpByScript);
      if (count > topCount) {
        topCount = count;
        topScript = script;
      }
    });
    return [topScript, topCount];
  }

  /// Get the occurrence ratio of [expression] for [value].
  /// Returns double between 0 and 1.

  double _getOccurrence(String value, String expression) {
    final int matchCount = RegExp(expression).allMatches(value).length;
    return (matchCount != 0 ? matchCount : 0) / value.length;
  }

  /// Normalize the difference for each tuple in [distances].
  /// Returns normalized distances.

  Map<String, double> _normalize(String value, Map<String, int> distances) {
    final normalizedDistances = <String, double>{};
    final int min = distances.values.toList()[0];
    final int max = value.length * maxDifference - min;
    for (final MapEntry<String, int> distance in distances.entries) {
      normalizedDistances.putIfAbsent(
          distance.key, () => 1 - (distance.value - min) / max);
    }
    return normalizedDistances;
  }

  /// Get the distance between an array of [trigrams] and [languages].
  /// Returns an array containing language--distance pairs.

  Map<String, int> _getDistances(
      Map<String, int> trigrams, Map<String, Map<String, int>> languages) {
    final distances = SplayTreeMap<int, String>();
    languages.forEach((language, model) {
      distances.putIfAbsent(_getDistance(trigrams, model), () => language);
    });
    return distances.map((key, value) => MapEntry(value, key));
  }

  /// Get the distance between an array of [trigrams] and a language [model].
  /// Returns single distance.

  int _getDistance(Map<String, int> trigrams, Map<String, int> model) {
    int distance = 0;
    int difference;
    trigrams.forEach((trigram, weight) {
      if (model.containsKey(trigram)) {
        difference = weight - model[trigram]! - 1;
        if (difference < 0) {
          difference = -difference;
        }
      } else {
        difference = maxDifference;
      }
      distance += difference;
    });
    return distance;
  }
}
