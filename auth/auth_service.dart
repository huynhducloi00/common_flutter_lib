import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// firebase_auth: 0.16.0
//  cloud_firestore: ^0.13.5
//#web dep:
//firebase: ^7.3.0
typedef ConvertToUserFunc= dynamic Function(Map<String, dynamic>);
class AuthService<T> {
  static final String USER_TABLE_NAME='users';
  final FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference _ref = Firestore.instance.collection(USER_TABLE_NAME);
  final GoogleSignIn googleSignIn = GoogleSignIn();
  ConvertToUserFunc convertToUser;

  AuthService(this.convertToUser);

  Stream<T> getUserStream() async* {
    Stream<FirebaseUser> stream = auth.onAuthStateChanged;
    await for (var returnedUser in stream) {
      if (returnedUser == null) {
        yield null;
      } else {
        T user = await _getUserWithEmail(returnedUser.email);
        yield user;
      }
    }
  }

  Future<T> _getUserWithEmail(String email) async {
    QuerySnapshot snapshot =
        await _ref.where("email", isEqualTo: email).getDocuments();
    if (snapshot.documents.length == 0) {
      return null;
    } else {
      Map data = snapshot.documents[0].data;
      T user = convertToUser(data);
      return user;
    }
  }

//  Future signInAnon() async {
//    try {
//      AuthResult authResult = await _auth.signInAnonymously();
//      FirebaseUser user = authResult.user;
//      return _createUser(user);
//    } catch (e) {
//      print(e.toString());
//      return null;
//    }
//  }

  Future<void> signOut() async {
    GoogleSignInAccount googleSignInAccount = googleSignIn.currentUser;
    if (googleSignInAccount != null) {
      await googleSignIn.signOut();
    }
    await auth.signOut();
  }

//
//  Future signInWithEmailAndPassword(String email, String password) async {
//    try {
//      return await auth.signInWithEmailAndPassword(
//          email: email, password: password);
//    } catch (e) {
//      return e;
//    }
//  }

  Future<void> signInWithGoogleAccount() async {
    GoogleSignInAccount currentUser = googleSignIn.currentUser;
    if (currentUser != null) {
      await googleSignIn.signOut();
      await auth.signOut();
      print('Signed out complete.');
    }
    // Nullify all errors
    Future signIn = googleSignIn.signIn().catchError((error) {
      print(error);
      return null;
    });
    final GoogleSignInAccount googleSignInAccount = await signIn;
    if (googleSignInAccount == null) {
      return Future.value(null);
    }
    T inDatabaseUser = await _getUserWithEmail(googleSignInAccount.email);
    if (inDatabaseUser == null) {
      return Future.error(
          'Người dùng ${googleSignInAccount.email} chưa được phép vào dữ liệu. Xin liên hệ Lợi');
    }
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
    await auth.signInWithCredential(credential);
  }
//
//  Future registerWithEmailAndPassword(
//      String name, String email, String password) async {
//    try {
//      AuthResult result = await auth.createUserWithEmailAndPassword(
//          email: email, password: password);
//      FirebaseUser user = result.user;
//      return await AllUsersService.addUser(
//          user.uid,
//          User(
//              name: name,
//              email: user.email,
//              type: AccountType.STUDENT /* student */,
//              studentProfile: null));
//    } catch (e) {
//      return e;
//    }
//  }
}
