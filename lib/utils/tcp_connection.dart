import 'dart:io';

class TcpConnection {
  final String receiverIP;
  final int sendPort; // one you are sending to
  final int receivePort; // one from which other clients sends data

  Socket? listeningSocket;
  Socket? sendingSocket;

  TcpConnection(this.receiverIP, this.sendPort, this.receivePort);

  void start() async {
    // listeningSocket = await Socket.connect(receiverIP, receivePort);
    // sendingSocket = await Socket.connect(receiverIP, sendPort);
  }

  @override
  String toString() {
    return 'TcpConnection{receiverIP: $receiverIP, sendPort: $sendPort, receivePort: $receivePort}';
  }
}
