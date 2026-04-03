import 'package:flutter/material.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('注文管理'),
          backgroundColor: const Color(0xFF0F4C81),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(text: '未確認(3)'),
              Tab(text: '確認済(12)'),
              Tab(text: '印刷済(8)'),
              Tab(text: '請求書済(5)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(status: 'pending'),
            _OrderList(status: 'confirmed'),
            _OrderList(status: 'printed'),
            _OrderList(status: 'invoiced'),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final String status;

  const _OrderList({required this.status});

  static const Map<String, String> _statusLabels = {
    'pending': '未確認',
    'confirmed': '確認済',
    'printed': '印刷済',
    'invoiced': '請求書済',
  };

  static const Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'printed': Colors.green,
    'invoiced': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'id': 'ORD-20260403-001', 'customer': 'ABC株式会社', 'total': 45600, 'items': 5, 'time': '10:23'},
      {'id': 'ORD-20260403-002', 'customer': 'XYZ商事', 'total': 123400, 'items': 12, 'time': '09:45'},
    ];

    final statusLabel = _statusLabels[status] ?? '不明';
    final statusColor = _statusColors[status] ?? Colors.grey;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(order['customer'] as String, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${order['items']}点', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 12),
                    Text('¥${NumberFormat('#,###').format(order['total'])}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                Text('注文時間: ${order['time']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 16),
                            SizedBox(width: 4),
                            Text('確認'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F4C81),
                          side: const BorderSide(color: Color(0xFF0F4C81)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print, size: 16),
                            SizedBox(width: 4),
                            Text('印刷'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
