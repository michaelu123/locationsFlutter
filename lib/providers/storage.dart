import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:locations/providers/locations_client.dart';

import 'firebase.dart';

class Storage extends ChangeNotifier {
  bool useLoc = true;
  LocationsClient locClnt;
  FireDB dbClnt;

  void setClnt(String clnt) {
    useLoc = clnt == "LocationsServer";
    useLoc = false; // TODO
    if (useLoc) {
      locClnt = LocationsClient();
      dbClnt = null;
    } else {
      locClnt = null;
      dbClnt = FireDB();
    }
  }

  void init(
      {String serverUrl,
      String extPath,
      List datenFelder,
      List zusatzFelder,
      List imagesFelder}) {
    if (useLoc) {
      locClnt.init(serverUrl, extPath);
    } else {
      dbClnt.init(datenFelder, zusatzFelder, imagesFelder);
    }
  }

  Future<void> sayHello(String tableBase) async {
    if (useLoc) return locClnt.sayHello(tableBase);
    return dbClnt.sayHello(tableBase);
  }

  Future<Map> imgPost(String tableBase, String imgName) async {
    if (useLoc) return locClnt.imgPost(tableBase, imgName);
    return dbClnt.imgPost(tableBase, imgName);
  }

  Future<void> post(String tableBase, Map values) async {
    if (useLoc) return locClnt.post(tableBase, values);
    return dbClnt.post(tableBase, values);
  }

  Future<Map> getValuesWithin(String tableBase, double minlat, double maxlat,
      double minlon, double maxlon) async {
    if (useLoc)
      return locClnt.getValuesWithin(tableBase, minlat, maxlat, minlon, maxlon);
    return dbClnt.getValuesWithin(tableBase, minlat, maxlat, minlon, maxlon);
  }

  Future<File> getImage(
      String tableBase, String imgName, int maxdim, bool thumbnail) async {
    if (useLoc) return locClnt.getImage(tableBase, imgName, maxdim, thumbnail);
    return dbClnt.getImage(tableBase, imgName, maxdim, thumbnail);
  }
}
