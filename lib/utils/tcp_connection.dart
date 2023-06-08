import 'dart:io';
import 'dart:typed_data';
import 'package:pointycastle/api.dart';
import 'package:uuid/uuid.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class TcpConnection {
  late AsymmetricKeyPair<PublicKey, PrivateKey> keyPair;
  ServerSocket? serverSocket;
  Socket? socket; // socket for sending messages
  Function nextPageCallback;

  var iv = encrypt.IV(Uint8List(16));

  PublicKey? connectedUsersKey;
  
  bool hasConnectedUsersKey = false;

  bool hasSessionKey = false;
  late String sessionKey;

  TcpConnection({required this.nextPageCallback});

  void setKeyPair(AsymmetricKeyPair<PublicKey, PrivateKey> keyPair) {
    this.keyPair = keyPair;
  }

  Future<String> getIpV4() async {
    for (var interface in await NetworkInterface.list()) {
      // todo: better choose interface
      if(interface.name == "Ethernet" || interface.name == "Wi-Fi") {
        // todo: better choose ip address
        return interface.addresses[0].address;
      }
    }
    return "Error. Ip not found";
  }

// BOTH USERS

  encrypt.Encrypter prepareEncrypterForKey(AsymmetricKey key) {
    return encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(
          key as Uint8List,
        ),
        mode: encrypt.AESMode.cbc,
      ),
    );
   }

  void startListeningForConnection() {
    getIpV4().then((ip) => ServerSocket.bind(ip, 4567).then(
      (ServerSocket myUser) {
        serverSocket = myUser;
        myUser.listen(handleConnectedUser);
      }
    ));
  }

// USER THAT INITIATED CONNECTION

  void connectToUser(String receiverIP) async {
    serverSocket!.close(); //close server, because you are connected
    RsaKeyHelper helper = RsaKeyHelper();
    Socket.connect(receiverIP, 4567).then((contactSocket) {
      print('Connected to: '
        '${contactSocket.remoteAddress.address}:${contactSocket.remotePort}');

      socket = contactSocket;

      // send public key after initiating a connection
      contactSocket.write(helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey));

      // listen for messages
      contactSocket.listen((data) {
        if(!hasConnectedUsersKey) {
          connectedUsersKey = data as PublicKey;
          hasConnectedUsersKey = true;
        } else if(!hasSessionKey) {
          // we decrypt session key using our private key
          encrypt.Encrypter encrypter = prepareEncrypterForKey(keyPair.privateKey);
          sessionKey = encrypter.decrypt(encrypt.Encrypted(data as Uint8List), iv: iv);
          hasSessionKey = true;
        }
      }, onDone: () {print("Connection closed"); contactSocket.destroy();});
    });
  }

// USER THAT ACCEPTED CONNECTION

  void handleConnectedUser(Socket connectedUserSocket) {
    print('Connection from ${connectedUserSocket.remoteAddress.address}:${connectedUserSocket.remotePort}');

    RsaKeyHelper helper = RsaKeyHelper();

    // send public key
    connectedUserSocket.write(helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey));
    
    generateSessionKey();

    // listen for messages
    connectedUserSocket.listen((data) {
      if(!hasConnectedUsersKey) {
        connectedUsersKey = data as PublicKey;
        hasConnectedUsersKey = true;
        initializeConnectionToConnectedUser(connectedUsersKey, connectedUserSocket);
      }
    }, onDone: () {print("Connection closed"); connectedUserSocket.destroy();});

    nextPageCallback();
  }

  void generateSessionKey() {
    sessionKey = Uuid().v4();
    hasSessionKey = true;
  }
  
  void initializeConnectionToConnectedUser(var data, var connectedUser) {
    // we encrypt session key using our connected user's public key and send it to connected user
    var encrypter = prepareEncrypterForKey(connectedUsersKey as AsymmetricKey);
    encrypt.Encrypted encryptedSessionKey = encrypter.encrypt(sessionKey, iv: iv);
    connectedUser.write(encryptedSessionKey);
  }
}
