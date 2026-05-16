import 'dart:convert';

import 'package:flutter/services.dart';

const String easyListAssetPath = 'assets/filters/easylist.txt';

enum AdBlockAction { block, ignorePreviousRules }

enum AdBlockLoadType { firstParty, thirdParty }

enum AdBlockResourceType { document, font, image, media, raw, script, styleSheet }

class AdBlockNetworkRule {
  const AdBlockNetworkRule({
    required this.urlFilter,
    required this.action,
    this.resourceTypes = const {},
    this.loadTypes = const {},
    this.ifTopUrl = const [],
    this.unlessTopUrl = const [],
    this.important = false,
  });

  final String urlFilter;
  final AdBlockAction action;
  final Set<AdBlockResourceType> resourceTypes;
  final Set<AdBlockLoadType> loadTypes;
  final List<String> ifTopUrl;
  final List<String> unlessTopUrl;
  final bool important;

  bool get isException => action == AdBlockAction.ignorePreviousRules;
}

class AdBlockCosmeticRule {
  const AdBlockCosmeticRule({
    required this.selector,
    required this.exception,
    this.domains = const [],
    this.excludedDomains = const [],
  });

  final String selector;
  final bool exception;
  final List<String> domains;
  final List<String> excludedDomains;

  bool appliesTo(Uri pageUrl) {
    final host = pageUrl.host.toLowerCase();
    if (host.isEmpty) {
      return domains.isEmpty;
    }
    if (excludedDomains.any((domain) => _hostMatchesDomain(host, domain))) {
      return false;
    }
    return domains.isEmpty || domains.any((domain) => _hostMatchesDomain(host, domain));
  }
}

class AdBlockParseStats {
  const AdBlockParseStats({
    required this.totalLines,
    required this.commentLines,
    required this.networkRules,
    required this.cosmeticRules,
    required this.exceptionRules,
    required this.unsupportedRules,
    required this.invalidRules,
  });

  final int totalLines;
  final int commentLines;
  final int networkRules;
  final int cosmeticRules;
  final int exceptionRules;
  final int unsupportedRules;
  final int invalidRules;
}

class CompiledAdBlockRules {
  const CompiledAdBlockRules({required this.networkRules, required this.cosmeticRules, required this.stats});

  final List<AdBlockNetworkRule> networkRules;
  final List<AdBlockCosmeticRule> cosmeticRules;
  final AdBlockParseStats stats;

  List<String> cosmeticSelectorsFor(Uri pageUrl) {
    final exceptions = <String>{};
    final selectors = <String>[];
    for (final rule in cosmeticRules) {
      if (!rule.appliesTo(pageUrl)) {
        continue;
      }
      if (rule.exception) {
        exceptions.add(rule.selector);
        continue;
      }
      selectors.add(rule.selector);
    }
    return selectors.where((selector) => !exceptions.contains(selector)).toList(growable: false);
  }

  bool shouldBlockRequest(Uri requestUrl, {required Uri? topUrl, AdBlockResourceType? resourceType}) {
    var block = false;
    var exception = false;
    var importantBlock = false;
    for (final rule in networkRules) {
      if (!_ruleMatches(rule, requestUrl, topUrl: topUrl, resourceType: resourceType)) {
        continue;
      }
      if (rule.isException) {
        if (!importantBlock) {
          exception = true;
          block = false;
        }
        continue;
      }
      if (rule.important) {
        importantBlock = true;
        block = true;
        continue;
      }
      if (!exception) {
        block = true;
      }
    }
    return block;
  }
}

class EasyListLoader {
  EasyListLoader({AssetBundle? assetBundle}) : _assetBundle = assetBundle ?? rootBundle;

  final AssetBundle _assetBundle;

  Future<CompiledAdBlockRules> load() async {
    final content = await _assetBundle.loadString(easyListAssetPath);
    return EasyListParser().parse(content);
  }
}

class EasyListParser {
  CompiledAdBlockRules parse(String content) {
    final networkRules = <AdBlockNetworkRule>[];
    final cosmeticRules = <AdBlockCosmeticRule>[];
    var totalLines = 0;
    var commentLines = 0;
    var exceptionRules = 0;
    var unsupportedRules = 0;
    var invalidRules = 0;

    for (final rawLine in const LineSplitter().convert(content)) {
      totalLines += 1;
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('!') || line.startsWith('[')) {
        commentLines += 1;
        continue;
      }
      final cosmetic = _parseCosmetic(line);
      if (cosmetic != null) {
        cosmeticRules.add(cosmetic);
        if (cosmetic.exception) {
          exceptionRules += 1;
        }
        continue;
      }
      if (_looksLikeUnsupportedExtendedFilter(line)) {
        unsupportedRules += 1;
        continue;
      }
      if (_containsUnsupportedNetworkOption(line)) {
        unsupportedRules += 1;
        continue;
      }
      final network = _parseNetwork(line);
      if (network == null) {
        invalidRules += 1;
        continue;
      }
      if (network.urlFilter.isEmpty) {
        unsupportedRules += 1;
        continue;
      }
      networkRules.add(network);
      if (network.isException) {
        exceptionRules += 1;
      }
    }

