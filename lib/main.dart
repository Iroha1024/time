import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

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

enum ToastColor { success, fail }

class _HomeState extends State<Home> {
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  _showToast(String text, ToastColor status) {
    Color color;
    switch (status) {
      case ToastColor.success:
        color = Colors.green[300]!;
        break;
      case ToastColor.fail:
        color = Colors.red[300]!;
        break;
    }

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: color,
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );

    fToast.showToast(
        child: toast,
        toastDuration: const Duration(seconds: 1),
        positionedToastBuilder: (context, child) {
          return child;
        });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box<Clock>("clock").listenable(),
        builder: (context, box, widget) {
          var clockList = (box as Box<Clock>).values.toList();

          var statusBar = SizedBox(
            height: MediaQuery.of(context).padding.top,
          );
          var toolBar = Row(
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () async {
                        FilePicker.platform.clearTemporaryFiles();
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles();
                        String str;
                        if (result != null) {
                          File file = File(result.files.single.path!);
                          str = await file.readAsString();
                        } else {
                          return;
                        }
                        List<Clock> clockList;
                        try {
                          List json = jsonDecode(str);
                          clockList =
                              json.map((e) => Clock.fromJson(e)).toList();
                        } catch (e) {
                          _showToast("导入失败，文件格式错误", ToastColor.fail);
                          return;
                        }
                        await box.clear();
                        box.addAll(clockList);
                        _showToast("导入成功", ToastColor.success);
                      },
                      icon: const Icon(
                        Icons.import_contacts,
                        size: 30,
                      )),
                  IconButton(
                      onPressed: () async {
                        var status = await Permission.storage.status;
                        if (!status.isGranted) {
                          await Permission.storage.request();
                        }

                        var clockList = Hive.box<Clock>('clock')
                            .values
                            .toList()
                            .map((e) => e.toJson())
                            .toList();
                        var encoder = const JsonEncoder.withIndent("  ");
                        String json = encoder.convert(clockList);

                        var path =
                            await ExtStorage.getExternalStoragePublicDirectory(
                                    ExtStorage.DIRECTORY_DOWNLOADS) +
                                "/storage.json";

                        File file = File(path);
                        try {
                          await file.writeAsString(json);
                        } catch (e) {
                          _showToast("导出失败", ToastColor.fail);
                          return;
                        }
                        _showToast("导出成功", ToastColor.success);
                      },
                      icon: const Icon(
                        Icons.download,
                        size: 30,
                      )),
                ],
              ),
              IconButton(
                  onPressed: () async {
                    await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          var hasError = false;
                          var advice = "";
                          return StatefulBuilder(builder: (context, setState) {
                            var textController = TextEditingController();

                            showAdvice(String text) {
                              setState(() {
                                hasError = true;
                                advice = text;
                              });
                            }

                            return AlertDialog(
                              title: const Text("添加时钟"),
                              content: Column(
                                children: [
                                  TextField(
                                    controller: textController,
                                    decoration: const InputDecoration(
                                      hintText: '名称',
                                    ),
                                  ),
                                  Container(
                                    child: Visibility(
                                      child: Text(
                                        advice,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                      visible: hasError,
                                    ),
                                    margin:
                                        const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                  )
                                ],
                                mainAxisSize: MainAxisSize.min,
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text("确定"),
                                  onPressed: () {
                                    var clockList = box.values.toList();
                                    var name = textController.text;
                                    if (name.isEmpty) {
                                      showAdvice("名称不能为空");
                                      return;
                                    }
                                    var duplicate = clockList
                                        .any((element) => element.name == name);
                                    if (duplicate) {
                                      showAdvice("名称不能重复");
                                      return;
                                    }
                                    var clock = Clock(name: name, records: []);
                                    box.add(clock);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          });
                        });
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 30,
                  )),
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          );
          var clockDetailList = Expanded(
              child: ListView.builder(
            itemCount: clockList.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              var clock = clockList[index];
              var time = 0;
              for (var element in clock.records) {
                time += element.end.difference(element.start).inMilliseconds;
              }

              var row = Container(
                child: Row(
                  children: [
                    Text(
                      clock.name,
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      "${formatTime(time)}",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                color: Colors.grey[200],
              );

              var slider = Slidable(
                actionPane: const SlidableBehindActionPane(),
                controller: sliderController,
                actionExtentRatio: 0.2,
                child: GestureDetector(
                    child: row,
                    onTap: () async {
                      var result =
                          await Navigator.of(context).push(MaterialPageRoute(
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
                              var textController = TextEditingController();

                              showAdvice(String text) {
                                setState(() {
                                  hasError = true;
                                  advice = text;
                                });
                              }

                              return AlertDialog(
                                title: const Text("修改名称"),
                                content: Column(
                                  children: [
                                    TextField(
                                      controller: textController,
                                      decoration: InputDecoration(
                                        hintText: clock.name,
                                      ),
                                    ),
                                    Container(
                                      child: Visibility(
                                        child: Text(
                                          advice,
                                          style: const TextStyle(
                                              color: Colors.red),
                                        ),
                                        visible: hasError,
                                      ),
                                      margin: const EdgeInsets.fromLTRB(
                                          0, 20, 0, 0),
                                    )
                                  ],
                                  mainAxisSize: MainAxisSize.min,
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("确定"),
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
                                          (element) => element.name == name);
                                      if (duplicate) {
                                        showAdvice("名称不能重复");
                                        return;
                                      }
                                      int index =
                                          box.values.toList().indexOf(clock);
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
          ));
          var emptyContent = Expanded(
              child: Container(
            child: Text(
              "什么都没有",
              style: TextStyle(fontSize: 30, color: Colors.grey[300]),
            ),
            alignment: Alignment.center,
          ));

          return Column(
            children: [
              statusBar,
              toolBar,
              if (clockList.isEmpty) emptyContent else clockDetailList
            ],
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
  bool isEnd = false;

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
    return WillPopScope(
        child: StreamBuilder<int>(
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
                      style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          decoration: TextDecoration.none),
                    ),
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                  Row(
                    children: [
                      TimerButton(
                        color: Colors.red,
                        onPressed: () {
                          if (start is DateTime) {
                            timer.onExecute.add(StopWatchExecute.stop);
                            var record =
                                Record(start: start, end: DateTime.now());
                            isEnd = true;
                            Navigator.of(context).pop(record);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        text: '结束',
                      ),
                      TimerButton(
                        color: Colors.green,
                        onPressed: () {
                          timer.onExecute.add(StopWatchExecute.start);
                          start = DateTime.now();
                        },
                        text: '开始',
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
        ),
        onWillPop: () async => isEnd);
  }
}

class TimerButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  final String text;

  const TimerButton(
      {required this.color, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: color,
        padding: const EdgeInsets.all(30),
        shape: const CircleBorder(),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }
}
