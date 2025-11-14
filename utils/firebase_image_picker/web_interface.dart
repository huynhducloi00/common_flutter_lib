import 'package:loi_tenant/common/utils/firebase_image_picker/upload_interface.dart';
import 'dart:js' as js;
class JsUtilImpl extends JsUtil{
  @override
  bindCall(Function dartFunc) {
    js.context['loiXong'] = js.allowInteropCaptureThis(dartFunc);
  }
}
