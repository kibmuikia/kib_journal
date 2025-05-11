import 'package:flutter/material.dart'
    show BuildContext, FocusScope, WidgetsBinding;
import 'package:kib_debug_print/kib_debug_print.dart' show kprint;

/// Wrapper for [WidgetsBinding.instance.addPostFrameCallback]
void postFrame(Future<void> Function() callback) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await callback();
    } on Exception catch (e) {
      kprint.lg('** postFrame: $e');
    }
  });
}

extension KeyboardUtil on BuildContext {
  void hideKeyboard() {
    final currentFocus = FocusScope.of(this);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild!.unfocus();
    }
  }
}
