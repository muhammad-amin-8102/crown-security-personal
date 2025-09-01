import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/site_profile_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/spend_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/password_reset_sent_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/shift_report_screen.dart';
import 'screens/night_round_screen.dart';
import 'screens/training_report_screen.dart';
import 'screens/salary_disbursement_screen.dart';
import 'screens/complaints_screen.dart';
import 'screens/rating_nps_screen.dart';
import 'screens/bills_soa_screen.dart';
import 'admin/admin_layout.dart';
import 'core/api.dart';

void main() {
  runApp(const CrownSecurityApp());
}

class CrownSecurityApp extends StatelessWidget {
  const CrownSecurityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crown Security',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFFCFAE02),
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFFCFAE02),
          onPrimary: Colors.white,
          secondary: Color(0xFFCFAE02),
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
          background: Colors.white,
          onBackground: Colors.black87,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFCFAE02),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCFAE02),
            foregroundColor: Colors.white,
          ),
        ),
      ),
  home: const LaunchGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
  '/main': (context) => const MainNav(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/password-reset-sent': (context) => const PasswordResetSentScreen(),
        // For reset password, pass token via settings.arguments
        '/reset-password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return ResetPasswordScreen(token: args);
          }
          return const Scaffold(body: Center(child: Text('Invalid token')));
        },
        '/dashboard': (context) => const DashboardScreen(),
        '/site-profile': (context) => const SiteProfileScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/spend': (context) => const SpendScreen(),
        '/shift-report': (context) => const ShiftReportScreen(),
        '/night-round': (context) => const NightRoundScreen(),
        '/training-report': (context) => const TrainingReportScreen(),
        '/salary-disbursement': (context) => const SalaryDisbursementScreen(),
        '/complaints': (context) => const ComplaintsScreen(),
        '/rating-nps': (context) => const RatingNpsScreen(),
        '/bills-soa': (context) => const BillsSoaScreen(),
  '/admin': (context) => const AdminLayout(),
      },
    );
  }
}

class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final token = await Api.storage.read(key: 'access_token');
    if (!mounted) return;
    if (token == null) {
      setState(() { _child = const LoginScreen(); });
      return;
    }
    final role = await Api.storage.read(key: 'role');
    final isAdmin = role == 'ADMIN' || role == 'OFFICER' || role == 'FINANCE' || role == 'CRO';
    setState(() { _child = isAdmin ? const AdminLayout() : const MainNav(); });
  }

  @override
  Widget build(BuildContext context) {
    return _child ?? const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await Api.storage.read(key: 'role');
    setState(() {
      _isAdmin = role == 'ADMIN' || role == 'OFFICER' || role == 'FINANCE' || role == 'CRO';
    });
    // If admin-type role, immediately send to admin dashboard and keep client shell hidden
    if (mounted && _isAdmin) {
      // replace so there's no back to client shell
      Navigator.of(context).pushReplacementNamed('/admin');
    }
  }
  static final List<Widget> _screens = [
    DashboardScreen(),
    SiteProfileScreen(),
    AttendanceScreen(),
    SpendScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // For admin roles, show an empty container; navigation is redirected to /admin above
    if (_isAdmin) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
  selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Site Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Spend',
          ),
        ],
      ),
  drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Crown Security')),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Shift-wise Report'),
              onTap: () {
                Navigator.pushNamed(context, '/shift-report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('Night Round Report'),
              onTap: () {
                Navigator.pushNamed(context, '/night-round');
              },
            ),
            ListTile(
              leading: const Icon(Icons.model_training),
              title: const Text('Training Report'),
              onTap: () {
                Navigator.pushNamed(context, '/training-report');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Salary Disbursement'),
              onTap: () {
                Navigator.pushNamed(context, '/salary-disbursement');
              },
            ),
            ListTile(
              leading: const Icon(Icons.comment),
              title: const Text('Complaints & Suggestions'),
              onTap: () {
                Navigator.pushNamed(context, '/complaints');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Rating & NPS'),
              onTap: () {
                Navigator.pushNamed(context, '/rating-nps');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Outstanding Bills (SOA)'),
              onTap: () {
                Navigator.pushNamed(context, '/bills-soa');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
