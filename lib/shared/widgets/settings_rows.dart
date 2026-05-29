import 'package:flutter/cupertino.dart';

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: CupertinoColors.systemGrey,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
  );
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({required this.label, this.trailing, super.key});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [SettingsSectionLabel(label), const Spacer(), ?trailing]);
}

class SettingsLinkRow extends StatelessWidget {
  const SettingsLinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SettingsRowFrame(
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.activeBlue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: SettingsRowText(title: title, subtitle: subtitle),
            ),
            const Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.systemGrey, size: 17),
          ],
        ),
      ),
    ),
  );
}

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.titleWidget,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Widget? titleWidget;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SettingsRowFrame(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.activeBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: SettingsRowText(title: title, subtitle: subtitle, titleWidget: titleWidget),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );
}

class SettingsRowText extends StatelessWidget {
  const SettingsRowText({required this.title, required this.subtitle, this.titleWidget, super.key});

  final String title;
  final String subtitle;
  final Widget? titleWidget;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      titleWidget ?? Text(title, style: const TextStyle(color: CupertinoColors.white, fontSize: 16, letterSpacing: 0)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, letterSpacing: 0)),
    ],
  );
}

class SettingsRowFrame extends StatelessWidget {
  const SettingsRowFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF151519),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
    ),
    child: child,
  );
}
