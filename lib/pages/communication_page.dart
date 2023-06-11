import 'package:flutter/material.dart';
import 'package:project_wombat/pages/communication_page/receive_messages_widget.dart';
import 'package:project_wombat/pages/communication_page/send_messages_widget.dart';
import 'package:project_wombat/utils/tcp_connection.dart';

class CommunicationPage extends StatelessWidget {
  CommunicationPage({super.key});

  static const String routeName = '/send';

  late TcpConnection tcpConnection;

  @override
  Widget build(BuildContext context) {
    tcpConnection = ModalRoute.of(context)!.settings.arguments as TcpConnection;
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Messages"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ReceiveMessagesWidget(tcpConnection: tcpConnection),
            SizedBox(
              height: 20,
            ),
            SendMessagesWidget(tcpConnection: tcpConnection),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
