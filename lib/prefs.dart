import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs._();

  static SharedPreferences? _instance;

  static SharedPreferences get instance => _instance!;

  static Future<void> init() async {
    _instance = await SharedPreferences.getInstance();
  }
}
