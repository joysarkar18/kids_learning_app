import 'dart:math';
import 'models/gonit_problem_model.dart';

class GanitDummyData {
  static final _random = Random();

  static List<GanitProblemModel> getProblems({
    required int difficulty,
    String? type,
    int count = 20,
  }) {
    final allProblems = <GanitProblemModel>[];

    if (type == null || type == 'arithmetic') {
      allProblems.addAll(_arithmeticProblems(difficulty));
    }
    if (type == null || type == 'counting') {
      allProblems.addAll(_countingProblems(difficulty));
    }
    if (type == null || type == 'comparison') {
      allProblems.addAll(_comparisonProblems(difficulty));
    }
    if (type == null || type == 'missing_number') {
      allProblems.addAll(_missingNumberProblems(difficulty));
    }
    if (type == null || type == 'word_problem') {
      allProblems.addAll(_wordProblems(difficulty));
    }
    if (type == null || type == 'matching') {
      allProblems.addAll(_matchingProblems(difficulty));
    }
    if (type == null || type == 'ordering') {
      allProblems.addAll(_orderingProblems(difficulty));
    }

    allProblems.shuffle(_random);
    return allProblems.take(count).toList();
  }

  // ==================== ARITHMETIC ====================
  static List<GanitProblemModel> _arithmeticProblems(int difficulty) {
    final problems = <GanitProblemModel>[];
    final int maxNum;
    final List<String> operators;

    switch (difficulty) {
      case 1:
        maxNum = 5;
        operators = ['+'];
      case 2:
        maxNum = 9;
        operators = ['+', '-'];
      case 3:
        maxNum = 15;
        operators = ['+', '-', 'x'];
      case 4:
        maxNum = 20;
        operators = ['+', '-', 'x'];
      default:
        maxNum = 50;
        operators = ['+', '-', 'x', '/'];
    }

    for (int i = 0; i < 8; i++) {
      final op = operators[_random.nextInt(operators.length)];
      int a, b, answer;

      switch (op) {
        case '+':
          a = _random.nextInt(maxNum) + 1;
          b = _random.nextInt(maxNum) + 1;
          answer = a + b;
        case '-':
          a = _random.nextInt(maxNum) + 2;
          b = _random.nextInt(a - 1) + 1;
          answer = a - b;
        case 'x':
          a = _random.nextInt(difficulty >= 4 ? 12 : 5) + 1;
          b = _random.nextInt(difficulty >= 4 ? 10 : 5) + 1;
          answer = a * b;
        case '/':
          b = _random.nextInt(9) + 2;
          answer = _random.nextInt(10) + 1;
          a = b * answer;
        default:
          a = 1;
          b = 1;
          answer = 2;
      }

      final displayOp = op == 'x'
          ? '×'
          : op == '/'
          ? '÷'
          : op;

      problems.add(
        _makeProblem(
          id: 'arith_${difficulty}_$i',
          type: 'arithmetic',
          difficulty: difficulty,
          questionText: '$a $displayOp $b = ?',
          answer: answer,
        ),
      );
    }

    return problems;
  }

  // ==================== COUNTING ====================
  static List<GanitProblemModel> _countingProblems(int difficulty) {
    final problems = <GanitProblemModel>[];
    final objects = ['আপেল', 'কলা', 'তারা', 'ফুল', 'পাখি', 'মাছ', 'বল', 'গাছ'];
    final int maxCount;

    switch (difficulty) {
      case 1:
        maxCount = 5;
      case 2:
        maxCount = 10;
      case 3:
        maxCount = 15;
      case 4:
        maxCount = 20;
      default:
        maxCount = 30;
    }

    for (int i = 0; i < 4; i++) {
      final obj = objects[_random.nextInt(objects.length)];
      final count = _random.nextInt(maxCount - 1) + 2;

      problems.add(
        _makeProblem(
          id: 'count_${difficulty}_$i',
          type: 'counting',
          difficulty: difficulty,
          questionText: 'কতগুলো $obj আছে? উত্তর: $count',
          answer: count,
        ),
      );
    }

    return problems;
  }

