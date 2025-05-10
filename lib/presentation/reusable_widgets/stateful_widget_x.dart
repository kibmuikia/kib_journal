import 'package:flutter/material.dart'
    show
        BuildContext,
        ColorScheme,
        MediaQuery,
        State,
        StatefulWidget,
        TextTheme,
        Theme,
        ThemeData,
        VoidCallback,
        Widget,
        protected;

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
}
