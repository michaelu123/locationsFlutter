import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/storage.dart';
import 'package:locations/screens/account.dart';
import 'package:locations/screens/locaccount.dart';
import 'package:locations/utils/db.dart';
import 'package:locations/utils/syntax.dart';
import 'package:locations/utils/utils.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/providers/photos.dart';
import 'package:locations/providers/settings.dart';
import 'package:locations/screens/bilder.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/karte.dart';
import 'package:locations/screens/photo.dart';
import 'package:locations/screens/splash_screen.dart';
import 'package:locations/screens/zusatz.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // https://pub.dev/packages/flutter_app_lock  ?
  static bool useLoc = true;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (BuildContext context) => Settings(),
        ),
        ChangeNotifierProvider(
          create: (BuildContext context) => BaseConfig(),
        ),
        ChangeNotifierProvider(
          create: (BuildContext context) => LocData(),
        ),
        ChangeNotifierProvider(
          create: (BuildContext context) => Markers(),
        ),
        ChangeNotifierProvider(
          create: (BuildContext context) => Photos(),
        ),
        ChangeNotifierProvider(
          create: (BuildContext context) => Storage(),
        ),
        ChangeNotifierProvider(
          create: (BuildContext context) => IndexModel(),
        ),
        ChangeNotifierProvider(
          create: (BuildContext context) => MsgModel(),
        ),
      ],
      child: Consumer3<BaseConfig, Settings, Storage>(
        builder: (ctx, baseConfig, settings, strgClnt, _) {
          return MaterialApp(
            title: 'Locations',
            theme: ThemeData(
              // This is the theme of your application.
              //
              // Try running your application with "flutter run". You'll see the
              // application has a blue toolbar. Then, without quitting the app, try
              // changing the primarySwatch below to Colors.green and then invoke
              // "hot reload" (press "r" in the console where you ran "flutter run",
              // or simply save your changes to "hot reload" in a Flutter IDE).
              // Notice that the counter didn't reset back to zero; the application
              // is not restarted.
              primarySwatch: Colors.blue,
              accentColor: Colors.deepOrange,
            ),
            home: FutureBuilder(
              // read config.json files only once at program start
              future: baseConfig.isInited()
                  ? null
                  : appInitialize(baseConfig, settings, strgClnt, ctx),
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
                return StreamBuilder(
                  stream: useLoc
                      ? LocAuth.instance.authStateChanges(strgClnt.locClnt)
                      : FirebaseAuth.instance.authStateChanges(),
                  builder: (ctx, snapShot) {
                    if (snapShot.connectionState == ConnectionState.waiting) {
                      return SplashScreen();
                    }
                    if (snapShot.hasData) {
                      return KartenScreen();
                    }
                    return useLoc ? LocAccountScreen() : AccountScreen();
                  },
                );
              },
            ),
            routes: {
              ImagesScreen.routeName: (ctx) => ImagesScreen(),
              DatenScreen.routeName: (ctx) => DatenScreen(),
              ZusatzScreen.routeName: (ctx) => ZusatzScreen(),
              KartenScreen.routeName: (ctx) => KartenScreen(),
              PhotoScreen.routeName: (ctx) => PhotoScreen(),
            },
          );
        },
      ),
    );
  }

  // conveniently do all asynchronous initialization
  Future<void> appInitialize(BaseConfig baseConfig, Settings settings,
      Storage strgClnt, BuildContext ctx) async {
    MsgModel msgModel = Provider.of<MsgModel>(ctx, listen: false);

    msgModel.setMessage("Laden...");
    await initExtPath();
    // allow external storage config files
    final extPath = getExtPath();
    final configPath = path.join(extPath, "config");
    Directory configDir = Directory(configPath);
    await configDir.create();

    await settings.getSharedPreferences();
    String serverName = settings.getConfigValueS("servername");
    int serverPort = settings.getConfigValueI("serverport");
    String serverUrl = "http://$serverName:$serverPort";
    msgModel.setMessage("Server has URL $serverUrl...");

    final fbApp = await Firebase.initializeApp();
    print("fbapp $fbApp");

    settings.setConfigValue(
        "storage", "LocationsServer"); // until Firebase works on windows
    useLoc = settings.getConfigValueS("storage", defVal: "LocationsServer") ==
        "LocationsServer";
    strgClnt.setClnt(useLoc);
    strgClnt.init(
      serverUrl: serverUrl,
      extPath: extPath,
      datenFelder: [],
      zusatzFelder: [],
      imagesFelder: [],
    );

    var bc = Map<String, List>();
    msgModel.setMessage("Lade Konfigurationsdateien von $configDir");
    List<FileSystemEntity> configFiles = await configDir.list().toList();
    await Future.forEach(configFiles, (f) async {
      if (f is File && f.path.endsWith(".json")) {
        final content2 = await f.readAsString();
        try {
          final Map content2JS = json.decode(content2);
          checkSyntax(content2JS);
          final name = content2JS['name'];
          if (bc[name] == null) bc[name] = [];
          bc[name].add(content2JS);
        } catch (e) {
          msgModel.setMessage("Error $e");
        }
      }
    });

    print("bc ${bc.keys}");
    if (bc.isEmpty) {
      msgModel.setMessage("Keine Konfigurationen gefunden");
      bc = {
        "undef": [
          {
            "daten": {
              "felder": [
                {
                  "helper_text": "null",
                  "hint_text": "null",
                  "name": "undef",
                  "type": "string"
                },
              ]
            },
            "db_name": "undef.db",
            "db_tabellenname": "undef",
            "gps": {"min_zoom": 11, "nachkommastellen": 5},
            "name": "undef",
            "version": 1,
            "program": ["return 0"]
          }
        ]
      };
    }

    await settings.getSharedPreferences();
    baseConfig.setInitially(bc, settings.initialBase());
    await LocationsDB.setBaseDB(baseConfig);

    strgClnt.init(
      serverUrl: serverUrl,
      extPath: extPath,
      datenFelder: baseConfig.getDbDatenFelder(),
      zusatzFelder: baseConfig.getDbZusatzFelder(),
      imagesFelder: baseConfig.getDbImagesFelder(),
    );
    msgModel.setMessage("");

    // used during setup of FireBase
    // copy from LocationsServer to Firebase
    // strgClnt.copyLoc2Fb("abstellanlagen", settings.getConfigValueI("maxdim"));

    // import bicycle_parking.xml into LocatonsServer or Firebase
    // await OsmImport(extPath, strgClnt, baseConfig.stellen(),
    //         baseConfig.getDbDatenFelder())
    //     .osmImport();
  }
}
