import 'dart:convert';
import 'dart:io';

import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/models/user_model.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSuccessful = false;
  String? _uid;
  String? _phoneNumber;
  UserModel? _userModel;

  bool get isLoading => _isLoading;
  bool get isSuccessful => _isSuccessful;
  String? get uid => _uid;
  String? get phoneNumber => _phoneNumber;
  UserModel? get userModel => _userModel;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // check authentication state
  Future<bool> checkAuthenticationState() async {
    bool isSignedIn = false;

    await Future.delayed(const Duration(seconds: 2));

    if (_auth.currentUser != null) {
      _uid = _auth.currentUser!.uid;

      // get  user data from firestore
      await getUserDataFromFireStore();

      // sacn user data to shared preferences
      await saveUserDataToSharedPreferences();

      notifyListeners();

      isSignedIn = true;
    } else {
      isSignedIn = false;
    }

    return isSignedIn;
  }

  // check if user exists
  Future<bool> checkUserExists() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    if (documentSnapshot.exists) {
      return true;
    } else {
      return false;
    }
  }

  // update user status
  Future<void> updateUserStatus({required bool value}) async {
    await _firestore
        .collection(Constants.users)
        .doc(_auth.currentUser!.uid)
        .update({Constants.isOnline: value});
  }

  // get user data from firestore
  Future<void> getUserDataFromFireStore() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    _userModel =
        UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    notifyListeners();
  }

  // save user data to shared preferences
  Future<void> saveUserDataToSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        Constants.userModel, jsonEncode(userModel!.toMap()));
  }

  // get user data from shared preferences
  Future<void> getUserDataFromSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String userModelString =
        sharedPreferences.getString(Constants.userModel) ?? '';
    _userModel = UserModel.fromMap(jsonDecode(userModelString));
    _uid = _userModel!.uid;
    notifyListeners();
  }

  // sign in with phone number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Xác thực hoàn tất tự động
          await _auth.signInWithCredential(credential).then((value) async {
            _uid = value.user!.uid;
            _phoneNumber = value.user!.phoneNumber;
            _isSuccessful = true;
            _isLoading = false;
            notifyListeners();
          });
        },
        verificationFailed: (FirebaseAuthException error) {
          // Thất bại xác thực
          _isSuccessful = false;
          _isLoading = false;
          notifyListeners();
          // showSnackBar(context, error.toString());
          // Kiểm tra lỗi và hiển thị thông báo tương ứng
          if (error.code == 'invalid-phone-number') {
            showSnackBar(
                context, 'Số điện thoại không hợp lệ. Vui lòng thử lại.');
          } else {
            showSnackBar(
                context, error.message ?? 'Đã xảy ra lỗi. Vui lòng thử lại.');
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          // Mã OTP đã được gửi thành công
          _isLoading = false;
          notifyListeners();
          // Chuyển hướng đến màn hình xác thực OTP
          Navigator.of(context).pushNamed(
            Constants.otpScreen,
            arguments: {
              Constants.verificationId: verificationId,
              Constants.phoneNumber: phoneNumber,
            },
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Thời gian tự động lấy mã OTP hết hạn
        },
      );
    } catch (e) {
      // Xử lý ngoại lệ nếu có lỗi xảy ra
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, e.toString());
    }
  }

  // xác thực otp code
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    _isLoading = true;
    notifyListeners();

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );

    await _auth.signInWithCredential(credential).then((value) async {
      _uid = value.user!.uid;
      _phoneNumber = value.user!.phoneNumber;
      _isSuccessful = true;
      _isLoading = false;
      onSuccess();
      notifyListeners();
    }).catchError((e) {
      _isSuccessful = false;
      _isLoading = false;
      notifyListeners();
      // showSnackBar(context, e.toString());
      if (e.toString().contains('invalid-verification-code')) {
        showSnackBar(context, 'Mã OTP không đúng. Vui lòng thử lại.');
      } else {
        showSnackBar(context, 'Đã xảy ra lỗi. Vui lòng thử lại sau.');
      }
    });
  }

  // save user data to firestore
  void saveUserDataToFireStore({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (fileImage != null) {
        // upload image to storage
        String imageUrl = await storeFileToStorage(
          file: fileImage,
          reference: '${Constants.userImages}/${userModel.uid}',
        );

        userModel.image = imageUrl;
      }

      userModel.lastSeen = DateTime.now().microsecondsSinceEpoch.toString();
      userModel.createdAt = DateTime.now().microsecondsSinceEpoch.toString();

      _userModel = userModel;
      _uid = userModel.uid;

      // save user data to firestore
      await _firestore
          .collection(Constants.users)
          .doc(userModel.uid)
          .set(userModel.toMap());

      _isLoading = false;
      onSuccess();
      notifyListeners();
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      onFail(e.message.toString());
    }
  }

  // store file to storage and return file url
  Future<String> storeFileToStorage({
    required File file,
    required String reference,
  }) async {
    UploadTask uploadTask = _storage.ref().child(reference).putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    String fileUrl = await taskSnapshot.ref.getDownloadURL();
    return fileUrl;
  }

  // lay user theo id
  Stream<DocumentSnapshot> getUserStream({required String userID}) {
    return _firestore.collection(Constants.users).doc(userID).snapshots();
  }

  // lấy tất cả người dùng trừ người dùng đang đăng nhập
  Stream<QuerySnapshot> getAllUsersStream({required String userID}) {
    return _firestore
        .collection(Constants.users)
        .where(Constants.uid, isNotEqualTo: userID)
        .snapshots();
  }

  // gửi lời mời kết bạn
  Future<void> sendFriendRequest({
    required String friendID,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // add owner to friend requests list
      await _firestore.collection(Constants.users).doc(friendID).update({
        Constants.friendRequestsUIDs: FieldValue.arrayUnion([_uid]),
      });

      // add friend uid to friend requests sent list
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.sentFriendRequestsUIDs: FieldValue.arrayUnion([friendID]),
      });
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  Future<void> cancelFriendRequest({required String friendID}) async {
    try {
      // remove friend uid from friend requests list
      await _firestore.collection(Constants.users).doc(friendID).update({
        Constants.friendRequestsUIDs: FieldValue.arrayRemove([_uid]),
      });

      // remove friend uid from our friend requests sent list
      await _firestore.collection(Constants.users).doc(_uid).update({
        Constants.sentFriendRequestsUIDs: FieldValue.arrayRemove([friendID]),
      });
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  Future<void> acceptFriendRequest({required String friendID}) async {
    // thêm our uid vào danh sách bạn bè
    await _firestore.collection(Constants.users).doc(friendID).update({
      Constants.friendsUIDs: FieldValue.arrayUnion([_uid]),
    });

    // thêm friend uid vào danh sách bạn bè
    await _firestore.collection(Constants.users).doc(_uid).update({
      Constants.friendsUIDs: FieldValue.arrayUnion([friendID]),
    });

    // remove our uid from friends requests list
    await _firestore.collection(Constants.users).doc(friendID).update({
      Constants.sentFriendRequestsUIDs: FieldValue.arrayRemove([_uid]),
    });

    // remove friend uid from our friends requests sent list
    await _firestore.collection(Constants.users).doc(_uid).update({
      Constants.friendRequestsUIDs: FieldValue.arrayRemove([friendID]),
    });
  }

  // xóa bạn bè
  Future<void> removeFriend({required String friendID}) async {
    // remove our uid from friends list
    await _firestore.collection(Constants.users).doc(friendID).update({
      Constants.friendsUIDs: FieldValue.arrayRemove([_uid]),
    });

    // remove friend uid from our friends list
    await _firestore.collection(Constants.users).doc(_uid).update({
      Constants.friendsUIDs: FieldValue.arrayRemove([friendID]),
    });
  }

  // lấy danh sách bạn bè
  Future<List<UserModel>> getFriendsList(
    String uid,
    List<String> groupMembersUIDs,
  ) async {
    List<UserModel> friendsList = [];

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();

    List<dynamic> friendsUIDs = documentSnapshot.get(Constants.friendsUIDs);

    for (String friendUID in friendsUIDs) {
      // nếu danh sách groupMembersUID không trống và chứa FriendUID thì chúng ta bỏ qua người bạn này
      if (groupMembersUIDs.isNotEmpty && groupMembersUIDs.contains(friendUID)) {
        continue;
      }

      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.users).doc(friendUID).get();
      UserModel friend =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      friendsList.add(friend);
    }

    return friendsList;
  }

  // lấy danh sách lời mời kết bạn
  Future<List<UserModel>> getFriendRequestsList({
    required String uid,
    required String groupId,
  }) async {
    List<UserModel> friendsRequestsList = [];

    if (groupId.isNotEmpty) {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constants.groups).doc(groupId).get();

      List<dynamic> requestsUIDs =
          documentSnapshot.get(Constants.awaitingApprovalUIDs);

      for (String friendRequestUID in requestsUIDs) {
        DocumentSnapshot documentSnapshot = await _firestore
            .collection(Constants.users)
            .doc(friendRequestUID)
            .get();
        UserModel friendRequest =
            UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
        friendsRequestsList.add(friendRequest);
      }

      return friendsRequestsList;
    }

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(uid).get();

    List<dynamic> friendRequestsUIDs =
        documentSnapshot.get(Constants.friendRequestsUIDs);

    for (String friendRequestsUID in friendRequestsUIDs) {
      DocumentSnapshot documentSnapshot = await _firestore
          .collection(Constants.users)
          .doc(friendRequestsUID)
          .get();
      UserModel friendRequest =
          UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      friendsRequestsList.add(friendRequest);
    }

    return friendsRequestsList;
  }

  Future logout() async {
    await _auth.signOut();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    notifyListeners();
  }
}
