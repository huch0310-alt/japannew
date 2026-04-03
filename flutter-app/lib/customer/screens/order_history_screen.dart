import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'id': 'ORD-20260403-001', 'status': 'pending', 'total': 45600, 'date': '04/03 10:23'},
      {'id': 'ORD-20260402-001', 'status': 'confirmed', 'total': 123400, 'date': '04/02 09:45'},
      {'id': 'ORD-20260401-001', 'status': 'completed', 'total': 78900, 'date': '04/01 14:30'},
    ];

    final statusLabels = {
      'pending': {'label': '未確認', 'color': Colors.blue},
      'confirmed': {'label': '確認済', 'color': Colors.orange},
      'completed': {'label': '完了', 'color': Colors.green},
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final status = statusLabels[order['status']]!;

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
                        color: status['color']!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(status['label'] as String, style: TextStyle(color: status['color'], fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['date'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('¥${NumberFormat('#,###').format(order['total'] as int)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F4C81))),
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
