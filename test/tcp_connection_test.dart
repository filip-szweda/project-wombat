import 'package:flutter_test/flutter_test.dart';
import 'package:project_wombat/utils/key_pair.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';

void main() {
  late KeyPair keyPair;
  setUp(() async {
    RsaKeyHelper helper = RsaKeyHelper();
    keyPair = KeyPair(
        keyPair: await helper.computeRSAKeyPair(helper.getSecureRandom()));
  });

  test("encryptsDataWithPublicKeyAndSuccessfullyDecryptsThemWithPrivateKey",
      () {
    String dataToEncrypt = "test data to encrypt";
    String encrypted = encrypt(dataToEncrypt, keyPair.publicKey);
    String decrypted = decrypt(encrypted, keyPair.privateKey!);
    expect(decrypted, dataToEncrypt);
  });
}
