import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
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
  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context);

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
              print("3build");
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
              print("4build");
              if (baseConfig.setBase(selectedValue)) {
                Provider.of<LocData>(context, listen: false).clearLocData();
                deleteFelder();
                print("5build");
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
                onPressed: () {
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
                onPressed: () {
                  final locDaten = Provider.of<LocData>(context, listen: false);
                  locDaten.useZusatz(true);
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
            ],
          ),
          Expanded(
            child: FlutterMap(
                options: MapOptions(
                  plugins: [CrossHairMapPlugin()],
                  center: LatLng(51.5, -0.09),
                  zoom: 13.0,
                ),
                layers: [
                  TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  MarkerLayerOptions(
                    markers: [
                      Marker(
                        width: 20.0,
                        height: 20.0,
                        point: LatLng(51.5, -0.09),
                        builder: (ctx) => Container(
                          child: FlutterLogo(),
                        ),
                      ),
                    ],
                  ),
                  CrossHairLayerOptions(
                    crossHair: CrossHair(
                      color: Colors.black,
                    ),
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}