  // ==================== COMPARISON ====================
  static List<GanitProblemModel> _comparisonProblems(int difficulty) {
    final problems = <GanitProblemModel>[];
    final int maxNum;

    switch (difficulty) {
      case 1:
        maxNum = 10;
      case 2:
        maxNum = 20;
      case 3:
        maxNum = 50;
      case 4:
        maxNum = 100;
      default:
        maxNum = 500;
    }

    for (int i = 0; i < 4; i++) {
      int a = _random.nextInt(maxNum) + 1;
      int b = _random.nextInt(maxNum) + 1;
      while (a == b) {
        b = _random.nextInt(maxNum) + 1;
      }

      final isBigger = _random.nextBool();
      final answer = isBigger ? (a > b ? a : b) : (a < b ? a : b);
      final questionType = isBigger ? 'বড়' : 'ছোট';

      problems.add(
        _makeProblem(
          id: 'comp_${difficulty}_$i',
          type: 'comparison',
          difficulty: difficulty,
          questionText: '$a আর $b — কোনটি $questionType?',
          answer: answer,
        ),
      );
    }

    return problems;
  }

  // ==================== MISSING NUMBER ====================
  static List<GanitProblemModel> _missingNumberProblems(int difficulty) {
    final problems = <GanitProblemModel>[];
    final int step;

    switch (difficulty) {
      case 1:
        step = 1;
      case 2:
        step = 2;
      case 3:
        step = 5;
      case 4:
        step = 10;
      default:
        step = 3;
    }

    for (int i = 0; i < 4; i++) {
      final start = _random.nextInt(10) * step + step;
      final missingPos =
          _random.nextInt(3) + 1; // position 1-3 in a 5-number sequence
      final answer = start + (missingPos * step);

      final sequence = List.generate(5, (j) {
        final val = start + (j * step);
        return j == missingPos ? '?' : '$val';
      });

      problems.add(
        _makeProblem(
          id: 'miss_${difficulty}_$i',
          type: 'missing_number',
          difficulty: difficulty,
          questionText: '${sequence.join(', ')} — ? = কত?',
          answer: answer,
        ),
      );
    }

    return problems;
  }

