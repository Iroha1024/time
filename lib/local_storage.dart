import 'package:shared_preferences/shared_preferences.dart';

import 'package:time/api/index.dart' as request;

const username = "username";
const token = "token";
const activity = "activity";

Future init() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(username)) {
    prefs.setString(username, "");
  }
  if (!prefs.containsKey(token)) {
    prefs.setString(token, "");
  }
  if (!prefs.containsKey(activity)) {
    prefs.setInt(activity, 0);
  }
  // await clear();
}

Future clear() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setString(username, "");
  prefs.setString(token, "");
  prefs.setInt(activity, 0);
}

Future<bool> login(String username, String password) async {
  var data = (await request.login(username, password)).data;
  if (data["code"] == 0) {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(username, username);
    prefs.setString(token, data["data"]);
    return true;
  }
  return false;
}

Future<String> getUserName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(username)!;
}

Future<String> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(token)!;
}

Future setActivity(int id) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setInt(activity, id);
}

Future<int> getActivity() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(activity)!;
}
