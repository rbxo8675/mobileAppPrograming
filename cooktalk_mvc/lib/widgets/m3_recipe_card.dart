import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../controllers/recipe_controller.dart';
import '../controllers/app_controller.dart';
import 'media_image.dart';
import 'tag_pill.dart';
import '../views/recipe_detail_view.dart';

class M3RecipeCard extends StatefulWidget {
  const M3RecipeCard({super.key, required this.recipe});
  final Recipe recipe;

  @override
  State<M3RecipeCard> createState() => _M3RecipeCardState();
}

class _M3RecipeCardState extends State<M3RecipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: _isHovered ? 4 : 1,
        shadowColor: scheme.shadow.withOpacity(0.2),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecipeDetailView(recipe: widget.recipe)),
          ),
          onHover: (hovering) {
            setState(() => _isHovered = hovering);
            if (hovering) {
              _controller.forward();
            } else {
              _controller.reverse();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(context, scheme),
              _buildContentSection(context, scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, ColorScheme scheme) {
    return Stack(
      children: [
        SizedBox(
          height: 192,
          width: double.infinity,
          child: Hero(
            tag: 'recipe_${widget.recipe.id}',
            child: MediaImage(path: widget.recipe.imagePath, fit: BoxFit.cover),
          ),
        ),
        if (widget.recipe.difficulty != null)
          Positioned(
            left: 12,
            bottom: 12,
            child: _DifficultyBadge(text: widget.recipe.difficulty!),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            children: [
              _FloatingActionButton(
                icon: widget.recipe.liked ? Icons.favorite : Icons.favorite_border,
                active: widget.recipe.liked,
                activeColor: Colors.red,
                onTap: () => context.read<RecipeController>().toggleLike(widget.recipe),
              ),
              const SizedBox(width: 8),
              _FloatingActionButton(
                icon: widget.recipe.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                active: widget.recipe.bookmarked,
                activeColor: Colors.blue,
                onTap: () async {
                  final bookmarked = await context.read<RecipeController>().toggleBookmark(widget.recipe);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(bookmarked ? '레시피가 저장되었습니다' : '저장이 취소되었습니다'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    if (bookmarked) {
                      context.read<AppController>().setTab(3);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.recipe.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.recipe.description != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.recipe.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          _buildMetadata(context, scheme),
          if (widget.recipe.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTags(scheme),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecipeDetailView(recipe: widget.recipe)),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('요리 시작하기', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, ColorScheme scheme) {
    return Row(
      children: [
        _MetadataChip(
          icon: Icons.schedule_rounded,
          label: '${widget.recipe.durationMinutes}분',
          scheme: scheme,
        ),
        if (widget.recipe.servings != null) ...[
          const SizedBox(width: 12),
          _MetadataChip(
            icon: Icons.people_alt_rounded,
            label: '${widget.recipe.servings}인분',
            scheme: scheme,
          ),
        ],
        if (widget.recipe.rating != null) ...[
          const SizedBox(width: 12),
          _MetadataChip(
            icon: Icons.star_rounded,
            label: widget.recipe.rating!.toStringAsFixed(1),
            scheme: scheme,
            iconColor: Colors.amber,
          ),
        ],
      ],
    );
  }

  Widget _buildTags(ColorScheme scheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...widget.recipe.tags.take(3).map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSecondaryContainer,
            ),
          ),
        )),
        if (widget.recipe.tags.length > 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '+${widget.recipe.tags.length - 3}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _FloatingActionButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Material(
      color: active 
          ? activeColor.withOpacity(0.2)
          : scheme.surface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: active ? activeColor : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final Color? iconColor;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.scheme,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _difficultyColors(context, text);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_difficultyIcon(text), size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

(Color, Color) _difficultyColors(BuildContext context, String text) {
  if (text.contains('쉬움') || text.toLowerCase().contains('easy')) {
    return (const Color(0xFFDCFCE7), const Color(0xFF166534));
  }
  if (text.contains('보통') || text.toLowerCase().contains('medium')) {
    return (const Color(0xFFFEF3C7), const Color(0xFF92400E));
  }
  if (text.contains('어려움') || text.toLowerCase().contains('hard')) {
    return (const Color(0xFFFEE2E2), const Color(0xFF991B1B));
  }
  return (const Color(0xFFE5E7EB), const Color(0xFF374151));
}

IconData _difficultyIcon(String text) {
  if (text.contains('쉬움') || text.toLowerCase().contains('easy')) {
    return Icons.check_circle_rounded;
  }
  if (text.contains('보통') || text.toLowerCase().contains('medium')) {
    return Icons.tune_rounded;
  }
  if (text.contains('어려움') || text.toLowerCase().contains('hard')) {
    return Icons.whatshot_rounded;
  }
  return Icons.circle_outlined;
}
