import 'dart:io';
import 'package:pointycastle/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

import 'package:project_wombat/config.dart' as config;


class TcpConnection {
  final String receiverIP;
  final int sendPort; // one you are sending to
  final int receivePort; // one from which other clients sends data

  Socket? listeningSocket;
  Socket? sendingSocket;
  // crypto.AsymmetricKeyPair? keyPair;

  TcpConnection(this.receiverIP, this.sendPort, this.receivePort);

  void saveRSAPublicKey(RSAPublicKey rsaPublic) async {
    final File file = File(config.publicRSAKeyPath);
    await file.writeAsString(rsaPublic.modulus.toString() + "\n" + rsaPublic.exponent.toString());
  }

  void saveRSAPrivateKey(RSAPrivateKey rsaPrivate) async {
    final File file = File(config.privateRSAKeyPath);
    // TODO: encrypt using AES code cipher in CBC mode
    var encryptedModulus = rsaPrivate.modulus.toString();
    var encryptedExponent = rsaPrivate.exponent.toString();
    await file.writeAsString(encryptedModulus + "\n" + encryptedExponent);
  }

  void generateRSAKeys() async {
    var helper = RsaKeyHelper();
    var keyPair = await helper.computeRSAKeyPair(helper.getSecureRandom());
    final rsaPublic = keyPair.publicKey as RSAPublicKey;
    final rsaPrivate = keyPair.privateKey as RSAPrivateKey;
    saveRSAPublicKey(rsaPublic);
    saveRSAPrivateKey(rsaPrivate);
  }

  void loadRSAKeys() async {
    
  }

  void start() async {
    //listeningSocket = await Socket.connect(receiverIP, receivePort);
    //sendingSocket = await Socket.connect(receiverIP, sendPort);
    if(!await File(config.publicRSAKeyPath).exists() || !await File(config.privateRSAKeyPath).exists() ) {
      generateRSAKeys();
    }
    loadRSAKeys();
  }

  @override
  String toString() {
    return 'TcpConnection{receiverIP: $receiverIP, sendPort: $sendPort, receivePort: $receivePort}';
  }
}
