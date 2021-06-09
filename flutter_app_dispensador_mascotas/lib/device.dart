import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothDeviceListEntry extends StatelessWidget {
  final Function onTap;
  final BluetoothDevice device;

  BluetoothDeviceListEntry({this.onTap, @required this.device});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(Icons.devices),
      title: Text(device.name ?? "Dispositivo desconocido"),
      subtitle: Text(device.address.toString()),
      trailing: TextButton(
        child: Text('Conectar'),
        onPressed: onTap,
        style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).unselectedWidgetColor,
            primary: Colors.white),
      ),
    );
  }
}
