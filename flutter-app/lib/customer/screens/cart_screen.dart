import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    return Column(
      children: [
        Expanded(
          child: cartProvider.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('カートは空です', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return _CartItem(
                      item: item,
                      onQuantityChanged: (qty) {
                        cartProvider.updateQuantity(item.productId, qty);
                      },
                      onRemove: () {
                        cartProvider.removeItem(item.productId);
                      },
                    );
                  },
                ),
        ),
        if (!cartProvider.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.2 * 255).round()),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('商品数', style: TextStyle(color: Colors.grey)),
                    Text('${cartProvider.itemCount}点'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('税抜合計', style: TextStyle(color: Colors.grey)),
                    Text('¥${NumberFormat('#,###').format(cartProvider.totalExTax)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('消費税(8%)', style: TextStyle(color: Colors.grey)),
                    Text('¥${NumberFormat('#,###').format(cartProvider.taxAmount)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('合計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      '¥${NumberFormat('#,###').format(cartProvider.totalInTax)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F4C81)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cartProvider.isLoading
                        ? null
                        : () => _submitOrder(context, cartProvider, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: cartProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('注文を確定する', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _submitOrder(BuildContext context, CartProvider cartProvider, AuthProvider authProvider) async {
    final user = authProvider.user;
    if (user == null) return;

    final success = await cartProvider.submitOrder(user.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('注文を確定しました'),
          backgroundColor: Colors.green,
        ),
      );
      // 刷新订单列表
      context.read<OrderProvider>().loadCustomerOrders(user.id);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProvider.error ?? '注文の確定に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _CartItem extends StatelessWidget {
  final dynamic item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItem({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('🥬', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${item.unit} • ¥${NumberFormat('#,###').format(item.unitPriceExTax)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: GestureDetector(
                  onTap: () => onQuantityChanged(item.quantity - 1),
                  child: const Center(child: Text('-', style: TextStyle(fontSize: 16))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: GestureDetector(
                  onTap: () => onQuantityChanged(item.quantity + 1),
                  child: const Center(child: Text('+', style: TextStyle(fontSize: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text(
            '¥${NumberFormat('#,###').format(item.lineTotalInTax)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
