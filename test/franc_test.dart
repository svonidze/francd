import 'package:franc/franc.dart';
import 'package:test/test.dart';

const shortInputs = {
  "Кот стоит на задних лапах": "mkd",
  "Слава слава слава": "bos",
};

const longInputs = {
  "Я пришёл к тебе с приветом,"
      "Рассказать, что солнце встало,"
      "Что оно горячим светом"
      "По листам затрепетало;"
      "Рассказать, что лес проснулся,"
      "Весь проснулся, веткой каждой,"
      "Каждой птицей встрепенулся"
      "И весенней полон жаждой;"
      "Рассказать, что с той же страстью,"
      "Как вчера, пришёл я снова,"
      "Что душа всё так же счастью"
      "И тебе служить готова;"
      "Рассказать, что отовсюду"
      "На меня весельем веет,"
      "Что не знаю сам, что буду"
      "Петь — но только песня зреет. ": "rus"
};

void main() {
  final franc = Franc();

  run(Map<String, String> inputs) {
    for (final input in inputs.keys) {
      test(_short(input), () async {
        final expectedLangCode3 = inputs[input];
        final detectionResults = await franc.detectLanguages(input);
        print("$detectionResults.\n$expectedLangCode3:  $input");
        expect(detectionResults[expectedLangCode3], 1.0);
      });
    }
  }

  group('long text will be detected correctly', () => run(longInputs));
  group('short text may be detected incorrectly', () => run(shortInputs));
}

String _short(String input, {int maxLength = 30}) {
  if (input.length > maxLength) return input.substring(0, maxLength - 1);
  return input;
}
