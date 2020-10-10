import 'package:flutter/material.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/screens/bilder.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/karte.dart';
import 'package:provider/provider.dart';

import 'package:locations/providers/base_config.dart';
import 'package:locations/screens/account.dart';
import 'package:locations/widgets/app_config.dart';
import 'package:locations/utils/felder.dart';

class ZusatzScreen extends StatefulWidget {
  static String routeName = "/zusatz";
  @override
  _ZusatzScreenState createState() => _ZusatzScreenState();
}

class _ZusatzScreenState extends State<ZusatzScreen> with Felder {
  @override
  void dispose() {
    super.dispose();
    deleteFelder();
  }

  @override
  Widget build(BuildContext context) {
    print("1build");
    final baseConfig = Provider.of<BaseConfig>(context);
    final felder = baseConfig.getZusatzFelder();

    print("2build $felder");
    return Scaffold(
      drawer: AppConfig(),
      appBar: AppBar(
        title: Text(baseConfig.getName() + "/Zusatz"),
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
        ],
      ),
      body: Consumer<LocData>(
        builder: (ctx, locData, _) {
          print("6build");
          if (focusHandlers == null) {
            initFelder(context, locData, true);
          } else {
            setFelder(locData, true);
          }
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
                  onPressed: () {
                    locData.useZusatz(false);
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
                  onPressed: locData.decIndex,
                ),
                IconButton(
                  iconSize: 40,
                  icon: Icon(Icons.add),
                  onPressed: null,
                ),
                IconButton(
                  iconSize: 40,
                  icon: Icon(Icons.arrow_forward),
                  onPressed: locData.incIndex,
                ),
              ],
            ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity < 0) {
                    locData.incIndex();
                  } else {
                    locData.decIndex();
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
