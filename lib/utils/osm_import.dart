import 'dart:io';
import 'package:locations/providers/storage.dart';
import 'package:locations/utils/utils.dart';
import 'package:xml/xml.dart';

/*
bicyle_parking.xml obtained from URL http://overpass-turbo.eu/
move to Munich on the map

node
  [amenity=bicycle_parking]
  ({{bbox}});
out;

Store xml in bicyle_parking.xml
Then copy file (I used AirDroid, adb push did not work!?) to 
/sdcard/Android/data/de.adfcmuenchen.locations/files/osmdaten
*/

Map translate = {
  'addr:housenumber': '',
  'addr:postcode': '',
  'addr:street': 'ort',
  'anchors': 'Anker',
  'bicycle': '',
  'bicycle_parking': 'bemerkung', //'anlagentyp',
  'bollard': 'Poller',
  'building': 'Gebäude',
  'capacity': 'anzahl',
  'covered': 'geschützt',
  'description': 'bemerkung',
  'description:de': 'bemerkung',
  'front_wheel': 'Vorderradhalter',
  'front_wheel_only': 'Vorderradhalter',
  'ground_slots': 'Erdschlitze',
  'hooks': 'Haken',
  'informal': 'Informell',
  'loops': 'Wendel',
  'maxstay': '',
  'multi-storey_racks': 'Mehrstöckig',
  'multistorey': 'Mehrstöckig',
  'multi-storey': 'Mehrstöckig',
  'name': 'ort',
  'no': 0,
  'partial': 1,
  'note:total_capacity': '',
  'opening_hours': '',
  'rack': 'Träger',
  'scooter_parking': 'Scooter-Parkplatz',
  'shed': 'Schuppen',
  'shelter': 'geschützt',
  'source:capacity': '',
  'stands': 'Ständer',
  'surface': '',
  'tree': 'Baum',
  'wall_loops': 'Wandschlaufen',
  'wide_stands': 'BreiteStänder',
  'yes': 1,
};

class OsmImport {
  final String extPath;
  final Storage strgClnt;
  final int stellen;
  Map<String, dynamic> defVal;

  OsmImport(this.extPath, this.strgClnt, this.stellen, List datenFelder) {
    defVal = {};
    for (Map feld in datenFelder.sublist(7)) {
      // 7 = after lat_round
      defVal[feld["name"]] = null;
    }
    defVal.remove("new_or_modified");
  }
  // final attrMap = Map<String, Set<String>>();

  Future<void> osmImport() async {
    File f = File(extPath + "/osmdaten/bicycle_parking.xml");
    if (!(await f.exists())) return;
    final re1 = RegExp(r'[0-9]');
    final re2 = RegExp(r'[^0-9]');
    final valMap = Map<String, Map<String, dynamic>>();
    String d2000 = "2000.01.01 01:00:01";
    XmlDocument doc = XmlDocument.parse(await f.readAsString());
    for (XmlElement node in doc.findAllElements('node')) {
      double lat, lon;
      int anzahl;
      List<String> bemerkung = [];
      int geschuetzt;
      String ort;

      for (final attr in node.attributes) {
        switch (attr.name.toString()) {
          case "lat":
            lat = double.parse(attr.value);
            break;
          case "lon":
            lon = double.parse(attr.value);
            break;
        }
      }

      for (XmlNode child in node.children) {
        String k, v;
        for (final attr in child.attributes) {
          if (attr.name.toString() == "k") k = attr.value;
          if (attr.name.toString() == "v") v = attr.value;
        }
        if (k == null || v == null) continue;
        // Set<String> set = attrMap[k];
        // if (set == null) {
        //   set = Set<String>();
        //   attrMap[k] = set;
        // }
        // set.add(v);

        switch (k) {
          case "capacity": // may have values ~80, 10-15, >50 !!
            int x = v.indexOf(re1);
            if (x < 0) continue;
            int y = v.indexOf(re2, x + 1);
            if (y == -1) {
              anzahl = int.parse(v.substring(x));
            } else {
              anzahl = int.tryParse(v.substring(x, y));
            }
            break;
          case "covered":
            if (v == "yes") geschuetzt = 1;
            break;
          case "name":
            ort = v;
            break;
          case 'bicycle_parking':
          case "description":
          case "note":
          case "note:de":
            String t = translate[v] ?? v;
            if (t != null && t.isNotEmpty) bemerkung.add(t);
            break;
        }
      }

      String latRound = roundDS(lat, stellen);
      String lonRound = roundDS(lon, stellen);
      Map<String, dynamic> val = Map<String, dynamic>.from(defVal);
      val.addAll({
        "creator": "OSM",
        "created": d2000,
        "modified": d2000,
        "lat": lat,
        "lon": lon,
        "lat_round": latRound,
        "lon_round": lonRound,
      });

      if (bemerkung.length != 0) {
        val["bemerkung"] = bemerkung.join(",");
      }
      if (anzahl != null) {
        val["anzahl"] = anzahl;
      }
      if (geschuetzt != null) {
        val["geschützt"] = geschuetzt;
      }
      if (ort != null) {
        val["ort"] = ort;
      }
      // eliminate duplicates in bicycle_parking.xml
      valMap["$latRound:$lonRound"] = val;
    }
    await strgClnt.post("abstellanlagen", {
      "daten": valMap.values.toList(),
    });
    // print("attrMap");
    // for (String k in attrMap.keys) {
    //   print("$k: ${attrMap[k]}");
    // }
  }
}
