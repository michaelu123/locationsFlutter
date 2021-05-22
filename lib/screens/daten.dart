import 'package:flutter/material.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/utils/db.dart';
import 'package:locations/providers/photos.dart';
import 'package:locations/providers/settings.dart';
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
  BaseConfig baseConfigNL;
  LocData locDataNL;
  Settings settingsNL;
  String tableBase;

  @override
  void initState() {
    super.initState();
    final baseConfigNL = Provider.of<BaseConfig>(context, listen: false);
    locDataNL = Provider.of<LocData>(context, listen: false);
    settingsNL = Provider.of<Settings>(context, listen: false);
    tableBase = baseConfigNL.getDbTableBaseName();
    initFelder(context, false);
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
            icon: const Icon(Icons.add_a_photo),
            onPressed: () {
              final photosNL = Provider.of<Photos>(context, listen: false);
              final markersNL = Provider.of<Markers>(context, listen: false);
              photosNL.takePicture(
                locDataNL,
                settingsNL.getConfigValueI("maxdim"),
                settingsNL.getConfigValueS("username"),
                settingsNL.getConfigValueS("region"),
                tableBase,
                markersNL,
              );
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
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      KartenScreen.routeName, (_) => false);
                },
                child: const Text(
                  'Karte',
                ),
              ),
              if (baseConfig.hasZusatz())
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () async {
                    final map = await LocationsDB.dataForSameLoc();
                    locDataNL.dataFor("zusatz", map);
                    await Navigator.of(context)
                        .pushNamed(ZusatzScreen.routeName);
                    // without the next statement, after pressing back button
                    // from zusatz the datenscreen shows wrong data
                    locDataNL.setIsZusatz(false);
                  },
                  child: const Text(
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
                child: const Text(
                  'Bilder',
                ),
              ),
            ],
          ),
          Expanded(
            child: settingsNL.getConfigValueS("username", defVal: "").isEmpty
                ? const Center(
                    child: Text(
                      "Bitte erst einen Benutzer/Spitznamen eingeben",
                      style: TextStyle(
                        backgroundColor: Colors.white,
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  )
                : Consumer<LocData>(
                    builder: (ctx, locDaten, _) {
                      setFelder(locDaten, baseConfig, false);
                      return ListView.builder(
                        itemCount: felder.length,
                        itemBuilder: (ctx, index) {
                          return Padding(
                            child: textFields[index],
                            padding: EdgeInsets.all(10),
                          );
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
