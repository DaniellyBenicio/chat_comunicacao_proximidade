class ChatConversation {
  final String endpointId;
  final String displayName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatConversation({
    required this.endpointId,
    required this.displayName,
    this.lastMessage = "",
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  ChatConversation copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversation(
      endpointId: endpointId,
      displayName: displayName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'endpointId': endpointId,
        'displayName': displayName,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
        'unreadCount': unreadCount,
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) => ChatConversation(
        endpointId: json['endpointId'],
        displayName: json['displayName'],
        lastMessage: json['lastMessage'] ?? "",
        lastMessageTime: DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime']),
        unreadCount: json['unreadCount'] ?? 0,
      );
}