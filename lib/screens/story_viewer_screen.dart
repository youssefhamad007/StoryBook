import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/stories_provider.dart';
import '../theme/app_colors.dart';

class StoryViewerScreen extends StatefulWidget {
  final String storyId;
  const StoryViewerScreen({super.key, required this.storyId});

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _goToPage(int next, int total) {
    if (next < 0 || next >= total) return;
    HapticFeedback.lightImpact();
    setState(() => _currentPage = next);
  }

  @override
  Widget build(BuildContext context) {
    final story =
        context.watch<StoriesProvider>().getStory(widget.storyId);

    if (story == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📚', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              const Text(
                'Story not found',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final page = story.pages.isNotEmpty
        ? story.pages[_currentPage]
        : null;
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == story.pages.length - 1;
    final bgColor =
        page != null ? _hexToColor(page.backgroundColor) : AppColors.gradientPink;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -100) {
            _goToPage(_currentPage + 1, story.pages.length);
          } else if (details.primaryVelocity! > 100) {
            _goToPage(_currentPage - 1, story.pages.length);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: bgColor,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: AppColors.foreground),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          story.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              context
                                  .read<StoriesProvider>()
                                  .toggleFavorite(story.id);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                story.isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: story.isFavorite
                                    ? AppColors.warning
                                    : AppColors.foreground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                                context, '/editor/${story.id}'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.edit_outlined,
                                  color: AppColors.foreground, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress dots
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: List.generate(
                      story.pages.length,
                      (i) => Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _goToPage(i, story.pages.length),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 6,
                            margin: EdgeInsets.only(
                                right: i < story.pages.length - 1 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? AppColors.foreground
                                  : AppColors.foreground.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Illustration area
                        Container(
                          width: double.infinity,
                          constraints:
                              const BoxConstraints(minHeight: 220),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            children: [
                              Text(
                                story.coverEmoji,
                                style: const TextStyle(fontSize: 90),
                              ),
                              if (page != null &&
                                  page.imageDescription.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.image_outlined,
                                      size: 14,
                                      color: Colors.black38,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        page.imageDescription,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black38,
                                          fontStyle: FontStyle.italic,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Text card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Page ${_currentPage + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedForeground,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                page?.text.isNotEmpty == true
                                    ? page!.text
                                    : 'This page has no text yet.',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.foreground,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Footer nav
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: isFirst
                            ? null
                            : () => _goToPage(
                                _currentPage - 1, story.pages.length),
                        child: Opacity(
                          opacity: isFirst ? 0.3 : 1,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                                Icons.chevron_left_rounded,
                                color: AppColors.foreground,
                                size: 28),
                          ),
                        ),
                      ),
                      Text(
                        '${_currentPage + 1} / ${story.pages.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      isLast
                          ? GestureDetector(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Finish',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () => _goToPage(
                                  _currentPage + 1, story.pages.length),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.foreground,
                                    size: 28),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
