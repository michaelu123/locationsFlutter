import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locations/providers/settings.dart';
import 'package:locations/widgets/app_config.dart';
import 'package:locations/widgets/auth_form.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  static String routeName = "/account";
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final auth = FirebaseAuth.instance;
  bool isLoading = false;
  Settings settingsNL;

  Future<void> submitAuthForm(
    String email,
    String password,
    String username,
    bool isLogin,
    BuildContext ctx,
  ) async {
    UserCredential authResult;
    try {
      setState(() {
        isLoading = true;
      });
      if (isLogin) {
        authResult = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        DocumentSnapshot dss = await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user.uid)
            .get();
        settingsNL.setConfigValue("username", dss.data()["username"]);
      } else {
        QuerySnapshot qss = await FirebaseFirestore.instance
            .collection('users')
            .where("username", isEqualTo: username)
            .get();
        for (QueryDocumentSnapshot d in qss.docs) {
          Map data = d.data();
          if (data["email"] != email) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text("Der Benutzername $username ist schon vergeben!"),
                backgroundColor: Theme.of(ctx).errorColor,
              ),
            );
            return;
          }
        }
        try {
          authResult = await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (err) {
          if (err.message == null || !err.message.contains("already in use")) {
            throw (err);
          }
          authResult = await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authResult.user.uid)
            .set({
          'username': username,
          'email': email,
        });
        settingsNL.setConfigValue("username", username);
      }
    } catch (err) {
      var message = "An error occurred, please check your credentials!";
      try {
        message = err.message;
      } catch (_) {}
      print("plaex $err $message");
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(ctx).errorColor,
        ),
      );
    } finally {
      if (this.mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    settingsNL = Provider.of<Settings>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text("Login/SignOn"),
      ),
      drawer: AppConfig(),
      backgroundColor: Theme.of(context).primaryColor,
      body: AuthForm(
        submitAuthForm,
        isLoading,
      ),
    );
  }
}
