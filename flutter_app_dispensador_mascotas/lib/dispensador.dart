import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mm_app/utils/data_preferences.dart';
import 'package:mm_app/widget/days_buttons_widget.dart';
import 'package:mm_app/widget/time_widget.dart';
import 'package:mm_app/widget/title_widget.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = [];
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;
  //Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final formKey = GlobalKey<FormState>();
  String amound = '';
  List<String> days;
  List<String> times;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    amound = DataPreferences.getAmound() ?? '';
    days = DataPreferences.getDays() ?? [];
    times = DataPreferences.getTimes() ?? [];
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => primaryFocus.unfocus(),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              const SizedBox(height: 16),
              TitleWidget(text: 'Dispensador'),
              const SizedBox(height: 32),

//------------------------------------------------------------BUILD AMOUND------------------------------------------------------------------
              buildAmound(),
              const SizedBox(height: 12),
//------------------------------------------------------------BUILD AMOUND------------------------------------------------------------------
              buildDay(),
              const SizedBox(height: 12),

              times.isEmpty
                  ? Column(
                      children: [
                        SizedBox(height: 50),
                        Text(
                          'Sin horario',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.alarm_off,
                          size: 100,
                        )
                      ],
                    )
//------------------------------------------------------------------------------------------------------------------------------------------
                  : Column(children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Horario',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: times.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () async {
                              updateTime(index);
                            },
                            child: TimeWidget(
                              time: times[index],
                              onClicked: () => removeTime(index),
                            ),
                          );
                        },
                      ),
                    ]),

              //ListView.builder()),
              //buildTime(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Colors.white,
        unselectedItemColor: Colors.white,
        currentIndex: _currentIndex,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.save_alt,
              size: 50,
            ),
            label: 'Guardar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, size: 50),
            label: 'Añadir horario',
          ),
        ],
        onTap: (index) {
          _currentIndex = index;
          print(index);
          index == 0 ? save() : addTime();
        },
      ),
    );
  }

  void save() async {
    await DataPreferences.setAmound(amound);
    await DataPreferences.setDays(days);
    await DataPreferences.setTimes(times);

    List<String> date = [];
    for (String e in times) {
      date.add((int.parse(DateFormat("H").format(DateFormat.jm().parse(e))) *
                  3600 +
              int.parse(DateFormat("m").format(DateFormat.jm().parse(e))) * 60)
          .toString());
    }
    List<String> daysFormat = [];
    for (String e in days) {
      if (e == 'L') daysFormat.add('1');
      if (e == 'M') daysFormat.add('2');
      if (e == 'Mi') daysFormat.add('3');
      if (e == 'J') daysFormat.add('4');
      if (e == 'V') daysFormat.add('5');
      if (e == 'S') daysFormat.add('6');
      if (e == 'D') daysFormat.add('0');
    }
    String messageSnackbar = '';
    bool timeCompare = true;
    //Capturar excepcion
    int amoundInt = (int.parse(amound) / 10).round() * 10;
    int redondeo = 0;
    List<int> amoundList = [];
    List<int> timesCompare = [];
    timesCompare = date.map((e) => int.parse(e)).toList();
    timesCompare.sort();

    for (int i = 0; i < timesCompare.length - 1; i++) {
      if ((timesCompare[i] - timesCompare[i + 1]).abs() <= 300) {
        timeCompare = false;
      }
    }

    for (int i = times.length; i > 0; i--) {
      redondeo = ((amoundInt / 10) ~/ i) * 10;
      amoundList.add(redondeo);
      amoundInt -= redondeo;
    }

    if (!isConnected) {
      messageSnackbar =
          'Esperando Conexión...\nRegrese atras e intentelo de nuevo';
    } else if (times.length != times.toSet().length) {
      messageSnackbar = 'No se puede repetir horarios';
    } else if (timeCompare == false) {
      messageSnackbar =
          'La diferncia de horario tiene que ser mayor a 5 minutos';
    } else if (int.parse(amound) / times.length > 1000) {
      messageSnackbar = 'Cada porción tiene que ser menor a 1000 gramos';
    } else if (int.parse(amound) / times.length < 10) {
      messageSnackbar = 'Cada porción tiene que ser mayor a 10 gramos';
    } else if (isConnected) {
      messageSnackbar = '¡TODO LISTO!';
      _sendMessage(
          '{\"amound\":$amoundList,\"days\":$daysFormat,\"times\":$date}');
      //_sendMessage(amound);
    }
    final snackBar = SnackBar(
        backgroundColor: Theme.of(context).unselectedWidgetColor,
        content: Text(messageSnackbar,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white)));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void addTime() async {
    await _showTimePicker(context);
    setState(() {
      times.add(_fromTime.format(context));
    });

    print(times);
  }

  void removeTime(int index) {
    setState(() {
      times.removeAt(index);
    });
  }

  void updateTime(int index) async {
    await _showTimePicker(context);
    setState(() {
      times.insert(index, _fromTime.format(context));
    });
    removeTime(index + 1);
  }

  TimeOfDay _fromTime = TimeOfDay.fromDateTime(DateTime.now());

  Future<void> _showTimePicker(BuildContext context) async {
    final picked =
        await showTimePicker(context: context, initialTime: _fromTime);
    if (picked != null && picked != _fromTime) {
      setState(() {
        _fromTime = picked;
        print('Se presiono el ok');
      });
    }
  }

  Widget buildAmound() => buildTitle(
        title: 'Cantidad diaria',
        child: TextFormField(
          initialValue: amound,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
              borderSide: BorderSide(
                color: Theme.of(context).unselectedWidgetColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).unselectedWidgetColor,
              ),
            ),
            hintText: 'Cantidad en gramos...',
          ),
          onChanged: (amound) => setState(() => this.amound = amound),
        ),
      );

  Widget buildDay() => buildTitle(
        title: 'Días',
        child: DaysButtonsWidget(
          days: days ?? [],
          onSelectedDay: (day) => setState(
              () => days.contains(day) ? days.remove(day) : days.add(day)),
        ),
      );

  Widget buildTitle({
    @required String title,
    @required Widget child,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          child,
        ],
      );

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
