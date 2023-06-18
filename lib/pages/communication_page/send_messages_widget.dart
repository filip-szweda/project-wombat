import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:project_wombat/utils/tcp_connection.dart';

class SendMessagesWidget extends StatelessWidget {
  final TcpConnection tcpConnection;

  SendMessagesWidget({required this.tcpConnection, super.key});

  TextEditingController messageController = TextEditingController();
  String messageText = "";
  File? attachedFile;

  void clearMessage() {
    messageController.clear();
    messageText = "";
  }

  void clearAttachedFile() {
    attachedFile = null;
  }

  void attachFile() async {
    FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles();
    if (filePickerResult != null &&
        filePickerResult.files.single.path != null) {
      attachedFile = File(filePickerResult.files.single.path!);
      messageController.text =
          "File ${basename(attachedFile!.path)} was attached";
      print("[INFO] Attached file: " + attachedFile!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          flex: 6,
          child: TextField(
            controller: messageController,
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
                  if (attachedFile != null) {
                    print("Start of sending file");
                    tcpConnection
                        .sendFile(attachedFile!)
                        .then((value) => clearAttachedFile());
                    print("File sent");
                    clearMessage();
                  }
                  if (messageText.isNotEmpty) {
                    this.tcpConnection.sendString(messageText);
                    clearMessage();
                  }
                },
                child: Text("Send"),
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  attachFile();
                },
                child: Text("Attach File"),
              )
            ],
          ),
        )
      ],
    );
  }
}
