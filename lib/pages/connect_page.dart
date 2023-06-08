import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pointycastle/api.dart';
import 'package:project_wombat/pages/send_page.dart';
import 'package:project_wombat/utils/tcp_connection.dart';

class ConnectPage extends StatefulWidget {
  ConnectPage({super.key});

  static const String routeName = '/connect';

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  var tcpConnection;
  @override
  void initState() {
    tcpConnection = TcpConnection(onConnectHandler: sendPage);
    super.initState();
  }

  void sendPage() {
    Navigator.pushNamed(context, SendPage.routeName, arguments: tcpConnection);
  }

  @override
  Widget build(BuildContext context) {
    final AsymmetricKeyPair<PublicKey, PrivateKey> keyPair =
        ModalRoute.of(context)!.settings.arguments
            as AsymmetricKeyPair<PublicKey, PrivateKey>;
    String ip = "";
    return Scaffold(
      appBar: AppBar(
        title: Text("Connect"),
      ),
      body: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Input IP'),
            onChanged: (value) {
              ip = value;
            },
          ),
          TextButton(
            onPressed: () {
              tcpConnection.startConnection(ip);
              sendPage();
            },
            child: Text("Connect"),
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
