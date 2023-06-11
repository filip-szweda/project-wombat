import 'package:flutter/material.dart';
import 'package:project_wombat/utils/tcp_connection.dart';

class SendMessagesWidget extends StatelessWidget {
  TcpConnection tcpConnection;
  SendMessagesWidget({required this.tcpConnection, super.key});

  @override
  Widget build(BuildContext context) {
    String messageText = "";
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          flex: 6,
          child: TextField(
            keyboardType: TextInputType.multiline,
            minLines: 8,
            maxLines: 8,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: 'Type a message',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              messageText = value;
            },
          ),
        ),
        Flexible(
          flex: 1,
          child: SizedBox(),
        ),
        Flexible(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  this.tcpConnection.sendString(messageText);
                },
                child: Text("Send"),
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text("Send file"),
              )
            ],
          ),
        )
      ],
    );
  }
}
