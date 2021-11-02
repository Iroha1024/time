import 'package:hive/hive.dart';

part 'entity.g.dart';

@HiveType(typeId: 0)
class Clock {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<Record> records;

  Clock({required this.name, required this.records});
}

@HiveType(typeId: 1)
class Record {
  @HiveField(0)
  DateTime start;

  @HiveField(1)
  DateTime end;

  Record({required this.start, required this.end});
}
