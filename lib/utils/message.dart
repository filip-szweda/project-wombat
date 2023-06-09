class Message {
  static const String PUBLIC_KEY = "PUBLIC_KEY";
  static const String SESSION_KEY = "SESSION_KEY";
  static const String DEFAULT = "DEFAULT";

  String type;
  String value;
  String sender;

  Message({required this.value, this.type = DEFAULT, this.sender = "Unknown"});

  Map toJson() => {
        'type': type,
        'value': value,
        'sender': sender,
      };
}
