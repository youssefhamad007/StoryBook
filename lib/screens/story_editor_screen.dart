import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../providers/stories_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_background.dart';
import '../widgets/kid_button.dart';

enum _SaveStatus { idle, saving, saved }

class StoryEditorScreen extends StatefulWidget {
  final String? storyId;
  const StoryEditorScreen({super.key, this.storyId});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  bool get isNew => widget.storyId == null;

  late TextEditingController _titleController;
  String _coverColor = '#FFD6E8';
  String _coverEmoji = '📖';
  List<StoryPage> _pages = [];
  int _activePage = 0;
  bool _showEmojiPicker = false;
  _SaveStatus _saveStatus = _SaveStatus.idle;

  static const _coverColors = [
    '#FFD6E8', '#C0E5FF', '#C2F5E9', '#E5DEFF',
    '#FFF3CD', '#FFE0B2', '#F8D7DA', '#D1ECF1',
  ];

  static const _coverEmojis = [
    '📖', '🐉', '🦄', '🐰', '🧚', '🌟', '🦋', '🐬', '🌈', '🏰',
  ];

  String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}${DateTime.now().microsecond % 9999}';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'My New Story');
    _pages = [StoryPage(id: _generateId(), backgroundColor: _coverColors[0])];

    if (!isNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final story =
            context.read<StoriesProvider>().getStory(widget.storyId!);
        if (story != null) {
          setState(() {
            _titleController.text = story.title;
            _coverColor = story.coverColor;
            _coverEmoji = story.coverEmoji;
            _pages = story.pages.map((p) => StoryPage(
                  id: p.id,
                  text: p.text,
                  imageDescription: p.imageDescription,
                  backgroundColor: p.backgroundColor,
                )).toList();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _updateActivePage(String field, String value) {
    final p = _pages[_activePage];
    setState(() {
      _pages[_activePage] = StoryPage(
        id: p.id,
        text: field == 'text' ? value : p.text,
        imageDescription: field == 'image' ? value : p.imageDescription,
        backgroundColor: field == 'color' ? value : p.backgroundColor,
      );
    });
  }

  void _addPage() {
    HapticFeedback.lightImpact();
    setState(() {
      _pages.add(StoryPage(
        id: _generateId(),
        backgroundColor: _coverColors[_pages.length % _coverColors.length],
      ));
      _activePage = _pages.length - 1;
    });
  }

  void _deletePage() {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A story needs at least one page.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Page'),
        content: const Text('Remove this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              setState(() {
                _pages.removeAt(_activePage);
                _activePage = (_activePage - 1).clamp(0, _pages.length - 1);
              });
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _save({bool andNavigate = true}) async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your story a title!')),
      );
      return;
    }

    setState(() => _saveStatus = _SaveStatus.saving);
    await Future.delayed(const Duration(milliseconds: 300));

    final provider = context.read<StoriesProvider>();

    if (isNew) {
      final id = provider.addStory(
        title: _titleController.text.trim(),
        coverColor: _coverColor,
        coverEmoji: _coverEmoji,
        pages: _pages,
      );
      HapticFeedback.heavyImpact();
      setState(() => _saveStatus = _SaveStatus.saved);
      if (mounted && andNavigate) {
        Navigator.pushReplacementNamed(context, '/viewer/$id');
      }
    } else {
      final story = provider.getStory(widget.storyId!);
      if (story != null) {
        provider.updateStory(
          widget.storyId!,
          story.copyWith(
            title: _titleController.text.trim(),
            coverColor: _coverColor,
            coverEmoji: _coverEmoji,
            pages: _pages,
          ),
        );
      }
      HapticFeedback.heavyImpact();
      setState(() => _saveStatus = _SaveStatus.saved);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _saveStatus = _SaveStatus.idle);
    }
  }

  void _openPreview() {
    final id = widget.storyId ?? 'unsaved';
    if (isNew) {
      // Save first, then preview
      final provider = context.read<StoriesProvider>();
      final savedId = provider.addStory(
        title: _titleController.text.trim().isEmpty
            ? 'My New Story'
            : _titleController.text.trim(),
        coverColor: _coverColor,
        coverEmoji: _coverEmoji,
        pages: _pages,
      );
      Navigator.pushNamed(context, '/preview/$savedId');
    } else {
      // Save silently then preview
      _save(andNavigate: false).then((_) {
        if (mounted) {
          Navigator.pushNamed(context, '/preview/$id');
        }
      });
    }
  }

  Widget _saveIndicator() {
    switch (_saveStatus) {
      case _SaveStatus.saving:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.mutedForeground),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Saving...',
              style: TextStyle(
                  fontSize: 12, color: AppColors.mutedForeground),
            ),
          ],
        );
      case _SaveStatus.saved:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 14, color: Color(0xFF4CAF50)),
            SizedBox(width: 4),
            Text(
              'Saved!',
              style:
                  TextStyle(fontSize: 12, color: Color(0xFF4CAF50)),
            ),
          ],
        ).animate().fadeIn(duration: 200.ms);
      case _SaveStatus.idle:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pages.isNotEmpty ? _pages[_activePage] : null;

    return Scaffold(
      body: GradientBackground(
        variant: GradientVariant.mint,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _iconBtn(
                      Icons.close_rounded,
                      Colors.white.withValues(alpha: 0.8),
                      AppColors.foreground,
                      () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            isNew ? 'New Story' : 'Edit Story',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _saveIndicator(),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _iconBtn(
                          Icons.play_arrow_rounded,
                          AppColors.secondary,
                          AppColors.foreground,
                          _openPreview,
                          tooltip: 'Preview',
                        ),
                        const SizedBox(width: 8),
                        _iconBtn(
                          Icons.check_rounded,
                          AppColors.primary,
                          Colors.white,
                          _saveStatus == _SaveStatus.saving
                              ? null
                              : () => _save(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover tap area
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showEmojiPicker = !_showEmojiPicker),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: _hexToColor(_coverColor),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _hexToColor(_coverColor).withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(_coverEmoji,
                                  style: const TextStyle(fontSize: 72)),
                              Positioned(
                                bottom: 10,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '✏️ Tap to change',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_showEmojiPicker) ...[
                        const SizedBox(height: 8),
                        _card(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _coverEmojis.map((e) {
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _coverEmoji = e;
                                    _showEmojiPicker = false;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _coverEmoji == e
                                        ? AppColors.muted
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(e,
                                        style:
                                            const TextStyle(fontSize: 28)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Color row
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: _coverColors.map((c) {
                          final selected = _coverColor == c;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _coverColor = c);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _hexToColor(c),
                                borderRadius: BorderRadius.circular(17),
                                border: selected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color:
                                              Colors.black.withValues(alpha: 0.22),
                                          blurRadius: 6,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // Title card
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('STORY TITLE'),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _titleController,
                              onChanged: (_) =>
                                  setState(() => _saveStatus = _SaveStatus.idle),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter story title...',
                                hintStyle: TextStyle(
                                    color: AppColors.mutedForeground),
                                counterText: '',
                              ),
                              maxLength: 60,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Pages header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pages (${_pages.length})',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground,
                            ),
                          ),
                          GestureDetector(
                            onTap: _addPage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add_rounded,
                                      size: 15,
                                      color: AppColors.secondaryForeground),
                                  SizedBox(width: 5),
                                  Text(
                                    'Add Page',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Page tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_pages.length, (i) {
                            final active = _activePage == i;
                            return GestureDetector(
                              onTap: () => setState(() => _activePage = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 46,
                                height: 46,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: _hexToColor(
                                      _pages[i].backgroundColor),
                                  borderRadius: BorderRadius.circular(14),
                                  border: active
                                      ? Border.all(
                                          color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: active
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 6,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.foreground,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Active page editor
                      if (currentPage != null)
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _label(
                                      'PAGE ${_activePage + 1} OF ${_pages.length}'),
                                  GestureDetector(
                                    onTap: _deletePage,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE5EA),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 14,
                                            color: AppColors.destructive,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.destructive,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _label('STORY TEXT'),
                              const SizedBox(height: 4),
                              _multilineField(
                                currentPage.text,
                                'What happens on this page?',
                                (v) => _updateActivePage('text', v),
                              ),
                              const SizedBox(height: 10),
                              _label('ILLUSTRATION DESCRIPTION'),
                              const SizedBox(height: 4),
                              _multilineField(
                                currentPage.imageDescription,
                                "Describe the picture on this page...",
                                (v) => _updateActivePage('image', v),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 10),
                              _label('PAGE COLOUR'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _coverColors.map((c) {
                                  final sel =
                                      currentPage.backgroundColor == c;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      _updateActivePage('color', c);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _hexToColor(c),
                                        borderRadius:
                                            BorderRadius.circular(15),
                                        border: sel
                                            ? Border.all(
                                                color: Colors.white,
                                                width: 3)
                                            : null,
                                        boxShadow: sel
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 4,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Bottom action row
                      Row(
                        children: [
                          Expanded(
                            child: KidButton(
                              label: 'Preview Story',
                              icon: Icons.play_arrow_rounded,
                              variant: KidButtonVariant.secondary,
                              onPressed: _openPreview,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KidButton(
                              label: _saveStatus == _SaveStatus.saving
                                  ? 'Saving...'
                                  : 'Save',
                              icon: Icons.save_rounded,
                              onPressed: _saveStatus == _SaveStatus.saving
                                  ? () {}
                                  : () => _save(),
                              isLoading:
                                  _saveStatus == _SaveStatus.saving,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback? onTap, {
    String? tooltip,
  }) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip, child: btn);
    return btn;
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.mutedForeground,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _multilineField(
    String value,
    String hint,
    ValueChanged<String> onChanged, {
    int maxLines = 4,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.foreground,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }
}
