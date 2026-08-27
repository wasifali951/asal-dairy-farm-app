import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'signin_screen.dart';
import 'notification_preferences_screen.dart';
import 'contact_us_screen.dart';
import 'complaint_form_screen.dart';
import 'support_form_screen.dart';
import 'about_screen.dart';
import 'profile_screen.dart';
import 'admin_notification_panel.dart';
import 'notifications_screen.dart';
import 'admin_signin_screen.dart';
import 'pos/pos_screen.dart';
import '../config/app_config.dart';
import '../services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final OrderProvider _orderProvider;

  @override
  void initState() {
    super.initState();
    // Initialize FCM and fetch orders
    _orderProvider = Provider.of<OrderProvider>(context, listen: false);
    _orderProvider.initializeFCM();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _orderProvider.listenToOrders(
      customerId: authProvider.isAdmin() ? null : authProvider.currentUser?.id,
    );
  }

  @override
  void dispose() {
    _orderProvider.stopListeningToOrders();
    super.dispose();
  }

  List<Widget> _getScreens() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAdmin()) {
      return [
        const HomeScreen(),
        const OrdersScreen(),
        const CustomersScreen(),
      ];
    } else {
      return [
        const HomeScreen(),
        const CartScreen(),
        const OrdersScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems({
    required int cartItemCount,
    required int orderCount,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAdmin()) {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: _NavigationBadge(
            icon: Icons.receipt_long,
            count: orderCount,
          ),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Customers',
        ),
      ];
    } else {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: _NavigationBadge(
            icon: Icons.shopping_cart,
            count: cartItemCount,
          ),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final screens = _getScreens();
    final userId = authProvider.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🥛'),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asal Dairy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  authProvider.isAdmin()
                      ? '👨‍💼 Admin Dashboard'
                      : '👋 ${authProvider.currentUser?.name ?? "Customer"}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if (userId == null)
            const IconButton(
              tooltip: 'Notifications',
              icon: Icon(Icons.notifications),
              onPressed: null,
            )
          else
            StreamBuilder<int>(
              stream: NotificationService.getUnreadCount(userId),
              builder: (context, snapshot) {
                return IconButton(
                  tooltip: 'Notifications',
                  icon: _NavigationBadge(
                    icon: Icons.notifications,
                    count: snapshot.data ?? 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          if (!authProvider.isAdmin())
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    setState(() => _currentIndex = 1);
                  },
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _getNavItems(
          cartItemCount: cartProvider.itemCount,
          orderCount: orderProvider.orders.length,
        ),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class _NavigationBadge extends StatelessWidget {
  final IconData icon;
  final int count;

  const _NavigationBadge({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F8E9), Colors.white],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                ),
              ),
              accountName: Text(
                user?.name ?? 'User',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: user?.profileImageUrl != null
                    ? NetworkImage(user!.profileImageUrl!)
                    : null,
                child: user?.profileImageUrl == null
                    ? Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              otherAccountsPictures: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: authProvider.isAdmin() ? Colors.orange : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    authProvider.isAdmin()
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            _buildDrawerItem(
              context,
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            const Divider(),
            if (authProvider.isAdmin())
              _buildDrawerItem(
                context,
                icon: Icons.notifications_active,
                title: 'Send Notifications',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminNotificationPanel(),
                    ),
                  );
                },
                iconColor: Colors.orange,
              ),
            if (authProvider.isAdmin() && AppConfig.isOwnerApp)
              _buildDrawerItem(
                context,
                icon: Icons.point_of_sale,
                title: 'POS',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PosScreen(),
                    ),
                  );
                },
                iconColor: Colors.green,
              ),
            _buildDrawerItem(
              context,
              icon: Icons.notifications,
              title: 'Notification Inbox',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (!authProvider.isAdmin()) ...[
              _buildDrawerItem(
                context,
                icon: Icons.notifications,
                title: 'Notification Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationPreferencesScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              _buildDrawerItem(
                context,
                icon: Icons.contact_phone,
                title: 'Contact Us',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ContactUsScreen()),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.support_agent,
                title: 'Support',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SupportFormScreen()),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.report_problem,
                title: 'Submit Complaint',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ComplaintFormScreen()),
                  );
                },
              ),
              const Divider(),
              _buildDrawerItem(
                context,
                icon: Icons.info,
                title: 'About Asal Dairy',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AboutScreen()),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacyPolicy(context);
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.article,
                title: 'Terms & Conditions',
                onTap: () {
                  Navigator.pop(context);
                  _showTermsAndConditions(context);
                },
              ),
            ],
            const Divider(),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await authProvider.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppConfig.isOwnerApp
                          ? const AdminSignInScreen()
                          : const SignInScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.green),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Asal Dairy Privacy Policy\n\n'
            '1. Information Collection\n'
            'We collect information you provide directly, including name, email, phone, and location.\n\n'
            '2. Use of Information\n'
            'We use your information to process orders, deliver products, and improve our services.\n\n'
            '3. Data Security\n'
            'We implement security measures to protect your personal information.\n\n'
            '4. Sharing Information\n'
            'We do not sell your personal information to third parties.\n\n'
            'For full privacy policy, visit our website or contact us.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms & Conditions\n\n'
            '1. Service Usage\n'
            'By using Asal Dairy services, you agree to these terms.\n\n'
            '2. Orders\n'
            'All orders are subject to availability and confirmation.\n\n'
            '3. Payment\n'
            'Payment must be made upon delivery or via approved methods.\n\n'
            '4. Delivery\n'
            'Delivery times are estimates and may vary.\n\n'
            '5. Returns\n'
            'Products can be returned within 24 hours if unopened.\n\n'
            'For complete terms, contact our support team.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
