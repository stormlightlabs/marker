import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marker/src/features/browser/ad_block/ad_block_rules.dart';
import 'package:marker/src/features/browser/ad_block/ad_block_runtime.dart';

final compiledAdBlockRulesProvider = FutureProvider<CompiledAdBlockRules>((ref) {
  return EasyListLoader().load();
});

final adBlockRuntimeProvider = Provider<AdBlockRuntime>((ref) => const AdBlockRuntime());
