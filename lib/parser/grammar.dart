import 'buchstabe.dart';
import 'package:petitparser/petitparser.dart';

/*
<program> : <statements>
<statements>: <statement> [; <statements> ]
<statement>: <assignment> | <if-statement> | <foreach-statement> | <return-statement>
<assignment>: <id> = <expr>
<if-statement>: if <expr> then <statements> [elif <expr> then <statements> ]* [else <statements>] end
<foreach-statement>: foreach(<id>[, asc|desc]) <statements> end
<return-statement>: return <expr>
<expr>: <id> | <value> | <expr> <op> <expr> | ( <expr> )
<op>: + | - | contains | startswith | endswith | and | or | < | > | <= | >= | == | != 
<value> : <string> | <number> 
*/

class LocGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(statements).end();
  Parser token(Object source, [String name]) {
    if (source is String) {
      return source.toParser(message: 'Expected ${name ?? source}').trim();
    } else if (source is Parser) {
      ArgumentError.checkNotNull(name, 'name');
      return source.flatten('Expected $name').trim();
    } else {
      throw ArgumentError('Unknown token type: $source.');
    }
  }

  Parser statements() =>
      ref0(statement).separatedBy(ref1(token, ';'), includeSeparators: false);
  Parser statement() => [
        ref0(assignment),
        ref0(ifStatement),
        ref0(forEachStatement),
        ref0(returnStatement),
      ].toChoiceParser(/*failureJoiner: selectFarthestJoined*/);
  Parser assignment() => ref0(idToken) & ref1(token, '=') & ref0(expression);
  Parser ifStatement() =>
      ref1(token, 'if') &
      ref0(expression) &
      ref1(token, 'then') &
      ref0(statements) &
      ref0(elifStatement).star() &
      ref0(elseStatement).optional() &
      ref1(token, 'end');
  Parser elifStatement() =>
      ref1(token, 'elif') &
      ref0(expression) &
      ref1(token, 'then') &
      ref0(statements);
  Parser elseStatement() => ref1(token, 'else') & ref0(statements);
  Parser forEachStatement() =>
      ref1(token, 'foreach') &
      ref1(token, '(') &
      ref0(idToken) &
      ref0(direction).optional() &
      ref1(token, ')') &
      ref0(statements) &
      ref1(token, 'end');
  Parser direction() =>
      ref1(token, ',') & (ref1(token, 'asc') | ref1(token, 'desc'));
  Parser returnStatement() => ref1(token, 'return') & ref0(expression);
  Parser value() => [
        ref0(numberToken),
        ref0(stringToken),
        ref0(trueToken),
        ref0(falseToken),
        ref0(nullToken),
        ref0(idToken),
      ].toChoiceParser(/*failureJoiner: selectFarthestJoined*/);

  Parser trueToken() => ref1(token, 'true');
  Parser falseToken() => ref1(token, 'false');
  Parser nullToken() => ref1(token, 'null');
  Parser idToken() => ref2(token, ref0(idPrimitive), 'id');
  Parser stringToken() => ref2(token, ref0(stringPrimitive), 'string');
  Parser numberToken() => ref2(token, ref0(numberPrimitive), 'number');

  Parser characterPrimitive() =>
      ref0(characterNormal) | ref0(characterEscape) | ref0(characterUnicode);
  Parser characterNormal() => pattern('^"\\');
  Parser characterEscape() => char('\\') & pattern(escapeChars.keys.join());
  Parser characterUnicode() => string('\\u') & pattern('0-9A-Fa-f').times(4);
  Parser numberPrimitive() =>
      digit().plus() & char('.').seq(digit().plus()).optional();
  Parser<String> buchstabe([String message = 'letter expected']) {
    return CharacterParser(DeLetterCharPredicate(), message);
  }

  Parser idPrimitive() => ref0(buchstabe).star();
  Parser stringPrimitive() =>
      char('"') & ref0(characterPrimitive).star() & char('"');

  Parser expression() {
    final builder = ExpressionBuilder();
    builder.group().primitive(value());
    builder.group().wrapper(char('(').trim(), char(')').trim());

    builder.group()..left(char('+').trim())..left(char('-').trim());
    builder.group()
      ..left(ref1(token, 'contains'))
      ..left(ref1(token, 'startswith'))
      ..left(ref1(token, 'endswith'));
    builder.group()
      ..left(ref1(token, '<'))
      ..left(ref1(token, '<='))
      ..left(ref1(token, '=='))
      ..left(ref1(token, '>='))
      ..left(ref1(token, '>'))
      ..left(ref1(token, '!='));
    builder.group().left(ref1(token, 'and'));
    builder.group().left(ref1(token, 'or'));
    final parser = builder.build();
    return parser;
  }
}

const Map<String, String> escapeChars = {
  '\\': '\\',
  '/': '/',
  '"': '"',
  'b': '\b',
  'f': '\f',
  'n': '\n',
  'r': '\r',
  't': '\t'
};
