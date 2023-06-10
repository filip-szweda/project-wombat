import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';

class KeyPair {
  RSAPrivateKey? privateKey;
  RSAPublicKey publicKey;

  KeyPair({required AsymmetricKeyPair<PublicKey, PrivateKey> keyPair})
      : privateKey = keyPair.privateKey as RSAPrivateKey,
        publicKey = keyPair.publicKey as RSAPublicKey;

  KeyPair.fromPublicKey({required this.publicKey});

  static KeyPair fromPublicKeyPem(String publicKeyPem) {
    RSAPublicKey key = RsaKeyHelper().parsePublicKeyFromPem(publicKeyPem);
    return KeyPair.fromPublicKey(publicKey: key);
  }

  String publicKeyAsPem() {
    return RsaKeyHelper().encodePublicKeyToPemPKCS1(publicKey);
  }
}
