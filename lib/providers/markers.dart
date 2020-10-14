import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:locations/providers/db.dart';

class Markers extends ChangeNotifier {
  Map<String, Marker> _markers = {};
  static final colors = [Colors.red, Colors.yellow, Colors.green];
  static int stellen;

  Future<void> readMarkers(int astellen) async {
    stellen = astellen;
    List<Coord> coords = await LocationsDB.readCoords();
    coords.forEach((coord) {
      add(_markers, coord);
    });
    notifyListeners();
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
    final key =
        "${coord.lat.toStringAsFixed(stellen)}:${coord.lon.toStringAsFixed(stellen)}";
    map[key] = m;
  }

  List<Marker> markers() {
    return _markers.values.toList();
  }
}
