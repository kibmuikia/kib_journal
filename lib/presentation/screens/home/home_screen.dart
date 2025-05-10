import 'package:flutter/material.dart';
import 'package:kib_journal/presentation/reusable_widgets/stateful_widget_x.dart';

class HomeScreen extends StatefulWidgetK {
  HomeScreen({super.key, super.tag = "HomeScreen"});

  @override
  StateK<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends StateK<HomeScreen> {
  @override
  Widget buildWithTheme(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: Center(
          child: Text('Home Screen', style: textTheme.bodyMedium),
        ),
      ),
    );
  }
}
