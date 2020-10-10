import 'package:flutter/material.dart';

class BilderScreen extends StatefulWidget {
  static String routeName = "/bilder";
  @override
  _BilderScreenState createState() => _BilderScreenState();
}

class _BilderScreenState extends State<BilderScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Bilder'),
    );
  }
}
