import 'package:flutter/material.dart';
import 'package:project_wombat/tcp_connection.dart';

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
        title: Text("connect"),
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
            onPressed: () => print(
                TcpConnection(ip, int.parse(sendPort), int.parse(receivePort))
                    .toString()),
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
