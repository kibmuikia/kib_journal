import 'package:flutter/material.dart';
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';

class SignUpScreen extends StatefulWidgetK {
  SignUpScreen({super.key, super.tag = "SignUpScreen"});

  @override
  StateK<StatefulWidgetK> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends StateK<SignUpScreen> {
  @override
  Widget buildWithTheme(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up Screen")),
      body: SafeArea(child: Column(children: [])),
    );
  }
}
