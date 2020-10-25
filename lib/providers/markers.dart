import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong/latlong.dart' as ll;
import 'package:locations/utils/db.dart';
import 'package:locations/utils/utils.dart';

class Markers extends ChangeNotifier {
  Map<String, dynamic> _markers = {};
  static final colors = [Colors.red, Colors.yellow, Colors.green];
  static int stellen;
  static bool useGoogle;
  Function onTappedG;

  Future<void> readMarkers(
      int astellen, bool auseGoogle, Function aonTappedG) async {
    _markers = {};
    stellen = astellen;
    useGoogle = auseGoogle;
    onTappedG = aonTappedG;
    List<Coord> coords = await LocationsDB.readCoords();
    coords.forEach((coord) {
      add(_markers, coord);
    });
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
    // return _markers.values.toList();
    final mlist = List<fm.Marker>();
    for (fm.Marker m in _markers.values) {
      mlist.add(m);
    }
    return mlist;
  }

  Set<gm.Marker> markersG() {
    // return _markers.values.toSet();
    final mset = Set<gm.Marker>();
    for (gm.Marker m in _markers.values) {
      mset.add(m);
    }
    return mset;
  }

  void deleteLoc(double lat, double lon) {
    String latRound = roundDS(lat, stellen);
    String lonRound = roundDS(lon, stellen);
    String key = "$latRound:$lonRound";
    _markers.remove(key);
    notifyListeners();
  }

  int length() {
    return _markers.length;
  }
}
