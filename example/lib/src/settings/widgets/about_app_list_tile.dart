import 'package:example/src/app/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';

class AboutAppListTile extends StatelessWidget {
  const AboutAppListTile({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    title: const Text('About app'),
    leading: const Icon(Icons.info),
    onTap: () {
      context.octopus.push(Routes.aboutAppDialog);
    },
  );
}
