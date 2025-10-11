import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../model/product.dart';
import '../model/favorite_manager.dart';

class DetailPage extends StatefulWidget {
  //object(객체) 방식으로 전달하기
  const DetailPage({Key? key, required this.product}) : super(key: key);
  
  final Product product;


  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final FavoriteManager _favoriteManager = FavoriteManager();

  @override
  void initState() {
    super.initState();
    _favoriteManager.addListener(_onFavoriteChanged);
  }

  @override
  void dispose() {
    _favoriteManager.removeListener(_onFavoriteChanged);
    super.dispose();
  }

  void _onFavoriteChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = _favoriteManager.isFavorite(widget.product.id);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          Stack(
            children: [
              InkWell(
                onDoubleTap: () {
                  _favoriteManager.toggleFavorite(widget.product.id);
                },
                child: Hero(
                  tag: 'hotel-${widget.product.id}',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(
                      widget.product.assetName,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    _favoriteManager.toggleFavorite(widget.product.id);
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      widget.product.rating.floor(),
                          (index) => const Icon(
                        Icons.star,
                        size: 20,
                        color: Colors.amber,
                      ),
                    ),
                    if (widget.product.rating % 1 >= 0.5)
                      const Icon(
                        Icons.star_half,
                        size: 20,
                        color: Colors.amber,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      widget.product.name,
                      textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),



                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.product.address,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.product.phone,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                Text(
                  widget.product.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
