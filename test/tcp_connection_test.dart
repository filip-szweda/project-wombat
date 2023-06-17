import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_wombat/utils/key_pair.dart';
import 'package:project_wombat/utils/message.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:project_wombat/utils/tcp_connection.dart';
import 'package:encrypt/encrypt.dart' as encrypt_package;
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
    int packetSize = 256;
    Uint8List bytes = inputFile.readAsBytesSync();
    String b64 = base64Encode(bytes);
    List<Uint8List> frames = [];
    for (var i = 0; i < bytes.length; i += packetSize) {
      frames.add(bytes.sublist(
          i, i + packetSize > bytes.length ? bytes.length : i + packetSize));
    }


    frames.forEach((element) {
      var value = tcpConnection.encryptString(base64Encode(element));
      var decryptString = tcpConnection.decryptString(value);
      result += decryptString;
      //print("decrypted string: ${decryptString}");
      //print("actual result: ${result}");
    });
    expect(result, b64);
    //var bytesAgain = base64Decode(result);
    //File("test/resources/savedCubes.png").writeAsBytes(bytesAgain);
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
