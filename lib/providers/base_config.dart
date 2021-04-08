import 'package:flutter/foundation.dart';

/// This class is initialized with the json files from
/// extPath/config (in [MyApp.appInitialize]).
/// With [setBase] one of them is chosen
/// and determines the current UI and DB fields. This enables the program to
/// switch between completely unrelated data.
class BaseConfig extends ChangeNotifier {
  List _datenFelder;
  List _zusatzFelder;
  List _dbDatenFelder;
  List _dbZusatzFelder;
  static const Map newOrModified = {
    "name": "new_or_modified",
    "type": "bool",
  };

  // the database fields of the images table
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
      "name": "region",
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
    {
      "name": "bemerkung",
      "type": "string",
    },
    newOrModified
  ];

  Map<String, dynamic> baseConfigJS;
  Map<String, dynamic> baseJS;
  String base = "";

  /// These fields are displayed on the Daten- and Zusatz-Screen.
  List dates = [
    {
      "name": "region",
      "hint_text": "Region/Gebiet",
      "helper_text": null,
      "type": "string",
    },
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

  /// The invariant fields of the daten-table.
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
      "name": "region",
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

  /// The invariant fields of the zusatz-table.
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
      "name": "region",
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

  /// setInitially is called during startup to set the category that was
  /// last set via the three vertical dots on the KartenScreen.
  void setInitially(Map map, String base) {
    if (baseConfigJS != null) return;
    if (base == null || base.isEmpty) {
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
    _dbDatenFelder = [
      ...dbDatenPlus,
      ...baseJS["daten"]["felder"],
      newOrModified
    ];
    if (z != null) {
      _dbZusatzFelder = [...dbZusatzPlus, ...z, newOrModified];
    } else {
      _dbZusatzFelder = [];
    }
  }

  /// Sets the current category.
  bool setBase(String base) {
    print("setBaseBC ${this.base} $base");
    if (base == this.base) return false;
    _setFelder(base);
    notifyListeners();
    return true;
  }

  /// Return the UI fields for "daten"
  List getDatenFelder() {
    return _datenFelder;
  }

  /// Return the UI fields for "zusatz"
  List getZusatzFelder() {
    return _zusatzFelder;
  }

  /// Return the DB fields for "daten"
  List getDbDatenFelder() {
    return _dbDatenFelder;
  }

  /// Return the DB fields for "zusatz"
  List getDbZusatzFelder() {
    return _dbZusatzFelder;
  }

  /// Return the DB fields for "images"
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

  String getDbTableBaseName() {
    return baseJS["db_tabellenname"];
  }

  Map getGPS() {
    return baseJS["gps"];
  }

  /// Geo coordinates are stored as doubles and as strings rounded to
  /// "stellen" digits after the decimal point. The strings are used
  /// as indices in the databases.
  int stellen() {
    return baseJS["gps"]["nachkommastellen"];
  }

  bool hasZusatz() {
    return _zusatzFelder.length > 0;
  }

  String getProgram() {
    var p = "return 0";
    final prog = baseJS["program"];
    if (prog != null) {
      if (prog is List) {
        p = prog.join('');
      } else if (prog is String) {
        p = prog;
      }
    }
    return p;
  }
}
