import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    await context.read<OrderProvider>().loadAllOrders();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('注文管理'),
        backgroundColor: const Color(0xFF0F4C81),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(text: '未確認(${orderProvider.pendingOrders.length})'),
            Tab(text: '確認済(${orderProvider.confirmedOrders.length})'),
            Tab(text: '印刷済(${orderProvider.printedOrders.length})'),
            Tab(text: '請求書済(${orderProvider.invoicedOrders.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _OrderList(orders: orderProvider.pendingOrders, status: 'pending', onRefresh: _loadOrders),
                _OrderList(orders: orderProvider.confirmedOrders, status: 'confirmed', onRefresh: _loadOrders),
                _OrderList(orders: orderProvider.printedOrders, status: 'printed', onRefresh: _loadOrders),
                _OrderList(orders: orderProvider.invoicedOrders, status: 'invoiced', onRefresh: _loadOrders),
              ],
            ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List orders;
  final String status;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.status,
    required this.onRefresh,
  });

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
    if (orders.isEmpty) {
      return const Center(child: Text('注文がありません'));
    }

    final statusLabel = _statusLabels[status] ?? '不明';
    final statusColor = _statusColors[status] ?? Colors.grey;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
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
                      Text(
                        order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (statusColor as Color).withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('注文日: ${DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt)}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${order.items.length}点', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 12),
                      Text('¥${NumberFormat('#,###').format(order.totalInTax)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (status == 'pending')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(context, order.id, 'confirmed'),
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
                      if (status == 'pending') const SizedBox(width: 8),
                      if (status == 'confirmed')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(context, order.id, 'printed'),
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
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String orderId, String newStatus) async {
    final success = await context.read<OrderProvider>().updateOrderStatus(orderId, newStatus);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '更新しました' : '更新に失敗しました'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
