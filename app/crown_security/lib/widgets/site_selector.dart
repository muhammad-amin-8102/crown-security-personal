import 'package:flutter/material.dart';
import '../core/api.dart';

class SiteSelector extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String siteId, String siteName) onSiteChanged;
  final bool enabled;

  const SiteSelector({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    this.enabled = true,
  });

  @override
  State<SiteSelector> createState() => _SiteSelectorState();
}

class _SiteSelectorState extends State<SiteSelector> {
  List<Map<String, dynamic>> _sites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Get current user ID
      final userId = await Api.storage.read(key: 'user_id');
      if (userId == null) {
        setState(() {
          _loading = false;
          _error = 'User not logged in';
        });
        return;
      }

      print('🏢 Loading sites for user: $userId');

      // Fetch sites for this user
      final response = await Api.dio.get(
        '/sites',
        queryParameters: {'client_id': userId},
      );

      final sites = response.data as List?;
      print('🏢 Sites loaded: ${sites?.length ?? 0}');

      if (sites == null || sites.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No sites assigned to your account';
          _sites = [];
        });
        return;
      }

      setState(() {
        _sites = sites.cast<Map<String, dynamic>>();
        _loading = false;
      });

      // If no site is selected but we have sites, select the first one
      if (widget.selectedSiteId == null && _sites.isNotEmpty) {
        final firstSite = _sites.first;
        widget.onSiteChanged(firstSite['id'], firstSite['name']);
      }

    } catch (e) {
      print('❌ Error loading sites: $e');
      setState(() {
        _loading = false;
        _error = 'Failed to load sites';
        _sites = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSites,
                tooltip: 'Retry',
              ),
            ],
          ),
        ),
      );
    }

    if (_sites.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No sites assigned to your account',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Find selected site name for any future use
    // final selectedSite = _sites.firstWhere(
    //   (site) => site['id'] == widget.selectedSiteId,
    //   orElse: () => _sites.first,
    // );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Selected Site',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: widget.selectedSiteId,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              hint: const Text('Select a site'),
              isExpanded: true,
              items: _sites.map((site) {
                return DropdownMenuItem<String>(
                  value: site['id'],
                  child: Text(
                    site['name'] ?? 'Unnamed Site',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: widget.enabled ? (String? newSiteId) {
                if (newSiteId != null) {
                  final selectedSite = _sites.firstWhere(
                    (site) => site['id'] == newSiteId,
                  );
                  widget.onSiteChanged(newSiteId, selectedSite['name'] ?? 'Unnamed Site');
                }
              } : null,
            ),
            if (_sites.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                '${_sites.length} sites available',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
