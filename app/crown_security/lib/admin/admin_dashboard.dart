import 'package:flutter/material.dart';
import '../core/api.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      // Load various statistics from different endpoints
      final responses = await Future.wait([
        Api.dio.get('/users'),
        Api.dio.get('/sites'),
        Api.dio.get('/guards'),
        Api.dio.get('/attendance'),
        Api.dio.get('/shifts'),
        Api.dio.get('/night-rounds'),
        Api.dio.get('/training'),
        Api.dio.get('/payroll'),
        Api.dio.get('/complaints'),
        Api.dio.get('/bills'),
      ]);

      setState(() {
        _stats = {
          'users': (responses[0].data as List).length,
          'sites': (responses[1].data as List).length,
          'guards': (responses[2].data as List).length,
          'attendance': (responses[3].data as List).length,
          'shifts': (responses[4].data as List).length,
          'nightRounds': (responses[5].data as List).length,
          'training': (responses[6].data as List).length,
          'payroll': (responses[7].data as List).length,
          'complaints': (responses[8].data as List).length,
          'bills': (responses[9].data as List).length,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _stats ?? {};

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to Crown Security Admin Panel',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Statistics Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : 
                             MediaQuery.of(context).size.width > 900 ? 4 :
                             MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildStatCard(
                  'Users',
                  stats['users']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Sites',
                  stats['sites']?.toString() ?? '0',
                  Icons.business,
                  Colors.green,
                ),
                _buildStatCard(
                  'Guards',
                  stats['guards']?.toString() ?? '0',
                  Icons.security,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Attendance',
                  stats['attendance']?.toString() ?? '0',
                  Icons.access_time,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Shifts',
                  stats['shifts']?.toString() ?? '0',
                  Icons.schedule,
                  Colors.teal,
                ),
                _buildStatCard(
                  'Night Rounds',
                  stats['nightRounds']?.toString() ?? '0',
                  Icons.nightlight_round,
                  Colors.indigo,
                ),
                _buildStatCard(
                  'Training',
                  stats['training']?.toString() ?? '0',
                  Icons.school,
                  Colors.brown,
                ),
                _buildStatCard(
                  'Payroll',
                  stats['payroll']?.toString() ?? '0',
                  Icons.payment,
                  Colors.red,
                ),
                _buildStatCard(
                  'Complaints',
                  stats['complaints']?.toString() ?? '0',
                  Icons.feedback,
                  Colors.pink,
                ),
                _buildStatCard(
                  'Bills/SOA',
                  stats['bills']?.toString() ?? '0',
                  Icons.receipt,
                  const Color(0xFFCFAE02),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
