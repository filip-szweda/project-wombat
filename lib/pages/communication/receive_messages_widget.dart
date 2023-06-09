import 'package:flutter/material.dart';

class ReceiveMessagesWidget extends StatefulWidget {
  const ReceiveMessagesWidget({Key? key}) : super(key: key);

  @override
  State<ReceiveMessagesWidget> createState() => _ReceiveMessagesWidgetState();
}

class _ReceiveMessagesWidgetState extends State<ReceiveMessagesWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Form(
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Send a message'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}