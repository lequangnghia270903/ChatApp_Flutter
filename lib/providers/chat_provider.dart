import 'dart:io';

import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/last_message_model.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/models/message_reply_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  bool _isLoading = false;
  MessageReplyModel? _messageReplyModel;

  bool get isLoading => _isLoading;
  MessageReplyModel? get messageReplyModel => _messageReplyModel;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setMessageReplyModel(MessageReplyModel? messageReply) {
    _messageReplyModel = messageReply;
    notifyListeners();
  }

  // firebase initialization
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  // send text message to firebase
  Future<void> sendTextMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required String message,
    required MessageEnum messageType,
    required String groupID,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    // set loading to true
    setLoading(true);
    try {
      var messageID = const Uuid().v4();

      // 1. check if the message is a reply and add the replied message to the message
      String repliedMessage = messageReplyModel?.message ?? '';
      String repliedTo = messageReplyModel == null
          ? ''
          : _messageReplyModel!.isMe
              ? 'Bạn'
              : _messageReplyModel!.senderName;
      MessageEnum repliedMessageType =
          _messageReplyModel?.messageType ?? MessageEnum.text;

      // 2. update/set the messageMmodel
      final messageModel = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: contactUID,
        message: message,
        messageType: messageType,
        timeSent: DateTime.now(),
        messageID: messageID,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        isSeenBy: [sender.uid],
      );

      // 3. check if it is a group message and send to group else send to contact
      if (groupID.isNotEmpty) {
        // handle group message
        await _firestore
            .collection(Constants.groups)
            .doc(groupID)
            .collection(Constants.messages)
            .doc(messageID)
            .set(messageModel.toMap());

        // update the last message fo the group
        await _firestore.collection(Constants.groups).doc(groupID).update({
          Constants.lastMessage: message,
          Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constants.senderUID: sender.uid,
          Constants.messageType: messageType.name,
        });

        // set loading to true
        setLoading(false);
        onSuccess();
        // set message reply model to null
        setMessageReplyModel(null);
      } else {
        // handle contact message
        await handleContactMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSuccess: onSuccess,
          onError: onError,
        );

        // send message reply modoel to null
        setMessageReplyModel(null);
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  //  send file message to firebase
  Future<void> sendFileMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required File file,
    required MessageEnum messageType,
    required String groupID,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    // set loading to true
    setLoading(true);
    try {
      var messageID = const Uuid().v4();

      // 1. check if the message is a reply and add the replied message to the message
      String repliedMessage = messageReplyModel?.message ?? '';
      String repliedTo = messageReplyModel == null
          ? ''
          : _messageReplyModel!.isMe
              ? 'Bạn'
              : _messageReplyModel!.senderName;
      MessageEnum repliedMessageType =
          _messageReplyModel?.messageType ?? MessageEnum.text;

      // 2. upload file to firebase storage
      final ref =
          '${Constants.chatFiles}/${messageType.name}/${sender.uid}/$contactUID/$messageID';
      String fileUrl = await storeFileToStorage(file: file, reference: ref);

      // 3. update/set the messageMmodel
      final messageModel = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: contactUID,
        message: fileUrl,
        messageType: messageType,
        timeSent: DateTime.now(),
        messageID: messageID,
        isSeen: false,
        repliedMessage: repliedMessage,
        repliedTo: repliedTo,
        repliedMessageType: repliedMessageType,
        isSeenBy: [sender.uid],
      );

      // 4. check if it is a group message and send to group else send to contact
      if (groupID.isNotEmpty) {
        await _firestore
            .collection(Constants.groups)
            .doc(groupID)
            .collection(Constants.messages)
            .doc(messageID)
            .set(messageModel.toMap());

        // update the last message fo the group
        await _firestore.collection(Constants.groups).doc(groupID).update({
          Constants.lastMessage: fileUrl,
          Constants.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constants.senderUID: sender.uid,
          Constants.messageType: messageType.name,
        });

        // set loading to true
        setLoading(false);
        onSuccess();
        // set message reply model to null
        setMessageReplyModel(null);
      } else {
        // handle contact message
        await handleContactMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSuccess: onSuccess,
          onError: onError,
        );

        // send message reply modoel to null
        setMessageReplyModel(null);
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> handleContactMessage(
      {required MessageModel messageModel,
      required String contactUID,
      required String contactName,
      required String contactImage,
      required Function onSuccess,
      required Function(String p1) onError}) async {
    try {
      // 0. contact messageModel'
      final contactMessageModel = messageModel.copyWith(
        userID: messageModel.senderUID,
      );

      // 1. initinalize last message for the sender
      final senderLastMessage = LastMessageModel(
        senderUID: messageModel.senderUID,
        contactUID: contactUID,
        contactName: contactName,
        contactImage: contactImage,
        message: messageModel.message,
        messageType: messageModel.messageType,
        timeSent: messageModel.timeSent,
        isSeen: false,
      );

      // 2. initialize lasrt message for the contact
      final contactLastMessage = senderLastMessage.copyWith(
        contactUID: messageModel.senderUID,
        contactName: messageModel.senderName,
        contactImage: messageModel.senderImage,
      );

      // 3. send message to sender firestore location
      await _firestore
          .collection(Constants.users)
          .doc(messageModel.senderUID)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .doc(messageModel.messageID)
          .set(messageModel.toMap());

      // 4. send message to contact firestore location
      await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(messageModel.senderUID)
          .collection(Constants.messages)
          .doc(messageModel.messageID)
          .set(contactMessageModel.toMap());

      // 5. send the last message to sender firestore location
      await _firestore
          .collection(Constants.users)
          .doc(messageModel.senderUID)
          .collection(Constants.chats)
          .doc(contactUID)
          .set(senderLastMessage.toMap());

      // 6. send the last message to contact firestore location
      await _firestore
          .collection(Constants.users)
          .doc(contactUID)
          .collection(Constants.chats)
          .doc(messageModel.senderUID)
          .set(contactLastMessage.toMap());

      // 7. call the onSuccess function
      // set loading to false
      setLoading(false);
      onSuccess();
    } on FirebaseException catch (e) {
      onError(e.message ?? e.toString());
    } catch (e) {
      setLoading(false);
      onError(e.toString());
    }
  }

  // set message as seen
  Future<void> setMessageAsSeen({
    required String userID,
    required String contactUID,
    required String messageID,
    required String groupID,
  }) async {
    try {
      // 1. check if it is a group message
      if (groupID.isNotEmpty) {
        // handle group message
      } else {
        // handle contact message (1-1 message)
        // 2. update the current message as seen
        await _firestore
            .collection(Constants.users)
            .doc(userID)
            .collection(Constants.chats)
            .doc(contactUID)
            .collection(Constants.messages)
            .doc(messageID)
            .update({
          Constants.isSeen: true,
        });

        // 3. update the contact message as seen
        await _firestore
            .collection(Constants.users)
            .doc(contactUID)
            .collection(Constants.chats)
            .doc(userID)
            .collection(Constants.messages)
            .doc(messageID)
            .update({
          Constants.isSeen: true,
        });

        // 4. update the last message as seen for the current user
        await _firestore
            .collection(Constants.users)
            .doc(userID)
            .collection(Constants.chats)
            .doc(contactUID)
            .update({
          Constants.isSeen: true,
        });

        // 5. update the last message as seen for the contact
        await _firestore
            .collection(Constants.users)
            .doc(contactUID)
            .collection(Constants.chats)
            .doc(userID)
            .update({
          Constants.isSeen: true,
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // get chatsList stream
  Stream<List<LastMessageModel>> getChatsListStream(String userID) {
    return _firestore
        .collection(Constants.users)
        .doc(userID)
        .collection(Constants.chats)
        .orderBy(Constants.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LastMessageModel.fromMap(doc.data());
      }).toList();
    });
  }

  // stream messages from chats collection
  Stream<List<MessageModel>> getMessagesStream({
    required String userID,
    required String contactUID,
    required String isGroup,
  }) {
    // 1. check if it is a group message
    if (isGroup.isNotEmpty) {
      // handle group message
      return _firestore
          .collection(Constants.groups)
          .doc(contactUID)
          .collection(Constants.messages)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data());
        }).toList();
      });
    } else {
      // handle contact message
      return _firestore
          .collection(Constants.users)
          .doc(userID)
          .collection(Constants.chats)
          .doc(contactUID)
          .collection(Constants.messages)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data());
        }).toList();
      });
    }
  }

  // store file to storage and return file url
  Future<String> storeFileToStorage({
    required File file,
    required String reference,
  }) async {
    UploadTask uploadTask =
        _firebaseStorage.ref().child(reference).putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String fileUrl = await taskSnapshot.ref.getDownloadURL();
    return fileUrl;
  }
}
