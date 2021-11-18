import 'package:shared_preferences/shared_preferences.dart';

import 'package:time/api/index.dart' as request;

Future loadUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  var username = prefs.getString("username") ?? "";
  var token = prefs.getString("token") ?? "";
  return {"username": username, "token": token};
}

Future<bool> loginStorage(String username, String password) async {
  var data = (await request.login(username, password)).data;
  if (data["code"] == 0) {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("username", username);
    prefs.setString("token", data["data"]);
    return true;
  }
  return false;
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("token");
}
