import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:path/path.dart';
import 'package:project_wombat/config.dart' as config;
import 'package:project_wombat/utils/key_pair.dart';
import 'package:project_wombat/utils/message.dart';
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
  encrypt_package.Encrypter? encrypter;
  String id;

  String multipartName = "";
  StringBuffer multipartContent = StringBuffer();

  encrypt_package.AESMode cipherMode = encrypt_package.AESMode.cbc;

  TcpConnection({required this.goToCommunicationPage}) : id = Uuid().v4();

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
        print(interface.addresses);
        return interface.addresses[0].address;
      }
    }
    return "[ERROR] IPv4 address for Ethernet or Wi-Fi interface not found";
  }

  encrypt_package.Encrypter prepareEncrypterForKey(String sessionKey) {
    Uint8List sessionKeyChars = Uint8List.fromList(sessionKey.codeUnits);
    encrypt_package.Key key = encrypt_package.Key(sessionKeyChars);
    return encrypt_package.Encrypter(
        encrypt_package.AES(key, mode: this.cipherMode));
  }

  void startListeningForConnection() {
    getIpV4().then((ip) =>
        ServerSocket.bind(ip, 4567).then((ServerSocket myUser) {
          serverSocket = myUser;
          myUser.listen(handleConnectedUser);
        }));
  }

  void sendMessage(Message message) {
    String json = jsonEncode(message);
    this.contactSocket!.encoding = utf8;
    this.contactSocket!.write(json + config.messageSeparator);
  }

  void sendPublicKey() {
    sendMessage(
        Message(type: Message.PUBLIC_KEY, value: keyPair.publicKeyAsPem()));
  }

  void sendString(String string) {
    var messageToBeShown =
        Message(type: Message.DEFAULT, value: string, sender: id);
    showMessage(messageToBeShown);
    String encrypted = encryptString(string);
    var messageToBeSent =
        Message(type: Message.DEFAULT, value: encrypted, sender: id);
    sendMessage(messageToBeSent);
  }

  String encryptString(String string) =>
      encrypter!.encrypt(string, iv: iv).base64;

  Future<bool> sendFile(File file) async {
    Stopwatch stopwatch = Stopwatch()..start();
    var messageToBeShown = Message(
        type: Message.DEFAULT, value: "Sent file: ${file.path}", sender: id);
    showMessage(messageToBeShown);
    int packetSize = 800;
    Uint8List bytes = file.readAsBytesSync();
    String base64data = base64Encode(bytes);
    String encrypted = encryptString(base64data);
    sendMessage(
      Message(
          value: encryptString(basename(file.path)),
          sender: id,
          type: Message.MULTIPART_START),
    );
    for (var i = 0; i < encrypted.length; i += packetSize) {
      String packet = encrypted.substring(
          i,
          i + packetSize > encrypted.length
              ? encrypted.length
              : i + packetSize);
      sendMessage(
          Message(value: packet, type: Message.MULTIPART_CONTINUE, sender: id));
    }

    sendMessage(
      Message(value: "Not important", type: Message.MULTIPART_END, sender: id),
    );
    print("All messages sent, it took ${stopwatch.elapsed}");
    stopwatch.stop();
    return Future(() => true);
  }

  void receiveMessages(Uint8List data) {
    // with multipart files the last element may not be the end of the file
    List<String> messageStrings =
        utf8.decode(data).trim().split(config.messageSeparator);
    for (String messageString in messageStrings) {
      if (messageString.length > 0) {
        // print("[INFO] Received message: " + messageString);
        Message message = decodeMessage(messageString);
        // print("[INFO] Decoded message: " + message.toString());
        handleMessage(message);
        // print("[INFO] Handled message");
      }
    }
  }

  Message decodeMessage(String messageString) {
    Map<String, dynamic> json =
        jsonDecode(messageString) as Map<String, dynamic>;
    return Message.fromJson(json);
  }

  void handleMessage(Message message) {
    switch (message.type) {
      case Message.PUBLIC_KEY:
        connectedPublicKey = KeyPair.fromPublicKeyPem(message.value);
        break;
      case Message.SESSION_KEY:
        String decryptedSessionKey =
            decrypt(message.value, keyPair.privateKey!);
        encrypter = prepareEncrypterForKey(decryptedSessionKey);
        break;
      case Message.DEFAULT:
        message.value = decryptString(message.value);
        print("[INFO] Decrypted message");
        print(message.value);
        showMessage(message);
        break;
      case Message.MULTIPART_START:
        multipartName = decryptString(message.value);
        multipartContent.clear();
        break;
      case Message.MULTIPART_CONTINUE:
        print(message.value.length);
        multipartContent.write(message.value);
        break;
      case Message.MULTIPART_END:
        Directory(config.receivedFilesPath).createSync();
        File("${config.receivedFilesPath}/$multipartName").writeAsBytes(
            base64Decode(decryptString(multipartContent.toString())));
        showMessage(Message(
            value: "File ${multipartName} was received",
            sender: message.sender));
        break;
    }
  }

  String decryptString(String message) {
    return encrypter!
        .decrypt(encrypt_package.Encrypted.fromBase64(message), iv: iv);
  }

//       __   __  __              ___     _   ___         __      __   __             __  __  ___    __
// |  | (__' |__ |__)    | |\ | |  |  |  /_\   |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    | | \| |  |  | /   \  |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void sendSessionKey() async {
    sessionKey = Uuid().v4().replaceAll("-", "");
    encrypter = prepareEncrypterForKey(sessionKey);

    while (connectedPublicKey == null) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    String cipher_text = encrypt(sessionKey, connectedPublicKey!.publicKey);

    sendMessage(Message(type: Message.SESSION_KEY, value: cipher_text));
  }

  void connectToUser(String receiverIP) {
    serverSocket!.close(); //close server, because you are connected
    Socket.connect(receiverIP, 4567).then((contactSocket) async {
      print(
          '[INFO] Connected to: ${contactSocket.remoteAddress.address}:${contactSocket.remotePort}');

      this.contactSocket = contactSocket;

      sendPublicKey();
      sendSessionKey();

      goToCommunicationPage();

      contactSocket.listen((data) => receiveMessages(data), onDone: () {
        print("[INFO] Connection closed");
        contactSocket.destroy();
      });
    });
  }

//       __   __  __       _    __   __   __  __  ___         __      __   __             __  __  ___    __
// |  | (__' |__ |__)     /_\  /  ` /  ` |__ |__)  |  | |\ | / __    /  ` /  \ |\ | |\ | |__ /  `  |  | /  \ |\ |
// \__/ .__) |__ |  \    /   \ \__, \__, |__ |     |  | | \| \__|    \__, \__/ | \| | \| |__ \__,  |  | \__/ | \|

  void handleConnectedUser(Socket contactSocket) async {
    print(
        '[INFO] Connection from ${contactSocket.remoteAddress.address}:${contactSocket.remotePort}');

    this.contactSocket = contactSocket;

    sendPublicKey();

    goToCommunicationPage();

    contactSocket.listen((data) => receiveMessages(data), onDone: () {
      print("[INFO] Connection closed");
      contactSocket.destroy();
    });
  }
}
