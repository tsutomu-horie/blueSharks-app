import 'package:flutter/material.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  // Constructor for the CustomSwitch widget to accept value and onChanged callback
  const CustomSwitch({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CustomSwitchState createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Switch(
        value: widget.value,
        onChanged: widget.onChanged,
        activeColor: Colors.white, // Thumb color when switched on
        activeTrackColor: BrandColor.main, // Track color when switched on
        inactiveThumbColor: Colors.white, // Thumb color when switched off
        inactiveTrackColor: Colors.grey, // Track color when switched off
      ),
    );
  }
}
