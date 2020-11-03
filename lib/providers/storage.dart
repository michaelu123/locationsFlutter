import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:locations/providers/locations_client.dart';

import 'firebase.dart';

class Storage extends ChangeNotifier {
  bool useLoc = true;
  LocationsClient locClnt;
  FirebaseClient fbClnt;

  void setClnt(String clnt) {
    useLoc = clnt == "LocationsServer";
    if (locClnt == null) locClnt = LocationsClient();
    if (fbClnt == null) fbClnt = FirebaseClient();
  }

  void init(
      {String serverUrl,
      String extPath,
      List datenFelder,
      List zusatzFelder,
      List imagesFelder}) {
    locClnt.init(serverUrl, extPath);
    fbClnt.init(extPath);
    fbClnt.initFelder(datenFelder, zusatzFelder, imagesFelder);
  }

  void initFelder({List datenFelder, List zusatzFelder, List imagesFelder}) {
    fbClnt.initFelder(datenFelder, zusatzFelder, imagesFelder);
  }

  Future<void> sayHello(String tableBase) async {
    if (useLoc) return locClnt.sayHello(tableBase);
    return fbClnt.sayHello(tableBase);
  }

  Future<Map> postImage(String tableBase, String imgName) async {
    if (useLoc) return locClnt.postImage(tableBase, imgName);
    return fbClnt.postImage(tableBase, imgName);
  }

  Future<void> post(String tableBase, Map values) async {
    if (useLoc) return locClnt.post(tableBase, values);
    return fbClnt.post(tableBase, values);
  }

  Future<Map> getValuesWithin(String tableBase, double minlat, double maxlat,
      double minlon, double maxlon) async {
    if (useLoc)
      return locClnt.getValuesWithin(tableBase, minlat, maxlat, minlon, maxlon);
    return fbClnt.getValuesWithin(tableBase, minlat, maxlat, minlon, maxlon);
  }

  Future<File> getImage(
      String tableBase, String imgName, int maxdim, bool thumbnail) async {
    // res[0] = imgFile, res[1] = notify, because thumbnail can be replaced
    // with full res image
    List res;
    if (useLoc) {
      res = await locClnt.getImage(tableBase, imgName, maxdim, thumbnail);
    } else {
      res = await fbClnt.getImage(tableBase, imgName, maxdim, thumbnail);
    }
    if (res[1]) {
      notifyListeners(); // changed from thumbnail to full image
    }
    return res[0];
  }

  Future<void> copyLoc2Fb(String tableBase, int maxdim) async {
    Map values = await locClnt.getValuesWithin(tableBase, -90, 90, -180, 180);
    // Map values = await locClnt.getValuesWithin(
    //    tableBase, 48.0808, 48.0809, 11.5270, 11.5275);
    final imageList = values["images"];
    for (final imageRow in imageList) {
      String imgName = imageRow[6];
      List lcres = await locClnt.getImage(tableBase, imgName, maxdim, false);
      File imgFile = lcres[0];
      if (imgFile == null) continue;
      Map res = await fbClnt.postImage(tableBase, imgName);
      String url = res["url"];
      imageRow[7] = url;
    }
    fbClnt.postRows(tableBase, values);
    print("copyLoc2Fb done");
  }
}
