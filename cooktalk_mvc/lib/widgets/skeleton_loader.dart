import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                scheme.surfaceContainerHighest,
                scheme.surfaceContainerHigh,
                scheme.surfaceContainerHighest,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkeletonLoader(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SkeletonLoader(width: 150, height: 14),
                const SizedBox(height: 4),
                const SkeletonLoader(width: 100, height: 10),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SkeletonLoader(width: 50, height: 8),
                    const SizedBox(width: 12),
                    const SkeletonLoader(width: 60, height: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeListSkeleton extends StatelessWidget {
  const RecipeListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SkeletonLoader(
              width: 80,
              height: 80,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: double.infinity, height: 18),
                  const SizedBox(height: 8),
                  const SkeletonLoader(width: 180, height: 14),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SkeletonLoader(width: 60, height: 12),
                      const SizedBox(width: 12),
                      const SkeletonLoader(width: 80, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  
  const SkeletonGrid({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 280,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const RecipeCardSkeleton(),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  
  const SkeletonList({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const RecipeListSkeleton(),
    );
  }
}
