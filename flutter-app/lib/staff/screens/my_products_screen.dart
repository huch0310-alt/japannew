import 'package:flutter/material.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('私の商品'),
          backgroundColor: const Color(0xFF3ECF8E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: '審査中(2)'),
              Tab(text: '通過(15)'),
              Tab(text: '拒否(1)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProductList(status: 'pending'),
            _ProductList(status: 'approved'),
            _ProductList(status: 'rejected'),
          ],
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final String status;

  const _ProductList({required this.status});

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': '新鮮な白菜', 'price': 300, 'status': 'pending'},
      {'name': '的有机胡萝卜', 'price': 200, 'status': 'pending'},
    ].where((p) => p['status'] == status).toList();

    if (products.isEmpty) {
      return const Center(child: Text('商品がありません'));
    }

    return ListView.builder(
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
            title: Text(product['name'] as String),
            subtitle: Text('¥${(product['price'] as int).toString()}'),
            trailing: status == 'rejected'
                ? const Text('拒否理由', style: TextStyle(color: Colors.red, fontSize: 12))
                : status == 'pending'
                    ? const Icon(Icons.edit)
                    : null,
          ),
        );
      },
    );
  }
}
