import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends ChangeNotifier {
  SharedPreferences prefs;

  Future<void> getSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  String initialBase() {
    return prefs.getString("base");
  }

  int getConfigValueI(String key) {
    try {
      final res = prefs.getInt(key);
      return res ?? _configDefaults[key];
    } catch (e) {
      return _configDefaults[key];
    }
  }

  String getConfigValueS(String key, {String defVal}) {
    try {
      final res = prefs.getString(key);
      if (res != null) return res;
    } catch (e) {}
    return defVal ?? _configDefaults[key];
  }

  dynamic getConfigValue(String key, {dynamic defVal}) {
    try {
      final res = prefs.get(key);
      if (res != null) return res;
    } catch (e) {}
    return defVal ?? _configDefaults[key];
  }

  Map getGPS() {
    double minLat = getConfigValue("south");
    double maxLat = getConfigValue("north");
    double minLon = getConfigValue("west");
    double maxLon = getConfigValue("east");
    if (minLat < -90.0) minLat = -90.0;
    if (maxLat > 90.0) maxLat = 90.0;
    if (minLon < -180.0) minLon = -180.0;
    if (maxLon > 180.0) maxLon = 180.0;
    if (minLat >= maxLat) {
      minLat = -90.0;
      maxLat = 90.0;
    }
    if (minLon >= maxLon) {
      minLon = -180.0;
      maxLon = 180.0;
    }
    final centerLat = (minLat + maxLat) / 2.0;
    final centerLon = (minLon + maxLon) / 2.0;
    return {
      "min_lat": minLat,
      "max_lat": maxLat,
      "min_lon": minLon,
      "max_lon": maxLon,
      "center_lat": centerLat,
      "center_lon": centerLon,
    };
  }

  Future<void> setConfigValueS(String key, String type, String val) async {
    if (type == "int") prefs.setInt(key, int.parse(val));
    if (type == "string") prefs.setString(key, val);
    if (type == "float") prefs.setDouble(key, double.parse(val));
    notifyListeners();
  }

  Future<void> setConfigValueF(String key, double val) async {
    prefs.setDouble(key, val);
    notifyListeners();
  }

  Future<void> setConfigValue(String key, dynamic val) async {
    if (val is int)
      prefs.setInt(key, val);
    else if (val is String)
      prefs.setString(key, val);
    else if (val is double)
      prefs.setDouble(key, val);
    else
      print("setConfigValue unimplemented type");
    // intentionally no notify
  }

  List _settingsJS = [
    {
      'type': 'int',
      'title': 'Max Dim',
      'desc': 'Max Größe der aufgenommenen Photos',
      'key': 'maxdim',
    },
    {
      'type': 'int',
      'title': 'Vorschaubilder Dim',
      'desc': 'Größe der Vorschaubilder',
      'key': 'thumbnaildim',
    },
    {
      'type': 'int',
      'title': 'Größe der MapMarker-Region',
      'desc': 'Größe der mit MapMarkern gefüllten Kartenfläche',
      'key': 'delta',
    },
    {
      'type': 'string',
      'title': 'Region/Gebiet',
      'desc': 'Name der Region/des Gebiets',
      'key': 'region',
    },
    {
      'type': 'float',
      'title': 'Südliche Grenze',
      'desc': 'Breitengrad Minimum der Karte',
      'key': 'south',
    },
    {
      'type': 'float',
      'title': 'Nördliche Grenze',
      'desc': 'Breitengrad Maximum der Karte',
      'key': 'north',
    },
    {
      'type': 'float',
      'title': 'Westliche Grenze',
      'desc': 'Längengrad Minimum der Karte',
      'key': 'west',
    },
    {
      'type': 'float',
      'title': 'Östliche Grenze',
      'desc': 'Längengrad Maximum der Karte',
      'key': 'east',
    },
    {
      'type': 'string',
      'title': 'Server Name',
      'desc': 'Name des LocationsServer',
      'key': 'servername',
    },
    {
      'type': 'int',
      'title': 'Server Portnummer',
      'desc': 'Portnummer des LocationsServer',
      'key': 'serverport',
    },
    {
      'type': 'string',
      'title': 'Benutzername',
      'desc': 'Name des Benutzers laut Anmeldung',
      'key': 'username',
    },
    {
      'type': 'choice',
      'title': 'Karten-Lieferant',
      'choices': ['OpenStreetMap', 'Google Maps'],
      'key': 'mapprovider',
    },
    {
      'type': 'choice',
      'title': 'Speichern auf',
      'choices': ['LocationsServer', 'Google Firebase'],
      'key': 'storage',
    },
    {
      'type': 'choice',
      'title': 'Google Maps Kartentyp',
      'choices': ['Normal', 'Hybrid', 'Satellit', 'Terrain'],
      'key': 'maptype',
    },
  ];

  List settingsJS() {
    return _settingsJS;
  }

  Map _configDefaults = {
    'maxdim': 1024,
    'thumbnaildim': 200,
    'delta': 5,
    'region': "",
    'servername': "locationsserver.feste-ip.net",
    'serverport': 52733,
    'username': '',
    'mapprovider': 'OpenStreetMap',
    'maptype': 'Normal',
    'storage': 'LocationsServer',
    'south': 48.0,
    'north': 48.25,
    'west': 11.4,
    'east': 11.8,
  };

  Map configDefaults() {
    return _configDefaults;
  }
}
