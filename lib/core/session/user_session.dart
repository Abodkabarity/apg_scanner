import 'package:flutter/material.dart';

class UserSession extends ChangeNotifier {
  String? userId;
  String? email;
  String? branch;

  bool isReady = false;

  void setUser({
    required String userId,
    required String email,
    required String branch,
  }) {
    this.userId = userId;
    this.email = email;
    this.branch = branch;
    isReady = true;
    notifyListeners();
  }

  void clear() {
    userId = null;
    email = null;
    branch = null;
    isReady = false;
    notifyListeners(); // 🔥
  }
}
