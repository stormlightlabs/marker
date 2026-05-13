import 'package:code_forge/code_forge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:marker/src/features/browser/application/selection_capture_controller.dart';
import 'package:re_highlight/languages/all.dart' as re_languages;
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/re_highlight.dart' as re;
import 'package:re_highlight/styles/github-dark.dart';

class NoteEditorSheet extends StatefulWidget {
  const NoteEditorSheet({required this.capture, super.key});

  final SelectionCapture capture;

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final CodeForgeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeForgeController()..addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.trim().isNotEmpty;
    final previewText = canSave ? _controller.text : '_Markdown preview will appear here._';

    return CupertinoPopupSurface(
      isSurfacePainted: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF111114),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SizedBox(
              height: 500,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(color: const Color(0xFF3A3A42), borderRadius: BorderRadius.circular(3)),
                  ),
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel', style: TextStyle(color: CupertinoColors.systemGrey)),
                        ),
                        const Expanded(
                          child: Text(
                            'Add Note',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: canSave ? () => Navigator.of(context).pop(_controller.text) : null,
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: canSave ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF33333A), width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '"${widget.capture.exact}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey2,
                            fontSize: 14,
                            height: 1.25,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 190,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF33333A), width: 0.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CodeForge(
                            controller: _controller,
                            language: langMarkdown,
                            editorTheme: githubDarkTheme,
                            textStyle: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 14,
                              height: 1.28,
                              letterSpacing: 0,
                              fontFamily: 'Menlo',
                            ),
                            innerPadding: const EdgeInsets.all(12),
                            autoFocus: true,
                            lineWrap: true,
                            enableFolding: false,
                            enableGuideLines: false,
                            enableGutter: false,
                            enableGutterDivider: false,
                            enableSuggestions: false,
                            enableKeyboardSuggestions: false,
                            selectionStyle: CodeSelectionStyle(
                              cursorColor: CupertinoColors.activeBlue,
                              selectionColor: CupertinoColors.activeBlue.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF33333A), width: 0.5),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Markdown(
                            data: previewText,
                            padding: const EdgeInsets.all(12),
                            selectable: false,
                            syntaxHighlighter: _ReHighlightSyntaxHighlighter(),
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 14,
                                height: 1.28,
                                letterSpacing: 0,
                              ),
                              em: const TextStyle(
                                color: CupertinoColors.systemGrey2,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0,
                              ),
                              strong: const TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                              code: const TextStyle(
                                color: Color(0xFFA5D6FF),
                                fontSize: 13,
                                fontFamily: 'Menlo',
                                letterSpacing: 0,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: const Color(0xFF161B22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              blockquoteDecoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: CupertinoColors.systemGrey, width: 3)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReHighlightSyntaxHighlighter extends SyntaxHighlighter {
  _ReHighlightSyntaxHighlighter() {
    _highlight.registerLanguages(re_languages.builtinAllLanguages);
  }

  static const _languageSubset = <String>[
    'markdown',
    'dart',
    'javascript',
    'typescript',
    'json',
    'bash',
    'yaml',
    'sql',
    'css',
    'xml',
  ];

  final re.Highlight _highlight = re.Highlight();

  @override
  TextSpan format(String source) {
    final result = _highlight.highlightAuto(source, _languageSubset);
    final renderer = re.TextSpanRenderer(
      const TextStyle(color: Color(0xFFC9D1D9), fontSize: 13, fontFamily: 'Menlo', letterSpacing: 0),
      githubDarkTheme,
    );
    result.render(renderer);
    return renderer.span ?? TextSpan(text: source);
  }
}
