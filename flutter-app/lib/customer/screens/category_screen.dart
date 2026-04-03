import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    if (categoryId != null) {
      context.read<ProductProvider>().loadProductsByCategory(categoryId);
    } else {
      context.read<ProductProvider>().loadProducts();
    }
  }

  void _addToCart(Product product) {
    context.read<CartProvider>().addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.nameJa}をカートに追加しました'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('分類'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Left category navigation
          Container(
            width: 100,
            color: Colors.grey[100],
            child: ListView(
              children: [
                ListTile(
                  title: const Text('すべて'),
                  selected: _selectedCategoryId == null,
                  selectedColor: const Color(0xFF0F4C81),
                  onTap: () => _onCategorySelected(null),
                ),
                ...categories.map((cat) {
                  return ListTile(
                    title: Text(cat.nameJa, style: const TextStyle(fontSize: 14)),
                    selected: _selectedCategoryId == cat.id,
                    selectedColor: const Color(0xFF0F4C81),
                    onTap: () => _onCategorySelected(cat.id),
                  );
                }),
              ],
            ),
          ),
          // Right product grid
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.products.isEmpty
                    ? const Center(child: Text('商品がありません'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: productProvider.products.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.products[index];
                          return _ProductGridItem(product: product, onAddToCart: _addToCart);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final Product product;
  final Function(Product) onAddToCart;

  const _ProductGridItem({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: product.images?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        product.images!.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                      ),
                    )
                  : const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.nameJa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 2),
                Text(product.unit, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¥${NumberFormat('#,###').format(product.salePriceInTax)}',
                      style: const TextStyle(color: Color(0xFF0F4C81), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () => onAddToCart(product),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4C81),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
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
