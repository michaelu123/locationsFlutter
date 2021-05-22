import 'parser.dart';

class Value {
  static Map context;
  static Map context2;
  static void setContext(Map ctx) {
    context = ctx;
    context2 = {};
  }

  static void setContext2(Map ctx) {
    context2 = ctx;
  }

  num numVal;
  String strVal;
  String type;

  Value() {
    numVal = 0;
    strVal = '';
    type = 'num';
  }

  static dynamic getValForId(String name) {
    dynamic r = context2["_" + name] ?? context["_" + name];
    if (r == null) {
      r = context2[name] ?? context[name];
    }
    if (name != 'created' && name != 'modified') return r;
    // "2000.01.01 01:00:00" -> 20000101 01:00:00
    String val = r.replaceAll(".", "");
    return DateTime.parse(val);
  }

  static Value from(dynamic v) {
    if (v is Value) {
      if (v.type != 'id') {
        return v;
      }
      v = Id(v.strVal);
    }
    if (v is String) return Value.fromString(v);
    if (v is num) return Value.fromNum(v);
    if (v is Id) {
      final w = getValForId(v.id);
      if (w == null) return Value.fromNum(0);
      if (w is Value) return w;
      if (w is int) return Value.fromNum(w);
      if (w is String) return Value.fromString(w);
      if (w is bool) return Value.fromNum(w ? 1 : 0);
      if (w is DateTime) {
        return Value.fromNum(DateTime.now().difference(w).inDays);
      }
    }
    print('!!!!!!!!!');
    return null;
  }

  Value.fromString(String s) {
    strVal = s;
    numVal = 0;
    type = 'string';
  }

  Value.fromNum(num n) {
    numVal = n;
    strVal = '';
    type = 'num';
  }

  Value.fromBool(bool b) {
    numVal = b ? 1 : 0;
    strVal = '';
    type = 'num';
  }

  Value.fromId(Id id) {
    numVal = 0;
    strVal = id.id;
    type = 'id';
  }

  String toStr() {
    if (type == 'string') return strVal;
    if (type == 'id') return getValForId(strVal) ?? 'undefined';
    return numVal.toString();
  }

  int toInt() {
    if (type == 'num') return numVal;
    if (type == 'string') return int.tryParse(strVal) ?? 0;
    if (type == 'id') {
      final r = from(getValForId(strVal) ?? 0);
      return r.toInt();
    }
    return 0;
  }

  @override
  String toString() {
    String r;
    if (type == 'string') {
      r = 'Value("$strVal")';
    } else if (type == 'id') {
      r = 'Id($strVal)';
    } else {
      r = 'Value($numVal)';
    }
    return r;
  }

  bool toBool() {
    if (type == 'string') return strVal != '';
    return numVal != 0;
  }

  Value operator +(Value other) {
    final r = Value();
    if (type == 'string' || other.type == 'string') {
      r.strVal = toStr() + other.toStr();
      r.type = 'string';
    } else {
      r.numVal = numVal + other.numVal;
    }
    return r;
  }

  Value operator -(Value other) {
    final r = Value();
    r.numVal = numVal - other.numVal;
    return r;
  }

  Value operator <=(Value other) {
    if (type == 'string' || other.type == 'string') {
      return Value.fromBool(toStr().compareTo(other.toStr()) <= 0);
    } else {
      return Value.fromBool(numVal <= other.numVal);
    }
  }

  Value operator <(Value other) {
    if (type == 'string' || other.type == 'string') {
      return Value.fromBool(toStr().compareTo(other.toStr()) < 0);
    } else {
      return Value.fromBool(numVal < other.numVal);
    }
  }

  Value eq(Value other) {
    if (type == 'string' || other.type == 'string') {
      return Value.fromBool(toStr().compareTo(other.toStr()) == 0);
    } else {
      return Value.fromBool(numVal == other.numVal);
    }
  }

  Value ne(Value other) {
    if (type == 'string' || other.type == 'string') {
      return Value.fromBool(toStr().compareTo(other.toStr()) != 0);
    } else {
      return Value.fromBool(numVal != other.numVal);
    }
  }

  Value operator >=(Value other) {
    if (type == 'string' || other.type == 'string') {
      return Value.fromBool(toStr().compareTo(other.toStr()) >= 0);
    } else {
      return Value.fromBool(numVal >= other.numVal);
    }
  }

  Value operator >(Value other) {
    if (type == 'string' || other.type == 'string') {
      return Value.fromBool(toStr().compareTo(other.toStr()) > 0);
    } else {
      return Value.fromBool(numVal > other.numVal);
    }
  }

  Value startswith(Value other) {
    if (type != 'string' || other.type != 'string') {
      return Value.fromBool(false);
    }
    return Value.fromBool(strVal.startsWith(other.strVal));
  }

  Value endswith(Value other) {
    if (type != 'string' || other.type != 'string') {
      return Value.fromBool(false);
    }
    return Value.fromBool(strVal.endsWith(other.strVal));
  }

  Value contains(Value other) {
    if (type != 'string' || other.type != 'string') {
      return Value.fromBool(false);
    }
    return Value.fromBool(strVal.contains(other.strVal));
  }

  Value and(Value other) {
    return Value.fromBool(toBool() && other.toBool());
  }

  Value or(Value other) {
    return Value.fromBool(toBool() || other.toBool());
  }
}
