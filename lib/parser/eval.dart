import 'parser.dart';
import 'val.dart';

class Eval {
  final Map context;
  final List zusatz;

  Eval(this.context, this.zusatz) {
    Value.setContext(context);
  }

  dynamic evalStmts(List<dynamic> stmts) {
    dynamic r = 0;
    for (final stmt in stmts) {
      r = evalStmt(stmt as Statement);
      if (r != null) {
        return r;
      }
    }
    return r;
  }

  dynamic evalStmt(Statement stmt) {
    dynamic r;
    switch (stmt.stmtType) {
      case StmtType.assS:
        r = evalAssS(stmt as Assignment);
        break;
      case StmtType.forS:
        r = evalForS(stmt as ForEachStatement);
        break;
      case StmtType.ifS:
        r = evalIfS(stmt as IfStatement);
        break;
      case StmtType.retS:
        r = evalRetS(stmt as ReturnStatement);
        break;
    }
    return r;
  }

  dynamic evalAssS(Assignment assS) {
    context[assS.id.id] = evalExpr(assS.expr);
    return null;
  }

  dynamic evalForS(ForEachStatement stmt) {
    final desc = stmt.direction == 'desc';
    final id = stmt.id.id;
    zusatz
        .sort((a, b) => desc ? b[id].compareTo(a[id]) : a[id].compareTo(b[id]));
    for (final m in zusatz) {
      Value.setContext2(m);
      final r = evalStmts(stmt.statements);
      if (r != null) {
        Value.setContext2({});
        return r;
      }
    }
    Value.setContext2({});
    return null;
  }

  dynamic evalIfS(IfStatement stmt) {
    var r = evalExpr(stmt.expr);
    if (r.toBool()) return evalStmts(stmt.thenStatements);
    if (stmt.elifStatements != null) {
      for (final stmt2 in stmt.elifStatements) {
        r = evalExpr(stmt2.expr);
        if (r.toBool()) return evalStmts(stmt2.thenStatements);
      }
    }
    if (stmt.elseStatements != null) return evalStmts(stmt.elseStatements);
    return null;
  }

  dynamic evalRetS(ReturnStatement stmt) {
    return evalExpr(stmt.expr).toInt(); // here we want to return 0,1,or 2
  }

  Value evalExpr(Expr expr) {
    if (expr.op == 'val') return expr.val;
    if (expr.op == 'id') return Value.from(expr.val);

    final left = Value.from(evalExpr(expr.children[0]));
    final right = Value.from(evalExpr(expr.children[1]));
    switch (expr.op) {
      case '<':
        return left < right;
      case '<=':
        return left <= right;
      case '==':
        return left.eq(right);
      case '>=':
        return left >= right;
      case '>':
        return left > right;
      case '!=':
        return left.ne(right);
      case '+':
        return left + right;
      case '-':
        return left - right;
      case 'contains':
        return left.contains(right);
      case 'startswith':
        return left.startswith(right);
      case 'endswith':
        return left.endswith(right);
      case 'and':
        return left.and(right);
      case 'or':
        return left.or(right);
      default:
        print('???? ${expr.op}');
    }
    return null;
  }

  // dynamic evalVal(Value val) {
  //   switch (val.type) {
  //     case 'string':
  //       return val.strVal;
  //     case 'num':
  //       return val.numVal;
  //     case 'id':
  //       return evalId(val.strVal);
  //   }
  // }

  // dynamic evalId(String id) {
  //   return context[id] ?? 0;
  // }
}
