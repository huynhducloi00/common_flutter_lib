import '../../utils.dart';
import '../auth_service.dart';
import '../../loadingstate/loading_state.dart';
import '../../widget/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInPage<T> extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState<T>();
}

class _SignInPageState<T> extends LoadingState<SignInPage, dynamic> {
  _SignInPageState() : super();

  @override
  Widget delegateBuild(BuildContext context) {
    var authService = Provider.of<AuthService<T>>(context);
    return Container(
      color: Colors.white,
      child: Center(
        child: CommonButton.getButton(context, () {
          markLoading();
          authService.signInWithGoogleAccount().then((value) {
            markDoneLoading();
            return null;
          }).catchError((error) {
            markDoneLoading();
            showInformation(context, "Thông báo", error.toString());
          });
        }, title: 'Đăng nhập với Google', align: TextAlign.center),
      ),
    );
  }
}
