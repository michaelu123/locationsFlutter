import 'package:flutter/material.dart';
import 'package:locations/providers/db.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/screens/bilder.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/karte.dart';
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
  void dispose() {
    super.dispose();
    deleteFelder();
  }

  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context);
    final felder = baseConfig.getZusatzFelder();

    return Scaffold(
      appBar: AppBar(
        title: Text(baseConfig.getName() + "/Zusatz"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: null,
          ),
        ],
      ),
      body: Consumer<LocData>(
        builder: (ctx, locDaten, _) {
          if (focusHandlers == null) {
            initFelder(context, baseConfig, true);
          }
          setFelder(locDaten, baseConfig, true);
          return Column(children: [
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
                    final locDaten =
                        Provider.of<LocData>(context, listen: false);
                    final map = await LocationsDB.dataForSameLoc();
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
                  onPressed: () {
                    Navigator.of(context).pushNamed(BilderScreen.routeName);
                  },
                  child: Text(
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
                  icon: Icon(Icons.arrow_back),
                  onPressed: locDaten.canDec() ? locDaten.decIndex : null,
                ),
                IconButton(
                  iconSize: 40,
                  icon: Icon(Icons.add),
                  onPressed: baseConfig.getZusatzFelder().length > 0
                      ? locDaten.addZusatz
                      : null,
                ),
                IconButton(
                  iconSize: 40,
                  icon: Icon(Icons.arrow_forward),
                  onPressed: locDaten.canInc() ? locDaten.incIndex : null,
                ),
              ],
            ),
            if (locDaten.isEmpty())
              Center(
                child: Text(
                  "Noch keine Daten eingetragen",
                ),
              ),
            if (!locDaten.isEmpty())
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity < 0) {
                      locDaten.incIndex();
                    } else {
                      locDaten.decIndex();
                    }
                  },
                  child: ListView.builder(
                    itemCount: felder.length,
                    itemBuilder: (ctx, index) {
                      return textFields[index];
                    },
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}
