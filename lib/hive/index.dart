import 'package:hive_flutter/hive_flutter.dart';

import 'package:time/hive/entity.dart';
import 'package:time/api/index.dart';
import 'package:time/local_storage.dart' as storage;

export 'package:time/hive/entity.dart';

const clock = "clock";
const record = "record";
const activity = "activity";

Future initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ClockAdapter());
  Hive.registerAdapter(RecordAdapter());
  Hive.registerAdapter(ActivityAdapter());
  await Hive.openBox<Clock>(clock);
  await Hive.openBox<Record>(record);
  await Hive.openBox<Activity>(activity);
  // await clear();
}

Box<Clock> getClockBox() => Hive.box<Clock>(clock);

Box<Record> getRecordBox() => Hive.box<Record>(record);

Box<Activity> getActivityBox() => Hive.box<Activity>(activity);

Box getBoxByName(String name) {
  late Box box;
  switch (name) {
    case clock:
      box = getClockBox();
      break;
    case record:
      box = getRecordBox();
      break;
    case activity:
      box = getActivityBox();
      break;
  }
  return box;
}

clear() async {
  for (var element in [getClockBox(), getRecordBox(), getActivityBox()]) {
    await element.clear();
  }
}

int generateId(String name) {
  var box = getBoxByName(name);
  try {
    int id = box.values.last.id;
    return id > 0 ? -(id + 1) : id - 1;
  } catch (e) {
    return -1;
  }
}

int getClockId(Map data) => data["data"]["clock"]["id"];

int getRecordId(Map data) => data["data"]["record"]["id"];

updateLocalId(int id, String name, Map data) {
  var box = getBoxByName(name);
  var target = box.values.firstWhere((e) => e.id == id);
  late int newId;
  switch (name) {
    case clock:
      newId = getClockId(data);
      break;
    case record:
      newId = getRecordId(data);
      break;
  }
  int index = box.values.toList().indexOf(target);
  target.id = newId;
  box.putAt(index, target);
}

updateRequestId(
  int id,
  String name,
) {
  var box = getBoxByName(name);
  var target = box.values.firstWhere((e) => e.localId == id);
  return target.id;
}

// 若是patch 和 delete请求，id为负数（即为本地id）则替换
// 若是post请求（新增操作），新增成功后更新本地id
Future checkPush() async {
  var box = getActivityBox();
  List<int> successList = [];
  var values = box.values.toList();
  for (var activity in values) {
    try {
      var path = activity.path;
      if (activity.method == patch || activity.method == delete) {
        var group = path.split("/");
        if (activity.target < 0) {
          group[group.length - 1] =
              updateRequestId(activity.target, activity.box);
          path = group.join("/");
        }
      }
      var data = (await request(path, activity.method, activity.data)).data;
      if (isSuccess(data)) {
        successList.add(values.indexOf(activity));
        if (activity.method == post) {
          updateLocalId(activity.target, activity.box, data);
        }
      }
    } catch (e) {
      break;
    }
  }
  for (var index in successList.reversed) {
    box.deleteAt(index);
  }
}

Future checkPull() async {
  var id = await storage.getActivity();
  var data = (await findActivity(id)).data;
  if (isSuccess(data)) {
    var activity = getActivity(data);
    storage.setActivity(activity);
    if (id == activity) {
      return;
    }
    var clock = data["data"]["clock"];
    var record = data["data"]["record"];
    await Pull.create("clock", clock);
    await Pull.create("record", record);
    await Pull.update("clock", clock);
    await Pull.update("record", record);
    await Pull.remove("clock", clock);
    await Pull.remove("record", record);
  }
}

class Pull {
  static Future create(String name, Map json) async {
    var box = getBoxByName(name);
    List create = json["create"];
    var data;
    for (var item in create) {
      switch (name) {
        case clock:
          data = Clock.fromJson(item);
          break;
        case record:
          data = Record.fromJson(item);
          break;
      }
      await box.add(data);
    }
  }

  static Future update(String name, Map json) async {
    var box = getBoxByName(name);
    var list = box.values.toList();
    List update = json["update"];
    var data;
    for (var item in update) {
      switch (name) {
        case clock:
          data = Clock.fromJson(item);
          break;
        case record:
          data = Record.fromJson(item);
          break;
      }
      int id = data.id;
      int index = list.indexWhere((e) => e.id == id);
      await box.putAt(index, data);
    }
  }

  static Future remove(String name, Map json) async {
    var box = getBoxByName(name);
    var list = box.values.toList();
    List remove = json["remove"];
    for (var id in remove) {
      int index = list.indexWhere((e) => e.id == id);
      await box.deleteAt(index);
    }
  }
}
