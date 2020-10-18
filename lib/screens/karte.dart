import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:locations/providers/photos.dart';
import 'package:locations/utils/db.dart';
import 'package:locations/providers/map_center.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/providers/settings.dart';
//import 'package:locations/screens/account.dart';
//import 'package:locations/screens/bilder.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/splash_screen.dart';
//import 'package:locations/screens/zusatz.dart';
import 'package:locations/utils/felder.dart';
import 'package:locations/providers/locations_client.dart';
import 'package:locations/widgets/app_config.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/widgets/crosshair.dart';
// import 'package:locations/widgets/markers.dart';
import 'package:provider/provider.dart';

class KartenScreen extends StatefulWidget {
  static String routeName = "/karte";
  @override
  _KartenScreenState createState() => _KartenScreenState();
}

class _KartenScreenState extends State<KartenScreen> with Felder {
  double mapLat = 0, mapLon = 0;
  final mapController = MapController();
  Future markersFuture;
  LatLng center;
  String base;

  @override
  void initState() {
    super.initState();
    final baseConfigNL = Provider.of<BaseConfig>(context, listen: false);
    final markersNL = Provider.of<Markers>(context, listen: false);
    final settingsNL = Provider.of<Settings>(context, listen: false);
    markersFuture = markersNL.readMarkers(baseConfigNL.stellen());
    center = getCenter(baseConfigNL, settingsNL);
  }

  LatLng getCenter(
    BaseConfig baseConfig,
    Settings settings,
  ) {
    if (base == baseConfig.base) return center;
    final configGPS = baseConfig.getGPS();

    LatLng c = LocationsDB.lat == null
        ? LatLng(
            settings.getConfigValue(
              "center_lat_${baseConfig.base}",
              defVal: configGPS["center_lat"],
            ),
            settings.getConfigValue(
              "center_lon_${baseConfig.base}",
              defVal: configGPS["center_lon"],
            ),
          )
        : LatLng(
            // use this if coming back from Daten/Zusatz
            LocationsDB.lat,
            LocationsDB.lon,
          );
    base = baseConfig.base;
    center = c;
    return c;
  }

  // strange that FlutterMap does not have Marker.onTap...
  // see flutter_map_marker_popup for more elaborated code.
  void onTapped(
      List<Marker> markers, LatLng latlng, LocData locData, int stellen) {
    double nearestLat = 0;
    double nearestLon = 0;
    double nearestDist = double.maxFinite;
    markers.forEach((m) {
      final dlat = (m.point.latitude - latlng.latitude);
      final dlon = (m.point.longitude - latlng.longitude);
      final dist = sqrt(dlat * dlat + dlon * dlon);
      if (dist < nearestDist) {
        nearestLat = m.point.latitude;
        nearestLon = m.point.longitude;
        nearestDist = dist;
      }
    });
    double zoom = mapController.zoom;
    // for zoom 19, I think 0.0001 is a good minimum distance
    // if the zoom goes down by 1, the distance halves.
    // 19:1 18:2 17:4 16:8...
    nearestDist = nearestDist / pow(2, 19 - zoom);
    // print("onTapped $zoom, $nearestDist $nearestLat $nearestLon");
    if (nearestDist < 0.0001) {
      mapController.move(LatLng(nearestLat, nearestLon), mapController.zoom);
      Future.delayed(const Duration(milliseconds: 500), () async {
        final map = await LocationsDB.dataFor(mapLat, mapLon, stellen);
        locData.dataFor("daten", map);
        Navigator.of(context).pushNamed(DatenScreen.routeName);
      });
    }
  }

  void deleteLoc(Markers markers) {
    LocationsDB.deleteAllLoc(mapLat, mapLon);
    markers.deleteLoc(mapLat, mapLon);
    // LocationsServer.deleteLoc(mapLat, mapLon);
  }

  Future<void> getDataFromServer(
      LocationsClient locClnt, String tableName, int delta) async {
    double f = delta / 1000;
    // await LocationsDB.deleteAll();
    Map values = await locClnt.getValuesWithin(
      tableName,
      mapLat - f,
      mapLat + f,
      mapLon - 2 * f,
      mapLon + 2 * f,
    );
    await LocationsDB.fillWithDBValues(values);
  }

  Future<void> laden(
      Settings settings, LocationsClient locClnt, BaseConfig baseConfig) async {
    await LocationsDB.deleteDB();
    await Provider.of<Photos>(context, listen: false).deleteAllImages(
      baseConfig.getDbTableBaseName(),
    );
    settings.setConfigValue("center_lat_${baseConfig.base}", mapLat);
    settings.setConfigValue("center_lon_${baseConfig.base}", mapLon);
    await getDataFromServer(
      locClnt,
      baseConfig.getDbTableBaseName(),
      settings.getConfigValueI("delta"),
    );
    await Provider.of<Markers>(context, listen: false)
        .readMarkers(baseConfig.stellen());
  }

