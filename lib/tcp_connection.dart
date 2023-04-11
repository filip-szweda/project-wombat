import 'dart:io';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;

class TcpConnection {
  final String receiverIP;
  final int sendPort; // one you are sending to
  final int receivePort; // one from which other clients sends data

  Socket? listeningSocket;
  Socket? sendingSocket;
  crypto.AsymmetricKeyPair? keyPair;

  TcpConnection(this.receiverIP, this.sendPort, this.receivePort);

  void start() async {
    //listeningSocket = await Socket.connect(receiverIP, receivePort);
    //sendingSocket = await Socket.connect(receiverIP, sendPort);

    var helper = RsaKeyHelper();
    keyPair = await helper.computeRSAKeyPair(helper.getSecureRandom());

    print(keyPair.toString());
  }

  @override
  String toString() {
    return 'TcpConnection{receiverIP: $receiverIP, sendPort: $sendPort, receivePort: $receivePort}';
  }
}
