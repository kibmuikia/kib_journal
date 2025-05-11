import 'package:flutter/material.dart'
    show
        BuildContext,
        ColorScheme,
        State,
        StatefulWidget,
        StatelessWidget,
        TextTheme,
        Theme,
        ThemeData,
        VoidCallback,
        Widget,
        protected;
import 'package:kib_journal/core/utils/snackbar_utils.dart';

abstract class StatefulWidgetK extends StatefulWidget {
  final String tag;

  StatefulWidgetK({super.key, required this.tag})
    : assert(tag.isNotEmpty, 'Tag must not be empty');

  @override
  StateK<StatefulWidgetK> createState();
}

abstract class StateK<T extends StatefulWidgetK> extends State<T> {
  late ThemeData _theme;
  late ColorScheme _colorScheme;
  late TextTheme _textTheme;

  @protected
  ThemeData get theme => _theme;

  @protected
  ColorScheme get colorScheme => _colorScheme;

  @protected
  TextTheme get textTheme => _textTheme;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    _colorScheme = _theme.colorScheme;
    _textTheme = _theme.textTheme;
    return buildWithTheme(context);
  }

  @protected
  Widget buildWithTheme(BuildContext context);

  @protected
  void informUser(String message) {
    if (mounted) context.showMessage(message);
  }
}

abstract class StatelessWidgetK extends StatelessWidget {
  final String tag;

  StatelessWidgetK({super.key, required this.tag})
    : assert(tag.isNotEmpty, 'Tag must not be empty');

  late ThemeData _theme;
  late ColorScheme _colorScheme;
  late TextTheme _textTheme;

  @protected
  ThemeData get theme => _theme;

  @protected
  ColorScheme get colorScheme => _colorScheme;

  @protected
  TextTheme get textTheme => _textTheme;

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context);
    _colorScheme = _theme.colorScheme;
    _textTheme = _theme.textTheme;
    return buildWithTheme(context);
  }

  @protected
  Widget buildWithTheme(BuildContext context);
}
