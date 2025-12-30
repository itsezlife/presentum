import 'dart:async';

import 'package:example/src/campaigns/camapigns.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

class CyberMondayDialog extends StatelessWidget with PromoDialogWidgetMixin {
  const CyberMondayDialog({super.key});

  @override
  Widget buildTitle(BuildContext context) => const Text('💻 Cyber Monday!');

  @override
  Widget buildContent(BuildContext context) => const Text(
    '40% OFF Premium for first 100 users!\n'
    'Limited time only.',
  );

  @override
  Widget buildPrimaryButton(BuildContext context) =>
      Text(textProcessor.process('Claim Now'));

  @override
  Future<void> onPrimaryAction(BuildContext context) async {
    final navigator = context.octopus;
    final result = await Navigator.maybePop(context);
    if (!result) {
      unawaited(navigator.maybePop());
    }
    if (!context.mounted) return;

    // await navigator.pushNamed(Routes.subscriptions.name);
  }
}
