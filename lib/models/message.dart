class Message {
  final int? id;
  final String sender;
  final String content;
  final DateTime timestamp;

  Message({
    this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      sender: map['sender'],
      content: map['content'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}
