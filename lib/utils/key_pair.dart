import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';

class KeyPair {
  AsymmetricKeyPair<PublicKey, PrivateKey> keyPair;

  KeyPair({required this.keyPair});

  String publicKeyAsString() {
    return RsaKeyHelper()
        .encodePublicKeyToPemPKCS1(keyPair.privateKey as RSAPublicKey);
  }

  Uint8List privateKeyAsBytes() {
    String pemFormat = RsaKeyHelper()
        .encodePrivateKeyToPemPKCS1(keyPair.privateKey as RSAPrivateKey);
    final List<int> codeUnits = pemFormat.codeUnits;
    return Uint8List.fromList(codeUnits);
  }
}
