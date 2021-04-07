import 'package:petitparser/parser.dart';
import 'package:petitparser/petitparser.dart';

class DeLetterCharPredicate extends CharacterPredicate {
  static final cuae = 'ä'.codeUnitAt(0);
  static final cuoe = 'ö'.codeUnitAt(0);
  static final cuue = 'ü'.codeUnitAt(0);
  static final cuAe = 'Ä'.codeUnitAt(0);
  static final cuOe = 'Ö'.codeUnitAt(0);
  static final cuUe = 'Ü'.codeUnitAt(0);
  static final cuss = 'ß'.codeUnitAt(0);
  static final cuaz = 'abcdefghijklmnopqrstuvwxyz'.codeUnits;
  static final cuAZ = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits;
  static final cuDE = [
    ...cuaz,
    ...cuAZ,
    cuae,
    cuoe,
    cuue,
    cuAe,
    cuOe,
    cuUe,
    cuss
  ];
  static final deArr = List<bool>.filled(256, false);

  DeLetterCharPredicate() {
    cuDE.forEach((cu) => deArr[cu] = true);
  }

  @override
  bool test(int value) {
    value &= 255;
    return deArr[value];
  }

  @override
  bool isEqualTo(CharacterPredicate other) => other is DeLetterCharPredicate;
}

/// Returns a parser that accepts any letter character.
Parser<String> buchstabe([String message = 'letter expected']) {
  return CharacterParser(DeLetterCharPredicate(), message);
}
