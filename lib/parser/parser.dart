import 'eval.dart';
import 'val.dart';
import 'package:petitparser/petitparser.dart';

import 'grammar.dart';

enum StmtType { retS, assS, ifS, forS }

class Statement {
  StmtType stmtType;
}

class ReturnStatement extends Statement {
  Expr expr;

  ReturnStatement(this.expr) {
    super.stmtType = StmtType.retS;
  }

  @override
  String toString() {
    return 'return: $expr';
  }
}

class Assignment extends Statement {
  Id id;
  Expr expr;

  Assignment(this.id, this.expr) {
    super.stmtType = StmtType.assS;
  }

  @override
  String toString() {
    return 'assign: $id = $expr';
  }
}

class IfStatement extends Statement {
  Expr expr;
  List thenStatements;
  List elifStatements;
  List elseStatements;

  IfStatement(Expr ex, List th, List ei, List el) {
    super.stmtType = StmtType.ifS;
    expr = ex;
    thenStatements = th;
    elifStatements = ei;
    elseStatements = el;
  }

  @override
  String toString() {
    var ei = elifStatements == null || elifStatements.isEmpty
        ? ''
        : ' elif $elifStatements';
    var el = (elseStatements == null) ? '' : ' else $elseStatements';
    return 'if: $expr then $thenStatements$ei$el';
  }
}

class ForEachStatement extends Statement {
  Id id;
  String direction;
  List statements;
  ForEachStatement(this.id, this.direction, this.statements) {
    super.stmtType = StmtType.forS;
  }
  @override
  String toString() {
    return 'foreach: id=$id dir=$direction stmts=$statements';
  }
}

class Id {
  String id;
  Id(this.id);
  @override
  String toString() {
    return 'ID($id)';
  }
}

class Expr {
  String op;
  Value val;
  List children;

  Expr(this.op);

  Expr.fromExpr(e) {
    if (e is List) {
      op = e[1];
      children = [Expr.fromExpr(e[0]), Expr.fromExpr(e[2])];
    } else if (e is Value) {
      op = 'val';
      val = e;
    } else if (e is Id) {
      op = 'id';
      val = Value.fromId(e);
    } else {
      op = 'op?';
      val = Value.fromString('???');
    }
  }

  @override
  String toString() {
    var v = val == null ? '' : '$val';
    var c = children == null ? '' : '$children';
    if (op == 'val') return v;
    if (op == 'id') return v;
    return 'Expr($op $c)';
  }
}

/// Loc parser definition.
class LocParserDefinition extends LocGrammarDefinition {
  @override
  Parser assignment() => super.assignment().map((each) {
        return Assignment(each[0], each[2]);
      });
  @override
  Parser returnStatement() => super.returnStatement().map((each) {
        return ReturnStatement(each[1]);
      });
  @override
  Parser ifStatement() => super.ifStatement().map((each) {
        return IfStatement(each[1], each[3], each[4], each[5]);
      });
  @override
  Parser elifStatement() => super.elifStatement().map((each) {
        return IfStatement(each[1], each[3], null, null);
      });
  @override
  Parser elseStatement() => super.elseStatement().map((each) {
        return each[1];
      });
  @override
  Parser forEachStatement() => super.forEachStatement().map((each) {
        var dir = 'asc';
        if (each[3] != null) dir = each[3][1];
        return ForEachStatement(each[2], dir, each[5]);
      });
  @override
  Parser expression() => super.expression().map((each) {
        final n = Expr.fromExpr(each);
        return n;
      });
  @override
  Parser idToken() => super.idToken().map((each) {
        return Id(each);
      });

  @override
  Parser numberToken() => super.numberToken().map((each) {
        return Value.fromNum(num.parse(each));
      });

  @override
  Parser stringToken() => ref(stringPrimitive).trim();

  @override
  Parser stringPrimitive() => super.stringPrimitive().map((each) {
        return Value.fromString(each[1].join());
      });
}

String parserErrorMessage;

List<Statement> parseProgram(String program) {
  final parser = LocParserDefinition().build();
  final v = parser.parse(program);
  if (v.isFailure) {
    parserErrorMessage = 'Error ${v.message} ${v.toPositionString()}';
    print(parserErrorMessage);
    return null;
  }
  List<dynamic> parsed = v.value;
  var statements = parsed.map((stmt) => stmt as Statement).toList();
  statements.forEach((stmt) {
    print('$stmt');
  });
  return statements;
}

int evalProgram(List<Statement> statements, Map daten, List zusatz) {
  final eval = Eval(daten, zusatz);
  final r = eval.evalStmts(statements);
  print('res $r');
  return r as int;
}
