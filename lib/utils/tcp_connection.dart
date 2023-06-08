import 'dart:io';
// import 'dart:math';
import 'package:pointycastle/api.dart';

class TcpConnection {
  AsymmetricKeyPair<PublicKey, PrivateKey>? keyPair;
  ServerSocket? serverSocket;
  Socket? socket; // socket for sending messages
  var onConnectHandler;

   TcpConnection({this.onConnectHandler}) {
    getIpV4().then((ip) => ServerSocket.bind(ip, 4567).then(
      (ServerSocket myUser) {
        serverSocket = myUser;
        myUser.listen(handleConnectedUser);
      }
    ));
  }

  Future<String> getIpV4() async {
    for (var interface in await NetworkInterface.list()) {
      if(interface.name == "Ethernet") {
        // not sure if the first address will be always the correct one
        return interface.addresses[0].address;
      }
    }
    return "Error. Ip not found";
  }

 

//connect to other user
  void startConnection(String receiverIP) async {
    serverSocket!.close(); //close server, because you are connected
    Socket.connect(receiverIP, 4567).then((connectedUser) {
      print('Connected to: '
        '${connectedUser.remoteAddress.address}:${connectedUser.remotePort}');

      socket = connectedUser;

      // send public key after initiating a connection
      connectedUser.write(keyPair!.publicKey);

      connectedUser.listen((data) { print(new String.fromCharCodes(data).trim());
      }, onDone: () {print("Connection closed"); connectedUser.destroy();});
    });
  }


//user connected to us
  void handleConnectedUser(Socket connectedUser) {
    // todo: save client, to user can send messages to them on the send page
    print('Connection from '
      '${connectedUser.remoteAddress.address}:${connectedUser.remotePort}');

    connectedUser.write(keyPair!.publicKey);

    connectedUser.listen((data) { print(new String.fromCharCodes(data).trim());
    }, onDone: () {print("Connection closed"); connectedUser.destroy();});
    
    onConnectHandler();
  }



  // num generatePublicDHKey() {
  //   return pow(6, keyPair.publicKey) % 13;
  // }
}
