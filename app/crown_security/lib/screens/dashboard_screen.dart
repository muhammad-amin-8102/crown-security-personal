import 'package:flutter/material.dart';
import '../core/api.dart';
import '../widgets/site_selector.dart';

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
  String? _siteName;
  String? _from;
  String? _to;
  String _selectedPreset = 'This Month';

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
    // If not logged in, redirect to login immediately
    final token = await Api.storage.read(key: 'access_token');
    if (token == null) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      return;
    }
    // Get user id from secure storage (set on login)
    final userId = await Api.storage.read(key: 'user_id');
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'User not logged in.';
      });
      return;
    }

    // Try to restore previously selected site
    final savedSiteId = await Api.storage.read(key: 'selected_site_id');
    final savedSiteName = await Api.storage.read(key: 'selected_site_name');
    
    if (savedSiteId != null && savedSiteName != null) {
      _siteId = savedSiteId;
      _siteName = savedSiteName;
      
      // Initialize date range (restore previous or default to current month)
      _from = await Api.storage.read(key: 'dash_from');
      _to = await Api.storage.read(key: 'dash_to');
      _selectedPreset = (await Api.storage.read(key: 'dash_preset')) ?? 'This Month';
      if (_from == null || _to == null) {
        _applyPresetInternal('This Month', persist: true);
      }
      
      await _loadDashboard(_siteId!);
    } else {
      // No saved site, let the SiteSelector handle initial selection
      setState(() {
        _loading = false;
      });
    }
  }

  void _onSiteChanged(String siteId, String siteName) async {
    print('🏢 Site changed: $siteName ($siteId)');
    
    setState(() {
      _siteId = siteId;
      _siteName = siteName;
      _loading = true;
      _error = null;
    });

    // Save selected site
    await Api.storage.write(key: 'selected_site_id', value: siteId);
    await Api.storage.write(key: 'selected_site_name', value: siteName);
    await Api.storage.write(key: 'site_id', value: siteId); // Legacy compatibility

    // Initialize date range if not set
    if (_from == null || _to == null) {
      _applyPresetInternal('This Month', persist: true);
    }

    await _loadDashboard(siteId);
  }

  Future<void> _loadDashboard(String siteId) async {
    final from = _from ?? DateTime.now().toIso8601String().substring(0, 10);
    final to = _to ?? DateTime.now().toIso8601String().substring(0, 10);
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
        title: Text(_siteName != null ? 'Dashboard - $_siteName' : 'Dashboard'),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserSiteAndDashboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _siteId == null
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SiteSelector(
                            selectedSiteId: _siteId,
                            onSiteChanged: _onSiteChanged,
                            enabled: !_loading,
                          ),
                          const SizedBox(height: 32),
                          const Center(
                            child: Text(
                              'Please select a site to view dashboard',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
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
                          // Site Selector - Only show if site is selected or loading
                          if (_siteId != null || _loading) ...[
                            SiteSelector(
                              selectedSiteId: _siteId,
                              onSiteChanged: _onSiteChanged,
                              enabled: !_loading,
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Date Range Selector
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      ((_from != null && _to != null) ? '${_formatDate(_from!)} — ${_formatDate(_to!)}' : 'Select date range'),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final initialStart = _parseDate(_from) ?? DateTime.now().subtract(const Duration(days: 7));
                                      final initialEnd = _parseDate(_to) ?? DateTime.now();
                                      final picked = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2020, 1, 1),
                                        lastDate: DateTime(2100, 12, 31),
                                        initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          _from = picked.start.toIso8601String().substring(0, 10);
                                          _to = picked.end.toIso8601String().substring(0, 10);
                                              _selectedPreset = 'Custom';
                                            });
                                            await Api.storage.write(key: 'dash_from', value: _from);
                                            await Api.storage.write(key: 'dash_to', value: _to);
                                            await Api.storage.write(key: 'dash_preset', value: _selectedPreset);
                                        if (_siteId != null) await _loadDashboard(_siteId!);
                                      }
                                    },
                                    icon: const Icon(Icons.edit_calendar),
                                    label: const Text('Change'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _presetChip('This Month'),
                                  _presetChip('Last 7 Days'),
                                  _presetChip('Last 30 Days'),
                                  _presetChip('This Year'),
                                  _presetChip('Custom'),
                                ],
                              ),
                          const SizedBox(height: 12),
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
                                  Icon(Icons.location_city, color: Theme.of(context).colorScheme.primary, size: 40),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                Text(_data!['site']?['name']?.toString() ?? 'Site', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                Text(_data!['site']?['location']?.toString() ?? 'Location not available', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
              // Removed pencil edit icon per requirement
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
                              _buildShiftMetricCard(
                                context,
                                title: 'Shift-wise Count',
                                shiftData: _data!['latestShiftReport']?['shiftBreakdown'] ?? [],
                                totalCount: _data!['latestShiftReport']?['shiftWiseCount']?.toString() ?? 'N/A',
                                icon: Icons.people_alt,
                                color: Theme.of(context).colorScheme.primary,
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
                                color: Theme.of(context).colorScheme.primary,
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
                                color: Theme.of(context).colorScheme.primary,
                                onTap: () => Navigator.pushNamed(context, '/spend'),
                              ),
                              _buildMetricCard(
                                context,
                                title: 'Outstanding Bills',
                                value: (() {
                                  final soa = _data!['soa'];
                                  if (soa is Map) {
                                    final items = (soa['items'] as List?) ?? [];
                                    final outstanding = items.where((e) => (e['status'] ?? '').toString().toUpperCase() == 'OUTSTANDING').length;
                                    return outstanding.toString();
                                  }
                                  if (soa is List) {
                                    final outstanding = soa.where((e) => (e['status'] ?? '').toString().toUpperCase() == 'OUTSTANDING').length;
                                    return outstanding.toString();
                                  }
                                  return '0';
                                })(),
                                icon: Icons.receipt_long,
                                color: Theme.of(context).colorScheme.primary,
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

  String _formatDate(String isoYMD) {
    try {
      final dt = DateTime.parse(isoYMD);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return isoYMD;
    }
  }

  DateTime? _parseDate(String? isoYMD) {
    if (isoYMD == null) return null;
    try { return DateTime.parse(isoYMD); } catch (_) { return null; }
  }

  // Set _from/_to based on a preset without triggering network; used during init
  void _applyPresetInternal(String preset, {bool persist = false}) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    switch (preset) {
      case 'Last 7 Days':
        end = DateTime(now.year, now.month, now.day);
        start = end.subtract(const Duration(days: 6));
        break;
      case 'Last 30 Days':
        end = DateTime(now.year, now.month, now.day);
        start = end.subtract(const Duration(days: 29));
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, now.month, now.day);
        break;
      case 'Custom':
        // Don't change dates here; Custom is set via picker
        return;
      case 'This Month':
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
    }
    _from = start.toIso8601String().substring(0, 10);
    _to = end.toIso8601String().substring(0, 10);
    _selectedPreset = preset;
    if (persist) {
      Api.storage.write(key: 'dash_from', value: _from);
      Api.storage.write(key: 'dash_to', value: _to);
      Api.storage.write(key: 'dash_preset', value: _selectedPreset);
    }
  }

  // Apply preset, persist, and reload dashboard
  Future<void> _applyPreset(String preset) async {
    setState(() {
      _applyPresetInternal(preset);
    });
    await Api.storage.write(key: 'dash_from', value: _from);
    await Api.storage.write(key: 'dash_to', value: _to);
    await Api.storage.write(key: 'dash_preset', value: _selectedPreset);
    if (_siteId != null) await _loadDashboard(_siteId!);
  }

  Widget _presetChip(String label) {
    final selected = _selectedPreset == label;
    return ChoiceChip(
  label: Text(label),
  labelStyle: const TextStyle(color: Colors.black),
      selected: selected,
      onSelected: (val) async {
        if (!val) return;
        if (label == 'Custom') {
          // Open picker directly
          final initialStart = _parseDate(_from) ?? DateTime.now().subtract(const Duration(days: 7));
          final initialEnd = _parseDate(_to) ?? DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020, 1, 1),
            lastDate: DateTime(2100, 12, 31),
            initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
          );
          if (picked != null) {
            setState(() {
              _from = picked.start.toIso8601String().substring(0, 10);
              _to = picked.end.toIso8601String().substring(0, 10);
              _selectedPreset = 'Custom';
            });
            await Api.storage.write(key: 'dash_from', value: _from);
            await Api.storage.write(key: 'dash_to', value: _to);
            await Api.storage.write(key: 'dash_preset', value: _selectedPreset);
            if (_siteId != null) await _loadDashboard(_siteId!);
          }
        } else {
          await _applyPreset(label);
        }
      },
  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
  backgroundColor: Colors.white,
  showCheckmark: false,
      shape: StadiumBorder(side: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300)),
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

  Widget _buildShiftMetricCard(
    BuildContext context, {
    required String title,
    required List<dynamic> shiftData,
    required String totalCount,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Total: $totalCount',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (shiftData.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'DAY',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ...shiftData.map((shift) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${shift['shift']}:',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${shift['guards']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'No shift data',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
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
  leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
  subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