    return CompiledAdBlockRules(
      networkRules: networkRules,
      cosmeticRules: cosmeticRules,
      stats: AdBlockParseStats(
        totalLines: totalLines,
        commentLines: commentLines,
        networkRules: networkRules.length,
        cosmeticRules: cosmeticRules.length,
        exceptionRules: exceptionRules,
        unsupportedRules: unsupportedRules,
        invalidRules: invalidRules,
      ),
    );
  }

  AdBlockCosmeticRule? _parseCosmetic(String line) {
    final exceptionIndex = line.indexOf('#@#');
    final hideIndex = line.indexOf('##');
    final isException = exceptionIndex != -1 && (hideIndex == -1 || exceptionIndex < hideIndex);
    final separatorIndex = isException ? exceptionIndex : hideIndex;
    if (separatorIndex == -1) {
      return null;
    }
    final separatorLength = isException ? 3 : 2;
    final selector = line.substring(separatorIndex + separatorLength).trim();
    if (selector.isEmpty || _isUnsupportedCosmeticSelector(selector)) {
      return null;
    }
    final domainsText = line.substring(0, separatorIndex).trim();
    final domains = <String>[];
    final excludedDomains = <String>[];
    if (domainsText.isNotEmpty) {
      for (final part in domainsText.split(',')) {
        final domain = part.trim().toLowerCase();
        if (domain.isEmpty) {
          continue;
        }
        if (domain.startsWith('~')) {
          excludedDomains.add(domain.substring(1));
        } else {
          domains.add(domain);
        }
      }
    }
    return AdBlockCosmeticRule(
      selector: selector,
      exception: isException,
      domains: domains,
      excludedDomains: excludedDomains,
    );
  }

  AdBlockNetworkRule? _parseNetwork(String line) {
    var ruleText = line;
    var isException = false;
    if (ruleText.startsWith('@@')) {
      isException = true;
      ruleText = ruleText.substring(2);
    }
    final optionIndex = _networkOptionIndex(ruleText);
    final options = <String>[];
    if (optionIndex > 0) {
      options.addAll(ruleText.substring(optionIndex + 1).split(',').map((option) => option.trim()));
      ruleText = ruleText.substring(0, optionIndex);
    }
    if (ruleText.isEmpty || ruleText.startsWith('#')) {
      return null;
    }

    final resourceTypes = <AdBlockResourceType>{};
    final loadTypes = <AdBlockLoadType>{};
    final ifTopUrl = <String>[];
    final unlessTopUrl = <String>[];
    var important = false;

    for (final option in options) {
      if (option.isEmpty) {
        continue;
      }
      if (option.startsWith('~')) {
        continue;
      }
      if (option == 'important') {
        important = true;
        continue;
      }
      if (option == 'third-party' || option == '3p') {
        loadTypes.add(AdBlockLoadType.thirdParty);
        continue;
      }
      if (option == 'first-party' || option == '1p') {
        loadTypes.add(AdBlockLoadType.firstParty);
        continue;
      }
      final resourceType = _resourceTypeFromOption(option);
      if (resourceType != null) {
        resourceTypes.add(resourceType);
        continue;
      }
      if (option.startsWith('domain=') || option.startsWith('from=')) {
        final domains = option.substring(option.indexOf('=') + 1).split('|');
        for (final rawDomain in domains) {
          final domain = rawDomain.trim().toLowerCase();
          if (domain.isEmpty) {
            continue;
          }
          final target = domain.startsWith('~') ? unlessTopUrl : ifTopUrl;
          target.add(_topUrlRegexForDomain(domain.replaceFirst('~', '')));
        }
        continue;
      }
      if (_isUnsupportedOption(option)) {
        return null;
      }
    }

    final urlFilter = _urlFilterFor(ruleText);
    if (urlFilter == null) {
      return null;
    }
    return AdBlockNetworkRule(
      urlFilter: urlFilter,
      action: isException ? AdBlockAction.ignorePreviousRules : AdBlockAction.block,
      resourceTypes: resourceTypes,
      loadTypes: loadTypes,
      ifTopUrl: ifTopUrl,
      unlessTopUrl: unlessTopUrl,
      important: important,
    );
  }
}

int _networkOptionIndex(String ruleText) {
  if (!ruleText.startsWith('/')) {
    return ruleText.lastIndexOf(r'$');
  }
  final regexEnd = _regexLiteralEndIndex(ruleText);
  if (regexEnd == -1 || regexEnd == ruleText.length - 1) {
    return -1;
  }
  return ruleText[regexEnd + 1] == r'$' ? regexEnd + 1 : -1;
}

int _regexLiteralEndIndex(String ruleText) {
  var escaped = false;
  for (var index = 1; index < ruleText.length; index += 1) {
    final char = ruleText[index];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (char == r'\') {
      escaped = true;
      continue;
    }
    if (char == '/') {
      return index;
    }
  }
  return -1;
}

