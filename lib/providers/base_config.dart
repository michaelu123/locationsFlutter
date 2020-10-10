import 'package:flutter/foundation.dart';

class BaseConfig with ChangeNotifier {
  static List datenFelder; // nasty hack, see daten.dart
  static List zusatzFelder; // nasty hack, see daten.dart
  Map<String, dynamic> baseConfigJS;
  Map<String, dynamic> baseJS;
  String base;

  BaseConfig() {
    print("BC constructor");
  }

  List dates = [
    {
      "name": "created",
      "hint_text": "Erzeugt",
      "helper_text": null,
      "type": "string"
    },
    {
      "name": "modified",
      "hint_text": "Geändert",
      "helper_text": null,
      "type": "string"
    },
  ];

  bool isInited() {
    bool b = baseConfigJS != null;
    print("isInited $b");
    return b;
  }

  void setInitially(Map map, String base) {
    if (baseConfigJS != null) return;
    print("setBaseConfig $base ${map.keys}");
    baseConfigJS = map;
    baseJS = baseConfigJS[base];
    datenFelder = getDatenFelder();
    zusatzFelder = getZusatzFelder();
    print("baseJS $baseJS");
    this.base = base;
  }

  bool setBase(String abase) {
    print("setBase $base $abase");
    if (base == abase) return false;
    base = abase;
    baseJS = baseConfigJS[base];
    datenFelder = getDatenFelder();
    zusatzFelder = getZusatzFelder();
    print("notify");
    notifyListeners();
    return true;
  }

  List getDatenFelder() {
    datenFelder = baseJS["daten"]["felder"];
    if (datenFelder[datenFelder.length - 1]["name"] != "modified") {
      datenFelder.addAll(dates);
    }
    return datenFelder;
  }

  List getZusatzFelder() {
    dynamic z = baseJS["zusatz"];
    if (z != null) {
      z = z["felder"];
    }
    if (z != null) {
      // something like ?. operator for arrays?
      zusatzFelder = z;
      if (zusatzFelder[zusatzFelder.length - 1]["name"] != "modified") {
        zusatzFelder.addAll(dates);
      }
    } else {
      zusatzFelder = [];
    }
    return zusatzFelder;
  }

  String getName() {
    final name = baseJS["name"];
    print("getName $name");
    return name;
  }

  List<String> getNames() {
    print("getNames");
    return baseConfigJS.keys.toList();
  }
}
