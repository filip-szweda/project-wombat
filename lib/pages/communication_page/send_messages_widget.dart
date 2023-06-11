import 'package:flutter/material.dart';

class SendMessagesWidget extends StatelessWidget {
  const SendMessagesWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {},
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
