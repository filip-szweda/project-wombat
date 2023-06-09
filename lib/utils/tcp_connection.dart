import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:project_wombat/utils/key_pair.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:uuid/uuid.dart';

class TcpConnection {
  late KeyPair keyPair;
  ServerSocket? serverSocket;
  Function goToCommunicationPage;
  encrypt.IV iv = encrypt.IV(Uint8List(16));
  Uint8List? connectedUsersPublicKey;
  String? sessionKey;

  encrypt.AESMode cipherMode = encrypt.AESMode.cbc;

  TcpConnection({required this.goToCommunicationPage});

  void setKeyPair(KeyPair keyPair) {
    this.keyPair = keyPair;
  }

  void setCipherMode(encrypt.AESMode mode) {
    this.cipherMode = mode;
  }

//  __   __  ___               __   __  __   __
// |__) /  \  |  |__|    |  | (__' |__ |__) (__'
// |__) \__/  |  |  |    \__/ .__) |__ |  \ .__)

  Future<String> getIpV4() async {
    for (var interface in await NetworkInterface.list()) {
      // todo: better choose interface
      if (interface.name == "Ethernet" || interface.name == "Wi-Fi") {
        // todo: better choose ip address
        return interface.addresses[0].address;
      }
    }
    return "Error. Ip not found";
  }

  encrypt.Encrypter prepareEncrypterForKey(Uint8List keyChars) {
    encrypt.Key key = encrypt.Key(keyChars);
    print("original key length: ${key.length}");
    // key must be 32 bytes in length
    key = key.stretch(32);
    return encrypt.Encrypter(
      encrypt.AES(
        key,
        mode: cipherMode,
      ),
    );
  }

  void startListeningForConnection() {
    getIpV4()
        .then((ip) => ServerSocket.bind(ip, 4567).then((ServerSocket myUser) {
              serverSocket = myUser;
              myUser.listen(handleConnectedUser);
            }));
  }

  String convertPublicKeyToString(PublicKey key) {
    return RsaKeyHelper().encodePublicKeyToPemPKCS1(key as RSAPublicKey);
  }

  Uint8List convertPrivateKeyToChars(PrivateKey privateKey) {
    String pemFormat =
        RsaKeyHelper().encodePrivateKeyToPemPKCS1(privateKey as RSAPrivateKey);
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
      print(
          'Connected to: ${contactSocket.remoteAddress.address}:${contactSocket.remotePort}');

      sendPublicKey(contactSocket);
      generateSessionKey();

      goToCommunicationPage();

      // listen for messages
      contactSocket.listen((data) {
        if (connectedUsersPublicKey == null) {
          connectedUsersPublicKey = data;
          sendSessionKey(contactSocket);
        }
        print(String.fromCharCodes(data).trim());
      }, onDone: () {
        print("Connection closed");
        contactSocket.destroy();
      });

      contactSocket.write("elo elo 123 heloł");
      contactSocket.write("hahahahahaha");
      contactSocket.write(":<");
    });
  }

  void sendSessionKey(var connectedUser) {
    // we encrypt session key using our connected user's public key and send it to connected user
    var encrypter = prepareEncrypterForKey(connectedUsersPublicKey!);
    encrypt.Encrypted encryptedSessionKey =
        encrypter.encrypt(sessionKey!, iv: iv);
    connectedUser.write(encryptedSessionKey);
  }

//       __   __  __       _    __   __   __  __  ___         __      __   __             __  __  ___    __
// |  | (__' |__ |__)     /_\  /  ` /  ` |__ |__)  |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    /   \ \__, \__, |__ |     |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void sendPublicKey(Socket receiverSocket) {
    receiverSocket.write(keyPair.publicKeyAsString());
  }

  void handleConnectedUser(Socket connectedUserSocket) async {
    print(
        'Connection from ${connectedUserSocket.remoteAddress.address}:${connectedUserSocket.remotePort}');

    sendPublicKey(connectedUserSocket);

    goToCommunicationPage();

    // listen for messages
    connectedUserSocket.listen((data) {
      if (connectedUsersPublicKey == null) {
        connectedUsersPublicKey = data;
      } else if (sessionKey == null) {
        encrypt.Encrypter encrypter =
            prepareEncrypterForKey(keyPair.privateKeyAsBytes());
        sessionKey = encrypter.decrypt(encrypt.Encrypted(data), iv: iv);
      }
      print(String.fromCharCodes(data).trim());
    }, onDone: () {
      print("Connection closed");
      connectedUserSocket.destroy();
    });
  }
}
