import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool isConnected = true;

  ConnectivityProvider() {
    _initializeConnectivity();
  }

  void _initializeConnectivity() async {
    // Kiểm tra trạng thái kết nối ban đầu
    List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);

    // Lắng nghe thay đổi kết nối mạng
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    isConnected = result.isNotEmpty &&
        result.first != ConnectivityResult.none; // true nếu có mạng
    notifyListeners(); // Thông báo thay đổi
  }
}
