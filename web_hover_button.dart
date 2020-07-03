import 'package:flutter/material.dart';
import 'package:lucidgoft/common/web_utils.dart';

class HoverButton extends StatefulWidget {
  final String title;
  final Color regularColor;
  final Color hoverColor;

  HoverButton({this.title, this.regularColor, this.hoverColor});

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _hovering=false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => hover(true),
      onExit: (e) => hover(false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
        child: Text(
          widget.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        decoration: BoxDecoration(
          color: _hovering ? widget.hoverColor : widget.regularColor,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  hover(bool hovering) {
    setCursor(hovering);
    setState(() {
      _hovering = hovering;
    });
  }
}
