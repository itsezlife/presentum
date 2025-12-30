import 'dart:math';

import 'package:app_ui/app_ui.dart';
import 'package:example/src/common/constant/pubspec.yaml.g.dart';
import 'package:example/src/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// {@template about_app_dialog}
/// AboutApplicationDialog widget.
/// {@endtemplate}
class AboutApplicationDialog extends StatelessWidget {
  /// {@macro about_app_dialog}
  const AboutApplicationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenSize = context.width;
    final iconSize = min(screenSize / 5, 64).toDouble();
    return AboutDialog(
      applicationName: Pubspec.name,
      applicationVersion: Pubspec.version.representation,
      applicationIcon: SizedBox.square(
        dimension: iconSize,
        child: CircleAvatar(
          radius: iconSize,
          child: Icon(Icons.apps, size: iconSize / 2),
        ),
      ),
      children: <Widget>[
        _AboutApplicationDialog$Tile(
          title: l10n.aboutDialogNameTitle,
          subtitle: Pubspec.name,
          content: Pubspec.name,
        ),
        _AboutApplicationDialog$Tile(
          title: l10n.aboutDialogVersionTitle,
          subtitle: Pubspec.version.representation,
          content: Pubspec.version.representation,
        ),
        _AboutApplicationDialog$Tile(
          title: l10n.aboutDialogHomepageTitle,
          subtitle: Pubspec.homepage,
          content: Pubspec.homepage,
        ),
        _AboutApplicationDialog$Tile(
          title: l10n.aboutDialogRepositoryTitle,
          subtitle: Pubspec.repository,
          content: Pubspec.repository,
        ),
      ],
    );
  }
}

class _AboutApplicationDialog$Tile extends StatelessWidget {
  const _AboutApplicationDialog$Tile({
    required this.title,
    this.subtitle,
    this.content,
  });

  final String title;
  final String? subtitle;
  final String? content;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 72,
    child: ListTile(
      title: Text(title),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      isThreeLine: false,
      subtitle: subtitle != null
          ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      onTap: () {
        final uri = Uri.tryParse(subtitle ?? '');
        if (uri case final uri?) {
          launchUrl(uri);
        }
        Clipboard.setData(
          ClipboardData(
            text: content ?? (subtitle == null ? title : '$title: $subtitle'),
          ),
        );
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.copied),
              duration: const Duration(seconds: 3),
            ),
          );
        HapticFeedback.lightImpact();
      },
    ),
  );
}
