//import 'dart:async';
//import 'dart:convert';
//
//import 'package:easy_web_view/easy_web_view.dart';
//import 'package:flutter/foundation.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
//import 'package:loichatapp/common_flutter_lib/widget/mobile_hover_button.dart';
//import 'package:webview_flutter/webview_flutter.dart';
//
//const String VAA_HTML_SEPARATOR = '|||';
//class HtmlEditor extends StatefulWidget {
//  String initValue;
//
//  HtmlEditor(this.initValue);
//
//  @override
//  _HtmlEditorState createState() => _HtmlEditorState();
//}
//
//class _HtmlEditorState extends State<HtmlEditor> {
//  TextEditingController _bodyController;
//  TextEditingController _headerController;
//  String _bodyData;
//  String _headerData;
//  WebViewController _webViewController;
//  Timer timer;
//
//  Widget maxSizeTextField(TextEditingController controller,
//      ValueChanged<String> onChanged, Color bgColor) {
//    return LayoutBuilder(
//      builder: (context, constraint) {
//        return Container(
//          decoration: BoxDecoration(border: Border.all(), color: bgColor),
//          child: TextFormField(
//            controller: controller,
//            onChanged: onChanged,
//            maxLines: double.maxFinite.floor(),
//            keyboardType: TextInputType.multiline,
//          ),
//        );
//      },
//    );
//  }
//  @override
//  void initState() {
//
//    super.initState();
//    widget.initValue = widget.initValue ?? "";
//
//    if (widget.initValue.contains(VAA_HTML_SEPARATOR)) {
//      var result = widget.initValue.split(VAA_HTML_SEPARATOR);
//      _headerData = result[0];
//      _bodyData = result[1];
//    } else {
//      _bodyData = widget.initValue;
//      _headerData = "";
//    }
//
//    _bodyController = TextEditingController(text: _bodyData);
//    _headerController = TextEditingController(text: _headerData);
//  }
//
//  void updateWebValue() {
//    if (kIsWeb) {
//      // do nothing
//    } else {
//      _webViewController.loadUrl(Uri.dataFromString('''
//      <div style="${_headerData}">
//      ${_bodyData}
//      </div>
//      ''', mimeType: "text/html", encoding: Encoding.getByName("utf-8"))
//          .toString());
//    }
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    bool experimentEasyWebView = true;
//    Widget renderWidget;
//    if (_bodyData == null) {
//      renderWidget = null;
//    } else {
//      if (experimentEasyWebView) {
//        renderWidget = EasyWebView(
//          src: '''
//          <html>
//          <head>
//          ${_headerData}
//          </head>
//            <body>
//      ${_bodyData}
//      </body>
//      </html>
//      ''',
//          isHtml: true,
//        );
//      } else {
//        renderWidget =
//            WebView(onWebViewCreated: (WebViewController controller) {
//          _webViewController = controller;
//          updateWebValue();
//        });
//      }
//    }
//    return Scaffold(
//        appBar: AppBar(
//          actions: [
//            CommonButton.getButton(context, () {
//              Clipboard.setData(
//                  ClipboardData(text: 'https://html-online.com/editor/'));
//            },
//              regularColor: Colors.transparent,
//              title: 'Copy editor link',
//              iconData: Icons.web,
//            ),
//            CommonButton.getButton(context,
//                  () {
//                Navigator.pop(context, _headerData+VAA_HTML_SEPARATOR+_bodyData);
//              },
//              regularColor: Colors.transparent,
//              iconData: Icons.save,
//              title: "Save",
//            )
//          ],
//        ),
//        body: SingleChildScrollView(
//          padding: EdgeInsets.all(15),
//          child: Column(children: [
//            Text('Header'),
//            Container(
//              height: 300,
//              child: maxSizeTextField(_headerController, (val) {
//                _headerData = val;
//                if (timer != null) {
//                  timer.cancel();
//                }
//                timer = Timer(Duration(seconds: 3), () {
//                  if (mounted) {
//                    setState(() {
//                      if (_webViewController != null) {
//                        updateWebValue();
//                      }
//                    });
//                  }
//                });
//              }, Colors.pink[50]),
//            ),
//            SizedBox(
//              height: 20,
//            ),
//            Container(
//              height: 500,
//              child:
//                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                Expanded(
//                  child: Column(children: [
//                    Text('Body'),
//                    Expanded(
//                      child: maxSizeTextField(_bodyController, (val) {
//                        _bodyData = val;
//                        if (timer != null) {
//                          timer.cancel();
//                        }
//                        timer = Timer(Duration(seconds: 3), () {
//                          if (mounted) {
//                            setState(() {
//                              if (_webViewController != null) {
//                                updateWebValue();
//                              }
//                            });
//                          }
//                        });
//                      }, Colors.white),
//                    ),
//                  ]),
//                ),
//                SizedBox(
//                  width: 20,
//                ),
//                Expanded(
//                  child: Column(
//                    children: [
//                      Text('Preview'),
//                      Expanded(
//                        child: Container(
//                          decoration: BoxDecoration(border: Border.all()),
//                          child: renderWidget,
//                        ),
//                      ),
//                    ],
//                  ),
//                )
//              ]),
//            ),
//          ]),
//        ));
//  }
//}
