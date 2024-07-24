import 'package:assignment/components/table.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';

class InvoiceFilter extends Filter<Invoice>  {
  final List<int> hasDiscs;
  final List<int> hasCustomers;
  final DateTime? before;
  final DateTime? after;

  InvoiceFilter({
    this.hasDiscs = const [],
    this.hasCustomers = const [],
    this.before,
    this.after,
  });

  static final InvoiceFilter all = InvoiceFilter();

  @override
  Map<String, dynamic> toMap() => {
        "path": "invoice",
        "hasDiscs": hasDiscs,
        "hasCustomers": hasCustomers,
        "before": nullDate(before),
        "after": nullDate(after),
      };

  @override
  Invoice constructor(Map raw) => Invoice.fromMap(raw);
}

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
    // Data().fetch({
    //   "method": "get",
    //   "path": "invoice",
    // }).then((data) {
    //   List<Invoice> d =
    //       (data as List).cast<Map>().map(Invoice.fromMap).toList();
    //   if (filter.before != null) {
    //     d = d.where((e) {
    //       return e.date.isBefore(filter.before!);
    //     }).toList();
    //   }
    //   if (filter.after != null) {
    //     d = d.where((e) {
    //       return e.date.isAfter(filter.after!);
    //     }).toList();
    //   }
    //   if (filter.hasDiscs.isNotEmpty) {
    //     Set f = filter.hasDiscs.toSet();
    //     d = d.where((e) {
    //       return e.trackIDs.keys.toSet().intersection(f).isNotEmpty;
    //     }).toList();
    //   }
    //   if (filter.hasCustomers.isNotEmpty) {
    //     d = d.where((e) => filter.hasCustomers.contains(e.customerID)).toList();
    //   }
    //   if (mounted) setState(() => this.data = d);
    // });
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
