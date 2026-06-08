import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:example/src/campaigns/camapigns.dart';
import 'package:flutter/material.dart';

class CyberMondayFullScreenDialog extends StatelessWidget
    with PromoDialogWidgetMixin {
  const CyberMondayFullScreenDialog({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      actions: [
        IconButton.filledTonal(
          onPressed: () => onDismiss(context),
          icon: const Icon(Icons.close),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    ),
    body: const SafeArea(child: Center(child: Text('Cyber Monday Dialog'))),
  );

  @override
  FutureOr<void> onPrimaryAction(BuildContext context) {}
}
