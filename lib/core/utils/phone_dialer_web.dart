// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/services.dart';

/// Web implementation: copies phone number to clipboard and triggers tel: link.
Future<bool> launchPhoneDialer(String phone) async {
  final clean = phone.trim().replaceAll(RegExp(r'\s+'), '');
  await Clipboard.setData(ClipboardData(text: clean));
  try {
    html.window.open('tel:$clean', '_self');
    return true;
  } catch (_) {
    return false;
  }
}
