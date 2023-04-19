import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:project_wombat/config.dart' as config;
import 'package:rsa_encrypt/rsa_encrypt.dart';

class Cryptography {
  late encrypt.Encrypter encrypter;
  late encrypt.IV iv;
  late AsymmetricKeyPair<PublicKey, PrivateKey> keyPair;

  Cryptography(String password) {
    crypto.Digest passwordHash = _calculateHash(password);
    Uint8List key = Uint8List.fromList(passwordHash.bytes);
    iv = encrypt.IV(Uint8List(16));

    encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(
          key,
        ),
        mode: encrypt.AESMode.cbc,
      ),
    );
  }

  Future<AsymmetricKeyPair<PublicKey, PrivateKey>> getKeyPair() async {
    String file = await findFileForHash();
    bool privateKeyNotFound = file.isEmpty;

    if (privateKeyNotFound) {
      keyPair = await _generateAndSaveKeyPair();
    } else {
      keyPair = await _retrieveKeyPair(file);
    }
    return keyPair;
  }

  Future<AsymmetricKeyPair<PublicKey, PrivateKey>> _retrieveKeyPair(
      String file) async {
    Uint8List bytes =
        File("${config.privateKeysPath}/$file").readAsBytesSync();
    String privateKey =
        encrypter.decrypt(encrypt.Encrypted(bytes), iv: iv);
    String publicKey =
        File("${config.publicKeysPath}/$file.pem").readAsStringSync();
    RsaKeyHelper helper = RsaKeyHelper();
    return AsymmetricKeyPair(helper.parsePublicKeyFromPem(publicKey),
        helper.parsePrivateKeyFromPem(privateKey));
  }

  Future<AsymmetricKeyPair<PublicKey, PrivateKey>>
      _generateAndSaveKeyPair() async {
    RsaKeyHelper helper = RsaKeyHelper();
    keyPair = await helper.computeRSAKeyPair(helper.getSecureRandom());

    String publicKey =
        helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey);
    String privateKey =
        helper.encodePrivateKeyToPemPKCS1(keyPair.privateKey as RSAPrivateKey);

    await _saveKeysToFiles(privateKey, publicKey);
    return keyPair;
  }

  Future<String> _saveKeysToFiles(String privateKey, String publicKey) async {
    encrypt.Encrypted privateKeyEncrypted =
        encrypter.encrypt(privateKey, iv: iv);
    String keyName = UniqueKey().toString();
    final File privateFile = await File("${config.privateKeysPath}/$keyName")
        .create(recursive: true);
    await privateFile.writeAsBytes(privateKeyEncrypted.bytes);
    final File publicFile = await File("${config.publicKeysPath}/$keyName.pem")
        .create(recursive: true);
    await publicFile.writeAsString(publicKey);
    return keyName;
  }

  crypto.Digest _calculateHash(String value) {
    List<int> bytes = utf8.encode(value);
    return crypto.sha256.convert(bytes);
  }

  Future<String> findFileForHash() async {
    createDirectoryStructure();
    List<String> filePaths = await Directory(config.privateKeysPath)
        .list()
        .map((file) => file.path)
        .toList();
    for (String filePath in filePaths) {
      if (await checkIfEncryptedCorrectly(filePath)) {
        return basename(filePath);
      }
    }
    return "";
  }

  Future<bool> checkIfEncryptedCorrectly(String filePath) async {
    Uint8List bytes = File(filePath).readAsBytesSync();
    try {
      await encrypter
          .decrypt(encrypt.Encrypted(bytes), iv: iv);
    } catch (e) {
      return false;
    }
    return true;
  }

  void createDirectoryStructure() {
    Directory(config.privateKeysPath).createSync();
    Directory(config.publicKeysPath).createSync();
  }
}
