import 'package:flutter/material.dart';
import 'package:project_wombat/pages/communication/receive_messages_widget.dart';
import 'package:project_wombat/pages/communication/send_messages_widget.dart';

class CommunicationPage extends StatelessWidget {
  CommunicationPage({super.key});

  static const String routeName = '/send';

  //TcpConnection tcpConnection;

  @override
  Widget build(BuildContext context) {
    //tcpConnection = ModalRoute.of(context)!.settings.arguments as TcpConnection;
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Messages"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ReceiveMessagesWidget(),
            SizedBox(
              height: 20,
            ),
            SendMessagesWidget(),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
