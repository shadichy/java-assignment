import 'package:assignment/components/table.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';

class CustomersFiltered extends StatefulWidget {
  final CustomerFilter? filter;
  const CustomersFiltered({super.key, this.filter});

  @override
  State<CustomersFiltered> createState() => _CustomersFilteredState();
}

class _CustomersFilteredState extends State<CustomersFiltered> {
  late CustomerFilter filter = widget.filter ?? CustomerFilter.all;
  List<Customer> data = [];

  @override
  void initState() {
    super.initState();
    filter.fetch().then((data) {
      if (mounted) setState(() => this.data = data);
    });
  }

  @override
  void dispose() {
    Filters().customerFilter = null;
    super.dispose();
  } 

  @override
  Widget build(BuildContext context) {
    return data.isEmpty
        ? const SizedBox()
        : CustomerTable(
            children: data.map((e) => CustomerTableRow(customer: e)).toList(),
          );
  }
}

class CustomersNoFilter extends StatelessWidget {
  const CustomersNoFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomersFiltered();
  }
}
