
import 'package:canxe/common/data/cloud_obj.dart';
import 'package:canxe/data/canxe_user.dart';

class User extends CloudObject {
  String name;
  String email;
  AccountType type;
  String photoUrl;

  User(docId, dataMap):super(docId, dataMap){
    name= dataMap['name'];
    email= dataMap['email'];
    photoUrl= dataMap['photo_url'];
  }

  @override
  String toString() {
    return 'email: $email type: $type';
  }
}
