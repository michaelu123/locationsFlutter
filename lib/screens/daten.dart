import 'package:flutter/material.dart';
import 'package:locations/providers/db.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/providers/photos.dart';
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
  void initState() {
    super.initState();
    final baseConfigNL = Provider.of<BaseConfig>(context, listen: false);
    initFelder(context, baseConfigNL, false);
  }

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
            icon: Icon(Icons.add_a_photo),
            onPressed: () {
              final photosNL = Provider.of<Photos>(context, listen: false);
              final markersNL = Provider.of<Markers>(context, listen: false);
              final locDataNL = Provider.of<LocData>(context, listen: false);
              photosNL.takePicture(markersNL, locDataNL);
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
                  Navigator.of(context).pushNamed(KartenScreen.routeName);
                },
                child: Text(
                  'Karte',
                ),
              ),
              if (baseConfig.hasZusatz())
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    final locDataNL =
                        Provider.of<LocData>(context, listen: false);
                    final map = await LocationsDB.dataForSameLoc();
                    locDataNL.dataFor("zusatz", map);
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
                  Navigator.of(context).pushNamed(ImagesScreen.routeName);
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
