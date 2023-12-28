import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification/Notificationdata.dart';

class AppSharedPrefs {


  static NotificationData notificationData = NotificationData();

  static const String CART_LIST = "CART_LIST";




  static SharedPreferences? preferences;

  /// this is used for a loged is true or false value


  static Future getCartProductList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(CART_LIST);
  }

  static Future setcartProductList(List<String> cartList) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userProfileJson = json.encode(cartList);

    return prefs.setStringList(CART_LIST, [userProfileJson]);
  }

  static Future<void> spClean() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(CART_LIST);
  }
}