// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:example/src/home/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppRetain extends StatelessWidget {
  const AppRetain({required this.child, super.key});

  final Widget child;

  static const _channel = MethodChannel('dev.itsezlife.presentum/app_retain');

  @override
  Widget build(BuildContext context) => WillPopScope(
    onWillPop: () async {
      final isAndroid = Platform.isAndroid;

      if (!isAndroid) return true;

      final canPop = Navigator.of(context).canPop();

      if (canPop) return true;

      final result = HomeController().handleBackPressed();
      if (result) {
        await _channel.invokeMethod('sendToBackground');
      }
      return false;
    },
    child: child,
  );
}
