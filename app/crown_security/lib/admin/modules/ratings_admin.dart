import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';

class RatingsAdmin extends StatelessWidget {
  const RatingsAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminDataTable(
      title: 'Ratings',
      endpoint: '/ratings',
      columns: [
        AdminColumn(field: 'month', title: 'Month'),
        AdminColumn(field: 'rating_value', title: 'Rating'),
        AdminColumn(field: 'nps_score', title: 'NPS Score'),
        AdminColumn(field: 'client_name', title: 'Client', flex: 2),
        AdminColumn(field: 'site_name', title: 'Site', flex: 2),
      ],
      mapRowData: (item) => {
        'id': item['id'],
        'month': item['month']?.toString().substring(0, 7) ?? '',
        'rating_value': item['rating_value']?.toString() ?? '',
        'nps_score': item['nps_score']?.toString() ?? '',
        'client_name': item['client_name'] ?? 'Unknown Client',
        'site_name': item['site_name'] ?? 'Unknown Site',
      },
    );
  }
}
