import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:locations/utils/db.dart';
import 'package:locations/utils/utils.dart';

class Markers extends ChangeNotifier {
  Map<String, Marker> _markers = {};
  static final colors = [Colors.red, Colors.yellow, Colors.green];
  static int stellen;

  Future<void> readMarkers(int astellen) async {
    print("1read");
    _markers = {};
    stellen = astellen;
    List<Coord> coords = await LocationsDB.readCoords();
    coords.forEach((coord) {
      add(_markers, coord);
    });
    notifyListeners();
    print("2read ${coords.length} ${_markers.length}");
  }

  Marker coord2Marker(Coord coord) {
    final color = colors[coord.quality];
    return Marker(
      anchorPos: AnchorPos.align(AnchorAlign.top),
      width: 40.0,
      height: 36.0,
      point: LatLng(coord.lat, coord.lon),
      builder: (ctx) => Icon(
        coord.hasImage ? Icons.location_on_outlined : Icons.location_on,
        color: color,
        size: 40,
      ),
    );
  }

  void current(Coord coord) {
    add(_markers, coord);
    notifyListeners();
  }

  void add(Map map, Coord coord) {
    final m = coord2Marker(coord);
    String latRound = roundDS(coord.lat, stellen);
    String lonRound = roundDS(coord.lon, stellen);
    String key = "$latRound:$lonRound";
    map[key] = m;
  }

  List<Marker> markers() {
    print("1markers ${_markers.values.length}");
    return _markers.values.toList();
  }

  void deleteLoc(double lat, double lon) {
    String latRound = roundDS(lat, stellen);
    String lonRound = roundDS(lon, stellen);
    String key = "$latRound:$lonRound";
    _markers.remove(key);
    notifyListeners();
  }
}
