import 'package:flutter/material.dart';

class UserSession extends ChangeNotifier {
  String? userId;
  String? email;
  String? branch;

  String? tempName;
  String? tempSessionId;

  bool isReady = false;

  void setUser({
    required String userId,
    required String email,
    required String branch,
  }) {
    this.userId = userId;
    this.email = email;
    this.branch = branch;

    tempName = null;
    tempSessionId = null;

    isReady = true;
    notifyListeners();
  }

  void setTempUser({required String name, required String sessionId}) {
    tempName = name;
    tempSessionId = sessionId;

    userId = null;
    email = null;
    branch = null;

    isReady = true;
    notifyListeners();
  }

  bool get isTempUser => tempSessionId != null;
  bool get isAuthUser => userId != null;

  String get displayName {
    if (isAuthUser) return email ?? 'User';
    if (isTempUser) return tempName ?? 'Guest';
    return 'Guest';
  }

  void clear() {
    userId = null;
    email = null;
    branch = null;

    tempName = null;
    tempSessionId = null;

    isReady = false;
    notifyListeners();
  }
}
