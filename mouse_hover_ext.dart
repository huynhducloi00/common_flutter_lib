import 'package:flutter/material.dart';
import 'dart:html' as html;
extension HoverExtension on Widget{
  // Remember to add this 'app-container' id to <body> tag
  static final appContainer =
  html.window.document.getElementById('app-container');
  Widget get showCursorOnHover {
    return MouseRegion(
      child: this,
      // When the mouse enters the widget set the cursor to pointer
      onHover: (event) {
        appContainer.style.cursor = 'pointer';
      },
      // When it exits set it back to default
      onExit: (event) {
        appContainer.style.cursor = 'default';
      },
    );
  }
}

class TextWithUnderline extends StatefulWidget {
  String text;
  TextStyle textStyle;
  TextWithUnderline(this.text, this.textStyle);
  @override
  _TextWithUnderlineState createState() => _TextWithUnderlineState();
}

class _TextWithUnderlineState extends State<TextWithUnderline> {
  // Remember to add this 'app-container' id to <body> tag
  static final appContainer =
  html.window.document.getElementById('app-container');
  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => _mouseEnter(true),
      onExit: (e) => _mouseEnter(false),
      child: Text(widget.text, style: widget.textStyle.copyWith(decoration: _hovering ? TextDecoration.underline:null),)
    );
  }
  void _mouseEnter(bool hover) {
    appContainer.style.cursor = hover ? 'pointer':'default';
    setState(() {
      _hovering = hover;
    });
  }
}
