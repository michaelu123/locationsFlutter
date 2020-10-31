import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong/latlong.dart' as ll;
import 'package:locations/utils/db.dart';
import 'package:locations/utils/utils.dart';

class Markers extends ChangeNotifier {
  Map<String, dynamic> _markers = {};
  List<fm.Marker> fmList;
  Set<gm.Marker> gmSet;
  bool changedF, changedG;
  int stellen;
  bool useGoogle;
  Function onTappedG;
  List<gm.BitmapDescriptor> gmIcons;

  final colors = [Colors.red, Colors.yellow, Colors.green];

  Future<void> readMarkers(
      int stellen, bool useGoogle, Function onTappedG) async {
    if (gmIcons == null) {
      await createGmIcons();
    }
    _markers = {};
    this.stellen = stellen;
    this.useGoogle = useGoogle;
    this.onTappedG = onTappedG;
    List<Coord> coords = await LocationsDB.readCoords();
    coords.forEach((coord) {
      add(_markers, coord);
    });
    changedF = true;
    changedG = true;
    notifyListeners();
  }

  fm.Marker coord2MarkerF(Coord coord) {
    final color = colors[coord.quality];
    return fm.Marker(
      anchorPos: fm.AnchorPos.align(fm.AnchorAlign.top),
      width: 40.0,
      height: 36.0,
      point: ll.LatLng(coord.lat, coord.lon),
      builder: (ctx) => Icon(
        coord.hasImage ? Icons.location_on_outlined : Icons.location_on,
        color: color,
        size: 40,
      ),
    );
  }

  gm.Marker coord2MarkerG(Coord coord) {
    // final color = colors[coord.quality];
    return gm.Marker(
      icon: iconFor(coord.quality, coord.hasImage),
      markerId: gm.MarkerId("${coord.lat}:${coord.lon}"),
      consumeTapEvents: false,
      onTap: () {
        onTappedG(coord.lat, coord.lon);
      },
      // anchor: const Offset(0.5, 1.0),
      // icon: gm.BitmapDescriptor.defaultMarker,
      position: gm.LatLng(coord.lat, coord.lon),
    );
  }

  void current(Coord coord) {
    add(_markers, coord);
    changedF = true;
    changedG = true;
    notifyListeners();
  }

  void add(Map map, Coord coord) {
    final m = useGoogle ? coord2MarkerG(coord) : coord2MarkerF(coord);
    String latRound = roundDS(coord.lat, stellen);
    String lonRound = roundDS(coord.lon, stellen);
    String key = "$latRound:$lonRound";
    map[key] = m;
  }

  List<fm.Marker> markersF() {
    if (changedF) {
      fmList = List<fm.Marker>();
      for (fm.Marker m in _markers.values) {
        fmList.add(m);
      }
    }
    changedF = false;
    return fmList;
  }

  Set<gm.Marker> markersG() {
    if (changedG) {
      gmSet = Set<gm.Marker>();
      for (gm.Marker m in _markers.values) {
        gmSet.add(m);
      }
    }
    changedG = false;
    return gmSet;
  }

  void deleteLoc(double lat, double lon) {
    String latRound = roundDS(lat, stellen);
    String lonRound = roundDS(lon, stellen);
    String key = "$latRound:$lonRound";
    _markers.remove(key);
    changedF = true;
    changedG = true;
    notifyListeners();
  }

  int length() {
    return _markers.length;
  }

  gm.BitmapDescriptor iconFor(int quality, bool hasImage) {
    return gmIcons[(hasImage ? 3 : 0) + quality];
  }

  Future<void> createGmIcons() async {
    final names = [
      "red48.png",
      "yellow48.png",
      "green48.png",
      "red_plus48.png",
      "yellow_plus48.png",
      "green_plus48.png",
    ];
    gmIcons = List<gm.BitmapDescriptor>(6);
    for (int i = 0; i < 6; i++) {
      // this crashes with "failed to decode image. the provided image must be a bitmap"
      // gmIcons[i] = await gm.BitmapDescriptor.fromAssetImage(
      //   ImageConfiguration(size: Size(48, 48)),
      //   "assets/icons/" + names[i],

      // https://stackoverflow.com/questions/60111721/flutter-failed-to-decode-image-the-provided-image-must-be-a-bitmap-null
      ByteData data = await rootBundle.load("assets/icons/" + names[i]);
      ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
          targetWidth: 96);
      ui.FrameInfo fi = await codec.getNextFrame();
      final bytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))
          .buffer
          .asUint8List();
      gmIcons[i] = gm.BitmapDescriptor.fromBytes(bytes);
    }
  }
}