bool _ruleMatches(
  AdBlockNetworkRule rule,
  Uri requestUrl, {
  required Uri? topUrl,
  required AdBlockResourceType? resourceType,
}) {
  if (resourceType != null && rule.resourceTypes.isNotEmpty && !rule.resourceTypes.contains(resourceType)) {
    return false;
  }
  if (!_matchesRegex(rule.urlFilter, requestUrl.toString())) {
    return false;
  }
  if (topUrl != null) {
    final isThirdParty = _domainForHost(requestUrl.host) != _domainForHost(topUrl.host);
    if (rule.loadTypes.contains(AdBlockLoadType.thirdParty) && !isThirdParty) {
      return false;
    }
    if (rule.loadTypes.contains(AdBlockLoadType.firstParty) && isThirdParty) {
      return false;
    }
    final topText = topUrl.toString();
    if (rule.ifTopUrl.isNotEmpty && !rule.ifTopUrl.any((pattern) => _matchesRegex(pattern, topText))) {
      return false;
    }
    if (rule.unlessTopUrl.any((pattern) => _matchesRegex(pattern, topText))) {
      return false;
    }
  }
  return true;
}

bool _matchesRegex(String pattern, String value) {
  try {
    return RegExp(pattern, caseSensitive: false).hasMatch(value);
  } on FormatException {
    return false;
  }
}

AdBlockResourceType? _resourceTypeFromOption(String option) {
  return switch (option) {
    'document' || 'doc' || 'subdocument' || 'frame' => AdBlockResourceType.document,
    'font' => AdBlockResourceType.font,
    'image' => AdBlockResourceType.image,
    'media' || 'object' => AdBlockResourceType.media,
    'other' || 'xmlhttprequest' || 'xhr' || 'ping' || 'websocket' => AdBlockResourceType.raw,
    'script' => AdBlockResourceType.script,
    'stylesheet' || 'css' => AdBlockResourceType.styleSheet,
    _ => null,
  };
}

bool _isUnsupportedOption(String option) {
  final name = option.split('=').first;
  return const {
    'badfilter',
    'cname',
    'csp',
    'denyallow',
    'empty',
    'genericblock',
    'generichide',
    'ghide',
    'inline-font',
    'inline-script',
    'method',
    'permissions',
    'redirect',
    'redirect-rule',
    'removeparam',
    'replace',
    'urlskip',
    'uritransform',
  }.contains(name);
}

bool _containsUnsupportedNetworkOption(String line) {
  final optionIndex = line.lastIndexOf(r'$');
  if (optionIndex == -1 || optionIndex == line.length - 1) {
    return false;
  }
  final options = line.substring(optionIndex + 1).split(',');
  return options.any((option) => _isUnsupportedOption(option.trim()));
}

bool _looksLikeUnsupportedExtendedFilter(String line) {
  return line.contains('#?#') ||
      line.contains(r'#$#') ||
      line.contains('#%#') ||
      line.contains('#^') ||
      line.contains('##+js') ||
      line.contains('#@#+js');
}

bool _isUnsupportedCosmeticSelector(String selector) {
  return selector.contains(':-abp-') ||
      selector.contains(':has-text') ||
      selector.contains(':matches-css') ||
      selector.contains(':xpath') ||
      selector.contains(':style(') ||
      selector.startsWith('+js') ||
      selector.startsWith('script:');
}

String? _urlFilterFor(String pattern) {
  if (pattern.length >= 2 && pattern.startsWith('/') && pattern.endsWith('/')) {
    return pattern.substring(1, pattern.length - 1);
  }
  if (pattern == '*' || pattern.isEmpty) {
    return null;
  }
  if (pattern.startsWith('||')) {
    return '^https?://([^/?#]+\\.)?${_easyListPatternToRegex(pattern.substring(2))}';
  }
  var anchoredLeft = false;
  var anchoredRight = false;
  var body = pattern;
  if (body.startsWith('|')) {
    anchoredLeft = true;
    body = body.substring(1);
  }
  if (body.endsWith('|')) {
    anchoredRight = true;
    body = body.substring(0, body.length - 1);
  }
  final regex = _easyListPatternToRegex(body);
  return '${anchoredLeft ? '^' : ''}$regex${anchoredRight ? r'$' : ''}';
}

String _easyListPatternToRegex(String pattern) {
  final buffer = StringBuffer();
  for (var i = 0; i < pattern.length; i += 1) {
    final char = pattern[i];
    if (char == '*') {
      buffer.write('.*');
    } else if (char == '^') {
      buffer.write(r'(?:[^A-Za-z0-9_.%-]|$)');
    } else {
      buffer.write(RegExp.escape(char));
    }
  }
  return buffer.toString();
}

String _topUrlRegexForDomain(String domain) {
  return '^https?://([^/?#]+\\.)?${RegExp.escape(domain)}(?:[/:?#]|${r'$'})';
}

String _domainForHost(String host) {
  final parts = host.toLowerCase().split('.').where((part) => part.isNotEmpty).toList();
  if (parts.length <= 2) {
    return parts.join('.');
  }
  return parts.sublist(parts.length - 2).join('.');
}

bool _hostMatchesDomain(String host, String domain) {
  final normalized = domain.toLowerCase();
  return host == normalized || host.endsWith('.$normalized');
}
