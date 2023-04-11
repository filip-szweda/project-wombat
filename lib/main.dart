import 'package:flutter/material.dart';
import 'package:project_wombat/connect_page.dart';
import 'package:project_wombat/send_page.dart';

void main() => runApp(const FileSharer());

class FileSharer extends StatelessWidget {
  const FileSharer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "File sharer",
      routes: {
        '/': (context) => const ConnectPage(),
        SendPage.routeName: (context) => SendPage(),
      },
    );
  }
}
