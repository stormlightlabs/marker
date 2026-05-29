import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marker/core/widgets/funnotation.dart';
import 'package:marker/features/settings/data/settings_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _linkedInUrl = 'https://linkedin.com/in/owais-jamil';
  static const _githubUrl = 'https://github.com/stormlightlabs/marker';
  static const _tangledUrl = 'https://github.com/stormlightlabs/marker';
  static const _emailUrl = 'mailto:info@stormlightlabs.org';

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.black,
    navigationBar: const CupertinoNavigationBar(
      backgroundColor: CupertinoColors.black,
      border: null,
      middle: Text('About'),
    ),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: SvgPicture.asset(
              'assets/images/logo.svg',
              width: 64,
              height: 64,
              colorFilter: const ColorFilter.mode(CupertinoColors.activeBlue, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 16),
          const _FunHeading('Marker'),
          const SizedBox(height: 16),
          const Text(
            'Marker is made at Stormlight Labs, which is just me:',
            style: TextStyle(color: CupertinoColors.white, fontSize: 17, height: 1.35),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openExternalUrl(_linkedInUrl),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Funnotation(
                color: CupertinoColors.systemYellow,
                padding: 5,
                child: Text(
                  'Owais',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    decoration: TextDecoration.underline,
                    decorationColor: CupertinoColors.activeBlue,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Funnotation(
            color: Color(0x445CBEFF),
            padding: 2,
            child: Text(
              'Stormlight Labs makes high quality, free and open source software. '
              'Check out our other projects on GitHub.',
              style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15, height: 1.35),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can view or contribute to this project on Tangled or GitHub. '
            'Feature requests and bug reports are welcome!',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LinkIcon(
                onTap: () => _openExternalUrl(_githubUrl),
                child: SvgPicture.asset(
                  'assets/images/github.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(CupertinoColors.white, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 24),
              _LinkIcon(
                onTap: () => _openExternalUrl(_tangledUrl),
                child: SvgPicture.asset(
                  'assets/images/tangled.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(CupertinoColors.white, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 24),
              _LinkIcon(
                onTap: () => _openExternalUrl(_emailUrl),
                child: const Icon(CupertinoIcons.mail, size: 28, color: CupertinoColors.white),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _FunHeading extends ConsumerWidget {
  const _FunHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funEnabled = ref.watch(funEnabledProvider).value ?? true;
    final child = Text(
      text,
      textAlign: TextAlign.center,
      style: funEnabled
          ? GoogleFonts.slacksideOne(color: CupertinoColors.white, fontSize: 44, fontWeight: FontWeight.w400)
          : const TextStyle(color: CupertinoColors.white, fontSize: 28, fontWeight: FontWeight.w700),
    );
    if (!funEnabled) {
      return child;
    }
    return Center(child: Funnotation(padding: 4, child: child));
  }
}

class _LinkIcon extends StatelessWidget {
  const _LinkIcon({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CupertinoButton(padding: const EdgeInsets.all(8), onPressed: onTap, child: child);
}

Future<void> _openExternalUrl(String value) async {
  await launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
}
