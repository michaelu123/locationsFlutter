import 'package:flutter/foundation.dart';

class BaseConfig extends ChangeNotifier {
  List _datenFelder;
  List _zusatzFelder;
  List _dbDatenFelder;
  List _dbZusatzFelder;
  List _dbImagesFelder = [
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
      "name": "nr",
      "type": "int",
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
    return b;
  }

  void setInitially(Map map, String base) {
    if (baseConfigJS != null) return;
    if (base == null || base == "") {
      base = map.keys.toList()[0];
    }
    baseConfigJS = map;
    _setFelder(base);
  }

  void _setFelder(abase) {
    print("setFelder $base $abase");
    if (base == abase) return;
    base = abase;
    baseJS = baseConfigJS[base];

    _datenFelder = [...baseJS["daten"]["felder"], ...dates];
    dynamic z = baseJS["zusatz"];
    if (z != null) {
      z = z["felder"];
    }
    if (z != null) {
      _zusatzFelder = [...z, ...dates];
    } else {
      _zusatzFelder = [];
    }
    _dbDatenFelder = [...dbDatenPlus, ...baseJS["daten"]["felder"]];
    if (z != null) {
      _dbZusatzFelder = [...dbZusatzPlus, ...z];
    } else {
      _dbZusatzFelder = [];
    }
  }

  bool setBase(String abase) {
    print("setBase $base $abase");
    if (base == abase) return false;
    _setFelder(abase);
    print("notify");
    notifyListeners();
    return true;
  }

  List getDatenFelder() {
    return _datenFelder;
  }

  List getZusatzFelder() {
    return _zusatzFelder;
  }

  List getDbDatenFelder() {
    return _dbDatenFelder;
  }

  List getDbZusatzFelder() {
    return _dbZusatzFelder;
  }

  List getDbImagesFelder() {
    return _dbImagesFelder;
  }

  String getName() {
    final name = baseJS["name"];
    return name;
  }

  List<String> getNames() {
    return baseConfigJS.keys.toList();
  }

  String getDbName() {
    return baseJS["db_name"];
  }

  Map getGPS() {
    return baseJS["gps"];
  }

  int stellen() {
    return baseJS["gps"]["nachkommastellen"];
  }
}
