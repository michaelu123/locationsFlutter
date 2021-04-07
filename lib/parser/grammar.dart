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
  Parser start() => ref(statements).end();
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
      ref(statement).separatedBy(ref(token, ';'), includeSeparators: false);
  Parser statement() => [
        ref(assignment),
        ref(ifStatement),
        ref(forEachStatement),
        ref(returnStatement),
      ].toChoiceParser(/*failureJoiner: selectFarthestJoined*/);
  Parser assignment() => ref(idToken) & ref(token, '=') & ref(expression);
  Parser ifStatement() =>
      ref(token, 'if') &
      ref(expression) &
      ref(token, 'then') &
      ref(statements) &
      ref(elifStatement).star() &
      ref(elseStatement).optional() &
      ref(token, 'end');
  Parser elifStatement() =>
      ref(token, 'elif') &
      ref(expression) &
      ref(token, 'then') &
      ref(statements);
  Parser elseStatement() => ref(token, 'else') & ref(statements);
  Parser forEachStatement() =>
      ref(token, 'foreach') &
      ref(token, '(') &
      ref(idToken) &
      ref(direction).optional() &
      ref(token, ')') &
      ref(statements) &
      ref(token, 'end');
  Parser direction() =>
      ref(token, ',') & (ref(token, 'asc') | ref(token, 'desc'));
  Parser returnStatement() => ref(token, 'return') & ref(expression);
  Parser value() => [
        ref(numberToken),
        ref(stringToken),
        ref(trueToken),
        ref(falseToken),
        ref(nullToken),
        ref(idToken),
      ].toChoiceParser(/*failureJoiner: selectFarthestJoined*/);

  Parser trueToken() => ref(token, 'true');
  Parser falseToken() => ref(token, 'false');
  Parser nullToken() => ref(token, 'null');
  Parser idToken() => ref(token, ref(idPrimitive), 'id');
  Parser stringToken() => ref(token, ref(stringPrimitive), 'string');
  Parser numberToken() => ref(token, ref(numberPrimitive), 'number');

  Parser characterPrimitive() =>
      ref(characterNormal) | ref(characterEscape) | ref(characterUnicode);
  Parser characterNormal() => pattern('^"\\');
  Parser characterEscape() => char('\\') & pattern(escapeChars.keys.join());
  Parser characterUnicode() => string('\\u') & pattern('0-9A-Fa-f').times(4);
  Parser numberPrimitive() =>
      digit().plus() & char('.').seq(digit().plus()).optional();
  Parser<String> buchstabe([String message = 'letter expected']) {
    return CharacterParser(DeLetterCharPredicate(), message);
  }

  Parser idPrimitive() => ref(buchstabe).star();
  Parser stringPrimitive() =>
      char('"') & ref(characterPrimitive).star() & char('"');

  Parser expression() {
    final builder = ExpressionBuilder();
    builder.group().primitive(value());
    builder.group().wrapper(char('(').trim(), char(')').trim());

    builder.group()..left(char('+').trim())..left(char('-').trim());
    builder.group()
      ..left(ref(token, 'contains'))
      ..left(ref(token, 'startswith'))
      ..left(ref(token, 'endswith'));
    builder.group()
      ..left(ref(token, '<'))
      ..left(ref(token, '<='))
      ..left(ref(token, '=='))
      ..left(ref(token, '>='))
      ..left(ref(token, '>'))
      ..left(ref(token, '!='));
    builder.group().left(ref(token, 'and'));
    builder.group().left(ref(token, 'or'));
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
