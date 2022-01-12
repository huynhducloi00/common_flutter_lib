import '../utils.dart';
import 'hover_button_interface.dart';
import 'package:flutter/material.dart';

import 'web_utils.dart';

class HoverButtonImpl extends HoverButtonInterface {
  @override
  Widget createButton(Function? onPressed,
      {String? title,
      TextAlign align = TextAlign.start,
      IconData? iconData,
      Color? regularColor,
      Color? hoverColor,
      Color textColor = Colors.white,
      Color iconColor = Colors.black,
      bool isDense = false}) {
    return HoverButton(onPressed, title, align, iconData, regularColor,
        hoverColor, textColor, iconColor, isDense);
  }
}

class HoverButton extends StatefulWidget {
  final Function? onPressed;
  final String? title;
  final TextAlign align;
  final IconData? iconData;
  final Color? regularColor;
  final Color? hoverColor;
  final Color iconColor;
  final Color textColor;
  final bool isDense;

  HoverButton(
      this.onPressed,
      this.title,
      this.align,
      this.iconData,
      this.regularColor,
      this.hoverColor,
      this.textColor,
      this.iconColor,
      this.isDense);

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    bool showEmptyPlaceHolder = isStringEmpty(widget.title) && widget.iconData == null;
    return GestureDetector(
      onTap: widget.onPressed as void Function()?,
      child: MouseRegion(
        onEnter: (e) => hover(true),
        onExit: (e) => hover(false),
        child: Container(
          padding: widget.isDense
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                showEmptyPlaceHolder || widget.iconData!=null ? Icon(
                      widget.iconData,
                      color: widget.iconColor,
                    ):null,
                (widget.iconData != null && !isStringEmpty(widget.title))
                    ? SizedBox(
                        width: widget.isDense ? 8: 15,
                      )
                    : null,
                isStringEmpty(widget.title)
                    ? null
                    : Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: 18,
                          color: widget.textColor,
                          decoration: TextDecoration.none,
                        ),
                      )
              ].where((element) => element != null).toList() as List<Widget>),
          decoration: BoxDecoration(
            color: _hovering ? widget.hoverColor : widget.regularColor,
            borderRadius: BorderRadius.circular(5),
          ),
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
