import 'package:encrypt/encrypt.dart';
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
  late TcpConnection tcpConnection;
  late AsymmetricKeyPair<PublicKey, PrivateKey> keyPair;
  List<AESMode> cipherModes = [AESMode.cbc, AESMode.ecb];
  late AESMode actualDropdownValue;

  @override
  void initState() {
    tcpConnection = TcpConnection(goToSendPage: toSendPage);
    tcpConnection.startListeningForConnection();
    actualDropdownValue = cipherModes.first;
    super.initState();
  }

  void toSendPage() => Navigator.pushNamed(context, SendPage.routeName,
      arguments: tcpConnection);

  @override
  Widget build(BuildContext context) {
    keyPair = ModalRoute.of(context)!.settings.arguments
        as AsymmetricKeyPair<PublicKey, PrivateKey>;
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
