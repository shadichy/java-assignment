import 'package:assignment/components/table.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';

class InvoicesFiltered extends StatefulWidget {
  final InvoiceFilter? filter;
  const InvoicesFiltered({super.key, this.filter});

  @override
  State<InvoicesFiltered> createState() => _InvoicesFilteredState();
}

class _InvoicesFilteredState extends State<InvoicesFiltered> {
  late InvoiceFilter filter = widget.filter ?? InvoiceFilter.all;
  List<Invoice> data = [];

  @override
  void initState() {
    super.initState();
    filter.fetch().then((data) {
      if (mounted) setState(() => this.data = data);
    });
  }

  @override
  void dispose() {
    Filters().invoiceFilter = null;
    super.dispose();
  } 

  @override
  Widget build(BuildContext context) {
    return data.isEmpty
        ? const SizedBox()
        : InvoiceTable(
            children: data.map((e) => InvoiceTableRow(invoice: e)).toList(),
          );
  }
}

class InvoicesNoFilter extends StatelessWidget {
  const InvoicesNoFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return const InvoicesFiltered();
  }
}
