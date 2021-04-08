import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MsgModel with ChangeNotifier {
  String msg = "Loading...";

  void setMessage(String m) async {
    debugPrint("Message: $m");
    msg = m;
    await Future.delayed(Duration(seconds: 1), () => notifyListeners());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  String getMessage() {
    return msg;
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final msgModel = Provider.of<MsgModel>(context);

    return Scaffold(
      body: Center(
        child: Text(
          msgModel.getMessage(),
          style: TextStyle(
            backgroundColor: Colors.white,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
