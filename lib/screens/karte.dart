import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong/latlong.dart' as ll;
import 'package:location/location.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/providers/photos.dart';
import 'package:locations/providers/settings.dart';
import 'package:locations/providers/storage.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/splash_screen.dart';
import 'package:locations/utils/db.dart';
import 'package:locations/utils/felder.dart';
import 'package:locations/widgets/app_config.dart';
import 'package:locations/widgets/crosshair.dart';
import 'package:provider/provider.dart';

ll.LatLng g2m(gm.LatLng a) {
  return ll.LatLng(a.latitude, a.longitude);
}

gm.LatLng m2g(ll.LatLng a) {
  return gm.LatLng(a.latitude, a.longitude);
}

class KartenScreen extends StatefulWidget {
  static String routeName = "/karte";
  @override
  _KartenScreenState createState() => _KartenScreenState();
}

class _KartenScreenState extends State<KartenScreen> with Felder {
  double mapLat = 0, mapLon = 0;
  final fmapController = fm.MapController();
  gm.GoogleMapController gmapController;
  Future markersFuture;
  ll.LatLng center;
  String base;
  String message;
  bool useGoogle = true;

  BaseConfig baseConfigNL;
  Markers markersNL;
  Settings settingsNL;
  Storage strgClntNL;
  LocData locDataNL;

