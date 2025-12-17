import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  Future<bool> hasInternet() async {
    final results = await Connectivity().checkConnectivity();

    if (results.isEmpty) return false;

    if (results.contains(ConnectivityResult.none)) return false;

    return true;
  }
}