  // ==================== WORD PROBLEMS ====================
  static List<GanitProblemModel> _wordProblems(int difficulty) {
    final problems = <GanitProblemModel>[];

    final templates = <Map<String, dynamic>>[];

    if (difficulty <= 2) {
      templates.addAll([
        {
          'q': 'তোমার কাছে {a}টি আপেল আছে। বন্ধু আরও {b}টি দিল। এখন কয়টি?',
          'op': '+',
        },
        {'q': 'গাছে {a}টি পাখি ছিল। {b}টি উড়ে গেল। কয়টি রইল?', 'op': '-'},
        {
          'q': 'তোমার {a}টি পেন্সিল আছে। মা আরও {b}টি কিনে দিল। মোট কয়টি?',
          'op': '+',
        },
        {'q': '{a}টি বল থেকে {b}টি হারিয়ে গেল। কয়টি আছে?', 'op': '-'},
      ]);
    } else {
      templates.addAll([
        {
          'q': '{a}জন বন্ধু, প্রত্যেকে {b}টি করে চকলেট পেল। মোট কয়টি?',
          'op': 'x',
        },
        {
          'q':
              'দোকানে {a}টি আম ছিল। {b}টি বিক্রি হলো, আরও {c}টি এলো। এখন কয়টি?',
          'op': '+-',
        },
        {
          'q': '{a}টি কুকি {b}জনের মধ্যে সমান ভাগ। প্রত্যেকে কয়টি পাবে?',
          'op': '/',
        },
      ]);
    }

    final maxNum = difficulty <= 2 ? 10 : (difficulty <= 3 ? 15 : 20);

    for (int i = 0; i < 4; i++) {
      final template = templates[_random.nextInt(templates.length)];
      final op = template['op'] as String;
      int a, b, answer;

      switch (op) {
        case '+':
          a = _random.nextInt(maxNum) + 1;
          b = _random.nextInt(maxNum) + 1;
          answer = a + b;
        case '-':
          a = _random.nextInt(maxNum) + 3;
          b = _random.nextInt(a - 1) + 1;
          answer = a - b;
        case 'x':
          a = _random.nextInt(5) + 2;
          b = _random.nextInt(5) + 2;
          answer = a * b;
        case '/':
          b = _random.nextInt(4) + 2;
          answer = _random.nextInt(5) + 2;
          a = b * answer;
        case '+-':
          a = _random.nextInt(maxNum) + 5;
          b = _random.nextInt(a - 2) + 1;
          final c = _random.nextInt(maxNum) + 1;
          answer = a - b + c;
          final questionText = (template['q'] as String)
              .replaceAll('{a}', '$a')
              .replaceAll('{b}', '$b')
              .replaceAll('{c}', '$c');

          problems.add(
            _makeProblem(
              id: 'word_${difficulty}_$i',
              type: 'word_problem',
              difficulty: difficulty,
              questionText: questionText,
              answer: answer,
            ),
          );
          continue;
        default:
          a = 1;
          b = 1;
          answer = 2;
      }

      final questionText = (template['q'] as String)
          .replaceAll('{a}', '$a')
          .replaceAll('{b}', '$b');

      problems.add(
        _makeProblem(
          id: 'word_${difficulty}_$i',
          type: 'word_problem',
          difficulty: difficulty,
          questionText: questionText,
          answer: answer,
        ),
      );
    }

    return problems;
  }

  // ==================== MATCHING ====================
  static List<GanitProblemModel> _matchingProblems(int difficulty) {
    final problems = <GanitProblemModel>[];
    final int maxNum;
    final List<String> operators;

    switch (difficulty) {
      case 1:
        maxNum = 5;
        operators = ['+'];
      case 2:
        maxNum = 9;
        operators = ['+', '-'];
      case 3:
        maxNum = 12;
        operators = ['+', '-', 'x'];
      case 4:
        maxNum = 15;
        operators = ['+', '-', 'x'];
      default:
        maxNum = 20;
        operators = ['+', '-', 'x'];
    }

    for (int i = 0; i < 4; i++) {
      final pairCount = _random.nextInt(2) + 3; // 3 or 4 pairs
      final pairs = <GanitMatchPairModel>[];
      final usedAnswers = <int>{};

      for (int j = 0; j < pairCount; j++) {
        final op = operators[_random.nextInt(operators.length)];
        int a, b, answer;

        // Keep generating until we get a unique answer
        do {
          switch (op) {
            case '+':
              a = _random.nextInt(maxNum) + 1;
              b = _random.nextInt(maxNum) + 1;
              answer = a + b;
            case '-':
              a = _random.nextInt(maxNum) + 2;
              b = _random.nextInt(a - 1) + 1;
              answer = a - b;
            case 'x':
              a = _random.nextInt(5) + 1;
              b = _random.nextInt(5) + 1;
              answer = a * b;
            default:
              a = 1;
              b = 1;
              answer = 2;
          }
        } while (usedAnswers.contains(answer));

        usedAnswers.add(answer);
        final displayOp =
            op == 'x' ? '×' : op;

        pairs.add(GanitMatchPairModel(
          id: j,
          left: '$a $displayOp $b',
          right: '$answer',
        ));
      }

      problems.add(GanitProblemModel(
        id: 'match_${difficulty}_${i}_${_random.nextInt(99999)}',
        type: 'matching',
        difficulty: difficulty,
        questionText: 'সঠিক উত্তরের সাথে মিলাও',
        questionImageUrl: '',
        explanationText: '',
        answerText: '',
        options: const [],
        matchPairs: pairs,
      ));
    }

    return problems;
  }

