import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';

class MapCenter extends ChangeNotifier {
  LatLng center = LatLng(0, 0);

  void setCenter(LatLng latLng) {
    if (latLng == center) return;
    center = latLng;
    notifyListeners();
  }

  String toString() {
    return "${center.latitude} ${center.longitude}";
  }

  LatLng latLng(String x) {
    return center;
  }
}
