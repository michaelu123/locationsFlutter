import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class LocationsClient extends ChangeNotifier {
  //"http://raspberrylan.1qgrvqjevtodmryr.myfritz.net:80/";
  static String serverUrl;
  static String extPath;

  void init(aserverUrl, aextPath) {
    extPath = aextPath;
    serverUrl = aserverUrl;
  }

  Future<dynamic> _req2(String method, String req,
      {Map headers, String body}) async {
    http.Response resp = await http.get(serverUrl + req, headers: headers);
    if (resp.statusCode >= 400) {
      // Map errbody = json.decode(resp.body);
      // String msg = errbody['error']['message'] ?? "Unknown error";
      // throw HttpException(msg);
      String errBody = resp.body;
      print("errbody $errBody");
      // throw HttpException(errBody);
      return null;
    }
    dynamic res = json.decode(resp.body);
    return res;
  }

  Future<dynamic> reqWithRetry(String method, String req,
      {Map headers, dynamic body}) async {
    dynamic res;
    try {
      res = await _req2(
        method,
        req,
        headers: headers,
        body: body,
      );
    } on HttpException catch (e) {
      print("http exc $e");
      res = await _req2(
        method,
        req,
        headers: headers,
        body: body,
      );
    }
    return res;
  }

  Future<Uint8List> _reqBytes(String req, {Map headers}) async {
    http.Response resp = await http.get(serverUrl + req, headers: headers);
    if (resp.statusCode >= 400) {
      print(
          "reqBytes code ${resp.statusCode} ${resp.reasonPhrase} ${resp.body}");
      return null;
    }
    return resp.bodyBytes;
  }

  Future<Uint8List> reqBytesWithRetry(String req, {Map headers}) async {
    Uint8List res;
    try {
      res = await _reqBytes(req, headers: headers);
    } on HttpException catch (e) {
      print("http exc $e");
      res = await _reqBytes(req, headers: headers);
    }
    return res;
  }

  Future<void> sayHello(String tableBase) async {
    String table = tableBase + "_daten";
    String req = "/tables";
    List res = await reqWithRetry("GET", req);
    for (String l in res) {
      if (l == table) return;
    }
    throw "Keine Tabelle $table auf dem LocationsServer gefunden";
  }

  Future<Map> imgPost(String tableBase, String imgName) async {
    String req = "/addimage/$tableBase/$imgName";
    final headers = {"Content-type": "image/jpeg"};

    final imgPath = path.join(extPath, tableBase, "images", imgName);
    File f = File(imgPath);
    final body = await f.readAsBytes();
    Map res = await reqWithRetry("POST", req, body: body, headers: headers);
    return res;
  }

  Future<Map> post(String table, dynamic valuesJS) async {
    String req = "/add/$table";
    String body = json.encode(valuesJS);
    Map headers = {"Content-type": "application/json"};
    Map res = await reqWithRetry("POST", req, body: body, headers: headers);
    return res;
  }

  Future<Map> getValuesWithin(String tableBase, double minlat, double maxlat,
      double minlon, double maxlon) async {
    final res = {};
    for (String table in ["daten", "zusatz", "images"]) {
      String req =
          "/region/${tableBase}_$table?minlat=$minlat&maxlat=$maxlat&minlon=$minlon&maxlon=$maxlon";
      List res2 = await reqWithRetry("GET", req);
      res[table] = res2;
    }
    return res;
  }

  Future<File> getImage(
      String tableBase, String imgName, int maxdim, bool thumbnail) async {
    String imgPath = path.join(extPath, tableBase, "images", imgName);
    File f = File(imgPath);
    if (await f.exists()) return f;
    if (thumbnail) {
      imgPath = path.join(extPath, tableBase, "images", "tn_" + imgName);
      f = File(imgPath);
      if (await f.exists()) return f;
    }
    final req = "/getimage/${tableBase}_images/$imgName?maxdim=$maxdim";
    final res = await reqBytesWithRetry(req);
    if (res == null) return null;
    await f.writeAsBytes(res, flush: true);
    if (!thumbnail) notifyListeners(); // changed from thumbnail to full image
    return f;
  }

  Future<void> uploadPhotos(photos) async {
    return null;
  }
}
