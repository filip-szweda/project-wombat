import 'package:flutter/material.dart';
import 'package:pointycastle/api.dart';
import 'package:project_wombat/pages/connect_page.dart';
import 'package:project_wombat/utils/cryptography.dart';

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
        title: Text("Login"),
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
            onPressed: () async {
              var crypto = Cryptography(inputPassword);
              AsymmetricKeyPair<PublicKey, PrivateKey> keyPair =
                  await crypto.getKeyPair();
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Logged in'),
                  content: Text(crypto.message),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, 'OK');
                        Navigator.pushNamed(context, ConnectPage.routeName,
                            arguments: keyPair);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
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
