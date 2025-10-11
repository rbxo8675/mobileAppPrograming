import 'package:flutter/material.dart';
import 'model/product.dart';
import 'model/products_repository.dart';
import 'page/detail.dart';


class ViewWidget extends StatefulWidget {
  const ViewWidget({Key? key}) : super(key: key);

  @override
  _ViewWidgetState createState() => _ViewWidgetState();
}

class _ViewWidgetState extends State<ViewWidget> {
  final List<bool> _selectedView = [false, true];  // [ListView, GridView]

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 토글 버튼
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ToggleButtons(
            direction: Axis.horizontal,
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < _selectedView.length; i++) {
                  _selectedView[i] = i == index;
                }
              });
            },
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            selectedBorderColor: Colors.blue[700],
            selectedColor: Colors.white,
            fillColor: Colors.blue[200],
            color: Colors.blue[400],
            isSelected: _selectedView,
            children: const [
              Icon(Icons.list_rounded),
              Icon(Icons.grid_view),
            ],
          ),
        ),
        // 조건부 뷰 렌더링
        Expanded(
          child: _selectedView[0]
              ? _buildListView()   // ListView
              : _buildGridView(),  // GridView
        ),
      ],
    );
  }

  // GridView 빌더
  Widget _buildGridView() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 3,
      padding: const EdgeInsets.all(16.0),
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      childAspectRatio: 0.65,
      children: _buildGridCards(context),

    );
  }

  // ListView 빌더
  Widget _buildListView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: _buildListCards(context),
    );
  }

  // GridView용 카드들 (기존 로직)
  List<Card> _buildGridCards(BuildContext context) {
    List<Product> products = ProductsRepository.loadProducts(Category.all);

    if (products.isEmpty) {
      return const <Card>[];
    }

    final ThemeData theme = Theme.of(context);

    return products.map((product) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 18 / 12,
              child: Hero(
                tag: 'hotel-${product.id}',
                child: Image.asset(
                  product.assetName,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                  Row(
                    children: [
                      ...List.generate(
                        product.rating.floor(),
                        (index) => const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                      if (product.rating % 1 >= 0.5)
                        const Icon(
                          Icons.star_half,
                          size: 14,
                          color: Colors.amber,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text( // 호텔 이름
                    product.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 32,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text( // 호텔 위치
                            product.address,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(product: product),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 20),
                      ),
                      child: const Text('more'),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      );
    }).toList();
  }

 //리스트 카드
  List<Card> _buildListCards(BuildContext context) {
    List<Product> products = ProductsRepository.loadProducts(Category.all);

    if (products.isEmpty) {
      return const <Card>[];
    }

    final ThemeData theme = Theme.of(context);

    return products.map((product) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Hero(
                  tag: 'hotel-${product.id}',
                  child: Image.asset(
                    product.assetName,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          product.rating.floor(),
                          (index) => const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                        if (product.rating % 1 >= 0.5)
                          const Icon(
                            Icons.star_half,
                            size: 14,
                            color: Colors.amber,
                          ),


                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.address,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(product: product),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 20),
                        ),
                        child: const Text('more'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}