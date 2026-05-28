import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/core/shared/utils/text_utils.dart';

final selectionCaptureControllerProvider = NotifierProvider<SelectionCaptureController, SelectionCaptureState>(
  SelectionCaptureController.new,
);

class SelectionCaptureController extends Notifier<SelectionCaptureState> {
  @override
  SelectionCaptureState build() {
    return const SelectionCaptureState.empty();
  }

  void handleBridgeMessage(String message) {
    final event = SelectionCaptureEvent.tryParse(message);
    if (event == null || event.isCleared) {
      clear();
      return;
    }

    final capture = event.capture;
    state = capture == null ? const SelectionCaptureState.empty() : SelectionCaptureState(capture: capture);
  }

  void clear() {
    state = const SelectionCaptureState.empty();
  }
}

class SelectionCaptureState {
  const SelectionCaptureState({this.capture});

  const SelectionCaptureState.empty() : capture = null;

  final SelectionCapture? capture;

  bool get hasSelection => capture != null;
}

class SelectionCaptureEvent {
  const SelectionCaptureEvent({required this.type, this.capture});

  final String type;
  final SelectionCapture? capture;

  bool get isCleared => type == 'selection-cleared';

  static SelectionCaptureEvent? tryParse(String message) {
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, Object?>) {
        return null;
      }

      final type = decoded['type']?.toString();
      if (type == null || type.isEmpty) {
        return null;
      }

      if (type == 'selection-cleared') {
        return SelectionCaptureEvent(type: type);
      }

      if (type != 'selection-captured') {
        return null;
      }

      final payload = decoded['payload'];
      if (payload is! Map<String, Object?>) {
        return null;
      }

      final capture = SelectionCapture.tryParse(payload);
      return capture == null ? null : SelectionCaptureEvent(type: type, capture: capture);
    } on FormatException catch (error) {
      debugPrint('Ignoring malformed selection bridge message: $error');
      return null;
    } on TypeError catch (error) {
      debugPrint('Ignoring invalid selection bridge message: $error');
      return null;
    }
  }
}

class SelectionCapture {
  const SelectionCapture({
    required this.exact,
    required this.prefix,
    required this.suffix,
    required this.sourceUrl,
    required this.textPositionStart,
    required this.textPositionEnd,
    this.pageTitle,
    this.cssSelector,
  });

  final String exact;
  final String prefix;
  final String suffix;
  final Uri sourceUrl;
  final int textPositionStart;
  final int textPositionEnd;
  final String? pageTitle;
  final String? cssSelector;

  static SelectionCapture? tryParse(Map<String, Object?> payload) {
    final exact = nonEmpty(payload['exact']);
    final source = nonEmpty(payload['sourceUrl']);
    final sourceUrl = source == null ? null : Uri.tryParse(source);
    if (exact == null || sourceUrl == null || !sourceUrl.hasScheme || !sourceUrl.hasAuthority) {
      return null;
    }

    final start = _intValue(payload['textPositionStart']);
    final end = _intValue(payload['textPositionEnd']);
    if (start == null || end == null || start < 0 || end <= start) {
      return null;
    }

    return SelectionCapture(
      exact: exact,
      prefix: nonEmpty(payload['prefix']) ?? '',
      suffix: nonEmpty(payload['suffix']) ?? '',
      sourceUrl: sourceUrl,
      textPositionStart: start,
      textPositionEnd: end,
      pageTitle: nonEmpty(payload['pageTitle']),
      cssSelector: nonEmpty(payload['cssSelector']),
    );
  }

  Map<String, Object?> toW3cTargetJson() => {
    'source': sourceUrl.toString(),
    'selector': [
      {'type': 'TextQuoteSelector', 'exact': exact, 'prefix': prefix, 'suffix': suffix},
      {'type': 'TextPositionSelector', 'start': textPositionStart, 'end': textPositionEnd},
      if (cssSelector != null) {'type': 'CssSelector', 'value': cssSelector},
    ],
  };

  static int? _intValue(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
