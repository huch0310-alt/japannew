// flutter-app/lib/customer/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/customer.dart';
import '../../models/invoice.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabaseService = SupabaseService();

  Customer? _customer;
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _supabaseService.currentUser;
      if (user == null) {
        setState(() {
          _error = '未登录';
          _isLoading = false;
        });
        return;
      }

      final customer = await _supabaseService.getCustomer(user.id);
      final invoices = await _supabaseService.getCustomerInvoices(user.id);

      setState(() {
        _customer = customer;
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的')),
        body: Center(child: Text('错误: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 个人信息卡片
            _buildInfoCard(),
            const SizedBox(height: 16),

            // 修改密码
            _buildMenuCard(
              icon: Icons.lock,
              title: '修改密码',
              onTap: () => _showChangePasswordDialog(),
            ),
            const SizedBox(height: 16),

            // 我的请求书
            _buildInvoicesCard(),
            const SizedBox(height: 16),

            // 联系客服
            _buildMenuCard(
              icon: Icons.support_agent,
              title: '联系客服',
              onTap: () => _showContactDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF0F4C81),
                  child: Text(
                    _customer?.companyName.isNotEmpty == true
                        ? _customer!.companyName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customer?.companyName ?? '未知公司',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_customer?.contactName != null)
                        Text(
                          _customer!.contactName!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('公司名称', _customer?.companyName ?? '-'),
            _buildInfoRow('税号', _customer?.taxId ?? '-'),
            _buildInfoRow('地址', _customer?.address ?? '-'),
            _buildInfoRow('电话', _customer?.phone ?? '-'),
            _buildInfoRow('折扣率', '${_customer?.discountRate ?? 0}%'),
            _buildInfoRow('付款期限', '${_customer?.paymentTermDays ?? 30}天'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0F4C81)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInvoicesCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Color(0xFF0F4C81)),
            title: const Text('我的请求书'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showInvoicesSheet(),
          ),
          if (_invoices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildInvoiceSummary('未払い', _invoices.where((i) => i.status == 'unpaid').length, Colors.orange),
                  const SizedBox(width: 12),
                  _buildInvoiceSummary('期限切れ', _invoices.where((i) => i.status == 'overdue').length, Colors.red),
                  const SizedBox(width: 12),
                  _buildInvoiceSummary('済み', _invoices.where((i) => i.status == 'paid').length, Colors.green),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSummary(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showInvoicesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text('请求书列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: _invoices.isEmpty
                  ? const Center(child: Text('暂无请求书'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _invoices[index];
                        return ListTile(
                          title: Text(invoice.invoiceNumber),
                          subtitle: Text(
                            '${invoice.issueDate.toIso8601String().split('T').first} ~ ${invoice.dueDate.toIso8601String().split('T').first}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(invoice.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              invoice.statusLabel,
                              style: TextStyle(color: _getStatusColor(invoice.status)),
                            ),
                          ),
                          onTap: () {},
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'unpaid':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '新密码'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '确认密码'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (passwordController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的密码不一致')),
                );
                return;
              }
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密码长度至少6位')),
                );
                return;
              }
              try {
                await _supabaseService.updatePassword(passwordController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码修改成功')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('修改失败: $e')),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('联系客服'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FreshBiz株式会社'),
            SizedBox(height: 8),
            Text('电话: 06-1234-5678'),
            SizedBox(height: 8),
            Text('邮箱: support@freshbiz.jp'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
