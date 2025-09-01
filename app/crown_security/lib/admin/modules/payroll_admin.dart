import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';

class PayrollAdmin extends StatelessWidget {
  const PayrollAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Payroll',
      endpoint: '/payroll',
      columns: [
        AdminColumn(field: 'month', title: 'Month'),
        AdminColumn(field: 'status', title: 'Status'),
        AdminColumn(field: 'date_paid', title: 'Date Paid'),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'month': item['month']?.toString().substring(0, 7) ?? '',
        'status': item['status'] ?? '',
        'date_paid': item['date_paid']?.toString().substring(0, 10) ?? '',
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
    );
  }
}
