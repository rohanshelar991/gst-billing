import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../theme/app_theme.dart';
import 'analytics_screen.dart';
import 'business_profile_screen.dart';
import 'calendar_due_screen.dart';
import 'calculator_screen.dart';
import 'clients_screen.dart';
import 'home_screen.dart';
import 'invoices_screen.dart';
import 'login_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = <String>[
    'Dashboard',
    'Clients',
    'Invoices',
    'Reminders',
    'Calculator',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final MessagingService? messagingService = context
          .read<MessagingService?>();
      final AnalyticsService? analyticsService = context
          .read<AnalyticsService?>();
      if (messagingService != null) {
        await messagingService.initialize();
      }
      if (analyticsService != null) {
        await analyticsService.logScreenView(_titles[_currentIndex]);
      }
    });
  }

  void _setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    context.read<AnalyticsService?>()?.logScreenView(_titles[index]);
  }

  void _pushScreen(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => screen,
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<Offset> offsetAnimation =
                  Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
      ),
    );
  }

  Widget _buildFab() {
    return const SizedBox.shrink();
  }

  Widget _currentTab() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(onQuickActionTabSelected: _setTab);
      case 1:
        return const ClientsScreen();
      case 2:
        return const InvoicesScreen();
      case 3:
        return const RemindersScreen();
      case 4:
        return const AdvancedCalculatorScreen();
      default:
        return HomeScreen(onQuickActionTabSelected: _setTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AuthService? authService = context.read<AuthService?>();
    final String userName =
        authService?.currentUser?.displayName ?? 'Smart Tax Manager';
    final String userEmail =
        authService?.currentUser?.email ?? 'user@smarttax.app';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _pushScreen(const ProfileScreen()),
            icon: const Icon(Icons.person_outline),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: blueGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.account_circle,
                      size: 38,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                _setTab(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _pushScreen(const ProfileScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.business_center_outlined),
              title: const Text('Business Profile'),
              onTap: () {
                Navigator.pop(context);
                _pushScreen(const BusinessProfileScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Calendar & Due'),
              onTap: () {
                Navigator.pop(context);
                _pushScreen(const CalendarDueScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Products'),
              onTap: () {
                Navigator.pop(context);
                _pushScreen(const ProductsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Mini Analytics'),
              onTap: () {
                Navigator.pop(context);
                _pushScreen(const AnalyticsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.summarize_outlined),
              title: const Text('Reports & Export'),
              onTap: () {
                Navigator.pop(context);
                _pushScreen(const ReportsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _pushScreen(const SettingsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Help & Support'),
                      content: const Text(
                        'Email: support@smarttax.app\nPhone: +91 98765 43210',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                final AuthService? authService = context.read<AuthService?>();
                final AnalyticsService? analyticsService = context
                    .read<AnalyticsService?>();
                final NavigatorState navigator = Navigator.of(this.context);
                if (authService != null) {
                  await authService.logout();
                }
                if (analyticsService != null) {
                  await analyticsService.logEvent('logout');
                }
                if (!mounted) {
                  return;
                }
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const LoginScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _currentTab(),
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? darkCardGlass : Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _setTab,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                label: 'Clients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                label: 'Invoices',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_none),
                label: 'Reminders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calculate_outlined),
                label: 'Calculator',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
