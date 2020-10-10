import 'package:flutter/foundation.dart';

class LocData with ChangeNotifier {
  // data read from / written to DB
  Map locDaten = {
    "ort": "Zuhause",
    "wetter": "gut",
    "anzahl": 111,
    "abstand": 1,
    "created": "2020.01.01",
    "modified": "2020.12.31",
  };

  List locZusatz = [
    {
      "wetter": "gut",
      "auslastung": 10,
      "bemerkung": "Keine",
      "created": "2020.01.01",
      "modified": "2020.12.31",
    },
    {
      "wetter": "mittel",
      "auslastung": 20,
      "bemerkung": "Keine",
      "created": "2020.01.01",
      "modified": "2020.12.31",
    },
    {
      "wetter": "schlecht",
      "auslastung": 30,
      "bemerkung": "Keine",
      "created": "2020.01.01",
      "modified": "2020.12.31",
    },
  ];
  bool isZusatz = false;
  int zusatzIndex = 0;

  void useZusatz(bool b) {
    if (isZusatz == b) return;
    isZusatz = b;
    notifyListeners();
  }

  void setZusatzIndex(int x) {
    zusatzIndex = x;
    notifyListeners();
  }

  List locImages = [];
  int imageIndex;
  void setImageIndex(int x) {
    imageIndex = x;
    notifyListeners();
  }

  void setLocData(double lat, double lon) {
    locDaten = {};
    locZusatz = [];
    locImages = [];
    notifyListeners();
  }

  void clearLocData() {
    locDaten = {};
    locZusatz = [];
    locImages = [];
  }

  setFeld(String name, String type, Object val) {
    if (isZusatz) {
      print("setZusatz $name $type $val} $zusatzIndex");
      final v = locZusatz[zusatzIndex][name];
      if (v != val) {
        locZusatz[zusatzIndex][name] = val;
        print("LocZusatz $zusatzIndex $name changed from $v to $val");
      }
    } else {
      print("setDaten $name $type $val}");
      final v = locDaten[name];
      if (v != val) {
        locDaten[name] = val;
        print("LocDatum $name changed from $v to $val");
      }
    }
    // no notify
  }

  String getFeldText(String name, String type) {
    var t;
    if (isZusatz) {
      t = locZusatz[zusatzIndex][name];
    } else {
      t = locDaten[name];
    }
    if (t == null) return "";
    if (type == "bool") return t == 1 ? "ja" : "nein";
    return t.toString();
  }

  void decIndex() {
    if (zusatzIndex > 0) {
      zusatzIndex--;
      notifyListeners();
    }
  }

  void incIndex() {
    if (zusatzIndex < locZusatz.length - 1) {
      zusatzIndex++;
      notifyListeners();
    }
  }
}
