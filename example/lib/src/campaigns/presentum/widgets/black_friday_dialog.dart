import 'dart:async';

import 'package:example/src/campaigns/presentum/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

class BlackFridayDialog extends StatelessWidget with PromoDialogWidgetMixin {
  const BlackFridayDialog({super.key});

  @override
  Widget buildTitle(BuildContext context) => const Text('🖤 Black Friday!');

  @override
  Widget buildContent(BuildContext context) => const Text(
    '50% OFF Premium for first 100 users!\n'
    'Limited time only.',
  );

  @override
  Widget buildPrimaryButton(BuildContext context) =>
      Text(textProcessor.process('Claim Now'));

  @override
  Future<void> onPrimaryAction(BuildContext context) async {
    final octopus = context.octopus;
    final result = await Navigator.maybePop(context);
    if (!result) {
      unawaited(octopus.maybePop());
    }
    if (!context.mounted) return;

    // await octopus.pushNamed(Routes.subscriptions.name);
  }
}
