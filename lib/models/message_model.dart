import 'package:chat_app_flutter/constants.dart';

class MessageModel {
  final String senderUID;
  final String senderName;
  final String senderImage;
  final String contactUID;
  final String message;
  final MessageEnum messageType;
  final DateTime timeSent;
  final String messageID;
  final bool isSeen;
  final String repliedMessage;
  final String repliedTo;
  final MessageEnum repliedMessageType;
  final List<String> isSeenBy;

  MessageModel({
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.contactUID,
    required this.message,
    required this.messageType,
    required this.timeSent,
    required this.messageID,
    required this.isSeen,
    required this.repliedMessage,
    required this.repliedTo,
    required this.repliedMessageType,
    required this.isSeenBy,
  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.senderUID: senderUID,
      Constants.senderName: senderName,
      Constants.senderImage: senderImage,
      Constants.contactUID: contactUID,
      Constants.message: message,
      Constants.messageType: messageType.name,
      Constants.timeSent: timeSent.millisecondsSinceEpoch,
      Constants.messageID: messageID,
      Constants.isSeen: isSeen,
      Constants.repliedMessage: repliedMessage,
      Constants.repliedTo: repliedTo,
      Constants.repliedMessageType: repliedMessageType.name,
    };
  }

  // from map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderUID: map[Constants.senderUID] ?? '',
      senderName: map[Constants.senderName] ?? '',
      senderImage: map[Constants.senderImage] ?? '',
      contactUID: map[Constants.contactUID] ?? '',
      message: map[Constants.message] ?? '',
      messageType: map[Constants.messageType].toString().toMessageEnum(),
      timeSent: DateTime.fromMillisecondsSinceEpoch(map[Constants.timeSent]),
      messageID: map[Constants.messageID] ?? '',
      isSeen: map[Constants.isSeen] ?? false,
      repliedMessage: map[Constants.repliedMessage] ?? '',
      repliedTo: map[Constants.repliedTo] ?? '',
      repliedMessageType:
          map[Constants.repliedMessageType].toString().toMessageEnum(),
      isSeenBy: List<String>.from(map[Constants.isSeenBy] ?? []),
    );
  }

  copyWith({
    required String userID,
  }) {
    return MessageModel(
      senderUID: senderUID,
      senderName: senderName,
      senderImage: senderImage,
      contactUID: userID,
      message: message,
      messageType: messageType,
      timeSent: timeSent,
      messageID: messageID,
      isSeen: isSeen,
      repliedMessage: repliedMessage,
      repliedTo: repliedTo,
      repliedMessageType: repliedMessageType,
      isSeenBy: isSeenBy,
    );
  }
}
