import 'dart:js' as js;

import 'upload_interface.dart';
class JsUtilImpl extends JsUtil{
  @override
  bindCall(Function dartFunc) {
    js.context['loiXong'] = js.allowInteropCaptureThis(dartFunc);
  }
}
