import 'package:shared_preferences/shared_preferences.dart';

class DataPreferences {
  static SharedPreferences _preferences;

  static const _keyAmound = 'amound';
  static const _keyDays = 'days';
  static const _keyTimes = 'times';

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

//------------------------------------------------------------------------------

  static Future setAmound(String amound) async =>
      await _preferences.setString(_keyAmound, amound);

  static String getAmound() => _preferences.getString('amound') ?? '';

//------------------------------------------------------------------------------

  static Future setDays(List<String> days) async =>
      await _preferences.setStringList(_keyDays, days);

  static List<String> getDays() => _preferences.getStringList(_keyDays);

  //----------------------------------------------------------------------------

  static Future setTimes(List<String> times) async =>
      await _preferences.setStringList(_keyTimes, times);

  static List<String> getTimes() => _preferences.getStringList(_keyTimes);
}
