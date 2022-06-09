import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../loadingstate/loading_state.dart';
import '../../utils.dart';
import '../../widget/common.dart';
import '../auth_service.dart';

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
        child: CommonButton.getButton(context, () async {
          markLoading();
          try {
            await authService.signInWithGoogleAccount();

            markDoneLoading();
            return null;
          } catch (error) {
            markDoneLoading();
            showInformation(context, "Thông báo", error.toString());
          }
        },
            title: 'Sign in with Google',
            align: TextAlign.center,
            iconData: Icons.login),
      ),
    );
  }
}
