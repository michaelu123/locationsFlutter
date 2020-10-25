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

  Future<void> setConfigValueS(String key, String type, String val) async {
    if (type == "int") prefs.setInt(key, int.parse(val));
    if (type == "string") prefs.setString(key, val);
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
    notifyListeners();
  }

  List _settingsJS = [
    {
      'type': 'string',
      'title': 'Nickname',
      'desc': 'Benutzername/Spitzname',
      'key': 'nickname',
    },
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
      'title': 'Karte OSM (o) oder Google Maps (g)',
      'desc': 'Wollen Sie OpenStreetMap (o) oder Google Maps (g) benutzen?',
      'key': 'usegooglemaps',
    },
  ];

  List settingsJS() {
    return _settingsJS;
  }

  Map _configDefaults = {
    'nickname': '',
    'maxdim': 1024,
    'thumbnaildim': 200,
    'delta': 5,
    'servername': "locationsserver.feste-ip.net",
    'serverport': 39885,
    'usegooglemaps': "o",
  };

  Map configDefaults() {
    return _configDefaults;
  }
}
