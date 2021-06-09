import 'package:flutter/material.dart';

class DaysButtonsWidget extends StatelessWidget {
  final List<String> days;
  final ValueChanged<String> onSelectedDay;

  const DaysButtonsWidget({
    Key key,
    @required this.days,
    @required this.onSelectedDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).unselectedWidgetColor;
    final allDays = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];

    return Container(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: background,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ToggleButtons(
            isSelected: allDays.map((pet) => days.contains(pet)).toList(),
            selectedColor: Colors.white,
            color: Colors.white,
            fillColor: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(10),
            renderBorder: false,
            children: allDays.map(buildDay).toList(),
            onPressed: (index) => onSelectedDay(allDays[index]),
          ),
        ),
      ),
    );
  }

  Widget buildDay(String text) => Text(text);
}
