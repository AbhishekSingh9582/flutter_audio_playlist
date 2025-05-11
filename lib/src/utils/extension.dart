import 'package:flutter/material.dart';

extension SizeExtension on num {
  SizedBox get toVerticalSizedBox => SizedBox(height: this * 1);
  SizedBox get toHorizontalSizedBox => SizedBox(width: this * 1);
}
