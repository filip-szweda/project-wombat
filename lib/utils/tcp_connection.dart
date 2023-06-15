import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:project_wombat/utils/key_pair.dart';
import 'package:project_wombat/utils/message.dart';
import 'package:project_wombat/config.dart' as config;
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:uuid/uuid.dart';

class TcpConnection {
  late KeyPair keyPair;
  ServerSocket? serverSocket;
  Socket? contactSocket;
  Function goToCommunicationPage;
  Function(Message) showMessage = (message) {};
  encrypt_package.IV iv = encrypt_package.IV(Uint8List(16));
  KeyPair? connectedPublicKey;
  String sessionKey = "Not initialized";

  encrypt_package.AESMode cipherMode = encrypt_package.AESMode.cbc;

  TcpConnection({required this.goToCommunicationPage});

  void setKeyPair(KeyPair keyPair) {
    this.keyPair = keyPair;
  }

  void setCipherMode(encrypt_package.AESMode mode) {
    this.cipherMode = mode;
  }

  void setShowMessage(Function(Message) showMessage) {
    this.showMessage = showMessage;
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
    return "[ERROR] IPv4 address for Ethernet or Wi-Fi interface not found";
  }

  encrypt_package.Encrypter prepareEncrypterForKey(Uint8List keyChars) {
    encrypt_package.Key key = encrypt_package.Key(keyChars);
    print("[INFO] Original key length: ${key.length}");
    // key must be 32 bytes in length
    key = key.stretch(32);
    return encrypt_package.Encrypter(
      encrypt_package.AES(
        key,
        mode: cipherMode,
      ),
    );
  }

  void startListeningForConnection() {
    getIpV4().then(
      (ip) => ServerSocket.bind(ip, 4567).then(
        (ServerSocket myUser) {
              serverSocket = myUser;
              myUser.listen(handleConnectedUser);
        }
      )
    );
  }

  void sendMessage(Message message) {
    String json = jsonEncode(message);
    this.contactSocket!.encoding = utf8;
    this.contactSocket!.write(json + config.messageSeparator);
  }

  void sendPublicKey() {
    sendMessage(Message(type: Message.PUBLIC_KEY,value: keyPair.publicKeyAsPem()));
  }

  void sendString(String string) {
    sendMessage(Message(value: string));
  }

  void receiveMessages(Uint8List data) {
    List<String> messageStrings = utf8.decode(data).trim().split(config.messageSeparator);
    for (final messageString in messageStrings){
      if (messageString.length > 0) {
        print("[INFO] Received message: " + messageString);
        Message message = decodeMessage(messageString);
        print("[INFO] Decoded message: " + message.toString());
        handleMessage(message);
        print("[INFO] Handled message");
      }
    }
  }

  Message decodeMessage(String messageString) {
    Map<String, dynamic> json = jsonDecode(messageString) as Map<String, dynamic>;
    return Message.fromJson(json);
  }

  void handleMessage(Message message) {
    switch (message.type) {
      case Message.PUBLIC_KEY:
        connectedPublicKey = KeyPair.fromPublicKeyPem(message.value);
        print(message.value);
        break;
      case Message.SESSION_KEY:
        String decrypted = decrypt(message.value, keyPair.privateKey!);
        print(message.value);
        print(decrypted);
        break;
      case Message.DEFAULT:
        print(message.value);
        showMessage(message);
        break;
    }
  }

//       __   __  __              ___     _   ___         __      __   __             __  __  ___    __
// |  | (__' |__ |__)    | |\ | |  |  |  /_\   |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    | | \| |  |  | /   \  |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void sendSessionKey() async {
    sessionKey = Uuid().v4();
    while (connectedPublicKey == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    String cipher_text = encrypt(sessionKey, connectedPublicKey!.publicKey);

    sendMessage(Message(type: Message.SESSION_KEY, value: cipher_text));
  }

  void connectToUser(String receiverIP) {
    serverSocket!.close(); //close server, because you are connected
    Socket.connect(receiverIP, 4567).then((contactSocket) async {
      print('[INFO] Connected to: ${contactSocket.remoteAddress.address}:${contactSocket.remotePort}');

      this.contactSocket = contactSocket;

      sendPublicKey();
      sendSessionKey();
      
      goToCommunicationPage();

      contactSocket.listen(
        (data) => receiveMessages(data),
        onDone: () {
          print("[INFO] Connection closed");
          contactSocket.destroy();
        }
      );

      sendMessage(Message(value: "elo elo 123 heloł"));
      sendMessage(Message(value: "hahahahahaha"));
      sendMessage(Message(value: ":<"));
    });
  }

//       __   __  __       _    __   __   __  __  ___         __      __   __             __  __  ___    __
// |  | (__' |__ |__)     /_\  /  ` /  ` |__ |__)  |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    /   \ \__, \__, |__ |     |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void handleConnectedUser(Socket contactSocket) async {
    print('[INFO] Connection from ${contactSocket.remoteAddress.address}:${contactSocket.remotePort}');

    this.contactSocket = contactSocket;

    sendPublicKey();

    goToCommunicationPage();

    contactSocket.listen(
      (data) => receiveMessages(data),
      onDone: () {
        print("[INFO] Connection closed");
        contactSocket.destroy();
      }
    );
  }
}
