import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

import 'package:time/hive/index.dart';

void main() async {
  await initHive();
  runApp(MaterialApp(
    theme: ThemeData(platform: TargetPlatform.iOS),
    home: App(),
    debugShowCheckedModeBanner: false,
  ));
}

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Home(),
      appBar: AppBar(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

var sliderController = SlidableController();

formatTime(int millisecond) {
  int s = (millisecond / 1000).floor();
  int h = (s / 3600).floor();
  s = s % 3600;
  int m = (s / 60).floor();
  s = s % 60;
  return "$h时$m分$s秒";
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box<Clock>("clock").listenable(),
        builder: (context, box, widget) {
          var clockList = (box as Box<Clock>).values.toList();
          return Container(
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: IconButton(
                          onPressed: () async {
                            await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  var hasError = false;
                                  var advice = "";
                                  return StatefulBuilder(
                                      builder: (context, setState) {
                                    var textController =
                                        TextEditingController();

                                    showAdvice(String text) {
                                      setState(() {
                                        hasError = true;
                                        advice = text;
                                      });
                                    }

                                    return AlertDialog(
                                      title: Text("添加时钟"),
                                      content: Column(
                                        children: [
                                          TextField(
                                            controller: textController,
                                            decoration: new InputDecoration(
                                              hintText: '名称',
                                            ),
                                          ),
                                          Container(
                                            child: Visibility(
                                              child: Text(
                                                advice,
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              visible: hasError,
                                            ),
                                            margin: EdgeInsets.fromLTRB(
                                                0, 20, 0, 0),
                                          )
                                        ],
                                        mainAxisSize: MainAxisSize.min,
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text("确定"),
                                          onPressed: () {
                                            var clockList = box.values.toList();
                                            var name = textController.text;
                                            if (name.isEmpty) {
                                              showAdvice("名称不能为空");
                                              return;
                                            }
                                            var duplicate = clockList.any(
                                                (element) =>
                                                    element.name == name);
                                            if (duplicate) {
                                              showAdvice("名称不能重复");
                                              return;
                                            }
                                            var clock =
                                                Clock(name: name, records: []);
                                            box.add(clock);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  });
                                });
                          },
                          icon: Icon(
                            Icons.add,
                            size: 30,
                          )),
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.end,
                ),
                Expanded(
                    child: ListView.builder(
                  itemCount: clockList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    var clock = clockList[index];
                    var time = 0;
                    clock.records.forEach((element) {
                      time +=
                          element.end.difference(element.start).inMilliseconds;
                    });

                    var row = Container(
                      child: Container(
                          child: Row(
                        children: [
                          Text(
                            "${clock.name}",
                            style: TextStyle(fontSize: 20),
                          ),
                          Text(
                            "${formatTime(time)}",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      )),
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      color: Colors.grey[200],
                    );

                    var slider = Slidable(
                      actionPane: SlidableBehindActionPane(),
                      controller: sliderController,
                      actionExtentRatio: 0.2,
                      child: GestureDetector(
                          child: row,
                          onTap: () async {
                            var result = await Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (context) => Timer(),
                            ));
                            if (result is Record) {
                              clock.records.add(result);
                              int index = box.values.toList().indexOf(clock);
                              box.putAt(index, clock);
                            }
                          }),
                      secondaryActions: <Widget>[
                        IconSlideAction(
                          caption: '编辑',
                          color: Colors.blue.shade400,
                          icon: Icons.edit,
                          foregroundColor: Colors.white,
                          onTap: () async {
                            await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  var hasError = false;
                                  var advice = "";
                                  return StatefulBuilder(
                                      builder: (context, setState) {
                                    var textController =
                                        TextEditingController();

                                    showAdvice(String text) {
                                      setState(() {
                                        hasError = true;
                                        advice = text;
                                      });
                                    }

                                    return AlertDialog(
                                      title: Text("修改名称"),
                                      content: Column(
                                        children: [
                                          TextField(
                                            controller: textController,
                                            decoration: new InputDecoration(
                                              hintText: clock.name,
                                            ),
                                          ),
                                          Container(
                                            child: Visibility(
                                              child: Text(
                                                advice,
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                              visible: hasError,
                                            ),
                                            margin: EdgeInsets.fromLTRB(
                                                0, 20, 0, 0),
                                          )
                                        ],
                                        mainAxisSize: MainAxisSize.min,
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text("确定"),
                                          onPressed: () {
                                            var clockList = box.values.toList();
                                            var name = textController.text;
                                            if (name == clock.name) {
                                              showAdvice("名称未改变");
                                              return;
                                            }
                                            if (name.isEmpty) {
                                              showAdvice("名称不能为空");
                                              return;
                                            }
                                            var duplicate = clockList.any(
                                                (element) =>
                                                    element.name == name);
                                            if (duplicate) {
                                              showAdvice("名称不能重复");
                                              return;
                                            }
                                            int index = box.values
                                                .toList()
                                                .indexOf(clock);
                                            clock.name = name;
                                            box.putAt(index, clock);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  });
                                });
                          },
                        ),
                        IconSlideAction(
                          caption: '删除',
                          color: Colors.red.shade400,
                          icon: Icons.delete,
                          onTap: () {
                            int index = box.values.toList().indexOf(clock);
                            box.deleteAt(index);
                          },
                        ),
                      ],
                    );

                    return slider;
                  },
                ))
              ],
            ),
          );
        });
  }
}

class Timer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TimerState();
}

class _TimerState extends State<Timer> {
  var start;

  var timer = StopWatchTimer(
    mode: StopWatchMode.countUp,
  );

  @override
  void dispose() {
    super.dispose();
    timer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: timer.rawTime,
      initialData: 0,
      builder: (context, snap) {
        final value = snap.data;
        final displayTime = StopWatchTimer.getDisplayTime(value ?? 0);

        return Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  displayTime,
                  style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      decoration: TextDecoration.none),
                ),
              ),
              SizedBox(
                height: 100,
              ),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      padding: const EdgeInsets.all(20),
                      shape: CircleBorder(),
                    ),
                    onPressed: () {
                      if (start is DateTime) {
                        timer.onExecute.add(StopWatchExecute.stop);
                        var record = Record(start: start, end: DateTime.now());
                        Navigator.of(context).pop(record);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '结束',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green,
                      padding: const EdgeInsets.all(20),
                      shape: CircleBorder(),
                    ),
                    onPressed: () {
                      timer.onExecute.add(StopWatchExecute.start);
                      this.start = DateTime.now();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '开始',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              )
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          color: Colors.black,
        );
      },
    );
  }
}