  Future<bool> _XXonBackPressed() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Sicher?'),
            content: new Text('Wollen Sie die App verlassen?'),
            actions: <Widget>[
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Text("Nein"),
              ),
              SizedBox(width: 30),
              new GestureDetector(
                onTap: () => Navigator.of(context).pop(true),
                child: Text("Ja"),
              ),
              SizedBox(width: 30),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _onBackPressed() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: new Text('Sicher?'),
            content: new Text('Wollen Sie die App verlassen?'),
            actions: <Widget>[
              FlatButton(
                child: Text("Nein"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              FlatButton(
                child: Text("Ja"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context, listen: false);
    final mapCenterNL = Provider.of<MapCenter>(context, listen: false);
    final locClntNL = Provider.of<LocationsClient>(context, listen: false);
    final locDataNL = Provider.of<LocData>(context, listen: false);
    final settingsNL = Provider.of<Settings>(context, listen: false);
    final markersNL = Provider.of<Markers>(context, listen: false);
    final configGPS = baseConfig.getGPS();
    // locClnt.sayHello(baseConfig.getDbTableBaseName());

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        drawer: AppConfig(),
        appBar: AppBar(
          title: Text(baseConfig.getName() + "/Karte"),
          actions: [
            // IconButton(
            //   icon: Icon(Icons.account_box),
            //   onPressed: () {
            //     Navigator.of(context).pushNamed(AccountScreen.routeName);
            //   },
            // ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => deleteLoc(markersNL),
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
              onSelected: (String selectedValue) async {
                if (baseConfig.setBase(selectedValue)) {
                  locDataNL.clearLocData();
                  settingsNL.setConfigValue("base", selectedValue);
                  await LocationsDB.setBaseDB(baseConfig);
                  await markersNL.readMarkers(baseConfig.stellen());
                  Navigator.of(context).popAndPushNamed(KartenScreen.routeName);
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
                    final map = await LocationsDB.dataFor(
                        mapLat, mapLon, baseConfig.stellen());
                    locDataNL.dataFor("daten", map);
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
                    await laden(settingsNL, locClntNL, baseConfig);
                  },
                  child: Text(
                    'Laden',
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () {},
                  child: Text(
                    'Speichern',
                  ),
                ),
                // if (baseConfig.hasZusatz())
                //   TextButton(
                //     style: TextButton.styleFrom(
                //       backgroundColor: Colors.amber,
                //     ),
                //     onPressed: () async {
                //       final map = await LocationsDB.dataFor(
                //           mapLat, mapLon, baseConfig.stellen());
                //       locDataNL.dataFor("zusatz", map);
                //       Navigator.of(context).pushNamed(ZusatzScreen.routeName);
                //     },
                //     child: Text(
                //       'Zusatzdaten',
                //     ),
                //   ),
                // TextButton(
                //   style: TextButton.styleFrom(
                //     backgroundColor: Colors.amber,
                //   ),
                //   onPressed: () async {
                //     final map = await LocationsDB.dataFor(
                //         mapLat, mapLon, baseConfig.stellen());
                //     locDataNL.dataFor("images", map);

                //     Navigator.of(context).pushNamed(ImagesScreen.routeName);
                //   },
                //   child: Text(
                //     'Bilder',
                //   ),
                // ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    final locationData = await Location().getLocation();
                    mapController.move(
                        LatLng(locationData.latitude, locationData.longitude),
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
                  FutureBuilder(
                    future: markersFuture,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return SplashScreen();
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            "error ${snap.error}",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        );
                      }

                      return Consumer<Markers>(
                        builder: (_, markers, __) {
                          return Stack(
                            children: [
                              FlutterMap(
                                mapController: mapController,
                                options: MapOptions(
                                  center: getCenter(baseConfig, settingsNL),
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
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      mapCenterNL.setCenter(pos.center);
                                      setState(() {
                                        // for the Text at the bottom of the screen
                                        mapLat = pos.center.latitude;
                                        mapLon = pos.center.longitude;
                                      });
                                    });
                                  },
                                  plugins: [
                                    CrossHairMapPlugin(),
                                  ],
                                  zoom: 16.0,
                                  minZoom: configGPS["min_zoom"] * 1.0,
                                  maxZoom: 19,
                                  onTap: (latlng) {
                                    onTapped(
                                      markers.markers(),
                                      latlng,
                                      locDataNL,
                                      baseConfig.stellen(),
                                    );
                                  },
                                ),
                                layers: [
                                  TileLayerOptions(
                                      minZoom: configGPS["min_zoom"] * 1.0,
                                      maxZoom: 19,
                                      urlTemplate:
                                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                      subdomains: ['a', 'b', 'c']),
                                  MarkerLayerOptions(
                                    markers: markers.markers(),
                                  ),
                                  CrossHairLayerOptions(
                                    crossHair: CrossHair(
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              if (markers.markers().length == 0)
                                Center(
                                  child: Text(
                                    "Noch keine Marker vorhanden",
                                    style: TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
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
      ),
    );
  }
}
