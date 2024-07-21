class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime timestamp;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    this.mediaUrl,
    this.mediaType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': timestamp,
    };
  }
}
