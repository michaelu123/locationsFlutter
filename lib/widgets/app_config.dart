import 'package:flutter/material.dart';

class AppConfig extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
      children: [
        AppBar(
          title: Text('Einstellungen'),
        ),
        ListTile(
          title: Text("config"),
          subtitle: Text("explain"),
          trailing: Text("trailing"),
        ),
      ],
    ));
  }
}
