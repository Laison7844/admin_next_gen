import 'package:flutter/services.dart';

/// Non-web fallback implementation: copies phone number to clipboard.
Future<bool> launchPhoneDialer(String phone) async {
  final clean = phone.trim().replaceAll(RegExp(r'\s+'), '');
  await Clipboard.setData(ClipboardData(text: clean));
  return true;
}

