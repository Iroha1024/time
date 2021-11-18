import 'package:dio/dio.dart';

import 'package:time/api/dio.dart';
import 'package:time/api/url.dart' as url;

Future<Response> login(String username, String password) {
  return instance()
      .post(url.login, data: {"username": username, "password": password});
}

Future<Response> createClock(String name) {
  return instance().post(url.clock, data: {"name": name});
}

Future<Response> updateClock(int id, String name) {
  return instance().patch("${url.clock}/$id", data: {"name": name});
}

Future<Response> deleteClock(int id) {
  return instance().delete("${url.clock}/$id");
}

Future<Response> createRecord(DateTime start, DateTime end, int clockId) {
  return instance().post(url.record, data: {
    "start": start.toString(),
    "end": end.toString(),
    "clockId": clockId,
  });
}

Future<Response> request(String path, String method, data) {
  return instance().request(path, data: data, options: Options(method: method));
}
