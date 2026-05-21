import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/browser/data/browser_history_search_repository.dart';

class HistorySearchFallbackIcon extends StatelessWidget {
  const HistorySearchFallbackIcon({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: Icon(CupertinoIcons.globe, color: CupertinoColors.systemTeal, size: 18),
  );
}

class HistorySearchDivider extends StatelessWidget {
  const HistorySearchDivider({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 40),
    child: SizedBox(
      height: 0.5,
      child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF33333A))),
    ),
  );
}

class HistorySearchRow extends StatelessWidget {
  const HistorySearchRow({
    super.key,
    required this.query,
    required this.match,
    required this.onPressed,
    required this.onCopyPressed,
    required this.onSharePressed,
  });

  final String query;
  final BrowserHistorySearchMatch match;
  final VoidCallback onPressed;
  final VoidCallback onCopyPressed;
  final ValueChanged<BuildContext> onSharePressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
    child: Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 40),
            alignment: Alignment.centerLeft,
            onPressed: onPressed,
            child: Row(
              children: [
                _HistorySearchFavicon(match: match),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightedLine(
                        text: match.title,
                        query: query,
                        style: const TextStyle(color: CupertinoColors.white, fontSize: 14, letterSpacing: 0),
                        highlightStyle: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _HighlightedLine(
                        text: match.subtitle,
                        query: query,
                        style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, letterSpacing: 0),
                        highlightStyle: const TextStyle(
                          color: CupertinoColors.systemGrey2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _HistorySearchActionButton(icon: CupertinoIcons.doc_on_doc, label: 'Copy URL', onPressed: onCopyPressed),
        _HistorySearchActionButton(
          icon: CupertinoIcons.share,
          label: 'Share URL',
          onPressed: () => onSharePressed(context),
        ),
      ],
    ),
  );
}

class HistorySearchMatches extends StatelessWidget {
  const HistorySearchMatches({
    super.key,
    required this.query,
    required this.matches,
    required this.currentMatch,
    required this.onMatchPressed,
    required this.onCopyPressed,
    required this.onSharePressed,
    required this.onPasteAndGoPressed,
  });

  final String query;
  final AsyncValue<List<BrowserHistorySearchMatch>> matches;
  final BrowserHistorySearchMatch? currentMatch;
  final ValueChanged<BrowserHistorySearchMatch> onMatchPressed;
  final ValueChanged<BrowserHistorySearchMatch> onCopyPressed;
  final void Function(BuildContext context, BrowserHistorySearchMatch match) onSharePressed;
  final VoidCallback onPasteAndGoPressed;

  @override
  Widget build(BuildContext context) => matches.when(
    data: _buildMatches,
    loading: () => _buildMatches(const []),
    error: (error, stackTrace) => _buildMatches(const []),
  );

  Widget _buildMatches(List<BrowserHistorySearchMatch> matches) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xF21A1A1F),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF33333A), width: 0.5),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HistorySearchActions(
          currentMatch: currentMatch,
          onCopyPressed: currentMatch == null ? null : () => onCopyPressed(currentMatch!),
          onPasteAndGoPressed: onPasteAndGoPressed,
        ),
        if (currentMatch case final match?) ...[
          const HistorySearchDivider(),
          HistorySearchRow(
            query: query,
            match: match,
            onPressed: () => onMatchPressed(match),
            onCopyPressed: () => onCopyPressed(match),
            onSharePressed: (context) => onSharePressed(context, match),
          ),
        ],
        for (final entry in matches.asMap().entries.where((entry) => entry.value.url != currentMatch?.url)) ...[
          const HistorySearchDivider(),
          HistorySearchRow(
            query: query,
            match: entry.value,
            onPressed: () => onMatchPressed(entry.value),
            onCopyPressed: () => onCopyPressed(entry.value),
            onSharePressed: (context) => onSharePressed(context, entry.value),
          ),
        ],
      ],
    ),
  );
}

class _HistorySearchActionButton extends StatelessWidget {
  const _HistorySearchActionButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(34, 34),
      onPressed: onPressed,
      child: Icon(icon, color: CupertinoColors.activeBlue, size: 18),
    ),
  );
}

class _HistorySearchFavicon extends StatelessWidget {
  const _HistorySearchFavicon({required this.match});

  final BrowserHistorySearchMatch match;

  @override
  Widget build(BuildContext context) {
    final faviconFilePath = match.faviconFilePath;
    if (faviconFilePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(faviconFilePath),
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const HistorySearchFallbackIcon(),
        ),
      );
    }
    return const HistorySearchFallbackIcon();
  }
}

class _HighlightedLine extends StatelessWidget {
  const _HighlightedLine({required this.text, required this.query, required this.style, required this.highlightStyle});

  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;

  @override
  Widget build(BuildContext context) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.trim().toLowerCase();
    final index = lowerQuery.isEmpty ? -1 : lowerText.indexOf(lowerQuery);
    if (index < 0) {
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(text: text.substring(index, index + lowerQuery.length), style: highlightStyle),
          TextSpan(text: text.substring(index + lowerQuery.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

class _HistorySearchActions extends StatelessWidget {
  const _HistorySearchActions({
    required this.currentMatch,
    required this.onCopyPressed,
    required this.onPasteAndGoPressed,
  });

  final BrowserHistorySearchMatch? currentMatch;
  final VoidCallback? onCopyPressed;
  final VoidCallback onPasteAndGoPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
    child: Row(
      children: [
        if (currentMatch != null) ...[
          _HistorySearchPillButton(
            icon: CupertinoIcons.doc_on_doc,
            label: 'Copy URL',
            semanticLabel: 'Copy Current URL',
            onPressed: onCopyPressed!,
          ),
          const SizedBox(width: 8),
        ],
        _HistorySearchPillButton(
          icon: CupertinoIcons.doc_on_clipboard,
          label: 'Paste and Go',
          semanticLabel: 'Paste and Go',
          onPressed: onPasteAndGoPressed,
        ),
      ],
    ),
  );
}

class _HistorySearchPillButton extends StatelessWidget {
  const _HistorySearchPillButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      minimumSize: const Size(0, 30),
      color: const Color(0xFF24242A),
      borderRadius: BorderRadius.circular(7),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: CupertinoColors.activeBlue, size: 16),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: CupertinoColors.white, fontSize: 13, letterSpacing: 0)),
        ],
      ),
    ),
  );
}
