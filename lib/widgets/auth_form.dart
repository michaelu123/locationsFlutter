import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final void Function(
    String email,
    String password,
    String username,
    bool isLogin,
    BuildContext ctx,
  ) submitFn;
  final bool isLoading;
  AuthForm(this.submitFn, this.isLoading);

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  String userEmail = "", userName = "", password = "";
  bool isLogin = true;

  void _trySubmit() {
    final isValid = _formKey.currentState.validate();
    FocusScope.of(context).unfocus(); // makes keyboard disappear
    if (isValid) {
      _formKey.currentState.save();
      widget.submitFn(
        userEmail.trim(),
        password.trim(),
        userName.trim(),
        isLogin,
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: ValueKey('email'),
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    enableSuggestions: false,
                    onSaved: (v) {
                      userEmail = v;
                    },
                    validator: (value) {
                      if (value.isEmpty || !value.contains('@')) {
                        return 'Bitte geben Sie eine gültige Email-Adresse an.';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email-Adresse',
                    ),
                  ),
                  if (!isLogin)
                    TextFormField(
                      autocorrect: true,
                      textCapitalization: TextCapitalization.words,
                      enableSuggestions: false,
                      key: ValueKey('username'),
                      onSaved: (v) {
                        userName = v;
                      },
                      validator: (value) {
                        if (value.isEmpty || value.length < 3) {
                          return 'Bitte geben Sie mindestens 3 Zeichen an.';
                        }
                        if (value == "OSM" || value == "STAMM") {
                          return 'OSM oder STAMM  sind reservierte Benutzernamen.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(labelText: 'Benutzername'),
                    ),
                  TextFormField(
                    key: ValueKey('password'),
                    onSaved: (v) {
                      password = v;
                    },
                    validator: (value) {
                      if (value.isEmpty || value.length < 6) {
                        return 'Das Passwort muß mindestens 6 Zeichen lang sein.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(labelText: 'Passwort'),
                    obscureText: true,
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  if (widget.isLoading) CircularProgressIndicator(),
                  if (!widget.isLoading)
                    RaisedButton(
                      child: Text(isLogin ? 'Login' : 'Anmelden'),
                      onPressed: _trySubmit,
                    ),
                  if (!widget.isLoading)
                    FlatButton(
                      textColor: Theme.of(context).primaryColor,
                      child: Text(isLogin
                          ? 'Neu anmelden'
                          : 'Ich bin schon angemeldet'),
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
