import 'package:flutter/material.dart';
import 'package:project_wombat/config.dart' as config;
import 'package:project_wombat/pages/send_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  bool checkPassword(inputPassword, actualPassword) {
    return inputPassword == actualPassword;
  }

  @override
  Widget build(BuildContext context) {
    String inputPassword = "";
    return Scaffold(
      appBar: AppBar(
        title: Text("connect"),
      ),
      body: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (value) {
              inputPassword = value;
            },
          ),
          TextButton(
            onPressed: () {
              if (checkPassword(inputPassword, config.password)) {
                Navigator.pushNamed(context, SendPage.routeName);
              }
              //TODO print if password not correct
            },
            child: Text("Login"),
          ),
          Container(
            child: SizedBox(
              height: 30,
            ),
            color: Colors.purple,
          )
        ],
      ),
    );
  }
}
