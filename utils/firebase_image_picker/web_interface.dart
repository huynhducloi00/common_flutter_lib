import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'upload_interface.dart';

class JsUtilImpl extends JsUtil {
  @override
  void bindCall(Function dartFunc) {
    globalContext['loiXong'] = dartFunc.toJSCaptureThis;
  }
}
