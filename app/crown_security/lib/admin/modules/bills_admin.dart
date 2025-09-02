import 'package:flutter/material.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/entity_dropdown.dart';

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
        AdminColumn(field: 'site_name', title: 'Site'),
      ],
      mapRowData: (item) => {
        final site = item['Site'];
        return {
          'id': item['id'],
          'code': item['code'] ?? '',
          'amount': item['amount']?.toString() ?? '',
          'due_date': item['due_date']?.toString().substring(0, 10) ?? '',
          'status': item['status'] ?? '',
          'site_name': site != null ? site['name'] ?? 'Unknown Site' : 'No Site',
        };
      },
      createFormFields: [
        AdminFormField(
          field: 'code',
          label: 'Bill Code',
          type: AdminFieldType.text,
          required: true,
        ),
        AdminFormField(
          field: 'amount',
          label: 'Amount',
          type: AdminFieldType.number,
          required: true,
        ),
        AdminFormField(
          field: 'due_date',
          label: 'Due Date',
          type: AdminFieldType.date,
          required: true,
        ),
        AdminFormField(
          field: 'status',
          label: 'Status',
          type: AdminFieldType.dropdown,
          dropdownOptions: ['PENDING', 'PAID', 'OVERDUE', 'CANCELLED'],
          required: true,
        ),
        AdminFormField(
          field: 'site_id',
          label: 'Site',
          type: AdminFieldType.custom,
          customWidget: (formKey, formData, onChanged) => EntityDropdown(
            endpoint: '/sites',
            value: formData['site_id'],
            onChanged: (value) => onChanged('site_id', value),
            displayField: 'name',
            valueField: 'id',
            placeholder: 'Select Site',
          ),
          required: true,
        ),
      ],
      onCreateItem: (data) async {
        // Convert amount to number
        if (data['amount'] != null) {
          data['amount'] = double.tryParse(data['amount'].toString()) ?? 0.0;
        }
        return data;
      },
      onUpdateItem: (data) async {
        // Convert amount to number
        if (data['amount'] != null) {
          data['amount'] = double.tryParse(data['amount'].toString()) ?? 0.0;
        }
        return data;
      },
    );
  }
}
