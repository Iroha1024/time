import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:time/local_storage.dart';
import 'package:time/api/url.dart';

const prefix = "/api/v1";

var options = BaseOptions(
  baseUrl: 'http://localhost:4000' + prefix,
  connectTimeout: 5000,
);

Dio instance() {
  Dio dio = Dio(options);
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    var url = options.uri.path.substring(prefix.length);
    if (!withoutAuth.contains(url)) {
      options.headers["Authorization"] = await getToken();
    }
    return handler.next(options);
  }, onResponse: (response, handler) {
    return handler.next(response);
  }, onError: (DioError e, handler) async {
    if (e.response?.statusCode == 401) {
      print("需要重新登录");
      Get.toNamed("/login");
    }
    if (e.type == DioErrorType.connectTimeout) {
      print("网络异常");
    }
    return handler.next(e);
  }));
  return dio;
}
