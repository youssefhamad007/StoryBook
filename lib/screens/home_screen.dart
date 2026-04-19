import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// تأكد إن المسار واسم الـ Provider مطابق للي زميلك عمله
import '../providers/stories_provider.dart'; 
import '../theme/app_colors.dart';
import '../widgets/gradient_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. قراءة القصص (زي ما هي)
    final stories = context.watch<StoriesProvider>().stories;
    final favoriteCount = stories.where((s) => s.isFavorite).length;

    // 2. قراءة بيانات المستخدم الحقيقية من الـ AuthProvider (الجديد)
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    // 3. استخراج الاسم (لو ملوش اسم مسجل، بناخد أول جزء من الإيميل، ولو مفيش نكتب Guest)
    final String userName = currentUser?.userMetadata?['name'] ?? 
                            currentUser?.email?.split('@')[0] ?? 
                            "Guest";

    // 4. استخراج الصورة (لو ملوش صورة، بنعمله صورة ديناميكية بأول حرف من اسمه زي ما كنا عاملين)
    final String userAvatarUrl = currentUser?.userMetadata?['avatar_url'] ?? 
                                "https://ui-avatars.com/api/?name=${userName.replaceAll(' ', '+')}&background=0D8ABC&color=fff";

    return Scaffold(
      body: GradientBackground(
        child: CustomScrollView(
          slivers: [
            // 1. Premium Frosted Glass AppBar
            SliverAppBar(
              expandedHeight: 85.0,
              floating: true,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(userAvatarUrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hello, $userName! 👋',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.foreground,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Ready to create stories?',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _statBadge(stories.length),
                ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2),
              ],
            ),

            // محتوى الشاشة
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero banner
                    _heroBanner(favoriteCount),

                    const SizedBox(height: 30),

                    // Section label
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mutedForeground,
                        letterSpacing: 0.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    // 2. Colored Glass Action Grid
                    _actionGrid(context),

                    const SizedBox(height: 32),

                    // Recent stories section
                    if (stories.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Stories',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.foreground,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/stories'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'See all →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 350.ms),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: stories.take(5).length,
                          clipBehavior: Clip.none,
                          itemBuilder: (context, i) {
                            final story = stories[i];
                            return _recentStoryChip(context, story);
                          },
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Widget _statBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_rounded,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBanner(int favoriteCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _bounceAnim.value),
              child: child,
            ),
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientPink, Color(0xFFFFD1D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('📚', style: TextStyle(fontSize: 45)),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Where Stories\nCome to Life!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.foreground,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create, imagine & share your adventures',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (favoriteCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '$favoriteCount Favourites',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB8860B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _actionGrid(BuildContext context) {
    final actions = [
      _ActionItem(
        label: 'Create Story',
        icon: Icons.auto_fix_high_rounded,
        color: const Color(0xFFFF4B6E), 
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, '/editor/new');
        },
      ),
      _ActionItem(
        label: 'My Library',
        icon: Icons.collections_bookmark_rounded,
        color: const Color(0xFF10AC84), 
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, '/stories');
        },
      ),
      _ActionItem(
        label: 'Favourites',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF9F1C), 
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, '/stories', arguments: {'filter': 'favorites'});
        },
      ),
      _ActionItem(
        label: 'Settings',
        icon: Icons.tune_rounded,
        color: const Color(0xFF8E54E9), 
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, '/settings');
        },
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: actions.asMap().entries.map((e) {
        final delay = (e.key * 70 + 250).ms;
        return _ActionCard(item: e.value)
            .animate()
            .fadeIn(delay: delay, duration: 400.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              delay: delay,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            );
      }).toList(),
    );
  }

  // تطبيق الستايل الزجاجي على كروت القصص الأخيرة
  Widget _recentStoryChip(BuildContext context, story) {
    final bgColor = _hexToColor(story.coverColor as String);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/viewer/${story.id}'),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.25), // ظل ناعم بنفس لون القصة
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // زغللة قوية عشان الإزاز يبان
            child: Container(
              decoration: BoxDecoration(
                // هنا السر: شفافية 0.4 عشان يدي تأثير الزجاج الملون
                color: bgColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5), // لمعة الإطار الزجاجي
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    story.coverEmoji as String,
                    style: const TextStyle(fontSize: 38),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      story.title as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.foreground, // النص غامق عشان يتقري بوضوح
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
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

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActionCard extends StatefulWidget {
  final _ActionItem item;
  const _ActionCard({required this.item});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.item.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.item.color.withValues(alpha: 0.35),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.item.color.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        widget.item.icon,
                        color: Colors.white,
                        size: 32,
                      ),
                      Text(
                        widget.item.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}