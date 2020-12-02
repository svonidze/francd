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

  /** The maximum distance to add when a given trigram does
   * not exist in a trigram dictionary. */
  int maxDifference;

  Map<String, Map<String, Map<String, int>>> _languageModelData = {};

  Franc({this.maxLength = 2048, this.minLength = 10, this.maxDifference = 300})
      : assert(maxLength != null),
        assert(minLength != null),
        assert(maxDifference != null) {
    //Construct trigram dictionaries
    for (String script in trigramsByLanguage.keys) {
      Map<String, String> languages = trigramsByLanguage[script];
      _languageModelData[script] = {};
      for (String languageCode in languages.keys) {
        List<String> model = languages[languageCode].split('|');
        int weight = model.length;
        final Map<String, int> trigrams = {};
        while (weight-- != 0) {
          trigrams[model[weight]] = weight;
        }
        _languageModelData[script][languageCode] = trigrams;
      }
    }
  }

  /** Get a list of probable languages the given value is
   * written in.
   *
   * @param {string} value - The value to test.
   * @param {Object} options - Configuration.
   * @return {Array.<Array.<string, number>>} An array
   *   containing language--distance tuples.
   */
  Future<Map<String, double>> detectLanguages(String text) async {
    if (text.isEmpty || text.length < minLength) {
      return {"und": 1.0}; //und()
    }
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
      print("Input text was truncated to maxLength");
    }

    //Get the script which characters occur the most in `value`.
    final List<Object> script = await _getTopScript(text, regExpByScript);

    // One languages exists for the most-used script.
    if (!(_languageModelData.containsKey(script[0]))) {
      //If no matches occurred, such as a digit only string,
      //or because the language is ignored, exit with `und`.
      if (script[1] == 0) return {}; //und()
      return {script[0]: 1.0};
    }

    // Get all distances for a given script, and normalize the distance values.
    return _normalize(
      text,
      _getDistances(
        trigram_utils.getCleanTrigramsAsDictionary(text),
        _languageModelData[script[0]],
      ),
    );
  }

  /** From `scripts`, get the most occurring expression for
   * `value`.
   *
   * @param {string} value - Value to check.
   * @param {Object.<RegExp>} scripts - Top-Scripts.
   * @return {Array} Top script and its
   *   occurrence percentage.
   */
  List<Object> _getTopScript(String value, Map<String, String> scripts) {
    double topCount = -1;
    String topScript;
    for (String script in scripts.keys) {
      final double count = _getOccurrence(value, scripts[script]);
      if (count > topCount) {
        topCount = count;
        topScript = script;
      }
    }
    return [topScript, topCount];
  }

  /** Get the occurrence ratio of `expression` for `value`.
   *
   * @param {string} value - Value to check.
   * @param {RegExp} expression - Code-point expression.
   * @return {number} Float between 0 and 1.
   */
  double _getOccurrence(String value, String expression) {
    final int matchCount = RegExp("$expression").allMatches(value).length;
    return (matchCount != null || matchCount != 0 ? matchCount : 0) /
        value.length;
  }

  /** Normalize the difference for each tuple in
   * `distances`.
   *
   * @param {string} value - Value to normalize.
   * @param {Array.<Array.<string, number>>} distances
   *   - List of distances.
   * @return {Array.<Array.<string, number>>} - Normalized
   *   distances.
   */
  Map<String, double> _normalize(String value, Map<String, int> distances) {
    final Map<String, double> normalizedDistances = {};
    final int min = distances.values.toList()[0];
    final int max = value.length * maxDifference - min;
    for (MapEntry<String, int> distance in distances.entries) {
      normalizedDistances.putIfAbsent(
          distance.key, () => 1 - (distance.value - min) / max);
    }
    return normalizedDistances;
  }

  /** Get the distance between an array of trigram--count
   * tuples, and multiple trigram dictionaries.
   *
   * @param {Array.<Array.<string, number>>} trigrams - An
   *   array containing trigram--count tuples.
   * @param {Object.<Object>} languages - multiple
   *   trigrams to test against.
   * @param {Array.<string>} only - Allowed languages; if
   *   non-empty, only included languages are kept.
   * @param {Array.<string>} ignore - Disallowed languages;
   *   included languages are ignored.
   * @return {Array.<Array.<string, number>>} An array
   *   containing language--distance tuples.
   */
  Map<String, int> _getDistances(
      Map<String, int> trigrams, Map<String, Map<String, int>> languages) {
    final distances = SplayTreeMap<int, String>();
    for (String language in languages.keys) {
      distances.putIfAbsent(
          _getDistance(trigrams, languages[language]), () => language);
    }
    return distances.map((key, value) => MapEntry(value, key));
  }

  /** Get the distance between an array of trigram--count
   * tuples, and a language dictionary.
   *
   * @param {Array.<Array.<string, number>>} trigrams - An
   *   array containing trigram--count tuples.
   * @param {Object.<number>} model - Object
   *   containing weighted trigrams.
   * @return {number} - The distance between the two.
   */
  int _getDistance(Map<String, int> trigrams, Map<String, int> model) {
    int distance = 0;
    int difference;
    trigrams.forEach((trigram, weight) {
      if (model.containsKey(trigram)) {
        difference = weight - model[trigram] - 1;
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

//
// /* Load `trigram-utils`. */
// var utilities = require('trigram-utils')
//
// /* Load `expressions` (regular expressions matching
//  * scripts). */
// var expressions = require('./expressions.js')
//
// /* Load `data` (trigram information per language,
//  * per script). */
// var data = require('./data.json')
//
// /* Expose `detectAll` on `detect`. */
// detect.all = detectAll
//
// /* Expose `detect`. */
// module.exports = detect
//
// /* Maximum sample length. */
// var MAX_LENGTH = 2048
//
// /* Minimum sample length. */
// var MIN_LENGTH = 10
//
// /* The maximum distance to add when a given trigram does
//  * not exist in a trigram dictionary. */
// var MAX_DIFFERENCE = 300
//
// /* Construct trigram dictionaries. */
// ;(function () {
//   var languages
//   var name
//   var trigrams
//   var model
//   var script
//   var weight
//
//   for (script in data) {
//     languages = data[script]
//
//     for (name in languages) {
//       model = languages[name].split('|')
//
//       weight = model.length
//
//       trigrams = {}
//
//       while (weight--) {
//         trigrams[model[weight]] = weight
//       }
//
//       languages[name] = trigrams
//     }
//   }
// })()
//
// /**
//  * Get the most probable language for the given value.
//  *
//  * @param {string} value - The value to test.
//  * @param {Object} options - Configuration.
//  * @return {string} The most probable language.
//  */
// function detect(value, options) {
//   return detectAll(value, options)[0][0]
// }
//
// /**
//  * Get a list of probable languages the given value is
//  * written in.
//  *
//  * @param {string} value - The value to test.
//  * @param {Object} options - Configuration.
//  * @return {Array.<Array.<string, number>>} An array
//  *   containing language--distance tuples.
//  */
// function detectAll(value, options) {
//   var settings = options || {}
//   var minLength = MIN_LENGTH
//   var only = [].concat(settings.whitelist || [], settings.only || [])
//   var ignore = [].concat(settings.blacklist || [], settings.ignore || [])
//   var script
//
//   if (settings.minLength !== null && settings.minLength !== undefined) {
//     minLength = settings.minLength
//   }
//
//   if (!value || value.length < minLength) {
//     return und()
//   }
//
//   value = value.slice(0, MAX_LENGTH)
//
//   /* Get the script which characters occur the most
//    * in `value`. */
//   script = getTopScript(value, expressions)
//
//   /* One languages exists for the most-used script. */
//   if (!(script[0] in data)) {
//     /* If no matches occured, such as a digit only string,
//      * or because the language is ignored, exit with `und`. */
//     if (script[1] === 0 || !allow(script[0], only, ignore)) {
//   return und()
//   }
//
//   return singleLanguageTuples(script[0])
//   }
//
//   /* Get all distances for a given script, and
//    * normalize the distance values. */
//   return normalize(
//   value,
//   getDistances(utilities.asTuples(value), data[script[0]], only, ignore)
//   )
// }
//
// /**
//  * Normalize the difference for each tuple in
//  * `distances`.
//  *
//  * @param {string} value - Value to normalize.
//  * @param {Array.<Array.<string, number>>} distances
//  *   - List of distances.
//  * @return {Array.<Array.<string, number>>} - Normalized
//  *   distances.
//  */
// function normalize(value, distances) {
//   var min = distances[0][1]
//   var max = value.length * MAX_DIFFERENCE - min
//   var index = -1
//   var length = distances.length
//
//   while (++index < length) {
//     distances[index][1] = 1 - (distances[index][1] - min) / max || 0
//   }
//
//   return distances
// }
//
// /**
//  * From `scripts`, get the most occurring expression for
//  * `value`.
//  *
//  * @param {string} value - Value to check.
//  * @param {Object.<RegExp>} scripts - Top-Scripts.
//  * @return {Array} Top script and its
//  *   occurrence percentage.
//  */
// function getTopScript(value, scripts) {
//   var topCount = -1
//   var topScript
//   var script
//   var count
//
//   for (script in scripts) {
//     count = getOccurrence(value, scripts[script])
//
//     if (count > topCount) {
//       topCount = count
//       topScript = script
//     }
//   }
//
//   return [topScript, topCount]
// }
//
// /**
//  * Get the occurrence ratio of `expression` for `value`.
//  *
//  * @param {string} value - Value to check.
//  * @param {RegExp} expression - Code-point expression.
//  * @return {number} Float between 0 and 1.
//  */
// function getOccurrence(value, expression) {
//   var count = value.match(expression)
//
//   return (count ? count.length : 0) / value.length || 0
// }
//
// /**
//  * Get the distance between an array of trigram--count
//  * tuples, and multiple trigram dictionaries.
//  *
//  * @param {Array.<Array.<string, number>>} trigrams - An
//  *   array containing trigram--count tuples.
//  * @param {Object.<Object>} languages - multiple
//  *   trigrams to test against.
//  * @param {Array.<string>} only - Allowed languages; if
//  *   non-empty, only included languages are kept.
//  * @param {Array.<string>} ignore - Disallowed languages;
//  *   included languages are ignored.
//  * @return {Array.<Array.<string, number>>} An array
//  *   containing language--distance tuples.
//  */
// function getDistances(trigrams, languages, only, ignore) {
//   var distances = []
//   var language
//
//   languages = filterLanguages(languages, only, ignore)
//
//   for (language in languages) {
//     distances.push([language, getDistance(trigrams, languages[language])])
//   }
//
//   return distances.length === 0 ? und() : distances.sort(sort)
// }
//
// /**
//  * Get the distance between an array of trigram--count
//  * tuples, and a language dictionary.
//  *
//  * @param {Array.<Array.<string, number>>} trigrams - An
//  *   array containing trigram--count tuples.
//  * @param {Object.<number>} model - Object
//  *   containing weighted trigrams.
//  * @return {number} - The distance between the two.
//  */
// function getDistance(trigrams, model) {
//   var distance = 0
//   var index = -1
//   var length = trigrams.length
//   var trigram
//   var difference
//
//   while (++index < length) {
//     trigram = trigrams[index]
//
//     if (trigram[0] in model) {
//       difference = trigram[1] - model[trigram[0]] - 1
//
//       if (difference < 0) {
//         difference = -difference
//       }
//     } else {
//       difference = MAX_DIFFERENCE
//     }
//
//     distance += difference
//   }
//
//   return distance
// }
//
// /**
//  * Filter `languages` by removing languages in
//  * `ignore`, or including languages in `only`.
//  *
//  * @param {Object.<Object>} languages - Languages
//  *   to filter
//  * @param {Array.<string>} only - Allowed languages; if
//  *   non-empty, only included languages are kept.
//  * @param {Array.<string>} ignore - Disallowed languages;
//  *   included languages are ignored.
//  * @return {Object.<Object>} - Filtered array of
//  *   languages.
//  */
// function filterLanguages(languages, only, ignore) {
//   var filteredLanguages
//   var language
//
//   if (only.length === 0 && ignore.length === 0) {
//     return languages
//   }
//
//   filteredLanguages = {}
//
//   for (language in languages) {
//     if (allow(language, only, ignore)) {
//       filteredLanguages[language] = languages[language]
//     }
//   }
//
//   return filteredLanguages
// }
//
// /**
//  * Check if `language` can match according to settings.
//  *
//  * @param {string} language - Languages
//  *   to filter
//  * @param {Array.<string>} only - Allowed languages; if
//  *   non-empty, only included languages are kept.
//  * @param {Array.<string>} ignore - Disallowed languages;
//  *   included languages are ignored.
//  * @return {boolean} - Whether `language` can match
//  */
// function allow(language, only, ignore) {
//   if (only.length === 0 && ignore.length === 0) {
//     return true
//   }
//
//   return (
//       (only.length === 0 || only.indexOf(language) !== -1) &&
//       ignore.indexOf(language) === -1
//   )
// }
//
