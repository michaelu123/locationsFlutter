import 'package:flutter/foundation.dart';
import 'package:locations/utils/db.dart';
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
    imagesIndex = 0;
    notifyListeners();
  }

  void clearLocData() {
    locDaten = {};
    locZusatz = [];
    locImages = [];
    isZusatz = false;
  }

  Future<void> setFeld(Markers markers, String region, String name, String type,
      Object val, String userName) async {
    Map res;
    if (isZusatz) {
      // print("setZusatz $name $type $val $zusatzIndex");
      final v = locZusatz[zusatzIndex][name];
      if (v != val) {
        int nr = locZusatz[zusatzIndex]["nr"];
        locZusatz[zusatzIndex][name] = val;
        res = await LocationsDB.updateRowDB(
            "zusatz", region, name, val, userName,
            nr: nr);
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
      // print("setDaten $name $type $val");
      final v = locDaten[name];
      if (v != val) {
        locDaten[name] = val;
        res =
            await LocationsDB.updateRowDB("daten", region, name, val, userName);
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
    coord.quality = LocationsDB.qualityOfLoc(locDaten, locZusatz);
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

  int getImagesCount() {
    return locImages.length;
  }

  void setImagesIndex(int x) {
    imagesIndex = x;
  }

  String getImgUrl(int index) {
    return locImages[index]["image_url"];
  }

  String getImgPath(int index) {
    return locImages[index]["image_path"];
  }

  String getImgCreated(int index) {
    return locImages[index]["created"];
  }

  String getImgBemerkung(int index) {
    return locImages[index]["bemerkung"];
  }

  void setImgBemerkung(String text, int index) {
    locImages[index]["bemerkung"] = text;
    String imgPath = getImgPath(index);
    LocationsDB.updateImagesDB(imgPath, "bemerkung", text);
  }

  bool isEmptyImages() {
    return (locImages.length) == 0;
  }

  int addImage(Map map, Markers markers) {
    locImages.add(map);
    imagesIndex = locImages.length - 1;
    notifyListeners();

    final coord = Coord();
    coord.lat = LocationsDB.lat;
    coord.lon = LocationsDB.lon;
    coord.quality = LocationsDB.qualityOfLoc(locDaten, locZusatz);
    coord.hasImage = locImages.length > 0;
    markers.current(coord);

    return imagesIndex;
  }

  String deleteImage(Markers markers) {
    String imgPath = locImages[imagesIndex]["image_path"];
    locImages.removeAt(imagesIndex);
    if (imagesIndex >= locImages.length) imagesIndex = locImages.length - 1;
    notifyListeners();

    final coord = Coord();
    coord.lat = LocationsDB.lat;
    coord.lon = LocationsDB.lon;
    coord.quality = LocationsDB.qualityOfLoc(locDaten, locZusatz);
    coord.hasImage = locImages.length > 0;
    markers.current(coord);

    return imgPath;
  }

  String getImagePath() {
    if (locImages.length == 0) return null;
    final imagePath = locImages[imagesIndex]["image_path"];
    return imagePath;
  }

  String getImageUrl() {
    if (locImages.length == 0) return null;
    final imageUrl = locImages[imagesIndex]["image_url"];
    return imageUrl;
  }

  void setIsZusatz(bool b) {
    if (isZusatz == b) return;
    isZusatz = b;
    notifyListeners();
  }
}
