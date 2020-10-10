import 'package:flutter/material.dart';

class KartenScreen extends StatefulWidget {
  static String routeName = "/karte";
  @override
  _KartenScreenState createState() => _KartenScreenState();
}

class _KartenScreenState extends State<KartenScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Karte'),
    );
  }
}
