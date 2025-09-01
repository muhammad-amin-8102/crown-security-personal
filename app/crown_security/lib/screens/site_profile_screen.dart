import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api.dart';

class SiteProfileScreen extends StatefulWidget {
  const SiteProfileScreen({super.key});

  @override
  State<SiteProfileScreen> createState() => _SiteProfileScreenState();
}

class _SiteProfileScreenState extends State<SiteProfileScreen> {
  Map<String, dynamic>? _site;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSiteProfile();
  }

  Future<void> _loadSiteProfile() async {
    try {
      final userId = await Api.storage.read(key: 'user_id');
      if (userId == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'User not logged in.';
          });
        }
        return;
      }

      final response = await Api.dio.get(
        '/sites',
        queryParameters: {'client_id': userId},
      );
      final sites = response.data as List?;
      if (sites == null || sites.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'No site assigned.';
          });
        }
        return;
      }
      final siteId = sites.first['id'];
      final profileResp = await Api.dio.get('/sites/$siteId');
      if (mounted) {
        setState(() {
          _site = profileResp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load site profile.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site Profile')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!, textAlign: TextAlign.center),
      ));
    }
    if (_site == null) {
      return const Center(child: Text('No site data found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadSiteProfile,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSiteDetailsCard(),
          const SizedBox(height: 16),
          _buildPersonnelCard('Area Officer', _site!['area_officer_name'],
              _site!['area_officer_phone']),
          const SizedBox(height: 16),
          _buildPersonnelCard('Client Relations Officer', _site!['cro_name'],
              _site!['cro_phone']),
        ],
      ),
    );
  }

  Widget _buildSiteDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _site!['name'] ?? 'Site Name Not Available',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_site!['location'] ?? 'Location not available',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 24),
      _buildDetailRow(
        Icons.calendar_today,
        'Agreement Start',
        _fmtDate(_site!['agreement_start'])),
      _buildDetailRow(
        Icons.calendar_today,
        'Agreement End',
        _fmtDate(_site!['agreement_end'])),
            _buildDetailRow(Icons.security, 'Strength',
                _site!['strength']?.toString() ?? 'N/A'),
            _buildDetailRow(Icons.money, 'Rate per Guard',
                '₹${_site!['rate_per_guard'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelCard(String title, String? name, String? phone) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.person,
            size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  subtitle: Text('${name ?? 'N/A'}\n${_fmtPhone(phone)}'),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor.withValues(alpha: 0.8)),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  String _fmtDate(dynamic v) {
    if (v == null) return 'N/A';
    DateTime? d;
    if (v is String) d = DateTime.tryParse(v);
    if (v is DateTime) d = v;
    if (d == null) return 'N/A';
    return DateFormat('dd-MM-yyyy').format(d);
  }

  String _fmtPhone(String? p) {
    if (p == null || p.isEmpty) return 'N/A';
    final digits = p.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }
}
