import 'package:flutter/material.dart';

class SettingToggleRow extends StatelessWidget {
  const SettingToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    super.key,
  });

  final String? title;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: title != null ? Text(title!) : null,
    subtitle: description != null ? Text(description!) : null,
    value: value,
    onChanged: onChanged,
  );
}
