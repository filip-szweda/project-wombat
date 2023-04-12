import 'package:flutter/material.dart';
import 'package:project_wombat/pages/connect_page.dart';
import 'package:project_wombat/pages/login_page.dart';
import 'package:project_wombat/pages/send_page.dart';

void main() => runApp(const FileSharer());

class FileSharer extends StatelessWidget {
  const FileSharer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "File sharer",
      routes: {
        '/': (context) => const ConnectPage(),
        LoginPage.routeName: (context) => const LoginPage(),
        SendPage.routeName: (context) => SendPage(),
      },
    );
  }
}
