import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UserSession extends ChangeNotifier {
  String? userId;
  String? email;
  String? branch;

  String? tempName;
  String? tempSessionId;

  bool isReady = false;

  final _uuid = const Uuid();

  // ---------------- NORMAL LOGIN ----------------
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

  // ---------------- NAME LOGIN ----------------
  void setTempUser({required String name, required String sessionId}) {
    tempName = name;
    tempSessionId = sessionId;

    userId = 'scanner_device';

    email = null;
    branch = null;

    isReady = true;
    notifyListeners();
  }

  bool get isTempUser => tempSessionId != null;
  bool get isAuthUser => email != null;

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
