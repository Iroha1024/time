import 'package:hive/hive.dart';

part 'entity.g.dart';

@HiveType(typeId: 0)
class Clock {
  @HiveField(0)
  int id;

  @HiveField(1)
  int localId;

  @HiveField(2)
  String name;

  Clock({required this.id, required this.name}) : localId = id;

  Clock.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        localId = json["id"],
        name = json["name"];
}

@HiveType(typeId: 1)
class Record {
  @HiveField(0)
  int id;

  @HiveField(1)
  int localId;

  @HiveField(2)
  DateTime start;

  @HiveField(3)
  DateTime end;

  @HiveField(4)
  int clockId;

  Record(
      {required this.id,
      required this.start,
      required this.end,
      required this.clockId})
      : localId = id;

  Record.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        localId = json["id"],
        start = DateTime.parse(json["start"]),
        end = DateTime.parse(json["end"]),
        clockId = json["clockId"];
}

@HiveType(typeId: 2)
class Activity {
  @HiveField(0)
  String path;

  @HiveField(1)
  String method;

  @HiveField(2)
  Map? data;

  @HiveField(3)
  int target;

  @HiveField(4)
  String box;

  Activity({
    required this.path,
    required this.method,
    this.data,
    required this.target,
    required this.box,
  });
}
