import 'package:chat_app_flutter/constants.dart';

class GroupModel {
  String creatorUID;
  String groupName;
  String groupDescription;
  String groupImage;
  String groupID;
  String lastMessage;
  String senderUID;
  MessageEnum messageType;
  String messageID;
  DateTime timeSent;
  DateTime createdAt;
  bool editSettings;
  List<String> membersUIDs;
  List<String> adminsUIDs;

  GroupModel({
    required this.creatorUID,
    required this.groupName,
    required this.groupDescription,
    required this.groupImage,
    required this.groupID,
    required this.lastMessage,
    required this.senderUID,
    required this.messageType,
    required this.messageID,
    required this.timeSent,
    required this.createdAt,
    required this.editSettings,
    required this.membersUIDs,
    required this.adminsUIDs,
  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constants.creatorUID: creatorUID,
      Constants.groupName: groupName,
      Constants.groupDescription: groupDescription,
      Constants.groupImage: groupImage,
      Constants.groupID: groupID,
      Constants.lastMessage: lastMessage,
      Constants.senderUID: senderUID,
      Constants.messageType: messageType.name,
      Constants.messageID: messageID,
      Constants.timeSent: timeSent.millisecondsSinceEpoch,
      Constants.createdAt: createdAt.millisecondsSinceEpoch,
      Constants.editSettings: editSettings,
      Constants.membersUIDs: membersUIDs,
      Constants.adminsUIDs: adminsUIDs,
    };
  }

  // from map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      creatorUID: map[Constants.creatorUID] ?? '',
      groupName: map[Constants.groupName] ?? '',
      groupDescription: map[Constants.groupDescription] ?? '',
      groupImage: map[Constants.groupImage] ?? '',
      groupID: map[Constants.groupID] ?? '',
      lastMessage: map[Constants.lastMessage] ?? '',
      senderUID: map[Constants.senderUID] ?? '',
      messageType: map[Constants.messageType].toString().toMessageEnum(),
      messageID: map[Constants.messageID] ?? '',
      timeSent: DateTime.fromMillisecondsSinceEpoch(
          map[Constants.timeSent] ?? DateTime.now().millisecondsSinceEpoch),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map[Constants.createdAt] ?? DateTime.now().millisecondsSinceEpoch),
      editSettings: map[Constants.editSettings] ?? false,
      membersUIDs: List<String>.from(map[Constants.membersUIDs] ?? []),
      adminsUIDs: List<String>.from(map[Constants.adminsUIDs] ?? []),
    );
  }
}
