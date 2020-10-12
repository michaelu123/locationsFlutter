import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:locations/providers/db.dart';
import 'package:locations/providers/settings.dart';
import 'package:provider/provider.dart';

import 'package:locations/providers/map_center.dart';
import 'package:locations/screens/account.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/screens/zusatz.dart';
import 'package:locations/screens/bilder.dart';
import 'package:locations/screens/karte.dart';
import 'package:locations/screens/daten.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("1mb");
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
          create: (BuildContext context) => MapCenter(),
        ),
      ],
      child: Consumer<BaseConfig>(
        builder: (ctx, baseConfig, _) {
          print("2mb");
          return Consumer<Settings>(
            builder: (ctx, settings, _) {
              return MaterialApp(
                title: 'Flutter Demo',
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
                      : readConfig(baseConfig, settings),
                  builder: (ctx, snap) {
                    print("3mb");
                    if (snap.connectionState == ConnectionState.waiting) {
                      print("4mb");
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    print("5mb");
                    if (snap.hasError) {
                      print("6mb");
                      return Center(
                        child: Text(
                          "error ${snap.error}",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      );
                    }
                    print("7mb");
                    return KartenScreen();
                  },
                ),
                routes: {
                  BilderScreen.routeName: (ctx) => BilderScreen(),
                  DatenScreen.routeName: (ctx) => DatenScreen(),
                  ZusatzScreen.routeName: (ctx) => ZusatzScreen(),
                  KartenScreen.routeName: (ctx) => KartenScreen(),
                  AccountScreen.routeName: (ctx) => AccountScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> readConfig(baseConfig, settings) async {
    // read all assets/config/*.json files
    print("1rc");
    var bc = Map<String, dynamic>();
    // I cannot obtain list of bundle content, therefore I need a TOC file...
    String content = await rootBundle.loadString("assets/config/content.json");
    List contentJS = json.decode(content);

    await Future.forEach(contentJS, (f) async {
      final content2 = await rootBundle.loadString("assets/config/" + f);
      final Map content2JS = json.decode(content2);
      final name = content2JS['name'];
      bc[name] = content2JS;
    });
    print("bc ${bc.keys}");
    await settings.getSharedPreferences();
    baseConfig.setInitially(bc, settings.initialBase());
    await LocationsDB.setBase(baseConfig);
  }
}
