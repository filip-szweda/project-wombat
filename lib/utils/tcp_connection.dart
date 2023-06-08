import 'dart:io';

class TcpConnection {
  Socket? socket; // socket for sending messages
  ServerSocket? serverSocket; // socket for receiving messages
  var onConnectHandler;

  TcpConnection({required this.onConnectHandler}) {
    // todo: user's IP should not be hardcoded
    ServerSocket.bind("192.168.1.102", 4567).then(
      (ServerSocket s) {
        serverSocket = s;
        s.listen(handleClient);
      }
    );
  }

  void startConnection(String receiverIP) async {
    Socket.connect(receiverIP, 4567).then((s) {
      print('Connected to: '
        '${s.remoteAddress.address}:${s.remotePort}');

      socket = s;

      s.listen((data) {
        print(new String.fromCharCodes(data).trim());
      },
      onDone: () {
        print("Connection closed");
        s.destroy();
      });
    });
  }

  void handleClient(Socket client) {
    // todo: move user to send page
    // todo: save client, to user can send messages to them on the send page
    print('Connection from '
      '${client.remoteAddress.address}:${client.remotePort}');

    client.write("Hello from simple server!\n"); // test message sent to client
    onConnectHandler();
  }
}
