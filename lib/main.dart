import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_login/flutter_login.dart';

import 'package:time/api/index.dart';
import 'package:time/hive/index.dart' as hive;
import 'package:time/local_storage.dart' as storage;
import 'package:time/api/url.dart' as url;

void main() async {
  await hive.initHive();
  await storage.init();
  // await hive.checkPush();
  // await hive.checkPull();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(GetMaterialApp(
    theme: ThemeData(platform: TargetPlatform.iOS),
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('zh', 'CH'),
    ],
    locale: const Locale('zh'),
    initialRoute: "/",
    routes: {
      '/': (context) => App(),
      '/login': (context) => LoginView(),
    },
  ));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return View(
      child: HomeView(),
    );
  }
}

class View extends StatelessWidget {
  Widget child;
  bool hasAppBar;

  View({required this.child, this.hasAppBar = false});

  @override
  Widget build(BuildContext context) {
    var statusBar = Container(
      height: MediaQuery.of(context).padding.top,
      color: Colors.transparent,
    );
    return hasAppBar
        ? Scaffold(
            body: child,
            appBar: AppBar(),
          )
        : Scaffold(
            body: Column(
              children: [statusBar, Expanded(child: child)],
            ),
          );
  }
}

class LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: storage.getUserName(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return FlutterLogin(
            title: 'TIME',
            // logo: AssetImage('assets/images/ecorp.png'),
            onLogin: (data) async {
              var success = await storage.login(data.name, data.password);
              if (success) {
                Get.toNamed("/");
              }
            },
            onSignup: (_) => Future.delayed(Duration.zero),
            // onSubmitAnimationCompleted: () {
            //   Navigator.of(context).pushReplacement(MaterialPageRoute(
            //     builder: (context) => DashboardScreen(),
            //   ));
            // },
            onRecoverPassword: (_) => Future.delayed(Duration.zero),
            savedEmail: snapshot.data,
            userValidator: (_) => null,
            messages: LoginMessages(
              userHint: '用户名',
              passwordHint: '密码',
              confirmPasswordHint: '再次输入密码',
              loginButton: '登录',
              signupButton: '注册',
              forgotPasswordButton: '忘记密码',
              recoverPasswordButton: 'HELP ME',
              goBackButton: 'GO BACK',
              confirmPasswordError: 'Not match!',
              recoverPasswordDescription:
                  'Lorem Ipsum is simply dummy text of the printing and typesetting industry',
              recoverPasswordSuccess: 'Password rescued successfully',
            ),
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  ValueListenableBuilder2(
    this.first,
    this.second, {
    required this.builder,
  });

  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (_, a, __) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, __) {
            return builder(context, a, b);
          },
        );
      },
    );
  }
}

class HomeView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeViewState();
}

enum ToastColor { success, fail }

