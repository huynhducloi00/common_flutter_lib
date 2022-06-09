import '../user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../sign_in/sign_in_page.dart';
import 'sign_in_page.dart';

class SignInWrapper<USER extends User?, TYPE> extends StatelessWidget {
  bool debugging;
  ConvertToUserFunc convertToUserFunc;
  String appName;
  TYPE accountType;
  Widget appRender;
  USER Function(TYPE userType) getDebugUser;

  SignInWrapper(this.debugging,this.accountType,this.appName, this.appRender,
      {required this.getDebugUser,
      required this.convertToUserFunc});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: appName,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: debugging
            ? Provider.value(value: getDebugUser(accountType), child: appRender)
            : Provider.value(
                value: AuthService<USER>(convertToUserFunc),
                child: Builder(builder: (BuildContext context) {
                  return StreamProvider.value(
                    initialData: null,
                      catchError: (context, error) {
                        print(error);
                      },
                      value: Provider.of<AuthService<USER>>(context)
                          .getUserStream(),
                      child: Builder(
                        builder: (BuildContext context) {
                          var userData = Provider.of<USER?>(context);
                          if (userData == null) {
                            return SignInPage<USER>();
                          } else {
                            return appRender;
                          }
                        },
                      ));
                }),
              ));
  }
}

Future<dynamic>? myBackgroundMessageHandler(Map<String, dynamic> message) {
  print('back ground ${message}');
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }
}
// OnInit, IF ever need to use notification on Android, on iOS needs to pay a fee.
//import 'package:firebase_messaging/firebase_messaging.dart';
//  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
//    if (!kIsWeb) {
//      _firebaseMessaging.configure(
//        onMessage: (Map<String, dynamic> message) async {
//          print("onMessage: $message");
//          showDialog<bool>(
//            context: context,
//            builder: (_) => _buildDialog(context, message),
//          ).then((bool shouldNavigate) {
//            if (shouldNavigate == true) {}
//          });
//        },
//        onBackgroundMessage: myBackgroundMessageHandler,
//        onLaunch: (Map<String, dynamic> message) async {
//          print("onLaunch: $message");
////        _navigateToItemDetail(message);
//        },
//        onResume: (Map<String, dynamic> message) async {
//          print("onResume: $message");
////        _navigateToItemDetail(message);
//        },
//      );
//      _firebaseMessaging.subscribeToTopic('weight_trans_topic');
//    }
