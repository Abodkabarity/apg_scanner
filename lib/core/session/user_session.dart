class UserSession {
  String? email;
  String? branch;

  void setUser({required String email, required String branch}) {
    this.email = email;
    this.branch = branch;
  }

  void clear() {
    email = null;
    branch = null;
  }
}
