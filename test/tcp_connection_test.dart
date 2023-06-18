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
    Stopwatch stopwatch = Stopwatch()..start();
    var sessionKey = Uuid().v4().replaceAll("-", "");
    encrypt_package.Encrypter encrypter =
        tcpConnection.prepareEncrypterForKey(sessionKey);
    tcpConnection.encrypter = encrypter;
    File inputFile = await File("test/resources/500m1.txt");
    int packetSize = 512;
    print("start ${stopwatch.elapsed}");
    Uint8List bytes = inputFile.readAsBytesSync();
    print("file read as bytes ${stopwatch.elapsed}");
    String base64data = base64Encode(bytes);
    print("base 64 string ready ${stopwatch.elapsed}");
    String encrypted  = tcpConnection.encryptString(base64data);
    print("string encoded ${stopwatch.elapsed}");
    List<String> frames = [];
    for (var i = 0; i < encrypted.length; i += packetSize) {
      frames.add(encrypted.substring(
          i,
          i + packetSize > encrypted.length
              ? encrypted.length
              : i + packetSize));
    }
    print("string made into parts ${stopwatch.elapsed}");

    var stringBuffer = StringBuffer();

    for(String s in frames) {
      stringBuffer.write(s);
    }

    print("concatenated cipher ${stopwatch.elapsed}");
    var decryptString = tcpConnection.decryptString(stringBuffer.toString());
    print("deciphered result ${stopwatch.elapsed}");
    expect(decryptString, base64data);
    stopwatch.stop();
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
