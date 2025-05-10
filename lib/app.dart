import 'package:flutter/material.dart';
import 'package:kib_journal/core/constants/app_constants.dart' show appName;
import 'package:kib_journal/presentation/screens/my_home_page.dart'
    show MyHomePage;
import 'package:sizer/sizer.dart';

class KibJournal extends StatelessWidget {
  const KibJournal({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return _setupMaterialApp(context);
  }

  Widget _setupMaterialApp(BuildContext ctx) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return _materialApp(context);
      },
    );
  }

  MaterialApp _materialApp(BuildContext ctx) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: '$appName Demo Page'),
    );
  }
}
