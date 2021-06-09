import 'package:flutter/material.dart';

class TimeWidget extends StatelessWidget {
  final String time;
  final VoidCallback onClicked;
  const TimeWidget({@required this.time, @required this.onClicked, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).unselectedWidgetColor),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 20,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onClicked,
          ),
        ],
      ),
    );
  }
}
