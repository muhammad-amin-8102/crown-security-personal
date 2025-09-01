import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_dashboard.dart';
import 'modules/users_admin.dart';
import 'modules/sites_admin.dart';
import 'modules/guards_admin.dart';
import 'modules/attendance_admin.dart';
import 'modules/shifts_admin.dart';
import 'modules/spend_admin.dart';
import 'modules/night_rounds_admin.dart';
import 'modules/training_admin.dart';
import 'modules/payroll_admin.dart';
import 'modules/complaints_admin.dart';
import 'modules/ratings_admin.dart';
import 'modules/bills_admin.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;

  final List<AdminMenuItem> _menuItems = [
    AdminMenuItem(
      icon: Icons.dashboard,
      title: 'Dashboard',
      widget: const AdminDashboard(),
    ),
    AdminMenuItem(
      icon: Icons.people,
      title: 'Users',
      widget: const UsersAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.business,
      title: 'Sites',
      widget: const SitesAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.security,
      title: 'Guards',
      widget: const GuardsAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.access_time,
      title: 'Attendance',
      widget: const AttendanceAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.schedule,
      title: 'Shifts',
      widget: const ShiftsAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.monetization_on,
      title: 'Spend',
      widget: const SpendAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.nightlight_round,
      title: 'Night Rounds',
      widget: const NightRoundsAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.school,
      title: 'Training',
      widget: const TrainingAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.payment,
      title: 'Payroll',
      widget: const PayrollAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.feedback,
      title: 'Complaints',
      widget: const ComplaintsAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.star,
      title: 'Ratings',
      widget: const RatingsAdmin(),
    ),
    AdminMenuItem(
      icon: Icons.receipt,
      title: 'Bills/SOA',
      widget: const BillsAdmin(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 768;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isCollapsed ? 70 : (isWideScreen ? 280 : 250),
            child: _buildSidebar(),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _menuItems[_selectedIndex].widget,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.security,
                  color: Color(0xFFCFAE02),
                  size: 32,
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'Crown Security',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = index == _selectedIndex;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFCFAE02).withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFFCFAE02),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected 
                                  ? const Color(0xFFCFAE02)
                                  : Colors.white70,
                              size: 20,
                            ),
                            if (!_isCollapsed) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isSelected 
                                        ? const Color(0xFFCFAE02)
                                        : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: isSelected 
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Collapse Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isCollapsed = !_isCollapsed;
                });
              },
              child: Row(
                mainAxisAlignment: _isCollapsed 
                    ? MainAxisAlignment.center 
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white70,
                  ),
                  if (!_isCollapsed) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Collapse',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _menuItems[_selectedIndex].title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          // User Menu
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings, size: 20),
                  SizedBox(width: 8),
                  Text('Admin'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await Api.storage.deleteAll();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class AdminMenuItem {
  final IconData icon;
  final String title;
  final Widget widget;

  AdminMenuItem({
    required this.icon,
    required this.title,
    required this.widget,
  });
}
