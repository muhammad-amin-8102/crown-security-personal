import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';

class BillsAdmin extends StatelessWidget {
  const BillsAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Bills/SOA',
      endpoint: '/bills',
      columns: [
        AdminColumn(field: 'code', title: 'Code'),
        AdminColumn(field: 'amount', title: 'Amount'),
        AdminColumn(field: 'due_date', title: 'Due Date'),
        AdminColumn(field: 'status', title: 'Status'),
        AdminColumn(field: 'site_id', title: 'Site'),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'code': item['code'] ?? '',
        'amount': item['amount']?.toString() ?? '',
        'due_date': item['due_date']?.toString().substring(0, 10) ?? '',
        'status': item['status'] ?? '',
        'site_id': item['site_id']?.toString().substring(0, 8) ?? '',
      },
    );
  }
}
