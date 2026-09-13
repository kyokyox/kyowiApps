import 'dart:math' as math;

class CalculatorException implements Exception {
  final String message;
  CalculatorException(this.message);
  @override
  String toString() => message;
}

/// Parser & evaluator ekspresi matematika sederhana - recursive descent,
/// pure Dart tanpa dependency. Support: + - * / ^, kurung, minus unary,
/// fungsi sin/cos/tan/log/ln/sqrt, konstanta pi/e.
///
/// Trigonometri dievaluasi dalam DERAJAT (lebih familiar buat kalkulator
/// biasa dibanding radian).
class CalculatorEngine {
  static double evaluate(String expression) {
    final tokens = _tokenize(expression);
    final parser = _Parser(tokens);
    final result = parser.parseExpression();
    if (!parser.isAtEnd) {
      throw CalculatorException('Ekspresi gak valid.');
    }
    return result;
  }

  static List<String> _tokenize(String input) {
    final tokens = <String>[];
    var i = 0;
    final cleaned = input.replaceAll(' ', '');
    while (i < cleaned.length) {
      final ch = cleaned[i];
      if (RegExp(r'[0-9.]').hasMatch(ch)) {
        var j = i;
        while (j < cleaned.length && RegExp(r'[0-9.]').hasMatch(cleaned[j])) {
          j++;
        }
        tokens.add(cleaned.substring(i, j));
        i = j;
      } else if (RegExp(r'[a-zA-Z]').hasMatch(ch)) {
        var j = i;
        while (j < cleaned.length && RegExp(r'[a-zA-Z]').hasMatch(cleaned[j])) {
          j++;
        }
        tokens.add(cleaned.substring(i, j));
        i = j;
      } else if ('+-*/^(),'.contains(ch)) {
        tokens.add(ch);
        i++;
      } else {
        throw CalculatorException('Karakter gak dikenal: $ch');
      }
    }
    return tokens;
  }
}

class _Parser {
  final List<String> tokens;
  int pos = 0;
  _Parser(this.tokens);

  bool get isAtEnd => pos >= tokens.length;
  String? get _peek => isAtEnd ? null : tokens[pos];

  double parseExpression() => _parseAddSub();

  double _parseAddSub() {
    var value = _parseMulDiv();
    while (_peek == '+' || _peek == '-') {
      final op = tokens[pos++];
      final rhs = _parseMulDiv();
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  double _parseMulDiv() {
    var value = _parsePower();
    while (_peek == '*' || _peek == '/') {
      final op = tokens[pos++];
      final rhs = _parsePower();
      if (op == '/' && rhs == 0) throw CalculatorException('Gak bisa bagi 0.');
      value = op == '*' ? value * rhs : value / rhs;
    }
    return value;
  }

  double _parsePower() {
    var value = _parseUnary();
    if (_peek == '^') {
      pos++;
      final rhs = _parsePower(); // right-associative
      value = math.pow(value, rhs).toDouble();
    }
    return value;
  }

  double _parseUnary() {
    if (_peek == '-') {
      pos++;
      return -_parseUnary();
    }
    if (_peek == '+') {
      pos++;
      return _parseUnary();
    }
    return _parseAtom();
  }

  double _parseAtom() {
    if (isAtEnd) throw CalculatorException('Ekspresi gak lengkap.');
    final token = tokens[pos];

    if (token == '(') {
      pos++;
      final value = _parseAddSub();
      if (_peek != ')') throw CalculatorException('Kurung gak seimbang.');
      pos++;
      return value;
    }

    if (RegExp(r'^[0-9.]+$').hasMatch(token)) {
      pos++;
      return double.parse(token);
    }

    if (RegExp(r'^[a-zA-Z]+$').hasMatch(token)) {
      pos++;
      switch (token.toLowerCase()) {
        case 'pi':
          return math.pi;
        case 'e':
          return math.e;
        case 'sin':
          return math.sin(_parseFunctionArg() * math.pi / 180);
        case 'cos':
          return math.cos(_parseFunctionArg() * math.pi / 180);
        case 'tan':
          return math.tan(_parseFunctionArg() * math.pi / 180);
        case 'log':
          return math.log(_parseFunctionArg()) / math.ln10;
        case 'ln':
          return math.log(_parseFunctionArg());
        case 'sqrt':
          final v = _parseFunctionArg();
          if (v < 0) throw CalculatorException('Gak bisa akar dari negatif.');
          return math.sqrt(v);
        default:
          throw CalculatorException('Fungsi gak dikenal: $token');
      }
    }

    throw CalculatorException('Token gak dikenal: $token');
  }

  double _parseFunctionArg() {
    if (_peek != '(') throw CalculatorException('Fungsi butuh kurung, contoh: sin(30)');
    pos++;
    final value = _parseAddSub();
    if (_peek != ')') throw CalculatorException('Kurung gak seimbang.');
    pos++;
    return value;
  }
}
