import 'package:flutter/material.dart';
import 'package:locations/utils/db.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/screens/bilder.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/karte.dart';
import 'package:locations/utils/utils.dart';
import 'package:provider/provider.dart';

import 'package:locations/providers/base_config.dart';
import 'package:locations/utils/felder.dart';

class ZusatzScreen extends StatefulWidget {
  static String routeName = "/zusatz";
  @override
  _ZusatzScreenState createState() => _ZusatzScreenState();
}

class _ZusatzScreenState extends State<ZusatzScreen>
    with Felder, SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    initFelder(context, true);
  }

  @override
  void dispose() {
    super.dispose();
    deleteFelder();
  }

  Future<void> deleteZusatz(LocData locData) async {
    if (!await areYouSure(context, 'Wollen Sie das Bild wirklich löschen?'))
      return;
    int nr = locData.deleteZusatz();
    LocationsDB.deleteZusatz(nr);
  }

  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context);
    final felder = baseConfig.getZusatzFelder();
    final locData = Provider.of<LocData>(context);
    setFelder(locData, baseConfig, true);

    return Scaffold(
      appBar: AppBar(
        title: Text(baseConfig.getName() + "/Zusatz"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: locData.isEmpty() ? null : () => deleteZusatz(locData),
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
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () async {
                  final map = await LocationsDB.dataForSameLoc();
                  locData.dataFor("daten", map);
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
                onPressed: () {
                  Navigator.of(context).pushNamed(ImagesScreen.routeName);
                },
                child: const Text(
                  'Bilder',
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                iconSize: 40,
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    locData.canDecZusatz() ? locData.decIndexZusatz : null,
              ),
              IconButton(
                iconSize: 40,
                icon: const Icon(Icons.add),
                onPressed: baseConfig.hasZusatz() && !locData.isEmpty()
                    ? locData.addZusatz
                    : null,
              ),
              IconButton(
                iconSize: 40,
                icon: const Icon(Icons.arrow_forward),
                onPressed:
                    locData.canIncZusatz() ? locData.incIndexZusatz : null,
              ),
            ],
          ),
          if (locData.isEmpty())
            const Center(
              child: const Text(
                "Noch keine Daten eingetragen",
                style: const TextStyle(
                  backgroundColor: Colors.white,
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
            ),
          if (!locData.isEmpty())
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity < 0) {
                    locData.incIndexZusatz();
                  } else {
                    locData.decIndexZusatz();
                  }
                },
                child: ListView.builder(
                  itemCount: felder.length,
                  itemBuilder: (ctx, index) {
                    return Padding(
                      child: textFields[index],
                      padding: EdgeInsets.all(10),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
