import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'services/supabase_service.dart';
import 'customer/screens/login_screen.dart';
import 'customer/screens/main_screen.dart';
import 'staff/screens/product_upload_screen.dart';
import 'staff/screens/my_products_screen.dart';
import 'staff/screens/order_management_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Supabase
  final supabase = SupabaseService();
  await supabase.initialize();

  runApp(const FreshBizApp());
}

class FreshBizApp extends StatelessWidget {
  const FreshBizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'FreshBiz',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ja'),
        supportedLocales: const [
          Locale('ja'),
          Locale('zh'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F4C81),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Noto Sans JP',
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/customer': (context) => const MainScreen(),
          '/staff/upload': (context) => const ProductUploadScreen(),
          '/staff/products': (context) => const MyProductsScreen(),
          '/staff/orders': (context) => const OrderManagementScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // 检查当前认证状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.user == null) {
      return const LoginScreen();
    }

    // 根据角色路由
    final role = authProvider.user!.userMetadata?['role'] as String? ?? 'customer';
    if (role == 'purchaser' || role == 'sales_manager') {
      return const StaffHome();
    }
    return const MainScreen();
  }
}

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _currentIndex = 0;

  final _screens = const [
    ProductUploadScreen(),
    MyProductsScreen(),
    OrderManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.upload_outlined),
            selectedIcon: Icon(Icons.upload),
            label: '上传',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '商品',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '订单',
          ),
        ],
      ),
    );
  }
}
