import 'package:flutter/material.dart' show WidgetsBinding;
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
