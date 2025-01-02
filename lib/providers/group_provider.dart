import 'dart:io';

import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/group_model.dart';
import 'package:chat_app_flutter/models/message_model.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class GroupProvider extends ChangeNotifier {
  bool _isSloading = false;

  GroupModel _groupModel = GroupModel(
    creatorUID: '',
    groupName: '',
    groupDescription: '',
    groupImage: '',
    groupID: '',
    lastMessage: '',
    senderUID: '',
    messageType: MessageEnum.text,
    messageID: '',
    timeSent: DateTime.now(),
    createdAt: DateTime.now(),
    editSettings: true,
    membersUIDs: [],
    adminsUIDs: [],
  );
  final List<UserModel> _groupMembersList = [];
  final List<UserModel> _groupAdminsList = [];

  // getters
  bool get isSloading => _isSloading;
  GroupModel get groupModel => _groupModel;
  List<UserModel> get groupMembersList => _groupMembersList;
  List<UserModel> get groupAdminsList => _groupAdminsList;

  // firebase initialization
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // setters
  void setIsSloading({required bool value}) {
    _isSloading = value;
    notifyListeners();
  }

  void setEditSettings({required bool value}) {
    _groupModel.editSettings = value;
    notifyListeners();
    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // update group settings in firestore
  Future<void> updateGroupDataInFireStore() async {
    try {
      await _firestore
          .collection(Constants.groups)
          .doc(_groupModel.groupID)
          .update(groupModel.toMap());
    } catch (e) {
      print(e.toString());
    }
  }

  // add a group member
  void addMemberToGroup({required UserModel groupMember}) {
    _groupMembersList.add(groupMember);
    _groupModel.membersUIDs.add(groupMember.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // add a member as an admin
  void addMemberToAdmins({required UserModel groupAdmin}) {
    _groupAdminsList.add(groupAdmin);
    _groupModel.adminsUIDs.add(groupAdmin.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  Future<void> setGroupModel({required GroupModel groupModel}) async {
    _groupModel = groupModel;
    notifyListeners();
  }

  // remove member from group
  Future<void> removeGroupMember({required UserModel groupMember}) async {
    _groupMembersList.remove(groupMember);
    // also remove this member from admins list if he is an admin
    _groupAdminsList.remove(groupMember);
    _groupModel.membersUIDs.remove(groupMember.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // remove admin from group
  void removeGroupAdmin({required UserModel groupAdmin}) {
    _groupAdminsList.remove(groupAdmin);
    _groupModel.adminsUIDs.remove(groupAdmin.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // get a list of goup members data from firestore
  Future<List<UserModel>> getGroupMembersDataFromFirestore({
    required bool isAdmin,
  }) async {
    try {
      List<UserModel> membersData = [];

      // get the list of membersUIDs
      List<String> membersUIDs =
          isAdmin ? _groupModel.adminsUIDs : _groupModel.membersUIDs;

      for (var uid in membersUIDs) {
        var user = await _firestore.collection(Constants.users).doc(uid).get();
        membersData.add(UserModel.fromMap(user.data()!));
      }

      return membersData;
    } catch (e) {
      return [];
    }
  }

  // update the groupMembersList
  Future<void> updateGroupMembersList() async {
    _groupMembersList.clear();

    _groupMembersList
        .addAll(await getGroupMembersDataFromFirestore(isAdmin: false));

    notifyListeners();
  }

  // update the groupAdminsList
  Future<void> updateGroupAdminsList() async {
    _groupAdminsList.clear();

    _groupAdminsList
        .addAll(await getGroupMembersDataFromFirestore(isAdmin: true));

    notifyListeners();
  }

  // clear group members list
  Future<void> clearGroupMembersList() async {
    _groupMembersList.clear();
    _groupAdminsList.clear();
    _groupModel = GroupModel(
      creatorUID: '',
      groupName: '',
      groupDescription: '',
      groupImage: '',
      groupID: '',
      lastMessage: '',
      senderUID: '',
      messageType: MessageEnum.text,
      messageID: '',
      timeSent: DateTime.now(),
      createdAt: DateTime.now(),
      editSettings: true,
      membersUIDs: [],
      adminsUIDs: [],
    );
    notifyListeners();
  }

  // get a list UIDs from group members list
  List<String> getGroupMembersUIDs() {
    return _groupMembersList.map((e) => e.uid).toList();
  }

  // get a list UIDs from group admins list
  List<String> getGroupAdminsUIDs() {
    return _groupAdminsList.map((e) => e.uid).toList();
  }

  // stream group data
  Stream<DocumentSnapshot> groupStream({required String groupID}) {
    return _firestore.collection(Constants.groups).doc(groupID).snapshots();
  }

  // stream users data from fireStore
  streamGroupMembersData({required List<String> membersUIDs}) {
    return Stream.fromFuture(Future.wait<DocumentSnapshot>(
      membersUIDs.map<Future<DocumentSnapshot>>((uid) async {
        return await _firestore.collection(Constants.users).doc(uid).get();
      }),
    ));
  }

  // tạo nhóm
  Future<void> createGroup({
    required GroupModel newGroupModel,
    required File? fileImage,
    // Gửi groupID qua callback
    required Function(String groupID) onSuccess,
    required Function(String) onFail,
  }) async {
    setIsSloading(value: true);

    try {
      var groupID = const Uuid().v4();
      newGroupModel.groupID = groupID;

      // kiểm tra xem file ảnh có null không
      if (fileImage != null) {
        // tải ảnh lên firebase storage
        final String imageUrl = await storeFileToStorage(
            file: fileImage, reference: '${Constants.groupImages}/$groupID');
        newGroupModel.groupImage = imageUrl;
      }

      // add the group admins
      newGroupModel.adminsUIDs = [
        newGroupModel.creatorUID,
        ...getGroupAdminsUIDs()
      ];

      // add the group members
      newGroupModel.membersUIDs = [
        newGroupModel.creatorUID,
        ...getGroupMembersUIDs()
      ];

      // cập nhật groupModel toàn cục
      setGroupModel(groupModel: newGroupModel);

      // thêm group vào firebase
      await _firestore
          .collection(Constants.groups)
          .doc(groupID)
          .set(groupModel.toMap());

      // set loading
      setIsSloading(value: false);
      // set onSuccess
      onSuccess(groupID); // Gửi groupID qua callback
    } catch (e) {
      setIsSloading(value: false);
      onFail(e.toString());
    }
  }

  // lấy danh sách các nhóm có chứa userId của người dùng hiện tại
  Stream<List<GroupModel>> GroupsStream({required String userId}) {
    return _firestore
        .collection(Constants.groups)
        // Kiểm tra trường 'membersUIDs' chứa userId
        .where(Constants.membersUIDs, arrayContains: userId)
        .snapshots()
        .asyncMap((event) {
      // Chuyển các doc thành GroupModel
      List<GroupModel> groups = [];
      for (var group in event.docs) {
        groups.add(GroupModel.fromMap(group.data()));
      }

      return groups;
    });
  }

  // check if is sender or admin
  bool isSenderOrAdmin({required MessageModel message, required String uid}) {
    if (message.senderUID == uid) {
      return true;
    } else if (_groupModel.adminsUIDs.contains(uid)) {
      return true;
    } else {
      return false;
    }
  }
}
