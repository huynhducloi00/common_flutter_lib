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
}
