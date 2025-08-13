import 'package:get/get.dart';
import 'package:flutter/material.dart';

class ThemeController extends GetxController {
  final _mode = ThemeMode.system.obs;

  ThemeMode get mode => _mode.value;

  void toggle() {
    _mode.value = _mode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }
}
