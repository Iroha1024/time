import 'package:hive/hive.dart';

part 'entity.g.dart';

@HiveType(typeId: 0)
class Clock {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<Record> records;

  Clock({this.id = 0, required this.name, required this.records});

  Clock.fromJson(Map<String, dynamic> json)
      : id = json["id"] ?? 0,
        name = json["name"],
        records =
            (json["records"] as List).map((e) => Record.fromJson(e)).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'records': records.map((e) => e.toJson()).toList(),
      };
}

@HiveType(typeId: 1)
class Record {
  @HiveField(0)
  int id;

  @HiveField(1)
  DateTime start;

  @HiveField(2)
  DateTime end;

  Record({this.id = 0, required this.start, required this.end});

  Record.fromJson(Map<String, dynamic> json)
      : id = json["id"] ?? 0,
        start = DateTime.parse(json["start"]),
        end = DateTime.parse(json["end"]);

  Map<String, dynamic> toJson() => {
        'id': id,
        'start': start.toString(),
        'end': end.toString(),
      };
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
  bool upload;

  Activity(
      {required this.path,
      required this.method,
      this.data,
      this.upload = false});
}
