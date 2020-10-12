import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:locations/providers/db.dart';
import 'package:locations/providers/map_center.dart';
import 'package:locations/providers/settings.dart';
import 'package:locations/screens/account.dart';
import 'package:locations/screens/bilder.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/zusatz.dart';
import 'package:locations/utils/felder.dart';
import 'package:locations/widgets/app_config.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/widgets/crosshair.dart';
import 'package:provider/provider.dart';

class KartenScreen extends StatefulWidget {
  static String routeName = "/karte";
  @override
  _KartenScreenState createState() => _KartenScreenState();
}

class _KartenScreenState extends State<KartenScreen> with Felder {
  double mapLat = 0, mapLon = 0;
  final mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context);
    final configGPS = baseConfig.getGPS();
    final mapCenter = Provider.of<MapCenter>(context, listen: false);

    return Scaffold(
      drawer: AppConfig(),
      appBar: AppBar(
        title: Text(baseConfig.getName() + "/Karte"),
        actions: [
          IconButton(
            icon: Icon(Icons.account_box),
            onPressed: () {
              Navigator.of(context).pushNamed(AccountScreen.routeName);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: null,
          ),
          IconButton(
            icon: Icon(Icons.add_a_photo),
            onPressed: null,
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            // child: Text('Auswahl der Datenbasis'),
            itemBuilder: (_) {
              final List keys = baseConfig.getNames();
              return List.generate(
                keys.length,
                (index) => PopupMenuItem(
                  child: Text(keys[index]),
                  value: keys[index] as String,
                ),
              );
            },
            onSelected: (String selectedValue) {
              if (baseConfig.setBase(selectedValue)) {
                Provider.of<LocData>(context, listen: false).clearLocData();
                Provider.of<Settings>(context, listen: false)
                    .setConfigValue("base", selectedValue);
                LocationsDB.setBase(baseConfig);
                deleteFelder();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () async {
                  final locDaten = Provider.of<LocData>(context, listen: false);
                  final map = await LocationsDB.dataFor(
                      mapLat, mapLon, baseConfig.stellen());
                  locDaten.dataFor("daten", map);
                  Navigator.of(context).pushNamed(DatenScreen.routeName);
                },
                child: Text(
                  'Daten',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () async {
                  final locDaten = Provider.of<LocData>(context, listen: false);
                  final map = await LocationsDB.dataFor(
                      mapLat, mapLon, baseConfig.stellen());
                  locDaten.dataFor("zusatz", map);
                  Navigator.of(context).pushNamed(ZusatzScreen.routeName);
                },
                child: Text(
                  'Zusatzdaten',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(BilderScreen.routeName);
                },
                child: Text(
                  'Bilder',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () async {
                  final locData = await Location().getLocation();
                  mapController.move(
                      LatLng(locData.latitude, locData.longitude),
                      mapController.zoom);
                },
                child: Text(
                  'GPS Fix',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () {
                  mapController.move(
                      LatLng(
                        configGPS["center_lat"],
                        configGPS["center_lon"],
                      ),
                      mapController.zoom);
                  // final mapCenter =
                  //     Provider.of<MapCenter>(context, listen: false);
                  // mapCenter.setCenter(MapCenter.marienplatz());
                },
                child: Text(
                  'Zentrieren',
                ),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    swPanBoundary: LatLng(
                      configGPS["min_lat"],
                      configGPS["min_lon"],
                    ), // LatLng(48.0, 11.4),
                    nePanBoundary: LatLng(
                      configGPS["max_lat"],
                      configGPS["max_lon"],
                    ), // LatLng(48.25, 11.8),
                    onPositionChanged: (pos, b) {
                      // onPositionChanged is called too early during build, must defer
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        mapCenter.setCenter(pos.center);
                        setState(() {
                          // for the Text at the bottom of the screen
                          mapLat = pos.center.latitude;
                          mapLon = pos.center.longitude;
                        });
                      });
                    },
                    plugins: [CrossHairMapPlugin()],
                    center: LatLng(
                      configGPS["center_lat"],
                      configGPS["center_lon"],
                    ),
                    zoom: 16.0,
                    minZoom: configGPS["min_zoom"] * 1.0,
                    maxZoom: 19,
                  ),
                  layers: [
                    TileLayerOptions(
                        minZoom: configGPS["min_zoom"] * 1.0,
                        maxZoom: 19,
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c']),
                    MarkerLayerOptions(markers: [
                      Marker(
                        //anchorPos: AnchorPos.exactly(Anchor(0, 20)),
                        anchorPos: AnchorPos.align(AnchorAlign.top),
                        width: 30.0,
                        height: 30.0,
                        point: LatLng(48.137235, 11.57554),
                        builder: (ctx) => ImageIcon(
                          AssetImage("assets/icons/red_plus48.png"),
                          color: Colors.blue,
                        ),
                      ),
                    ]),
                    CrossHairLayerOptions(
                      crossHair: CrossHair(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const Positioned(
                  child: const Text("© OpenStreetMap-Mitwirkende"),
                  bottom: 10,
                  left: 10,
                ),
                Positioned(
                  child: Text(
                      "${mapLat.toStringAsFixed(6)} ${mapLon.toStringAsFixed(6)}"),
                  bottom: 10,
                  right: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
