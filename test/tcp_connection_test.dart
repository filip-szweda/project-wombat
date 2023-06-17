import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:flutter_test/flutter_test.dart';
import 'package:project_wombat/utils/key_pair.dart';
import 'package:project_wombat/utils/message.dart';
import 'package:project_wombat/utils/tcp_connection.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:uuid/uuid.dart';

void main() {
  late KeyPair keyPair;
  late TcpConnection tcpConnection;
  setUp(() async {
    RsaKeyHelper helper = RsaKeyHelper();
    keyPair = KeyPair(
        keyPair: await helper.computeRSAKeyPair(helper.getSecureRandom()));
    tcpConnection = TcpConnection(goToCommunicationPage: () {});
  });

  test("encryptsDataWithPublicKeyAndSuccessfullyDecryptsThemWithPrivateKey",
      () {
    String dataToEncrypt = "test data to encrypt";
    String encrypted = encrypt(dataToEncrypt, keyPair.publicKey);
    String decrypted = decrypt(encrypted, keyPair.privateKey!);
    expect(decrypted, dataToEncrypt);
  });

  test("savesReceivedFileFromString", () async {
    var sessionKey = Uuid().v4().replaceAll("-", "");
    encrypt_package.Encrypter encrypter =
        tcpConnection.prepareEncrypterForKey(sessionKey);
    tcpConnection.encrypter = encrypter;
    String result = "";
    File inputFile = await File("test/resources/cubes.png");
    int packetSize = 512;
    Uint8List bytes = inputFile.readAsBytesSync();
    String base64data = base64Encode(bytes);
    List<String> frames = [];
    for (var i = 0; i < base64data.length; i += packetSize) {
      frames.add(base64data.substring(
          i,
          i + packetSize > base64data.length
              ? base64data.length
              : i + packetSize));
    }

    frames.forEach((element) {
      var value = tcpConnection.encryptString(element);
      var decryptString = tcpConnection.decryptString(value);
      result += decryptString;
    });
    expect(result, base64data);
  });

  test("encryptsDataWithSessionKeySendsItAndSuccessfullyDecrypts", () {
    encrypt_package.IV iv = encrypt_package.IV(Uint8List(16));
    var sessionKey = Uuid().v4().replaceAll("-", "");
    String dataToEncrypt = "test data to encrypt";

    encrypt_package.Encrypter encrypter =
        tcpConnection.prepareEncrypterForKey(sessionKey);

    encrypt_package.Encrypted encrypted =
        encrypter.encrypt(dataToEncrypt, iv: iv);

    Message message = Message(type: Message.DEFAULT, value: encrypted.base64);

    String json = jsonEncode(message);

    Uint8List list = Uint8List.fromList(json.codeUnits);

    tcpConnection.encrypter = encrypter;
    tcpConnection.receiveMessages(list);
  });
}
