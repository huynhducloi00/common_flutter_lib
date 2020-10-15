import '../data/cloud_table.dart';

import '../data/cloud_obj.dart';

class User extends CloudObject {
  String name;
  String email;
  String photoUrl;

  User(docId, dataMap):super(docId, dataMap){
    name= dataMap['name'];
    email= dataMap['email'];
    photoUrl= dataMap['photo_url'];
  }

  @override
  String toString() {
    return 'email: $email';
  }
  static InputInfoMap inputInfoMap() => InputInfoMap({
    'email': InputInfo(DataType.string,
        fieldDes: 'Email', validator: InputInfo.nonEmptyStrValidator),
    'name': InputInfo(DataType.string, fieldDes: 'Tên'),
  });
}
