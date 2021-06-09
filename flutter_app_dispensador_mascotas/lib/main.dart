import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mm_app/connection.dart';
import 'package:mm_app/dispensador.dart';
import 'package:mm_app/utils/data_preferences.dart';

Future main() async {
  runApp(MyApp());
  await DataPreferences.init();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.dark(),
        scaffoldBackgroundColor: Color(0xff8c52ff),
        accentColor: Colors.lightGreen.shade400,
        unselectedWidgetColor: Colors.deepPurple.shade200,
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.all(Colors.white),
        ),
      ),
      home: FutureBuilder(
        future: FlutterBluetoothSerial.instance.requestEnable(),
        builder: (context, future) {
          if (future.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                height: double.infinity,
                child: Center(
                  child: Icon(
                    Icons.bluetooth_disabled,
                    size: 200.0,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          } else if (future.connectionState == ConnectionState.done) {
            // return MyHomePage(title: 'Flutter Demo Home Page');
            return Home();
          } else {
            return Home();
          }
        },
        // child: MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          child: Text(
            'Conexión Bluetooth',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Color(0xff8c52ff),
        elevation: 0,
      ),
      body: SelectBondedDevicePage(
        onCahtPage: (device1) {
          BluetoothDevice device = device1;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ChatPage(server: device);
              },
            ),
          );
        },
      ),
    ));
  }
}
