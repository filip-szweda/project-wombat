import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:project_wombat/pages/communication_page.dart';
import 'package:project_wombat/utils/tcp_connection.dart';

import '../utils/key_pair.dart';

class ConnectPage extends StatefulWidget {
  ConnectPage({super.key});

  static const String routeName = '/connect';

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  late TcpConnection tcpConnection;
  late KeyPair keyPair;
  List<AESMode> cipherModes = [AESMode.cbc, AESMode.ecb];
  late AESMode actualDropdownValue;

  @override
  void initState() {
    tcpConnection = TcpConnection(goToCommunicationPage: goToCommunicationPage);
    tcpConnection.startListeningForConnection();
    actualDropdownValue = cipherModes.first;
    super.initState();
  }

  void goToCommunicationPage() =>
      Navigator.pushNamed(context, CommunicationPage.routeName,
          arguments: tcpConnection);

  @override
  Widget build(BuildContext context) {
    keyPair = ModalRoute.of(context)!.settings.arguments as KeyPair;
    tcpConnection.setKeyPair(keyPair);
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
              tcpConnection.setCipherMode(actualDropdownValue);
              tcpConnection.connectToUser(ip);
            },
            child: Text("Connect"),
          ),
          Container(
            child: SizedBox(
              height: 30,
            ),
            color: Colors.purple,
          ),
          DropdownButton(
              value: actualDropdownValue,
              items:
                  cipherModes.map<DropdownMenuItem<AESMode>>((AESMode value) {
                return DropdownMenuItem<AESMode>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
              onChanged: (mode) => setState(() {
                    actualDropdownValue = mode!;
                  })),
        ],
      ),
    );
  }
}
