
class User<AccountType> {
  String name;
  String email;
  AccountType type;
  String photoUrl;

  User({this.name, this.email, this.type, this.photoUrl});

  @override
  String toString() {
    return 'email: $email type: $type';
  }

  void setData(data) {
    name= data['name'];
    email= data['email'];
    photoUrl= data['photo_url'];
  }
//  Client please implement those
//
//  AccountType convertIntToEnum(int accountTypeInt) {
//    throw 'Not implemented';
//  }
//
//  int convertEnumToInt(AccountType accountType) {
//    throw 'Not implemented';
//  }

}
