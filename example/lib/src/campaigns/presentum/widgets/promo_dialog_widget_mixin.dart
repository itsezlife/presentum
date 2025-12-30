// ignore_for_file: deprecated_member_use, one_member_abstracts

import 'dart:async';

import 'package:example/src/campaigns/camapigns.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

/// {@template i_promo_widget}
/// A mixin that provides a base implementation for a promo widget.
/// {@endtemplate}
abstract interface class IPromoWidget {
  /// {@macro i_promo_widget}
  const IPromoWidget();

  /// Build the promo widget.
  Widget build(BuildContext context);

  /// Handle the primary action.
  FutureOr<void> onPrimaryAction(BuildContext context);

  /// Handle the dismiss action.
  FutureOr<void> onDismiss(BuildContext context);
}

mixin PromoDialogWidgetMixin implements IPromoWidget {
  ITextProcessor get textProcessor => const TextProcessor();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: buildTitle(context),
    content: buildContent(context),
    actions: [
      TextButton(
        onPressed: () => onDismiss(context),
        child: Text(textProcessor.process('Dismiss')),
      ),
      FilledButton(
        onPressed: () => onPrimaryAction(context),
        child: buildPrimaryButton(context),
      ),
    ],
  );

  @override
  FutureOr<void> onDismiss(BuildContext context) async {
    final navigator = context.octopus;
    final result = await Navigator.maybePop(context, true);
    if (!result) {
      unawaited(navigator.maybePop());
    }
    if (!context.mounted) return;

    final item = context.campaignItem;
    await context.campaignsPresentum.markDismissed(item);
  }

  Widget buildTitle(BuildContext context) => const SizedBox.shrink();
  Widget buildContent(BuildContext context) => const SizedBox.shrink();
  Widget buildPrimaryButton(BuildContext context) => const SizedBox.shrink();
}

/// {@template i_text_processor}
/// The interface for processing text in a dialog.
/// {@endtemplate}
abstract interface class ITextProcessor {
  /// {@macro i_text_processor}
  const ITextProcessor();

  /// Processes the text in a dialog.
  String process(String text);
}

/// {@template text_processor}
/// The interface for processing text in a dialog.
/// {@endtemplate}
class TextProcessor implements ITextProcessor {
  /// {@macro dialog_text_processor}
  const TextProcessor();

  /// Processes the text in a dialog.
  @override
  String process(String text) => text;
}

/// {@template uppercase_dialog_text_processor}
/// The implementation of the [TextProcessor] that converts the text to
/// uppercase.
/// {@endtemplate}
class UppercaseTextProcessor implements ITextProcessor {
  /// {@macro uppercase_text_processor}
  const UppercaseTextProcessor();

  @override
  String process(String text) => text.toUpperCase();
}
