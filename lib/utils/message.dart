class Message {
  static const String PUBLIC_KEY = "PUBLIC_KEY";
  static const String SESSION_KEY = "SESSION_KEY";
  static const String DEFAULT = "DEFAULT";
  static const String MULTIPART_START = "MULTIPART_START";
  static const String MULTIPART_CONTINUE = "MULTIPART_CONTINUE";
  static const String MULTIPART_END = "MULTIPART_END";

  String type;
  String value;
  String sender;

  Message({required this.value, this.type = DEFAULT, this.sender = "Unknown"});

  Map toJson() => {
    'type': type,
    'value': value,
    'sender': sender,
  };

  static Message fromJson(Map<String, dynamic> json) {
    return Message(type: json['type'], value: json['value'], sender: json['sender']);
  }

  String toString() {
    return "{\"type\": $type, \"value\": $value, \"sender\": $sender}";
  }
}
