import 'dart:io';

class TcpConnection {
  Socket? socket; // socket for sending messages
  ServerSocket? serverSocket; // socket for receiving messages
  var onConnectHandler;

  Future<String> getIpV4() async {
    for (var interface in await NetworkInterface.list()) {
      if(interface.name == "Ethernet") {
        // not sure if the first address will be always the correct one
        return interface.addresses[0].address;
      }
    }
    return "Error. Ip not found";
  }

  TcpConnection({required this.onConnectHandler}) {
    getIpV4().then((ip) => ServerSocket.bind(ip, 4567).then(
      (ServerSocket s) {
        serverSocket = s;
        s.listen(handleClient);
      }
    ));
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
    // todo: save client, to user can send messages to them on the send page
    print('Connection from '
      '${client.remoteAddress.address}:${client.remotePort}');

    client.write("Hello from simple server!\n"); // test message sent to client
    onConnectHandler();
  }
}
