import 'package:flutter/foundation.dart';
import 'package:locations/providers/db.dart';
import 'package:locations/providers/markers.dart';

class LocData with ChangeNotifier {
  // data read from / written to DB
  Map locDaten = {};
  List locImages = [];
  int imagesIndex = 0;
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

  void clearLocData() {
    locDaten = {};
    locZusatz = [];
    locImages = [];
    isZusatz = false;
  }

  Future<void> setFeld(
      Markers markers, String name, String type, Object val) async {
    Map res;
    if (isZusatz) {
      print("setZusatz $name $type $val $zusatzIndex");
      final v = locZusatz[zusatzIndex][name];
      if (v != val) {
        int nr = locZusatz[zusatzIndex]["nr"];
        locZusatz[zusatzIndex][name] = val;
        res = await LocationsDB.updateDB("zusatz", name, val, nr: nr);
        nr = res["nr"];
        //print(
        //    "LocZusatz index=$zusatzIndex nr=$nr $name changed from $v to $val");
        if (nr != null) locZusatz[zusatzIndex]["nr"] = nr;
        final created = res["created"];
        if (created != null) {
          locZusatz[zusatzIndex]["created"] = created;
          locZusatz[zusatzIndex]["modified"] = created;
        }
        final modified = res["modified"];
        if (modified != null) {
          locZusatz[zusatzIndex]["modified"] = modified;
        }
        notifyListeners();
      }
    } else {
      print("setDaten $name $type $val");
      final v = locDaten[name];
      if (v != val) {
        locDaten[name] = val;
        res = await LocationsDB.updateDB("daten", name, val);
        // print("LocDatum $name changed from $v to $val");
        final created = res["created"];
        if (created != null) {
          locDaten["created"] = created;
          locDaten["modified"] = created;
        }
        final modified = res["modified"];
        if (modified != null) {
          locDaten["modified"] = modified;
        }
        notifyListeners();
      }
    }

    final coord = Coord();
    coord.lat = LocationsDB.lat;
    coord.lon = LocationsDB.lon;
    coord.quality = LocationsDB.qualityOf(locDaten);
    coord.hasImage = locImages.length > 0;
    markers.current(coord);
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

  void decIndexZusatz() {
    if (zusatzIndex > 0) {
      zusatzIndex--;
      notifyListeners();
    }
  }

  void incIndexZusatz() {
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

  bool canDecZusatz() {
    return zusatzIndex > 0;
  }

  bool canIncZusatz() {
    return zusatzIndex < (locZusatz.length - 1);
  }

  int deleteZusatz() {
    int nr = locZusatz[zusatzIndex]["nr"];
    locZusatz.removeAt(zusatzIndex);
    if (zusatzIndex >= locZusatz.length) zusatzIndex = locZusatz.length - 1;
    notifyListeners();
    return nr;
  }

  void decIndexImages() {
    if (imagesIndex > 0) {
      imagesIndex--;
      notifyListeners();
    }
  }

  void incIndexImages() {
    if (imagesIndex < locImages.length - 1) {
      imagesIndex++;
      notifyListeners();
    }
  }

  bool isEmptyImages() {
    return (locImages.length) == 0;
  }

  void addImage(Map map) {
    locImages.add(map);
    notifyListeners();
  }

  bool canDecImages() {
    return imagesIndex > 0;
  }

  bool canIncImages() {
    return imagesIndex < (locImages.length - 1);
  }

  String deleteImage() {
    String imgPath = locImages[imagesIndex]["image_path"];
    locImages.removeAt(imagesIndex);
    if (imagesIndex >= locImages.length) imagesIndex = locImages.length - 1;
    notifyListeners();
    return imgPath;
  }

  String getImagePath() {
    if (locImages.length == 0) return null;
    if (imagesIndex >= locImages.length) imagesIndex = 0;
    final imagePath = locImages[imagesIndex]["image_path"];
    return imagePath;
  }
}
