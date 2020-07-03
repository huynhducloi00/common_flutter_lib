import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'web_utils.dart';

import 'common.dart';

extension HoverExtension on Widget {
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

TextWithUnderline getTextWithUnderline(text, style) =>
    TextWithUnderlineWeb(text, style);

class TextWithUnderlineWeb extends StatefulWidget implements TextWithUnderline {
  String text;
  TextStyle style;

  TextWithUnderlineWeb(this.text, this.style);

  @override
  _TextWithUnderlineWebState createState() => _TextWithUnderlineWebState();
}

class _TextWithUnderlineWebState extends State<TextWithUnderlineWeb> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (e) => _mouseEnter(true),
        onExit: (e) => _mouseEnter(false),
        child: Text(
          widget.text,
          style: widget.style.copyWith(
              decoration: _hovering ? TextDecoration.underline : null),
        ));
  }

  void _mouseEnter(bool hover) {
    setCursor(hover);
    setState(() {
      _hovering = hover;
    });
  }
}
