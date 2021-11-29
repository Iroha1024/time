import 'package:shared_preferences/shared_preferences.dart';

const username = "username";
const token = "token";
const activity = "activity";

var prefs;
getStorage() async {
  prefs ??= await SharedPreferences.getInstance();
  return prefs;
}

Future init() async {
  final prefs = await getStorage();
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
  final prefs = await getStorage();
  prefs.setString(username, "");
  prefs.setString(token, "");
  prefs.setInt(activity, 0);
}

Future login(String _username, String _token) async {
  final prefs = await getStorage();
  prefs.setString(username, _username);
  prefs.setString(token, _token);
}

Future<String> getUserName() async {
  final prefs = await getStorage();
  return prefs.getString(username)!;
}

Future<String> getToken() async {
  final prefs = await getStorage();
  return prefs.getString(token)!;
}

Future setActivity(int id) async {
  final prefs = await getStorage();
  prefs.setInt(activity, id);
}

Future<int> getActivity() async {
  final prefs = await getStorage();
  return prefs.getInt(activity)!;
}
