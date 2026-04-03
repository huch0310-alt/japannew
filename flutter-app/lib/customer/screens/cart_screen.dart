import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _CartItem(
                name: 'ほうれん草',
                unit: '束',
                price: 180,
                quantity: 2,
              ),
              _CartItem(
                name: '和牛カルビ',
                unit: '100g',
                price: 850,
                quantity: 3,
              ),
            ],
          ),
        ),
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
                  const Text('5点'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('税抜合計', style: TextStyle(color: Colors.grey)),
                  const Text('¥2,650'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('消費税(8%)', style: TextStyle(color: Colors.grey)),
                  const Text('¥212'),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('合計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('¥2,862', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F4C81))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('注文を確定する', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItem extends StatelessWidget {
  final String name;
  final String unit;
  final int price;
  final int quantity;

  const _CartItem({
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$unit • ¥${NumberFormat('#,###').format(price)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                  onTap: () => print('Decrease quantity'),
                  child: Center(child: Text('-', style: TextStyle(fontSize: 16))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: GestureDetector(
                  onTap: () => print('Increase quantity'),
                  child: Center(child: Text('+', style: TextStyle(fontSize: 16))),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text('¥${NumberFormat('#,###').format(price * quantity)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81))),
        ],
      ),
    );
  }
}
