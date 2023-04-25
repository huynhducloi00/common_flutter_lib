import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


// firebase_auth: 0.16.0
//  cloud_firestore: ^0.13.5
//#web dep:
//firebase: ^7.3.0
typedef ConvertToUserFunc = dynamic Function(Map<String, dynamic>);

class AuthService<T> {
  static const String USER_TABLE_NAME = 'users';
  final FirebaseAuth auth = FirebaseAuth.instance;
  final CollectionReference _ref =
      FirebaseFirestore.instance.collection(USER_TABLE_NAME);
  final GoogleSignIn googleSignIn = GoogleSignIn();
  ConvertToUserFunc convertToUser;

  AuthService(this.convertToUser);

  Stream<T?> getUserStream() async* {
    Stream<User?> stream = auth.userChanges();
    await for (var returnedUser in stream) {
      if (returnedUser == null) {
        yield null;
      } else {
        yield await _getUserWithEmail<T>(returnedUser.email);
      }
    }
  }

  Future<T?> _getUserWithEmail<T>(String? email) async {
    QuerySnapshot snapshot = await _ref.where("email", isEqualTo: email).get();
    if (snapshot.docs.isEmpty) {
      return null;
    } else {
      Map data = snapshot.docs[0].data() as Map;
      T user = convertToUser(data as Map<String, dynamic>);
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
    GoogleSignInAccount? googleSignInAccount = googleSignIn.currentUser;
    await googleSignIn.signOut();
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

  signInWithGoogleAccount() async {
    GoogleSignInAccount? currentUser = googleSignIn.currentUser;
    await googleSignIn.signOut();
    await auth.signOut();
    print('Signed out complete.');
    // Nullify all errors
    Future signIn = googleSignIn.signIn().catchError((error) {
      print(error);
      return null;
    });
    final GoogleSignInAccount? googleSignInAccount =
        await (signIn as FutureOr<GoogleSignInAccount?>);
    if (googleSignInAccount == null) {
      return null;
    }
    T? inDatabaseUser = await _getUserWithEmail(googleSignInAccount.email);
    if (inDatabaseUser == null) {
      throw(
          'Người dùng ${googleSignInAccount.email} chưa được phép vào dữ liệu. Xin liên hệ Lợi');
    }
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
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
