import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHelper {
  static const String viewModeKey = 'viewType';

  static Future<bool> getViewMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(viewModeKey) == 'grid'; // Default ke grid
  }

  static Future<void> saveViewMode(bool isGrid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(viewModeKey, isGrid ? 'grid' : 'list');
  }
}
