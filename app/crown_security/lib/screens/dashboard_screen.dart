import 'package:flutter/material.dart';
import '../core/api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String? _siteId;

  @override
  void initState() {
    super.initState();
    _loadUserSiteAndDashboard();
  }

  Future<void> _loadUserSiteAndDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Get user id from secure storage (set on login)
    final userId = await Api.storage.read(key: 'user_id');
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'User not logged in.';
      });
      return;
    }
    // Fetch sites for this user
    try {
      final response = await Api.dio.get(
        '/sites',
        queryParameters: {'client_id': userId},
      );
      final sites = response.data as List?;
      if (sites == null || sites.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No site assigned to your account.';
        });
        return;
      }
      _siteId = sites.first['id'];
      // Store siteId for other screens to use
      await Api.storage.write(key: 'site_id', value: _siteId);
      await _loadDashboard(_siteId!);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load sites.';
      });
    }
  }

  Future<void> _loadDashboard(String siteId) async {
    final from = '2025-08-01';
    final to = '2025-08-31';
    final data = await Api.fetchDashboard(siteId, from, to);
    setState(() {
      _data = data;
      _loading = false;
      if (data == null) _error = 'Failed to load dashboard';
      if (data != null && data['error'] == 'no_site_assigned') {
        _error = data['message'] ?? 'No site assigned to your account.';
        _data = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final navigator = Navigator.of(context);
              await Api.storage.delete(key: 'access_token');
              await Api.storage.delete(key: 'refresh_token');
              await Api.storage.delete(key: 'user_id');
              if (!mounted) return;
              navigator.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _data == null
                  ? const Center(child: Text('No data'))
                  : RefreshIndicator(
                      onRefresh: () async {
                        if (_siteId != null) {
                          await _loadDashboard(_siteId!);
                        }
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Site Info Header
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.location_city, color: Theme.of(context).primaryColor, size: 40),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _data!['site']?['name'] ?? 'Site Name',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _data!['site']?['location'] ?? 'Location not available',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/site-profile');
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Metrics Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _buildMetricCard(
                                context,
                                title: 'Shift-wise Count',
                                value: _data!['latestShiftReport']?['shiftWiseCount']?.toString() ?? 'N/A',
                                icon: Icons.people_alt,
                                color: Colors.blue,
                                onTap: () => Navigator.pushNamed(context, '/shift-report'),
                              ),
                              _buildMetricCard(
                                context,
                                title: 'Attendance',
                                value: (() {
                                  final att = _data!['tillDateAttendance'];
                                  if (att is Map) {
                                    final present = att['PRESENT'] ?? att['present'] ?? att['Present'];
                                    return (present ?? 'N/A').toString();
                                  }
                                  return att?.toString() ?? 'N/A';
                                })(),
                                icon: Icons.check_circle_outline,
                                color: Colors.green,
                                onTap: () => Navigator.pushNamed(context, '/attendance'),
                              ),
                              _buildMetricCard(
                                context,
                                title: 'Spend',
                                value: (() {
                                  final s = _data!['tillDateSpend'];
                                  return '₹${s ?? 0}';
                                })(),
                                icon: Icons.monetization_on,
                                color: Colors.orange,
                                onTap: () => Navigator.pushNamed(context, '/spend'),
                              ),
                              _buildMetricCard(
                                context,
                                title: 'Outstanding Bills',
                                value: (() {
                                  final soa = _data!['soa'];
                                  if (soa is Map) {
                                    final items = soa['items'];
                                    if (items is List) return items.length.toString();
                                  }
                                  if (soa is List) return soa.length.toString();
                                  return '0';
                                })(),
                                icon: Icons.receipt_long,
                                color: Colors.red,
                                onTap: () => Navigator.pushNamed(context, '/bills-soa'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Detailed List
                          _buildDetailListItem(
                            context,
                            title: 'Latest Night Round',
                            subtitle: _data!['latestNightRound']?['findings'] ?? 'No report',
                            icon: Icons.nightlight_round,
                            onTap: () => Navigator.pushNamed(context, '/night-round'),
                          ),
                          _buildDetailListItem(
                            context,
                            title: 'Latest Training',
                            subtitle: (() {
                              final lt = _data!['latestTraining'];
                              if (lt == null) return 'No report';
                              // Prefer numeric count if provided
                              final topicsCovered = lt['topicsCovered'];
                              if (topicsCovered != null) return 'Topics: ${topicsCovered.toString()}';
                              // Fall back to topics_covered string or topics
                              return (lt['topics_covered']?.toString() ?? lt['topics']?.toString() ?? 'No report');
                            })(),
                            icon: Icons.model_training,
                            onTap: () => Navigator.pushNamed(context, '/training-report'),
                          ),
                          _buildDetailListItem(
                            context,
                            title: 'Salary Disbursement',
                            subtitle: (() {
                              final pr = _data!['payroll'];
                              if (pr is Map) {
                                return 'Status: ${pr['status'] ?? 'N/A'}';
                              }
                              return 'No data available';
                            })(),
                            icon: Icons.payment,
                            onTap: () => Navigator.pushNamed(context, '/salary-disbursement'),
                          ),
                          _buildDetailListItem(
                            context,
                            title: 'Complaints & Suggestions',
                            subtitle: '${_data!['complaints']?.length ?? 0} open issues',
                            icon: Icons.comment,
                            onTap: () => Navigator.pushNamed(context, '/complaints'),
                          ),
                          _buildDetailListItem(
                            context,
                            title: 'Ratings & NPS',
                            subtitle: 'NPS: ${_data!['latestRating']?['npsScore']?.toString() ?? 'N/A'}',
                            icon: Icons.star,
                            onTap: () => Navigator.pushNamed(context, '/rating-nps'),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailListItem(BuildContext context, {required String title, required String subtitle, required IconData icon, VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
