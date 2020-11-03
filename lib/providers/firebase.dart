import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
// ignore: implementation_imports
import 'package:geoflutterfire/src/Util.dart';
// ignore: implementation_imports
import 'package:geoflutterfire/src/models/DistanceDocSnapshot.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class FirebaseClient {
  static DateFormat dateFormatterDB = DateFormat('yyyy.MM.dd HH:mm:ss');
  Map felder;
  Map types;
  String extPath;
  final geo = Geoflutterfire();

  void init(
    String extPath,
  ) {
    this.extPath = extPath;

    /* compute distances between points:
    var lat = 48.137235;
    var lon = 11.575540;
    GeoFirePoint p1 = geo.point(latitude: lat, longitude: lon);
    print("dist5, ${p1.distance(lat: lat + 0.005, lng: lon)}"); // 0.556
    print("dist5 ${p1.distance(lat: lat, lng: lon + 0.01)}"); // 0.742

    print("dist10, ${p1.distance(lat: lat + 0.01, lng: lon)}"); // 1.111
    print("dist10 ${p1.distance(lat: lat, lng: lon + 0.02)}"); // 1.483

    lat = 48.13;
    lon = 11.57;
    p1 = geo.point(latitude: lat, longitude: lon);

    // stellen = 3
    print("dist3, ${p1.distance(lat: lat + 0.001, lng: lon)}"); // 0.111
    print("dist3 ${p1.distance(lat: lat, lng: lon + 0.001)}"); // 0.074

    // stellen = 4
    print("dist4, ${p1.distance(lat: lat + 0.0001, lng: lon)}"); // 0.011
    print("dist4 ${p1.distance(lat: lat, lng: lon + 0.0001)}"); // 0.007

    // stellen = 5
    print("dist5, ${p1.distance(lat: lat + 0.00001, lng: lon)}"); // 0.001
    print("dist5 ${p1.distance(lat: lat, lng: lon + 0.00001)}"); // 0.001

    // stellen = 6
    print("dist6, ${p1.distance(lat: lat + 0.000001, lng: lon)}"); // 0.0
    print("dist6 ${p1.distance(lat: lat, lng: lon + 0.000001)}"); // 0.0
    */
  }

  void initFelder(
    List datenFelder,
    List zusatzFelder,
    List imagesFelder,
  ) {
    felder = {
      "daten": datenFelder,
      "zusatz": zusatzFelder,
      "images": imagesFelder,
    };
    types = {
      "daten": {},
      "zusatz": {},
      "images": {},
    };
    for (String tableName in felder.keys) {
      Map tmap = types[tableName];
      List lst = felder[tableName];
      for (Map m in lst) {
        tmap[m["name"]] = m["type"];
      }
    }
  }

  dynamic convertFb2DB(String type, dynamic val) {
    if (val == null) return null;
    if (type == "bool") return (val as bool) ? 1 : 0;
    return val;
  }

  dynamic convertDb2Fb(String type, dynamic val) {
    if (val == null) return null;
    if (type == "bool") return val != 0;
    return val;
  }

  Future<Map> getValuesWithin(String tableBase, double minlat, double maxlat,
      double minlon, double maxlon) async {
    final geo = Geoflutterfire();
    final res = {};
    for (String tableName in ["daten", "zusatz", "images"]) {
      String table = "${tableBase}_$tableName";
      List dbFelder = felder[tableName];
      int len = dbFelder.length;
      final collRef = FirebaseFirestore.instance.collection(table);
      // Stream<List<DocumentSnapshot>> stream = geo
      //     .collection(collectionRef: collRef)
      //     .withinBox(collRef, "latlng", minlat, maxlat, minlon, maxlon);
      List<DocumentSnapshot> dssList = await geo
          .collection(collectionRef: collRef)
          .withinBox(collRef, "latlng", minlat, maxlat, minlon, maxlon);

      final rows = [];
      dssList.forEach((DocumentSnapshot dss) {
        final data = dss.data();
        final row = List(len);
        dynamic val;
        int index = 0;
        for (Map feld in dbFelder) {
          String name = feld["name"];
          switch (name) {
            case "created":
              val = dateFormatterDB
                  .format((data["created"] as Timestamp).toDate());
              break;
            case "modified":
              val = dateFormatterDB
                  .format((data["modified"] as Timestamp).toDate());
              break;
            case "lat":
              val = (data["latlng"]["geopoint"] as GeoPoint).latitude;
              break;
            case "lon":
              val = (data["latlng"]["geopoint"] as GeoPoint).longitude;
              break;
            case "nr":
              val = dss.id;
              break;
            default:
              val = convertFb2DB(feld["type"], data[name]);
          }
          row[index++] = val;
        }
        rows.add(row);
      });
      res[tableName] = rows;
    }
    return res;
  }

  Future<Map> postImage(String tableBase, String imgName) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child("${tableBase}_images")
        .child(imgName);
    String imgPath = path.join(extPath, tableBase, "images", imgName);
    File f = File(imgPath);
    StorageTaskSnapshot snap = await ref.putFile(f).onComplete;
    String url = await snap.ref.getDownloadURL();
    return {"url": url};
  }

  // thumbnail suppport requires Firebase Extension "Resize Images"
  Future<List> getImage(
      String tableBase, String imgName, int maxdim, bool thumbnail) async {
    String imgPath = path.join(extPath, tableBase, "images", imgName);
    File f = File(imgPath);
    if (await f.exists()) return [f, false];
    if (thumbnail) {
      imgPath = path.join(extPath, tableBase, "images", "tn_" + imgName);
      f = File(imgPath);
      if (await f.exists()) return [f, false];
      imgName = imgName.replaceFirst(".jpg", "_200x200.jpg");
    }
    final ref = FirebaseStorage.instance
        .ref()
        .child(thumbnail
            ? "${tableBase}_images/thumbnails"
            : "${tableBase}_images")
        .child(imgName);
    Uint8List res = await ref.getData(10 * 1024 * 1024);
    if (res == null) return null;
    await f.writeAsBytes(res, flush: true);
    return [f, !thumbnail];
  }

  String docidFor(Map val, String tableName) {
    String id;
    switch (tableName) {
      case "daten":
        id = '${val["lat_round"]}_${val["lon_round"]}_${val["creator"]}';
        break;
      case "zusatz":
        String uniq = (val["created"] as Timestamp).seconds.toRadixString(36);
        id = '${val["lat_round"]}_${val["lon_round"]}_${val["creator"]}_$uniq';
        break;
      case "images":
        id = '${val["creator"]}_${val["image_path"]}';
        break;
    }
    return id;
  }

  Future<void> post(String tableBase, Map values) async {
    // values is a Map {table: [{colname:colvalue},...]}
    for (final tableName in values.keys) {
      String table = "${tableBase}_$tableName";
      final collRef = FirebaseFirestore.instance.collection(table);

      List rows = values[tableName];
      if (rows.length == 0) continue;
      double lat;
      GeoFirePoint latlng;
      for (Map map in rows) {
        for (String name in map.keys) {
          switch (name) {
            case "created":
            case "modified":
              // "2000.01.01 01:00:00" -> 20000101 01:00:00
              String val = map[name].replaceAll(".", "");
              final dt = DateTime.parse(val);
              final msec = dt.millisecondsSinceEpoch;
              final ts = Timestamp((msec / 1000).round(), 0);
              map[name] = ts;
              break;
            case "lat":
              double val = map[name];
              lat = val;
              break;
            case "lon":
              double val = map[name];
              latlng = geo.point(latitude: lat, longitude: val);
              break;
            default:
              dynamic val = map[name];
              String type = types[tableName][name];
              map[name] = convertDb2Fb(type, val);
          }
        }
        map["latlng"] = latlng.data;
        map.remove("new_or_modified");
        map.remove("nr");
        map.remove("lat");
        map.remove("lon");
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int ctr = 0;
      for (Map val in rows) {
        String id = docidFor(val, tableName);
        final newDoc = collRef.doc(id);
        batch.set(newDoc, val);
        if (ctr++ > 400) {
          batch.commit();
          batch = FirebaseFirestore.instance.batch();
          ctr = 0;
        }
      }
      batch.commit();
    }
  }

  void postRows(String tableBase, Map values) {
    // values is a Map {table: [[colvalue,...],...]]
    for (final tableName in values.keys) {
      String table = "${tableBase}_$tableName";
      List dbFelder = felder[tableName];
      final collRef = FirebaseFirestore.instance.collection(table);
      double lat;
      List rowsIn = values[tableName];
      List rowsOut = [];
      if (rowsIn.length == 0) continue;
      for (List row in rowsIn) {
        Map<String, dynamic> map = {};
        int index = 0;
        for (Map feld in dbFelder) {
          String name = feld["name"];
          String type = feld["type"];
          switch (name) {
            case "created":
            case "modified":
              // "2000.01.01 01:00:00" -> 20000101 01:00:00
              String val = row[index].replaceAll(".", "");
              final dt = DateTime.parse(val);
              final msec = dt.millisecondsSinceEpoch;
              final ts = Timestamp((msec / 1000).round(), 0);
              map[name] = ts;
              break;
            case "lat":
              double val = row[index];
              lat = val;
              break;
            case "lon":
              double val = row[index];
              GeoFirePoint latlng = geo.point(latitude: lat, longitude: val);
              map["latlng"] = latlng.data;
              break;
            case "nr":
            case "new_or_modified":
              break;
            default:
              dynamic val = row[index];
              map[name] = convertDb2Fb(type, val);
          }
          index++;
        }
        rowsOut.add(map);
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int ctr = 0;
      for (Map val in rowsOut) {
        String id = docidFor(val, tableName);
        final newDoc = collRef.doc(id);
        batch.set(newDoc, val);
        if (ctr++ >= 400) {
          print("committing $ctr entries for $table");
          batch.commit();
          batch = FirebaseFirestore.instance.batch();
          ctr = 0;
        }
      }
      print("committing $ctr entries for $table");
      batch.commit();
    }
  }

  Future<void> sayHello(String tableBase) async {
    throw UnimplementedError();
  }
}

// like within, but sw/ne instead of circle/radius
// see https://stackoverflow.com/questions/64592474/geoflutterfire-within-function-shall-simply-return-all-existing-values-in-the-fi
extension GeoBox on GeoFireCollectionRef {
  static Query _collectionReference;

  Query _queryPoint(String geoHash, String field) {
    final end = '$geoHash~';
    final temp = _collectionReference;
    return temp.orderBy('$field.geohash').startAt([geoHash]).endAt([end]);
  }

  Future<List<DocumentSnapshot>> withinBox(Query collRef, String field,
      double minlat, double maxlat, double minlon, double maxlon) async {
    _collectionReference = collRef;
    GeoFirePoint center =
        GeoFirePoint((minlat + maxlat) / 2, (minlon + maxlon) / 2);
    double radius = center.distance(lat: maxlat, lng: maxlon);

    final precision = Util.setPrecision(radius);
    final centerHash = center.hash.substring(0, precision);
    final area = GeoFirePoint.neighborsOf(hash: centerHash)..add(centerHash);

    Iterable<Future<List<DistanceDocSnapshot>>> queries = area.map((hash) {
      final tempQuery = _queryPoint(hash, field);
      return tempQuery.get().then((QuerySnapshot querySnapshot) {
        return querySnapshot.docs
            .map((element) => DistanceDocSnapshot(element, null))
            .toList();
      });
    });

    List<DocumentSnapshot> filtered = [];
    await Future.wait(
        queries.map((Future<List<DistanceDocSnapshot>> query) async {
      List<DistanceDocSnapshot> list = await query;
      var mappedList = list.map((DistanceDocSnapshot distanceDocSnapshot) {
        // split and fetch geoPoint from the nested Map
        final fieldList = field.split('.');
        var geoPointField =
            distanceDocSnapshot.documentSnapshot.data()[fieldList[0]];
        final GeoPoint geoPoint = geoPointField['geopoint'];
        bool insideBox = geoPoint.latitude >= minlat &&
            geoPoint.latitude <= maxlat &&
            geoPoint.longitude >= minlon &&
            geoPoint.longitude <= maxlon;
        distanceDocSnapshot.distance = insideBox ? 0 : 9999999;
        return distanceDocSnapshot;
      });
      final filteredList = mappedList
          .where((DistanceDocSnapshot doc) => doc.distance == 0)
          .toList();
      filtered.addAll(filteredList.map((element) => element.documentSnapshot));
    }));
    return filtered;
  }
}
