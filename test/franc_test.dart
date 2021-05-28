import 'package:franc/franc.dart';
import 'package:test/test.dart';

const shortInputs = {
  "Кот стоит на задних лапах": "mkd",
  "Слава слава слава": "bos",
};

const longInputs = {
  "Я пришёл к тебе с приветом,\n"
      "Рассказать, что солнце встало,\n"
      "Что оно горячим светом\n"
      "По листам затрепетало;\n"
      "Рассказать, что лес проснулся,\n"
      "Весь проснулся, веткой каждой,\n"
      "Каждой птицей встрепенулся\n"
      "И весенней полон жаждой;\n"
      "Рассказать, что с той же страстью,\n"
      "Как вчера, пришёл я снова,\n"
      "Что душа всё так же счастью\n"
      "И тебе служить готова;\n"
      "Рассказать, что отовсюду\n"
      "На меня весельем веет,\n"
      "Что не знаю сам, что буду\n"
      "Петь — но только песня зреет.": "rus"
};

void main() {
  final franc = Franc();

  void run(Map<String, String> inputs) {
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
