import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Product> _pendingProducts = [];
  List<Product> _approvedProducts = [];
  List<Product> _rejectedProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final products = await context.read<ProductProvider>().getMyProducts(user.id);

    setState(() {
      _pendingProducts = products.where((p) => p.status == 'pending').toList();
      _approvedProducts = products.where((p) => p.status == 'approved').toList();
      _rejectedProducts = products.where((p) => p.status == 'rejected').toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('私の商品'),
        backgroundColor: const Color(0xFF3ECF8E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: '審査中(${_pendingProducts.length})'),
            Tab(text: '通過(${_approvedProducts.length})'),
            Tab(text: '拒否(${_rejectedProducts.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ProductList(products: _pendingProducts, status: 'pending', onRefresh: _loadProducts),
                _ProductList(products: _approvedProducts, status: 'approved', onRefresh: _loadProducts),
                _ProductList(products: _rejectedProducts, status: 'rejected', onRefresh: _loadProducts),
              ],
            ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Product> products;
  final String status;
  final Future<void> Function() onRefresh;

  const _ProductList({
    required this.products,
    required this.status,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('商品がありません'));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.eco, color: Color(0xFF3ECF8E), size: 28)),
              ),
              title: Text(product.nameJa),
              subtitle: Text('¥${NumberFormat('#,###').format(product.purchasePrice)}'),
              trailing: status == 'rejected'
                  ? Text(product.rejectReason ?? '拒否理由', style: const TextStyle(color: Colors.red, fontSize: 12))
                  : status == 'pending'
                      ? const Icon(Icons.edit)
                      : null,
            ),
          );
        },
      ),
    );
  }
}
