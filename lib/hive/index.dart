import 'package:hive_flutter/hive_flutter.dart';

import 'package:time/hive/entity.dart';
export 'package:time/hive/entity.dart';

Future initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ClockAdapter());
  Hive.registerAdapter(RecordAdapter());
  await Hive.openBox<Clock>("clock");
}
