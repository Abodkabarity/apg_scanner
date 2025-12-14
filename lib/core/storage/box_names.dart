import '../di/injection.dart';
import '../session/user_session.dart';

class BoxNames {
  static String _uid() {
    final uid = getIt<UserSession>().userId;
    if (uid == null || uid.isEmpty) {
      throw Exception("UserSession.userId is null - login required");
    }
    return uid;
  }

  static String projects() => "projects_${_uid()}";
  static String stockItems() => "stock_items_${_uid()}";
  static String products() => "products_${_uid()}";
}
