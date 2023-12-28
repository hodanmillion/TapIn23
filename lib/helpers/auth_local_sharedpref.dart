import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage.dart';

class SharedPrefAuth {
  static late SharedPreferences _prefsInstance;

  static Future<SharedPreferences> init() async {
    _prefsInstance = await SharedPref.init();
    return _prefsInstance;
  }


  static const String _date_timestamp_key = "key_date_timestamp";

  static Future<bool> saveDateTimestamp(String? date) async {
    bool? isSaved = await _prefsInstance.setString(_date_timestamp_key, date!);
    if (isSaved) {
      return true;
    } else {
      return false;
    }
  }

  static Future<String> getDateTimeStamp() async {
    String? email = await _prefsInstance.getString(_date_timestamp_key);
    if (email!.isNotEmpty) {
      return email;
    } else {
      return "";
    }
  }

}
