import 'package:flutter/material.dart';
import 'package:locations/utils/db.dart';
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
  void initState() {
    super.initState();
    final baseConfigNL = Provider.of<BaseConfig>(context, listen: false);
    initFelder(context, baseConfigNL, true);
  }

  @override
  void dispose() {
    super.dispose();
    deleteFelder();
  }

  void deleteZusatz(LocData locData) {
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
            icon: Icon(Icons.delete),
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
                  final map = await LocationsDB.dataForSameLoc();
                  locData.dataFor("daten", map);
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
                  Navigator.of(context).pushNamed(ImagesScreen.routeName);
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
                onPressed:
                    locData.canDecZusatz() ? locData.decIndexZusatz : null,
              ),
              IconButton(
                iconSize: 40,
                icon: Icon(Icons.add),
                onPressed: baseConfig.hasZusatz() ? locData.addZusatz : null,
              ),
              IconButton(
                iconSize: 40,
                icon: Icon(Icons.arrow_forward),
                onPressed:
                    locData.canIncZusatz() ? locData.incIndexZusatz : null,
              ),
            ],
          ),
          if (locData.isEmpty())
            Center(
              child: Text(
                "Noch keine Daten eingetragen",
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
                      padding: EdgeInsets.symmetric(vertical: 10),
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
