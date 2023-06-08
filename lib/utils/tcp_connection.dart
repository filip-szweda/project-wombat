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
  encrypt.IV iv = encrypt.IV(Uint8List(16));
  late Uint8List? connectedUsersPublicKey;
  late String? sessionKey;
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

  encrypt.Encrypter prepareEncrypterForKey(Uint8List keyChars) {
    encrypt.Key key = encrypt.Key(keyChars);
    // key must be 32 bytes in length
    key = key.stretch(32);
    return encrypt.Encrypter(
      encrypt.AES(
        key,
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

  String convertPublicKeyToString(PublicKey key) {
    return RsaKeyHelper().encodePublicKeyToPemPKCS1(key as RSAPublicKey);
  }

  Uint8List convertPrivateKeyToChars(PrivateKey privateKey) {
    String pemFormat = RsaKeyHelper().encodePrivateKeyToPemPKCS1(privateKey as RSAPrivateKey);
    final List<int> codeUnits = pemFormat.codeUnits;
    return Uint8List.fromList(codeUnits);
  }

//       __   __  __              ___     _   ___         __      __   __             __  __  ___    __      
// |  | (__' |__ |__)    | |\ | |  |  |  /_\   |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    | | \| |  |  | /   \  |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void generateSessionKey() {
    sessionKey = Uuid().v4();
  }

  void connectToUser(String receiverIP) {
    serverSocket!.close(); //close server, because you are connected
    Socket.connect(receiverIP, 4567).then((contactSocket) async {
      print('Connected to: ${contactSocket.remoteAddress.address}:${contactSocket.remotePort}');

      sendPublicKey(contactSocket);
      generateSessionKey();

      // listen for messages
      contactSocket.listen((data) {
        if(connectedUsersPublicKey == null) {
          connectedUsersPublicKey = data;
          sendSessionKey(contactSocket);
        } else {
          contactSocket.write("elo elo 123 heloł");
          contactSocket.write("hahahahahaha");
          contactSocket.write(":<");
        }
        print(String.fromCharCodes(data).trim());
      }, onDone: () {print("Connection closed"); contactSocket.destroy();});
    });
  }

  void sendSessionKey(var connectedUser) {
    // we encrypt session key using our connected user's public key and send it to connected user
    var encrypter = prepareEncrypterForKey(connectedUsersPublicKey!);
    encrypt.Encrypted encryptedSessionKey = encrypter.encrypt(sessionKey!, iv: iv);
    connectedUser.write(encryptedSessionKey);
  }

//       __   __  __       _    __   __   __  __  ___         __      __   __             __  __  ___    __      
// |  | (__' |__ |__)     /_\  /  ` /  ` |__ |__)  |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    /   \ \__, \__, |__ |     |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void sendPublicKey(Socket receiverSocket) {
    receiverSocket.write(convertPublicKeyToString(keyPair.publicKey));
  }

  void handleConnectedUser(Socket connectedUserSocket) async {
    print('Connection from ${connectedUserSocket.remoteAddress.address}:${connectedUserSocket.remotePort}');

    sendPublicKey(connectedUserSocket);

    // listen for messages
    connectedUserSocket.listen((data) {
      if(connectedUsersPublicKey == null) {
        connectedUsersPublicKey = data;
      } else if (sessionKey == null) {
        encrypt.Encrypter encrypter = prepareEncrypterForKey(convertPrivateKeyToChars(keyPair.privateKey));
        sessionKey = encrypter.decrypt(encrypt.Encrypted(data), iv: iv);
      }
      print(String.fromCharCodes(data).trim());
    }, onDone: () {print("Connection closed"); connectedUserSocket.destroy();});

    nextPageCallback();
  }
}
