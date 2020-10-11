import 'package:flutter/foundation.dart';

class BaseConfig with ChangeNotifier {
  static List datenFelder; // nasty hack, see daten.dart
  static List zusatzFelder;
  static List dbDatenFelder;
  static List dbZusatzFelder;
  static List dbImagesFelder = [
    {
      "name": "creator",
      "type": "string",
    },
    {
      "name": "created",
      "type": "string",
    },
    {
      "name": "lat",
      "type": "float",
    },
    {
      "name": "lon",
      "type": "float",
    },
    {
      "name": "lat_round",
      "type": "string",
    },
    {
      "name": "lon_round",
      "type": "string",
    },
    {
      "name": "image_path",
      "type": "string",
    },
    {
      "name": "image_url",
      "type": "string",
    },
  ];

  Map<String, dynamic> baseConfigJS;
  Map<String, dynamic> baseJS;
  String base = "";

  BaseConfig() {
    print("BC constructor");
  }

  List dates = [
    {
      "name": "created",
      "hint_text": "Erzeugt",
      "helper_text": null,
      "type": "string",
    },
    {
      "name": "modified",
      "hint_text": "Geändert",
      "helper_text": null,
      "type": "string",
    },
  ];

  final List dbDatenPlus = [
    {
      "name": "creator",
      "type": "string",
    },
    {
      "name": "created",
      "type": "string",
    },
    {
      "name": "modified",
      "type": "string",
    },
    {
      "name": "lat",
      "type": "float",
    },
    {
      "name": "lon",
      "type": "float",
    },
    {
      "name": "lat_round",
      "type": "string",
    },
    {
      "name": "lon_round",
      "type": "string",
    },
  ];

  final List dbZusatzPlus = [
    {
      "nr": "creator",
      "type": "string",
    },
    {
      "name": "creator",
      "type": "string",
    },
    {
      "name": "created",
      "type": "string",
    },
    {
      "name": "modified",
      "type": "string",
    },
    {
      "name": "lat",
      "type": "float",
    },
    {
      "name": "lon",
      "type": "float",
    },
    {
      "name": "lat_round",
      "type": "string",
    },
    {
      "name": "lon_round",
      "type": "string",
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
    setFelder(base);
  }

  void setFelder(abase) {
    print("setBase $base $abase");
    if (base == abase) return;
    base = abase;
    baseJS = baseConfigJS[base];
    print("baseJS $baseJS");

    datenFelder = [...baseJS["daten"]["felder"], ...dates];
    dynamic z = baseJS["zusatz"];
    if (z != null) {
      z = z["felder"];
    }
    if (z != null) {
      zusatzFelder = [...z, ...dates];
    } else {
      zusatzFelder = [];
    }
    dbDatenFelder = [...dbDatenPlus, ...baseJS["daten"]["felder"]];
    if (z != null) {
      dbZusatzFelder = [...dbZusatzPlus, ...z];
    } else {
      dbZusatzFelder = [];
    }
  }

  bool setBase(String abase) {
    print("setBase $base $abase");
    if (base == abase) return false;
    setFelder(abase);
    print("notify");
    notifyListeners();
    return true;
  }

  List getDatenFelder() {
    return datenFelder;
  }

  List getZusatzFelder() {
    return zusatzFelder;
  }

  List getDbDatenFelder() {
    return dbDatenFelder;
  }

  List getDbZusatzFelder() {
    return dbZusatzFelder;
  }

  List getDbImagesFelder() {
    return dbImagesFelder;
  }

  String getName() {
    final name = baseJS["name"];
    // print("getName $name");
    return name;
  }

  List<String> getNames() {
    print("getNames");
    return baseConfigJS.keys.toList();
  }
}
