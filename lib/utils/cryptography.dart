import 'dart:convert';
import 'package:crypto/crypto.dart';

String getHash(String value) {
  var bytes = utf8.encode(value);
  var hash = sha256.convert(bytes);
  return hash.toString();
}