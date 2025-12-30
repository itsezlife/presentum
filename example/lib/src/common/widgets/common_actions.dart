import 'dart:collection';

import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/constant/config.dart';
import 'package:example/src/common/widgets/history_button.dart';
import 'package:flutter/widgets.dart';

class CommonActions extends ListBase<Widget> {
  CommonActions([List<Widget>? actions])
    : _actions = <Widget>[
        ...?actions,
        const HistoryButton(),

        /// In development mode debug banner is shown, add some space to make
        /// the actions more readable.
        if (Config.environment.isDevelopment)
          const SizedBox(width: AppSpacing.xxlg),
      ];

  final List<Widget> _actions;

  @override
  int get length => _actions.length;

  @override
  set length(int newLength) => _actions.length = newLength;

  @override
  Widget operator [](int index) => _actions[index];

  @override
  void operator []=(int index, Widget value) => _actions[index] = value;
}
