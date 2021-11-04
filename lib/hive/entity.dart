import 'package:hive/hive.dart';

part 'entity.g.dart';

@HiveType(typeId: 0)
class Clock {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<Record> records;

  Clock({required this.name, required this.records});

  Clock.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        records =
            (json["records"] as List).map((e) => Record.fromJson(e)).toList();

  Map<String, dynamic> toJson() => {
        'name': name,
        'records': records.map((e) => e.toJson()).toList(),
      };
}

@HiveType(typeId: 1)
class Record {
  @HiveField(0)
  DateTime start;

  @HiveField(1)
  DateTime end;

  Record({required this.start, required this.end});

  Record.fromJson(Map<String, dynamic> json)
      : start = DateTime.parse(json["start"]),
        end = DateTime.parse(json["end"]);

  Map<String, dynamic> toJson() => {
        'start': start.toString(),
        'end': end.toString(),
      };
}
