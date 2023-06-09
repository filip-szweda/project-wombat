import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:project_wombat/utils/key_pair.dart';
import 'package:project_wombat/utils/message.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:uuid/uuid.dart';

class TcpConnection {
  late KeyPair keyPair;
  ServerSocket? serverSocket;
  Function goToCommunicationPage;
  encrypt.IV iv = encrypt.IV(Uint8List(16));
  String? connectedPublicKey;
  String sessionKey = "Not initialized";

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
      sendSessionKey(contactSocket);

      goToCommunicationPage();

      // listen for messages
      contactSocket.listen((data) => receiveMessage(data), onDone: () {
        print("Connection closed");
        contactSocket.destroy();
      });

      sendMessage(Message(value: "elo elo 123 heloł"), contactSocket);
      sendMessage(Message(value: "hahahahahaha"), contactSocket);
      sendMessage(Message(value: ":<"), contactSocket);
    });
  }

  void sendSessionKey(Socket destination) async {
    generateSessionKey();
    while (connectedPublicKey == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    var encrypter =
        prepareEncrypterForKey(convertStringToBytes(connectedPublicKey!));
    encrypt.Encrypted encryptedSessionKey =
        encrypter.encrypt(sessionKey, iv: iv);

    sendMessage(
        Message(
            type: Message.SESSION_KEY,
            value: convertBytesToString(encryptedSessionKey.bytes)),
        destination);
  }

//       __   __  __       _    __   __   __  __  ___         __      __   __             __  __  ___    __
// |  | (__' |__ |__)     /_\  /  ` /  ` |__ |__)  |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    /   \ \__, \__, |__ |     |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void sendPublicKey(Socket receiverSocket) {
    sendMessage(
        Message(type: Message.PUBLIC_KEY, value: keyPair.publicKeyAsString()),
        receiverSocket);
  }

  void handleConnectedUser(Socket connectedUserSocket) async {
    print(
        'Connection from ${connectedUserSocket.remoteAddress.address}:${connectedUserSocket.remotePort}');

    sendPublicKey(connectedUserSocket);

    goToCommunicationPage();

    // listen for messages
    connectedUserSocket.listen((data) => receiveMessage(data), onDone: () {
      print("Connection closed");
      connectedUserSocket.destroy();
    });
  }

  Uint8List convertStringToBytes(String str) {
    final List<int> codeUnits = str.codeUnits;
    return Uint8List.fromList(codeUnits);
  }

  String convertBytesToString(Uint8List bytes) {
    return String.fromCharCodes(bytes).trim();
  }

  void sendMessage(Message message, Socket destination) {
    String json = jsonEncode(message);
    destination.write(json);
  }

  void receiveMessage(Uint8List data) {
    Message message = decodeMessage(data);
    handleMessage(message);
  }

  Message decodeMessage(Uint8List data) {
    return jsonDecode(convertBytesToString(data));
  }

  void handleMessage(Message message) {
    switch (message.type) {
      case Message.PUBLIC_KEY:
        connectedPublicKey = message.value;
        print(message.value);
        break;
      case Message.SESSION_KEY:
        encrypt.Encrypter encrypter =
            prepareEncrypterForKey(keyPair.privateKeyAsBytes());
        sessionKey = encrypter
            .decrypt(encrypt.Encrypted.fromUtf8(message.value), iv: iv);
        print(message.value);
        break;
      case Message.DEFAULT:
        print(message.value);
        break;
    }
  }
}
