import 'package:flutter/material.dart';
import '../core/api.dart';
import 'admin_common.dart';
import 'attendance_admin_screen.dart';
import 'shifts_admin_screen.dart';
import 'spend_admin_screen.dart';
import 'night_round_admin_screen.dart';
import 'training_admin_screen.dart';
import 'payroll_admin_screen.dart';
import 'bills_admin_screen.dart';
import 'complaints_admin_screen.dart';
import 'ratings_admin_screen.dart';
import 'sites_admin_screen.dart';

class AdminSection extends StatefulWidget {
  const AdminSection({super.key});

  @override
  State<AdminSection> createState() => _AdminSectionState();
}

class _AdminSectionState extends State<AdminSection> {
  List<dynamic> _sites = const [];
  String? _selectedSiteId;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Fallback to sites list without client filter for admins
      final res = await Api.dio.get('/sites');
      final sites = (res.data as List?) ?? const [];
      _sites = sites;
      if (_sites.isNotEmpty) {
        _selectedSiteId = _sites.first['id'];
        await _loadSummary();
      }
      setState(() { _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = 'Failed to load admin data'; });
    }
  }

  Future<void> _loadSummary() async {
    if (_selectedSiteId == null) return;
    try {
      final to = DateTime.now();
      final from = DateTime(to.year, to.month, 1);
      final resp = await Api.dio.get('/reports/summary', queryParameters: {
        'siteId': _selectedSiteId,
        'from': from.toIso8601String().substring(0,10),
        'to': to.toIso8601String().substring(0,10),
      });
      setState(() { _summary = Map<String, dynamic>.from(resp.data as Map); });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false, // no back button from admin landing
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              // Clear session
              await Api.storage.delete(key: 'access_token');
              await Api.storage.delete(key: 'refresh_token');
              await Api.storage.delete(key: 'user_id');
              await Api.storage.delete(key: 'role');
              await Api.storage.delete(key: 'site_id');
              await Api.storage.delete(key: 'user_profile');
              if (!mounted) return;
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: () async { await _init(); },
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                        children: [
                          const Text('Site:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSiteId,
                              items: _sites.map((s) => DropdownMenuItem<String>(value: s['id'], child: Text(s['name'] ?? 'Unnamed'))).toList(),
                              onChanged: (v) async { setState(() { _selectedSiteId = v; }); await _loadSummary(); },
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                          ),
                          const SizedBox(height: 16),
                          if (_summary != null) _AdminMetrics(summary: _summary!),
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('Manage Modules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                      _AdminTile(
                        title: 'Shifts',
                        bulkUrl: '/shifts/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftsAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Attendance',
                        bulkUrl: '/attendance/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Spend',
                        bulkUrl: '/spend/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpendAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Night Rounds',
                        bulkUrl: '/night-rounds/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NightRoundAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Training Reports',
                        bulkUrl: '/training/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Salary Disbursement',
                        bulkUrl: '/payroll/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Complaints',
                        bulkUrl: '/complaints/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintsAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Ratings',
                        bulkUrl: '/ratings/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RatingsAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Bills (SOA)',
                        bulkUrl: '/billing/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsAdminScreen())),
                      ),
                          _AdminTile(
                        title: 'Sites',
                        bulkUrl: '/sites/bulk',
                        onOpen: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SitesAdminScreen())),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _AdminMetrics extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _AdminMetrics({required this.summary});

  @override
  Widget build(BuildContext context) {
    final shiftCount = summary['shiftWiseCount'] is Map ? (summary['shiftWiseCount'] as Map).length.toString() : '0';
    final attendance = (() {
      final att = summary['tillDateAttendance'];
      if (att is Map) {
        final present = att['PRESENT'] ?? att['present'] ?? att['Present'];
        return (present ?? 0).toString();
      }
      return '0';
    })();
    final spend = summary['tillDateSpend']?.toString() ?? '0';
    final bills = (() {
      final ob = summary['outstandingBills'];
      if (ob is List) return ob.length.toString();
      return '0';
    })();

  return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1200 ? 4 : (w >= 900 ? 3 : 2);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
      _metricCard(context, 'Days with Shifts', shiftCount, Icons.people_alt, Theme.of(context).colorScheme.primary),
      _metricCard(context, 'Presents (MTD)', attendance, Icons.check_circle_outline, Theme.of(context).colorScheme.primary),
      _metricCard(context, 'Spend (MTD)', '₹$spend', Icons.monetization_on, Theme.of(context).colorScheme.primary),
      _metricCard(context, 'Outstanding Bills', bills, Icons.receipt_long, Theme.of(context).colorScheme.primary),
          ],
        );
      },
    );
  }

  Widget _metricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String title;
  final String bulkUrl;
  final VoidCallback? onOpen;
  const _AdminTile({required this.title, required this.bulkUrl, this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text('Upload CSV/XLSX to bulk insert or update'),
        trailing: BulkUploadButton(
          bulkUrl: bulkUrl,
          singleUrl: _singleUrlFor(title),
          templateHeaders: _templateHeadersFor(title),
          extraFields: const {},
        ),
        onTap: onOpen,
      ),
    );
  }
}

List<String>? _templateHeadersFor(String title) {
  switch (title) {
    case 'Attendance':
      return ['siteId','guardId','date','status'];
    case 'Shifts':
      return ['siteId','date','shiftType','guardCount'];
    case 'Spend':
      return ['siteId','amount','date','description'];
    case 'Night Rounds':
      return ['siteId','date','findings','officerId'];
    case 'Training Reports':
      return ['siteId','date','topics','attendance_count'];
    case 'Salary Disbursement':
      return ['siteId','month','status','date_paid'];
    case 'Complaints':
      return ['siteId','complaint_text','client_id','status'];
    case 'Ratings':
      return ['siteId','month','rating_value','nps_score','client_id'];
    case 'Bills (SOA)':
      return ['siteId','amount','due_date','status','invoice_url'];
    case 'Sites':
      return ['id','name','location','strength','rate','agreementStart','agreementEnd','officerName','officerPhone','croName','croPhone','clientId'];
  }
  return null;
}

String? _singleUrlFor(String title) {
  switch (title) {
    case 'Attendance':
      return '/attendance';
    case 'Shifts':
      return '/shifts';
    case 'Spend':
      return '/spend';
    case 'Night Rounds':
      return '/night-rounds';
    case 'Training Reports':
      return '/training';
    case 'Salary Disbursement':
      return '/payroll';
    case 'Complaints':
      return '/complaints/admin';
    case 'Ratings':
      return '/ratings/admin';
    case 'Bills (SOA)':
      return '/billing';
    case 'Sites':
      return null; // only bulk upsert or PATCH per site
  }
  return null;
}
