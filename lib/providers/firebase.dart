import 'dart:io';
import 'package:geoflutterfire/geoflutterfire.dart';
// ignore: implementation_imports
import 'package:geoflutterfire/src/models/DistanceDocSnapshot.dart';
// ignore: implementation_imports
import 'package:geoflutterfire/src/Util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class FireDB extends ChangeNotifier {
  static DateFormat dateFormatterDB = DateFormat('yyyy.MM.dd HH:mm:ss');
  List datenFelder;
  List zusatzFelder;
  List imagesFelder;
  Map felder;

  void init(List adatenFelder, List azusatzFelder, List aimagesFelder) {
    datenFelder = adatenFelder;
    zusatzFelder = azusatzFelder;
    imagesFelder = aimagesFelder;
    felder = {};
    felder["daten"] = datenFelder;
    felder["zusatz"] = zusatzFelder;
    felder["images"] = imagesFelder;

    // final geo = Geoflutterfire();
    // GeoFirePoint latlng = geo.point(latitude: 48.137235, longitude: 11.575540);
    // FirebaseFirestore.instance.collection("abstellanlagen_daten").add({
    //   "latlng": latlng.data,
    // });
  }

  Future<File> getImage(
      String tableBase, String imgName, int maxdim, bool thumbnail) async {
    throw UnimplementedError();
  }

  dynamic convert(String type, dynamic val) {
    if (val == null) return null;
    if (type == "bool") return (val as bool) ? 1 : 0;
    return val;
  }

  Future<Map> getValuesWithin(String tableBase, double minlat, double maxlat,
      double minlon, double maxlon) async {
    final geo = Geoflutterfire();
    final res = {};
    for (String collection in ["daten" /*, "zusatz", "images"*/]) {
      String table = "${tableBase}_$collection";
      List dbFelder = felder[collection];
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
            default:
              val = convert(feld["type"], data[name]);
          }
          row[index++] = val;
        }
        rows.add(row);
      });
      res[collection] = rows;
    }
    return res;
  }

  Future<Map> imgPost(String tableBase, String imgName) async {
    throw UnimplementedError();
  }

  Future<void> post(String tableBase, Map values) async {
    throw UnimplementedError();
  }

  Future<void> sayHello(String tableBase) async {
    throw UnimplementedError();
  }
}

// like within, but sw/ne instead of circle/radius
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
        bool insideBox = geoPoint.latitude > minlat &&
            geoPoint.latitude < maxlat &&
            geoPoint.longitude > minlon &&
            geoPoint.longitude < maxlon;
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
