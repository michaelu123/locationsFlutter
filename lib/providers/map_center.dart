import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';

class MapCenter extends ChangeNotifier {
  MapCenter() {
    print("MapCenter constructor");
  }

  LatLng center = marienplatz();

  void setCenter(LatLng latLng) {
    if (latLng == center) return;
    center = latLng;
    // print("setCenter $this");
    notifyListeners();
  }

  String toString() {
    return "${center.latitude} ${center.longitude}";
  }

  LatLng latLng(String x) {
    // print("latLng $x $this");
    return center;
  }

  static LatLng marienplatz() {
    return LatLng(48.137235, 11.57554);
  }
}
