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
  Function nextPageCallback;

  var iv = encrypt.IV(Uint8List(16));

  PublicKey? connectedUsersPublicKey;
  
  bool hasConnectedUsersPublicKey = false;

  bool hasSessionKey = false;
  late String sessionKey;

  TcpConnection({required this.nextPageCallback});

  void setKeyPair(AsymmetricKeyPair<PublicKey, PrivateKey> keyPair) {
    this.keyPair = keyPair;
  }

//  __   __  ___               __   __  __   __ 
// |__) /  \  |  |__|    |  | (__' |__ |__) (__'
// |__) \__/  |  |  |    \__/ .__) |__ |  \ .__)

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

  String readStringFromChar(Uint8List chars) {
    return String.fromCharCodes(chars);
  }

  PublicKey parsePublicKeyFromChars(Uint8List chars) {
    return RsaKeyHelper().parsePublicKeyFromPem(readStringFromChar(chars));
  }

  String convertPublicKeyToString(PublicKey key) {
    return RsaKeyHelper().encodePublicKeyToPemPKCS1(key as RSAPublicKey);
  }

//       __   __  __              ___     _   ___         __      __   __             __  __  ___    __      
// |  | (__' |__ |__)    | |\ | |  |  |  /_\   |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    | | \| |  |  | /   \  |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void generateSessionKey() {
    sessionKey = Uuid().v4();
    hasSessionKey = true;
  }

  void connectToUser(String receiverIP) async {
    serverSocket!.close(); //close server, because you are connected
    Socket.connect(receiverIP, 4567).then((contactSocket) {
      print('Connected to: ${contactSocket.remoteAddress.address}:${contactSocket.remotePort}');

      sendPublicKey(contactSocket);

      generateSessionKey();
      hasSessionKey = true;

      // listen for messages
      contactSocket.listen((data) {
        if(!hasConnectedUsersPublicKey) {
          connectedUsersPublicKey = parsePublicKeyFromChars(data);
          hasConnectedUsersPublicKey = true;
          sendSessionKey(connectedUsersPublicKey, contactSocket);
        }
      }, onDone: () {print("Connection closed"); contactSocket.destroy();});
    });
  }

  void sendSessionKey(var data, var connectedUser) {
    // we encrypt session key using our connected user's public key and send it to connected user
    var encrypter = prepareEncrypterForKey(connectedUsersPublicKey as AsymmetricKey);
    encrypt.Encrypted encryptedSessionKey = encrypter.encrypt(sessionKey, iv: iv);
    connectedUser.write(encryptedSessionKey);
  }

//       __   __  __       _    __   __   __  __  ___         __      __   __             __  __  ___    __      
// |  | (__' |__ |__)     /_\  /  ` /  ` |__ |__)  |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    /   \ \__, \__, |__ |     |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void sendPublicKey(Socket receiverSocket) {
    receiverSocket.write(convertPublicKeyToString(keyPair.publicKey));
  }

  void handleConnectedUser(Socket connectedUserSocket) {
    print('Connection from ${connectedUserSocket.remoteAddress.address}:${connectedUserSocket.remotePort}');

    sendPublicKey(connectedUserSocket);

    // listen for messages
    connectedUserSocket.listen((data) {
      // dostalismy dane
      // robimy cos z danymi
      // connectedUserSocket.firstWhere((element) => false)
      // connectedUserSocket.first;

      if(!hasConnectedUsersPublicKey) {
        connectedUsersPublicKey = parsePublicKeyFromChars(data);
        hasConnectedUsersPublicKey = true;
      } else if(!hasSessionKey) {
        // we decrypt session key using our private key
        encrypt.Encrypter encrypter = prepareEncrypterForKey(keyPair.privateKey);
        sessionKey = encrypter.decrypt(encrypt.Encrypted(data), iv: iv);
        hasSessionKey = true;
      }
    }, onDone: () {print("Connection closed"); connectedUserSocket.destroy();});

    nextPageCallback();
  }
}
