import 'package:flutter/material.dart';
import 'package:project_wombat/pages/connect_page.dart';
import 'package:project_wombat/pages/login_page.dart';
import 'package:project_wombat/pages/communication_page.dart';

void main() => runApp(const FileSharer());

class FileSharer extends StatelessWidget {
  const FileSharer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: "File sharer",
      routes: {
        '/': (context) => const LoginPage(),
        LoginPage.routeName: (context) => const LoginPage(),
        ConnectPage.routeName: (context) => ConnectPage(),
        CommunicationPage.routeName: (context) => CommunicationPage(),
      },
    );
  }
}
