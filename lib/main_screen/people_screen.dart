import 'package:chat_app_flutter/constants.dart';
import 'package:chat_app_flutter/providers/authentication_provider.dart';
import 'package:chat_app_flutter/utilities/global_methods.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthenticationProvider>().userModel!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Tìm kiếm',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            //

            // danh sách người dùng
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: context
                    .read<AuthenticationProvider>()
                    .getAllUsersStream(userID: currentUser.uid),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Đã có lỗi xảy ra'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allUsers =
                      snapshot.data!.docs; // Danh sách toàn bộ người dùng
                  final filteredUsers = allUsers.where((document) {
                    Map<String, dynamic> data =
                        document.data()! as Map<String, dynamic>;
                    String name = data[Constants.name].toLowerCase();
                    return name
                        .contains(_searchQuery); // Lọc người dùng theo tên
                  }).toList();

                  // Kiểm tra danh sách hiển thị
                  final displayUsers =
                      _searchQuery.isEmpty ? allUsers : filteredUsers;

                  if (displayUsers.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Không có người dùng nào'
                            : 'Không tìm thấy người dùng phù hợp',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.openSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  }

                  // Sắp xếp dữ liệu theo tên người dùng
                  displayUsers.sort((a, b) {
                    var nameA = a['name'].toString().toLowerCase();
                    var nameB = b['name'].toString().toLowerCase();
                    return nameA.compareTo(nameB); // Sắp xếp theo tên
                  });

                  // Trả về danh sách đã sắp xếp
                  return ListView.builder(
                    itemCount: displayUsers.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = displayUsers[index];
                      Map<String, dynamic> data =
                          document.data()! as Map<String, dynamic>;

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: userImageWidget(
                            imageUrl: data[Constants.image],
                            radius: 40,
                            onTap: () {},
                          ),
                          title: Text(data[Constants.name]),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Constants.profileScreen,
                              arguments: data[Constants.uid],
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
