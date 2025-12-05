import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'm3_recipe_card.dart';

class AnimatedRecipeCard extends StatefulWidget {
  final Recipe recipe;
  final int index;

  const AnimatedRecipeCard({
    super.key,
    required this.recipe,
    this.index = 0,
  });

  @override
  State<AnimatedRecipeCard> createState() => _AnimatedRecipeCardState();
}

class _AnimatedRecipeCardState extends State<AnimatedRecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: M3RecipeCard(recipe: widget.recipe),
      ),
    );
  }
}
