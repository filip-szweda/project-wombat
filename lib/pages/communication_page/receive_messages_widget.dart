import 'package:flutter/material.dart';
import 'package:project_wombat/utils/tcp_connection.dart';

class ReceiveMessagesWidget extends StatelessWidget {
  TcpConnection tcpConnection;
  ReceiveMessagesWidget({required this.tcpConnection, Key? key}) : super(key: key);

  final List<String> messages = [];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
            //reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messages.map((message) => MessageBubble(message, "test", false)).toList()),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble(this.message, this.sender, this.isUser, {Key? key})
      : super(key: key);

  final String message;
  final String sender;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry borderRadiusGeometry = isUser == true
        ? BorderRadius.only(
      topLeft: Radius.circular(30),
      bottomRight: Radius.circular(30),
      bottomLeft: Radius.circular(30),
    )
        : BorderRadius.only(
      topRight: Radius.circular(30),
      bottomRight: Radius.circular(30),
      bottomLeft: Radius.circular(30),
    );

    Color color = isUser == true ? Colors.lightBlueAccent : Colors.white;
    Color fontColor = isUser == true ? Colors.white : Colors.black54;

    CrossAxisAlignment crossAxisAlignment =
    isUser == true ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Material(
            borderRadius: borderRadiusGeometry,
            elevation: 5,
            color: color,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: fontColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