class _HomeViewState extends State<HomeView> {
  var sliderController = SlidableController();
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  _formatTime(int millisecond) {
    int s = (millisecond / 1000).floor();
    int h = (s / 3600).floor();
    s = s % 3600;
    int m = (s / 60).floor();
    s = s % 60;
    return "$h时$m分$s秒";
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
    return ValueListenableBuilder2(
        hive.getClockBox().listenable(), hive.getRecordBox().listenable(),
        builder: (BuildContext context, clockBox, recordBox) {
      var clockList = (clockBox as Box<hive.Clock>).values.toList();

      var toolBar = Row(
        children: [
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
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  visible: hasError,
                                ),
                                margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                              )
                            ],
                            mainAxisSize: MainAxisSize.min,
                          ),
                          actions: [
                            TextButton(
                              child: const Text("确定"),
                              onPressed: () async {
                                var clockList = clockBox.values.toList();
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
                                var clock = hive.Clock(
                                  id: hive.generateId(hive.clock),
                                  name: name,
                                );
                                try {
                                  var data =
                                      (await createClock(clock.name)).data;
                                  if (isSuccess(data)) {
                                    clock.id = hive.getClockId(data);
                                    await storage
                                        .setActivity(getActivity(data));
                                  }
                                } catch (e) {
                                  var box = hive.getActivityBox();
                                  box.add(hive.Activity(
                                      path: url.clock,
                                      method: post,
                                      data: {"name": clock.name},
                                      target: clock.id,
                                      box: hive.clock));
                                }
                                clockBox.add(clock);
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
        mainAxisAlignment: MainAxisAlignment.end,
      );
      var clockDetailList = Expanded(
          child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.builder(
                itemCount: clockList.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  var clock = clockList[index];
                  var time = 0;
                  var recordList = hive
                      .getRecordBox()
                      .values
                      .toList()
                      .where((e) => e.clockId == clock.id)
                      .toList();
                  for (var element in recordList) {
                    time +=
                        element.end.difference(element.start).inMilliseconds;
                  }

                  var row = Container(
                    child: Row(
                      children: [
                        Text(
                          clock.name,
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          "${_formatTime(time)}",
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    color: Colors.grey[200],
                  );

                  var slider = Slidable(
                    actionPane: const SlidableBehindActionPane(),
                    controller: sliderController,
                    actionExtentRatio: 0.2,
                    child: GestureDetector(
                        child: row,
                        onTap: () async {
                          var result = await Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (context) => TimerView(),
                          ));
                          if (result != null) {
                            var record = hive.Record(
                                id: hive.generateId(hive.record),
                                start: result["start"],
                                end: result["end"],
                                clockId: clock.id);

                            try {
                              var data = (await createRecord(
                                      record.start, record.end, clock.id))
                                  .data;
                              if (isSuccess(data)) {
                                record.id = hive.getRecordId(data);
                                await storage.setActivity(getActivity(data));
                              }
                            } catch (e) {
                              var box = hive.getActivityBox();
                              box.add(hive.Activity(
                                  path: url.record,
                                  method: post,
                                  data: {
                                    "start": record.start.toString(),
                                    "end": record.end.toString(),
                                    "clockId": clock.id,
                                  },
                                  target: record.id,
                                  box: hive.record));
                            }
                            var box = hive.getRecordBox();
                            box.add(record);
                          }
                        }),
                    actions: [
                      IconSlideAction(
                        caption: '统计',
                        color: Colors.green,
                        icon: Icons.query_builder,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => StatisticsMonthView(
                              clock: clock,
                            ),
                          ));
                        },
                      ),
                    ],
                    secondaryActions: [
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
                                    actions: [
                                      TextButton(
                                        child: const Text("确定"),
                                        onPressed: () async {
                                          var clockList =
                                              clockBox.values.toList();
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
                                          int index = clockBox.values
                                              .toList()
                                              .indexOf(clock);
                                          clock.name = name;

                                          try {
                                            var data = (await updateClock(
                                                    clock.id, clock.name))
                                                .data;
                                            if (isSuccess(data)) {
                                              storage.setActivity(
                                                  getActivity(data));
                                            }
                                          } catch (e) {
                                            var box = hive.getActivityBox();
                                            box.add(hive.Activity(
                                                path:
                                                    "${url.clock}/${clock.id}",
                                                method: patch,
                                                data: {"name": clock.name},
                                                target: clock.id,
                                                box: hive.clock));
                                          }
                                          clockBox.putAt(index, clock);
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
                        onTap: () async {
                          try {
                            var data = (await deleteClock(clock.id)).data;
                            if (isSuccess(data)) {
                              storage.setActivity(getActivity(data));
                            }
                          } catch (e) {
                            var box = hive.getActivityBox();
                            box.add(hive.Activity(
                                path: "${url.clock}/${clock.id}",
                                method: delete,
                                target: clock.id,
                                box: hive.clock));
                          }
                          int index = clockBox.values.toList().indexOf(clock);
                          clockBox.deleteAt(index);
                        },
                      ),
                    ],
                  );

                  return slider;
                },
              )));
      var emptyContent = Expanded(
          child: Container(
        child: Text(
          "什么都没有",
          style: TextStyle(fontSize: 30, color: Colors.grey[300]),
        ),
        alignment: Alignment.center,
      ));

      return Column(
        children: [toolBar, clockList.isEmpty ? emptyContent : clockDetailList],
      );
    });
  }
}

class TimerView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
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

            return View(
                child: Container(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      displayTime,
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                      ),
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
                            var record = {
                              "start": start,
                              "end": DateTime.now()
                            };
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
            ));
          },
        ),
        onWillPop: () async => isEnd);
  }
}

class TimerButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  final String text;

  TimerButton(
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

class StatisticsMonthView extends StatefulWidget {
  hive.Clock clock;

  StatisticsMonthView({required this.clock});

  State<StatefulWidget> createState() => _StatisticsMonthViewState();
}

class _StatisticsMonthViewState extends State<StatisticsMonthView> {
  DateTime selectionTime = DateTime.now();

  bool _isSameDay(
    DateTime time1,
    DateTime time2,
  ) =>
      DateTime(time1.year, time1.month, time1.day) ==
      DateTime(time2.year, time2.month, time2.day);

  _formatTime(DateTime time) {
    String h =
        time.hour < 10 ? "0" + time.hour.toString() : time.hour.toString();
    String m = time.minute < 10
        ? "0" + time.minute.toString()
        : time.minute.toString();
    String s = time.second < 10
        ? "0" + time.second.toString()
        : time.second.toString();
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var calendar = SfCalendar(
      view: CalendarView.month,
      showDatePickerButton: true,
      headerStyle:
          const CalendarHeaderStyle(textStyle: TextStyle(fontSize: 24)),
      headerHeight: 60,
      viewHeaderStyle: const ViewHeaderStyle(
        dayTextStyle: TextStyle(color: Colors.black, fontSize: 20),
      ),
      viewHeaderHeight: 50,
      selectionDecoration: const BoxDecoration(),
      monthCellBuilder: (BuildContext buildContext, MonthCellDetails details) {
        var date = details.date;
        var current = DateTime(date.year, date.month, date.day);
        var currentMonth =
            details.visibleDates[details.visibleDates.length ~/ 2].month;
        bool isSameMonth = currentMonth == date.month;
        bool hasRecord = hive
            .getRecordBox()
            .values
            .toList()
            .where((e) => e.clockId == widget.clock.id)
            .where((e) => _isSameDay(date, e.start) || _isSameDay(date, e.end))
            .isNotEmpty;
        var cell = Column(
          children: [
            Text(
              details.date.day.toString(),
              style: TextStyle(
                  fontSize: 18,
                  color: isSameMonth
                      ? _isSameDay(today, current)
                          ? Colors.white
                          : Colors.black
                      : Colors.grey,
                  fontWeight: FontWeight.normal),
            ),
            const SizedBox(
              height: 5,
            ),
            if (hasRecord)
              Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.green),
                width: 8,
                height: 8,
              )
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        );
        return Container(
          child: isSameMonth && _isSameDay(today, current)
              ? Container(
                  child: cell,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.blue),
                )
              : _isSameDay(selectionTime, current)
                  ? Container(
                      child: cell,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.cyan[200]!),
                    )
                  : cell,
        );
      },
      onTap: (CalendarTapDetails details) {
        if (details.targetElement == CalendarElement.calendarCell) {
          setState(() {
            selectionTime = details.date!;
          });
        }
      },
    );

    var recordList = hive
        .getRecordBox()
        .values
        .toList()
        .where((e) => e.clockId == widget.clock.id)
        .where((e) =>
            _isSameDay(e.start, selectionTime) ||
            _isSameDay(e.end, selectionTime))
        .toList();
    var content = recordList.isNotEmpty
        ? Row(
            children: [
              Container(
                child: Column(
                  children: [
                    Text(
                      "${selectionTime.month.toString()}月${selectionTime.day.toString()}日",
                      style: const TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.normal),
                    )
                  ],
                ),
                margin: const EdgeInsets.fromLTRB(10, 0, 20, 0),
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.builder(
                      itemCount: recordList.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        var record = recordList[index];
                        return Container(
                          child: Text(
                            "${_formatTime(record.start)}-${_formatTime(record.end)}",
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.green,
                          ),
                        );
                      }),
                ),
              )
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          )
        : const Center(
            child: Text(
            "无记录",
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey,
            ),
          ));

    return View(
      child: Column(
        children: [
          Expanded(
            child: calendar,
            flex: 2,
          ),
          Expanded(
            child: Container(
              child: content,
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            ),
          )
        ],
      ),
      hasAppBar: true,
    );
  }
}
