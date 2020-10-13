import 'package:flutter/foundation.dart';
import 'package:locations/providers/db.dart';

class LocData with ChangeNotifier {
  // data read from / written to DB
  Map locDaten = {};
  List locImages = [];
  int imageIndex;
  List locZusatz = [];
  bool isZusatz = false;
  int zusatzIndex = 0;

  void dataFor(String table, Map data) {
    isZusatz = table == "zusatz";
    locDaten = data["daten"].length > 0 ? data["daten"][0] : {};
    locZusatz = data["zusatz"];
    locImages = data["images"];
    notifyListeners();
  }

  void setZusatzIndex(int x) {
    zusatzIndex = x;
    notifyListeners();
  }

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
    isZusatz = false;
  }

  Future<void> setFeld(String name, String type, Object val) async {
    if (isZusatz) {
      print("setZusatz $name $type $val $zusatzIndex");
      final v = locZusatz[zusatzIndex][name];
      if (v != val) {
        int nr = locZusatz[zusatzIndex]["nr"];
        locZusatz[zusatzIndex][name] = val;
        nr = await LocationsDB.updateDB("zusatz", name, val, nr: nr);
        print(
            "LocZusatz index=$zusatzIndex nr=$nr $name changed from $v to $val");
        if (nr != null) locZusatz[zusatzIndex]["nr"] = nr;
      }
    } else {
      print("setDaten $name $type $val");
      final v = locDaten[name];
      if (v != val) {
        locDaten[name] = val;
        await LocationsDB.updateDB("daten", name, val);
        print("LocDatum $name changed from $v to $val");
      }
    }
    // no notify
  }

  String getFeldText(String name, String type) {
    dynamic t;
    if (isZusatz) {
      if (locZusatz.length == 0) return "";
      if (zusatzIndex >= locZusatz.length) zusatzIndex = 0;
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

  bool isEmpty() {
    return (isZusatz ? locZusatz.length : locDaten.length) == 0;
  }

  void addZusatz() {
    locZusatz.add({});
    zusatzIndex = locZusatz.length - 1;
    notifyListeners();
  }

  bool canDec() {
    return zusatzIndex > 0;
  }

  bool canInc() {
    return zusatzIndex < (locZusatz.length - 1);
  }
}