  // ==================== ORDERING ====================
  static List<GanitProblemModel> _orderingProblems(int difficulty) {
    final problems = <GanitProblemModel>[];

    const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', '১০'];
    const bengaliVowels = ['অ', 'আ', 'ই', 'ঈ', 'উ', 'ঊ', 'ঋ', 'এ', 'ঐ', 'ও', 'ঔ'];

    final int seqLength;
    switch (difficulty) {
      case 1:
        seqLength = 4;
      case 2:
        seqLength = 5;
      default:
        seqLength = 6;
    }

    // Number sequences
    for (int i = 0; i < 2; i++) {
      final start = _random.nextInt(6);
      final items = List.generate(seqLength, (j) {
        final idx = start + j;
        return GanitOrderItemModel(
          id: j,
          text: idx < bengaliDigits.length ? bengaliDigits[idx] : '$idx',
          correctPosition: j,
        );
      });

      problems.add(GanitProblemModel(
        id: 'order_num_${difficulty}_${i}_${_random.nextInt(99999)}',
        type: 'ordering',
        difficulty: difficulty,
        questionText: 'সংখ্যাগুলো ছোট থেকে বড় সাজাও',
        questionImageUrl: '',
        explanationText: '',
        answerText: '',
        options: const [],
        orderItems: items,
      ));
    }

    // Bengali alphabet sequences
    for (int i = 0; i < 2; i++) {
      final start = _random.nextInt(4);
      final len = seqLength.clamp(3, 5);
      final items = List.generate(len, (j) {
        final idx = start + j;
        return GanitOrderItemModel(
          id: j,
          text: idx < bengaliVowels.length ? bengaliVowels[idx] : '?',
          correctPosition: j,
        );
      });

      problems.add(GanitProblemModel(
        id: 'order_alpha_${difficulty}_${i}_${_random.nextInt(99999)}',
        type: 'ordering',
        difficulty: difficulty,
        questionText: 'বর্ণগুলো সঠিক ক্রমে সাজাও',
        questionImageUrl: '',
        explanationText: '',
        answerText: '',
        options: const [],
        orderItems: items,
      ));
    }

    return problems;
  }

  // ==================== HELPER ====================
  static GanitProblemModel _makeProblem({
    required String id,
    required String type,
    required int difficulty,
    required String questionText,
    required int answer,
  }) {
    // Generate wrong options (unique, different from answer)
    final wrongOptions = <int>{};
    while (wrongOptions.length < 3) {
      int wrong;
      if (answer <= 5) {
        wrong = _random.nextInt(10) + 1;
      } else {
        final offset = _random.nextInt(5) + 1;
        wrong = _random.nextBool() ? answer + offset : answer - offset;
        if (wrong <= 0) wrong = answer + offset + 1;
      }
      if (wrong != answer) wrongOptions.add(wrong);
    }

    final options = [
      GanitOptionModel(id: 0, text: '$answer', imageUrl: '', isCorrect: true),
      ...wrongOptions.toList().asMap().entries.map(
        (e) => GanitOptionModel(
          id: e.key + 1,
          text: '${e.value}',
          imageUrl: '',
          isCorrect: false,
        ),
      ),
    ];
    options.shuffle(_random);

    // Reassign IDs after shuffle
    final finalOptions = options
        .asMap()
        .entries
        .map(
          (e) => GanitOptionModel(
            id: e.key,
            text: e.value.text,
            imageUrl: e.value.imageUrl,
            isCorrect: e.value.isCorrect,
          ),
        )
        .toList();

    return GanitProblemModel(
      id: '${id}_${_random.nextInt(99999)}',
      type: type,
      difficulty: difficulty,
      questionText: questionText,
      questionImageUrl: '',
      explanationText: '',
      answerText: '$answer',
      options: finalOptions,
    );
  }
}
