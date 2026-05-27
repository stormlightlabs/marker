import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/features/settings/application/log_share_controller.dart';
import 'package:marker/features/settings/data/app_log_repository.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  _LevelFilter _levelFilter = _LevelFilter.all;
  _TimeFilter _timeFilter = _TimeFilter.all;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(appLogEntriesProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Logs'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => unawaited(_shareLogs(context)),
          child: const Text('Download'),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            logs.when(
              data: (entries) {
                final filtered = _filterEntries(entries);
                return Column(
                  children: [
                    _LogFilters(
                      levelFilter: _levelFilter,
                      timeFilter: _timeFilter,
                      onLevelChanged: (level) => setState(() => _levelFilter = level),
                      onTimeFilterChanged: (filter) => setState(() => _timeFilter = filter),
                      onRefresh: () => ref.invalidate(appLogEntriesProvider),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'No matching logs',
                                style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 15, letterSpacing: 0),
                              ),
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) => _LogRow(
                                entry: filtered[index],
                                onCopy: () => unawaited(_copyEntry(context, filtered[index])),
                              ),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13, letterSpacing: 0),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 18,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(8),
                onPressed: _scrollToBottom,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.arrow_down, size: 16, color: CupertinoColors.white),
                    SizedBox(width: 6),
                    Text('Bottom', style: TextStyle(color: CupertinoColors.white, fontSize: 13, letterSpacing: 0)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AppLogEntry> _filterEntries(List<AppLogEntry> entries) {
    final cutoff = _timeFilter.cutoff;
    final minimumLevel = _levelFilter.minimumLevel;
    return entries
        .where((entry) {
          if (minimumLevel != null && entry.level.severity < minimumLevel.severity) {
            return false;
          }
          if (cutoff != null && entry.time.isBefore(cutoff)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _copyEntry(BuildContext context, AppLogEntry entry) async {
    await Clipboard.setData(ClipboardData(text: entry.toClipboardText()));
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Copied log entry'),
        content: const Text('The selected log entry was copied to the clipboard.'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _shareLogs(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    await ref.read(nativeLogShareProvider)(sharePositionOrigin: origin);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }
}

class _LogFilters extends StatelessWidget {
  const _LogFilters({
    required this.levelFilter,
    required this.timeFilter,
    required this.onLevelChanged,
    required this.onTimeFilterChanged,
    required this.onRefresh,
  });

  final _LevelFilter levelFilter;
  final _TimeFilter timeFilter;
  final ValueChanged<_LevelFilter> onLevelChanged;
  final ValueChanged<_TimeFilter> onTimeFilterChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D10),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A30), width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: CupertinoSlidingSegmentedControl<_LevelFilter>(
                groupValue: levelFilter,
                children: {for (final filter in _LevelFilter.values) filter: _SegmentLabel(filter.label)},
                onValueChanged: (value) {
                  if (value != null) {
                    onLevelChanged(value);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CupertinoSlidingSegmentedControl<_TimeFilter>(
                    groupValue: timeFilter,
                    children: {for (final filter in _TimeFilter.values) filter: _SegmentLabel(filter.label)},
                    onValueChanged: (value) {
                      if (value != null) {
                        onTimeFilterChanged(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size.square(34),
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(8),
                  onPressed: onRefresh,
                  child: const Icon(CupertinoIcons.arrow_clockwise, size: 18, color: CupertinoColors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry, required this.onCopy});

  final AppLogEntry entry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(entry.level);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF151519),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A30), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    child: Text(
                      entry.level.label.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatTime(entry.time),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12, letterSpacing: 0),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size.square(28),
                  onPressed: onCopy,
                  child: const Icon(CupertinoIcons.doc_on_doc, size: 16, color: CupertinoColors.systemGrey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.message,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 14, height: 1.28, letterSpacing: 0),
            ),
            if (entry.error != null) ...[
              const SizedBox(height: 8),
              Text(
                entry.error!,
                style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 12, height: 1.25, letterSpacing: 0),
              ),
            ],
            if (entry.stackTrace != null) ...[
              const SizedBox(height: 8),
              Text(
                entry.stackTrace!,
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 11,
                  height: 1.2,
                  letterSpacing: 0,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorFor(AppLogLevel level) => switch (level) {
    AppLogLevel.trace => CupertinoColors.systemPurple,
    AppLogLevel.debug => CupertinoColors.systemTeal,
    AppLogLevel.info => CupertinoColors.activeBlue,
    AppLogLevel.warning => CupertinoColors.systemYellow,
    AppLogLevel.error => CupertinoColors.systemOrange,
    AppLogLevel.fatal => CupertinoColors.systemRed,
  };
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(text, style: const TextStyle(fontSize: 12, letterSpacing: 0)),
  );
}

enum _LevelFilter {
  all('All', null),
  trace('Trace', AppLogLevel.trace),
  debug('Debug', AppLogLevel.debug),
  info('Info', AppLogLevel.info),
  warning('Warn', AppLogLevel.warning),
  error('Error', AppLogLevel.error),
  fatal('Fatal', AppLogLevel.fatal);

  const _LevelFilter(this.label, this.minimumLevel);

  final String label;
  final AppLogLevel? minimumLevel;
}

enum _TimeFilter {
  all('All', null),
  lastHour('1h', Duration(hours: 1)),
  lastDay('24h', Duration(hours: 24)),
  lastWeek('7d', Duration(days: 7));

  const _TimeFilter(this.label, this.duration);

  final String label;
  final Duration? duration;

  DateTime? get cutoff {
    final value = duration;
    return value == null ? null : DateTime.now().subtract(value);
  }
}

String _formatTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}
