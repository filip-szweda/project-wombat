import 'package:flutter/material.dart';
import 'package:project_wombat/pages/login_page.dart';
import 'package:project_wombat/pages/send_page.dart';
import 'package:project_wombat/utils/tcp_connection.dart';

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  static const String routeName = '/connect';

  @override
  Widget build(BuildContext context) {
    String ip = "";
    String sendPort = "";
    String receivePort = "";
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
          TextFormField(
              decoration: const InputDecoration(labelText: 'Send port'),
              onChanged: (value) {
                sendPort = value;
              }),
          TextFormField(
              decoration: const InputDecoration(labelText: 'Receive port'),
              onChanged: (value) {
                receivePort = value;
              }),
          TextButton(
            onPressed: () {
              TcpConnection(ip, int.parse(sendPort), int.parse(receivePort)).start();
              Navigator.pushNamed(context, SendPage.routeName);
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
