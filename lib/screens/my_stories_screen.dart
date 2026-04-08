import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../providers/stories_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_background.dart';
import '../widgets/story_card.dart';

class MyStoriesScreen extends StatefulWidget {
  const MyStoriesScreen({super.key});

  @override
  State<MyStoriesScreen> createState() => _MyStoriesScreenState();
}

class _MyStoriesScreenState extends State<MyStoriesScreen> {
  String _search = '';
  bool _showFavoritesOnly = false;
  bool _isGridView = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['filter'] == 'favorites') {
      setState(() => _showFavoritesOnly = true);
    }
  }

  List<Story> _filtered(List<Story> stories) {
    return stories.where((s) {
      final matchesSearch =
          s.title.toLowerCase().contains(_search.toLowerCase());
      final matchesFav = !_showFavoritesOnly || s.isFavorite;
      return matchesSearch && matchesFav;
    }).toList();
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Story'),
        content: const Text("Are you sure? This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              context.read<StoriesProvider>().deleteStory(id);
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final stories = context.watch<StoriesProvider>().stories;
    final filtered = _filtered(stories);

    return Scaffold(
      body: GradientBackground(
        variant: GradientVariant.purple,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                    const Expanded(
                      child: Text(
                        'My Stories',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    // Grid/List toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isGridView = !_isGridView);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _isGridView
                              ? Icons.view_list_rounded
                              : Icons.grid_view_rounded,
                          color: AppColors.foreground,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // New story button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushNamed(context, '/editor/new');
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 12),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search stories...',
                      hintStyle: const TextStyle(
                          color: AppColors.mutedForeground, fontSize: 14),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.mutedForeground, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                              child: const Icon(Icons.clear_rounded,
                                  color: AppColors.mutedForeground,
                                  size: 16),
                            )
                          : null,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 10),

              // Filter chips + count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip('All', !_showFavoritesOnly, null),
                    const SizedBox(width: 8),
                    _filterChip('Favourites', _showFavoritesOnly,
                        Icons.star_rounded),
                    const Spacer(),
                    Text(
                      '${filtered.length} ${filtered.length == 1 ? "story" : "stories"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 12),

              // Content
              Expanded(
                child: filtered.isEmpty
                    ? _emptyState()
                    : _isGridView
                        ? _gridView(filtered)
                        : _listView(filtered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listView(List<Story> stories) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: stories.length,
      itemBuilder: (context, i) {
        return StoryCard(
          story: stories[i],
          onTap: () =>
              Navigator.pushNamed(context, '/viewer/${stories[i].id}'),
          onEdit: () =>
              Navigator.pushNamed(context, '/editor/${stories[i].id}'),
          onDelete: () => _confirmDelete(context, stories[i].id),
          onToggleFavorite: () =>
              context.read<StoriesProvider>().toggleFavorite(stories[i].id),
        ).animate().fadeIn(delay: (i * 50).ms);
      },
    );
  }

  Widget _gridView(List<Story> stories) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: stories.length,
      itemBuilder: (context, i) {
        final story = stories[i];
        final bgColor = _hexToColor(story.coverColor);
        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/viewer/${story.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      color: bgColor,
                      child: Stack(
                        children: [
                          Center(
                            child: Text(story.coverEmoji,
                                style: const TextStyle(fontSize: 50)),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                context
                                    .read<StoriesProvider>()
                                    .toggleFavorite(story.id);
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  story.isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 16,
                                  color: story.isFavorite
                                      ? AppColors.warning
                                      : AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/editor/${story.id}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondaryForeground,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () =>
                                  _confirmDelete(context, story.id),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE5EA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 14,
                                  color: AppColors.destructive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (i * 50).ms).scale(
              begin: const Offset(0.92, 0.92),
              duration: 300.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 14),
          Text(
            _showFavoritesOnly
                ? 'No favourites yet'
                : _search.isNotEmpty
                    ? 'No stories found'
                    : 'No stories yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _showFavoritesOnly
                ? 'Star a story to add it here'
                : 'Tap + to create your first story!',
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, IconData? icon) {
    return GestureDetector(
      onTap: () => setState(() => _showFavoritesOnly = label != 'All'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 12,
                  color:
                      active ? Colors.white : AppColors.mutedForeground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    active ? Colors.white : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
