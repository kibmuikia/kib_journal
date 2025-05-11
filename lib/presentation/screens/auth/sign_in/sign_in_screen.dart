import 'package:flutter/material.dart';
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';

class SignInScreen extends StatefulWidgetK {
  SignInScreen({super.key, super.tag = "SignInScreen"});

  @override
  StateK<StatefulWidgetK> createState() => _SignInScreenState();
}

class _SignInScreenState extends StateK<SignInScreen> {
  @override
  Widget buildWithTheme(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign In Screen")),
      body: SafeArea(child: Column(children: [])),
    );
  }
}
