import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';

class ComplaintsAdmin extends StatelessWidget {
  const ComplaintsAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Complaints',
      endpoint: '/complaints',
      columns: [
        AdminColumn(field: 'complaint_text', title: 'Complaint', flex: 3),
        AdminColumn(field: 'status', title: 'Status'),
        AdminColumn(field: 'client_name', title: 'Client', flex: 2),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'complaint_text': item['complaint_text'] ?? '',
        'status': item['status'] ?? '',
        'client_name': item['client_name'] ?? 'Unknown Client',
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
    );
  }
}
