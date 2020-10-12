import 'package:flutter/material.dart';
import 'package:locations/providers/db.dart';
import 'package:locations/screens/zusatz.dart';
import 'package:locations/screens/bilder.dart';
import 'package:locations/screens/karte.dart';
import 'package:provider/provider.dart';

import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/utils/felder.dart';

class DatenScreen extends StatefulWidget {
  static String routeName = "/daten";
  @override
  _DatenScreenState createState() => _DatenScreenState();
}

class _DatenScreenState extends State<DatenScreen> with Felder {
  @override
  void dispose() {
    super.dispose();
    deleteFelder();
  }

  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context);
    final felder = baseConfig.getDatenFelder();

    return Scaffold(
      appBar: AppBar(
        title: Text(baseConfig.getName() + "/Daten"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: null,
          ),
          IconButton(
            icon: Icon(Icons.add_a_photo),
            onPressed: null,
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
                  Navigator.of(context).pushNamed(KartenScreen.routeName);
                },
                child: Text(
                  'Karte',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () async {
                  final locDaten = Provider.of<LocData>(context, listen: false);
                  final map = await LocationsDB.dataFor2();
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
            ],
          ),
          Expanded(
            child: Consumer<LocData>(
              builder: (ctx, locDaten, _) {
                if (focusHandlers == null) {
                  initFelder(context, baseConfig, false);
                }
                setFelder(locDaten, baseConfig, false);
                return ListView.builder(
                  itemCount: felder.length,
                  itemBuilder: (ctx, index) {
                    return textFields[index];
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
