import 'package:flutter/material.dart';
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

class AdminSection extends StatelessWidget {
  const AdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminTile(
            title: 'Shifts',
            bulkUrl: '/shifts/bulk',
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShiftsAdminScreen()),
            ),
          ),
          _AdminTile(
            title: 'Attendance',
            bulkUrl: '/attendance/bulk',
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceAdminScreen()),
            ),
          ),
          _AdminTile(
            title: 'Spend',
            bulkUrl: '/spend/bulk',
            onOpen: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpendAdminScreen()),
            ),
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