  @override
  void initState() {
    super.initState();
    baseConfigNL = Provider.of<BaseConfig>(context, listen: false);
    markersNL = Provider.of<Markers>(context, listen: false);
    settingsNL = Provider.of<Settings>(context, listen: false);
    strgClntNL = Provider.of<Storage>(context, listen: false);
    locDataNL = Provider.of<LocData>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
    if (gmapController != null) gmapController.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    useGoogle =
        settingsNL.getConfigValueS("mapprovider", defVal: "OpenStreetMap")[0] ==
            "G";
    markersFuture =
        markersNL.readMarkers(baseConfigNL.stellen(), useGoogle, onTappedG);
    center = getCenter(baseConfigNL, settingsNL);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // for the Text at the bottom of the screen
        mapLat = center.latitude;
        mapLon = center.longitude;
      });
    });
  }

  void setState2() {
    setState(() {});
  }

  ll.LatLng getCenter(
    BaseConfig baseConfig,
    Settings settings,
  ) {
    if (base == baseConfig.base) return center;
    final configGPS = baseConfig.getGPS();
    final configLat = configGPS["center_lat"];
    final configLon = configGPS["center_lon"];
    final configMinLat = configGPS["min_lat"];
    final configMinLon = configGPS["min_lon"];
    final configMaxLat = configGPS["max_lat"];
    final configMaxLon = configGPS["max_lon"];

    ll.LatLng c = LocationsDB.lat == null
        ? ll.LatLng(
            settings.getConfigValue(
              "center_lat_${baseConfig.base}",
              defVal: configLat,
            ),
            settings.getConfigValue(
              "center_lon_${baseConfig.base}",
              defVal: configLon,
            ),
          )
        : ll.LatLng(
            // use this if coming back from Daten/Zusatz
            LocationsDB.lat,
            LocationsDB.lon,
          );
    // last rescue
    if (c.latitude < configMinLat || c.latitude > configMaxLat)
      c.latitude = (configMinLat + configMaxLat) / 2;
    if (c.longitude < configMinLon || c.longitude > configMaxLon)
      c.longitude = (configMinLon + configMaxLon) / 2;
    base = baseConfig.base;
    center = c;
    return c;
  }

  // strange that FlutterMap does not have Marker.onTap...
  // see flutter_map_marker_popup for more elaborated code.

  void onTappedF(
      List<fm.Marker> markers, ll.LatLng latlng, LocData locData, int stellen) {
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
      if (dist < nearestDist) {
        nearestLat = m.point.latitude;
        nearestLon = m.point.longitude;
        nearestDist = dist;
      }
    });
    double zoom = fmapController.zoom;
    // for zoom 19, I think 0.0001 is a good minimum distance
    // if the zoom goes down by 1, the distance halves.
    // 19:1 18:2 17:4 16:8...
    nearestDist = nearestDist / pow(2, 19 - zoom);
    if (nearestDist > 0.0001) return;
    fmapController.move(ll.LatLng(nearestLat, nearestLon), fmapController.zoom);
    Future.delayed(const Duration(milliseconds: 500), () async {
      final map = await LocationsDB.dataFor(nearestLat, nearestLon, stellen);
      locData.dataFor("daten", map);
      Navigator.of(context).pushNamed(DatenScreen.routeName);
    });
  }

  // on Google, the Markers handle onTap
  Future<void> onTappedG(double lat, double lon) async {
    Future.delayed(const Duration(milliseconds: 500), () async {
      final map = await LocationsDB.dataFor(lat, lon, baseConfigNL.stellen());
      locDataNL.dataFor("daten", map);
      Navigator.of(context).pushNamed(DatenScreen.routeName);
    });
  }

  void move(double lat, double lon) {
    if (useGoogle) {
      final gmll = gm.LatLng(lat, lon);
      gmapController.moveCamera(
        gm.CameraUpdate.newLatLng(gmll),
      );
      // moveCamera does not trigger onCameraMove callback
      // for the Text at the bottom of the screen
      setState(() {
        mapLat = gmll.latitude;
        mapLon = gmll.longitude;
      });
    } else {
      fmapController.move(ll.LatLng(lat, lon), fmapController.zoom);
    }
  }

  void deleteLoc(Markers markers) {
    LocationsDB.deleteAllLoc(mapLat, mapLon);
    markers.deleteLoc(mapLat, mapLon);
    setState2();
  }

  Future<void> getDataFromServer(
      Storage strgClnt, String tableName, int delta) async {
    double f = delta / 1000;
    // await LocationsDB.deleteAll();
    Map values = await strgClnt.getValuesWithin(
      tableName,
      mapLat - f,
      mapLat + f,
      mapLon - 2 * f,
      mapLon + 2 * f,
    );
    await LocationsDB.fillWithDBValues(values);
  }

  Future<void> laden(
      Settings settings, Storage strgClnt, BaseConfig baseConfig) async {
    if (message != null) return;
    try {
      setState(() => message = "Lösche alte Daten");
      await LocationsDB.deleteOldData();
      Set newImagePaths = await LocationsDB.getNewImagePaths();
      setState(() => message = "Lösche alte Photos");
      await Provider.of<Photos>(context, listen: false).deleteAllImagesExcept(
          baseConfig.getDbTableBaseName(), newImagePaths);
      settings.setConfigValue("center_lat_${baseConfig.base}", mapLat);
      settings.setConfigValue("center_lon_${baseConfig.base}", mapLon);
      setState(() => message = "Lade neue Daten");
      await getDataFromServer(
        strgClnt,
        baseConfig.getDbTableBaseName(),
        settings.getConfigValueI("delta"),
      );
      setState(() => message = "Lade MapMarker");
      await markersNL.readMarkers(baseConfig.stellen(), useGoogle, onTappedG);
    } finally {
      setState(() => message = null);
    }
  }

  Future<void> speichern(
      Settings settings, Storage strgClnt, BaseConfig baseConfig) async {
    if (message != null) return;
    try {
      final nickName = settings.getConfigValueS("nickname");
      setState(() => message = "Neue/geänderte Daten bestimmen");
      final Map newData = await LocationsDB.getNewData();
      final String tableBase = baseConfig.getDbTableBaseName();
      final newImages = newData["images"];
      final newImagesLen = newImages.length;
      int i = 0;
      for (final img in newImages) {
        final String imagePath = img["image_path"];
        i += 1;
        setState(() => message = "Bild $i von $newImagesLen");
        final Map map = await strgClnt.postImage(tableBase, imagePath);
        final String url = map["url"];
        await LocationsDB.updateImagesDB(imagePath, "image_url", url, nickName);
        img["image_url"] = url;
      }
      setState(() => message = "Neue/geänderte Daten speichern");
      await strgClnt.post(tableBase, newData);
      await LocationsDB.clearNewOrModified();
    } finally {
      setState(() => message = null);
    }
  }

  Future<bool> _onBackPressed() {
    return showDialog(
          context: context,
          builder: (context) => new AlertDialog(
            title: const Text('Sicher?'),
            content: const Text('Wollen Sie die App verlassen?'),
            actions: <Widget>[
              FlatButton(
                child: const Text("Nein"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              FlatButton(
                child: const Text("Ja"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // strgClnt.sayHello(baseConfig.getDbTableBaseName());
    final settings = Provider.of<Settings>(context);
    strgClntNL.setClnt(
        settings.getConfigValueS("storage", defVal: "LocationsServer"));

    final configGPS = baseConfigNL.getGPS();
    useGoogle =
        settings.getConfigValueS("mapprovider", defVal: "OpenStreetMap")[0] ==
            "G";

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        drawer: AppConfig(),
        appBar: AppBar(
          title: Text(baseConfigNL.getName() + "/Karte"),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteLoc(markersNL),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              // child: Text('Auswahl der Datenbasis'),
              itemBuilder: (_) {
                final List keys = baseConfigNL.getNames();
                return List.generate(
                  keys.length,
                  (index) => PopupMenuItem(
                    child: Text(keys[index]),
                    value: keys[index] as String,
                  ),
                );
              },
              onSelected: (String selectedValue) async {
                if (baseConfigNL.setBase(selectedValue)) {
                  locDataNL.clearLocData();
                  settingsNL.setConfigValueS("base", "string", selectedValue);
                  await LocationsDB.setBaseDB(baseConfigNL);
                  await markersNL.readMarkers(
                      baseConfigNL.stellen(), useGoogle, onTappedG);
                  strgClntNL.initFelder(
                    datenFelder: baseConfigNL.getDbDatenFelder(),
                    zusatzFelder: baseConfigNL.getDbZusatzFelder(),
                    imagesFelder: baseConfigNL.getDbImagesFelder(),
                  );
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
                        mapLat, mapLon, baseConfigNL.stellen());
                    locDataNL.dataFor("daten", map);
                    Navigator.of(context).pushNamed(DatenScreen.routeName);
                  },
                  child: const Text(
                    'Daten',
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    await laden(settingsNL, strgClntNL, baseConfigNL);
                  },
                  child: const Text(
                    'Laden',
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    await speichern(settingsNL, strgClntNL, baseConfigNL);
                  },
                  child: const Text(
                    'Speichern',
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    final locationData = await Location().getLocation();
                    move(locationData.latitude, locationData.longitude);
                  },
                  child: const Text(
                    'GPS Fix',
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    move(configGPS["center_lat"], configGPS["center_lon"]);
                  },
                  child: const Text(
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
                            style: const TextStyle(
                              backgroundColor: Colors.white,
                              color: Colors.black,
                              fontSize: 20,
                            ),
                          ),
                        );
                      }
                      return Consumer<Markers>(
                        builder: (_, markers, __) {
                          return CustomPaint(
                            foregroundPainter: CrossHairPainter(),
                            child: Stack(
                              children: [
                                useGoogle
                                    ? MyGoogleMap(this, markers.markersG())
                                    : OsmMap(this, markers.markersF()),
                                if (markers.length() == 0)
                                  Center(
                                    child: const Text(
                                      "Noch keine Marker vorhanden",
                                      style: TextStyle(
                                        backgroundColor: Colors.white,
                                        color: Colors.black,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  if (message != null)
                    Center(
                      child: Card(
                        margin: EdgeInsets.all(50),
                        child: Text(
                          message,
                          style: const TextStyle(
                            backgroundColor: Colors.white,
                            color: Colors.black,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                  if (!useGoogle)
                    const Positioned(
                      child: const Text("© OpenStreetMap-Mitwirkende"),
                      bottom: 10,
                      left: 10,
                    ),
                  Positioned(
                    child: Text(
                      "${mapLat.toStringAsFixed(6)} ${mapLon.toStringAsFixed(6)}",
                      style: TextStyle(backgroundColor: Colors.white),
                    ),
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

class OsmMap extends StatelessWidget {
  final _KartenScreenState state;
  final List<fm.Marker> markers;
  const OsmMap(this.state, this.markers);
  @override
  Widget build(BuildContext context) {
    final configGPS = state.baseConfigNL.getGPS();

    return fm.FlutterMap(
      mapController: state.fmapController,
      options: fm.MapOptions(
        center: state.getCenter(state.baseConfigNL, state.settingsNL),
        swPanBoundary: ll.LatLng(
          configGPS["min_lat"],
          configGPS["min_lon"],
        ), // LatLng(48.0, 11.4),
        nePanBoundary: ll.LatLng(
          configGPS["max_lat"],
          configGPS["max_lon"],
        ), // LatLng(48.25, 11.8),
        onPositionChanged: (pos, b) {
          // onPositionChanged is called too early during build, must defer
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // for the Text at the bottom of the screen
            state.mapLat = pos.center.latitude;
            state.mapLon = pos.center.longitude;
            state.setState2();
          });
        },
        zoom: 16.0,
        minZoom: configGPS["min_zoom"] * 1.0,
        maxZoom: 19,
        onTap: (latlng) {
          state.onTappedF(
            markers,
            latlng,
            state.locDataNL,
            state.baseConfigNL.stellen(),
          );
        },
      ),
      layers: [
        fm.TileLayerOptions(
            minZoom: configGPS["min_zoom"] * 1.0,
            maxZoom: 19,
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c']),
        fm.MarkerLayerOptions(
          markers: markers,
        ),
      ],
    );
  }
}

class MyGoogleMap extends StatelessWidget {
  final _KartenScreenState state;
  final Set<gm.Marker> markers;
  const MyGoogleMap(this.state, this.markers);

  @override
  Widget build(BuildContext context) {
    final configGPS = state.baseConfigNL.getGPS();

    String mapTypeS = state.settingsNL.getConfigValueS("maptype");
    gm.MapType mt = gm.MapType.normal;
    switch (mapTypeS) {
      case 'Normal':
        mt = gm.MapType.normal;
        break;
      case 'Hybrid':
        mt = gm.MapType.hybrid;
        break;
      case 'Satellit':
        mt = gm.MapType.satellite;
        break;
      case 'Terrain':
        mt = gm.MapType.terrain;
        break;
    }

    return gm.GoogleMap(
      mapType: mt,
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        state.gmapController = controller;
      },
      zoomControlsEnabled: false,
      zoomGesturesEnabled: true,
      // onTap handled by each marker
      onCameraMove: (gm.CameraPosition pos) {
        // for the Text at the bottom of the screen
        state.mapLat = pos.target.latitude;
        state.mapLon = pos.target.longitude;
        state.setState2();
      },
      markers: markers,
      minMaxZoomPreference: gm.MinMaxZoomPreference(
        configGPS["min_zoom"] * 1.0,
        19,
      ),
      cameraTargetBounds: gm.CameraTargetBounds(gm.LatLngBounds(
        southwest: gm.LatLng(
          configGPS["min_lat"],
          configGPS["min_lon"],
        ),
        northeast: gm.LatLng(
          configGPS["max_lat"],
          configGPS["max_lon"],
        ),
      )),
      initialCameraPosition: gm.CameraPosition(
        target: m2g(
          state.getCenter(
            state.baseConfigNL,
            state.settingsNL,
          ),
        ),
        zoom: 16.0,
      ),
    );
  }
}
