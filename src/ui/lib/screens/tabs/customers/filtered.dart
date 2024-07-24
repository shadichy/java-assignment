import 'package:assignment/components/table.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';

class CustomerFilter extends Filter<Customer> {
  final String? name;
  final String? email;
  final List<int> hasPhones;
  final DateTime? createdBefore;
  final DateTime? createdAfter;

  CustomerFilter({
    this.name,
    this.email,
    this.hasPhones = const [],
    this.createdBefore,
    this.createdAfter,
  });

  static final CustomerFilter all = CustomerFilter();

  @override
  Map<String, dynamic> toMap() => {
        "path": "customer",
        "name": name,
        "email": email,
        "hasPhones": hasPhones,
        "createdBefore": nullDate(createdBefore),
        "createdAfter": nullDate(createdAfter),
      };

  @override
  Customer constructor(Map raw) => Customer.fromMap(raw);
}

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
    // Data().fetch({
    //   "method": "get",
    //   "path": "customer",
    // }).then((data) {
    //   List<Customer> d =
    //       (data as List).cast<Map>().map(Customer.fromMap).toList();
    //   if (filter.name != null) {
    //     d = d.where((e) => e.name.contains(filter.name!)).toList();
    //   }
    //   if (filter.email != null) {
    //     d = d.where((e) => e.email.contains(filter.email!)).toList();
    //   }
    //   if (filter.createdBefore != null) {
    //     d = d.where((e) {
    //       return e.createdDate.isBefore(filter.createdBefore!);
    //     }).toList();
    //   }
    //   if (filter.createdAfter != null) {
    //     d = d.where((e) {
    //       return e.createdDate.isAfter(filter.createdAfter!);
    //     }).toList();
    //   }
    //   if (filter.hasPhones.isNotEmpty) {
    //     Set f = filter.hasPhones.toSet();
    //     d = d.where((e) {
    //       return e.phoneNo.toSet().intersection(f).isNotEmpty;
    //     }).toList();
    //   }
    //   if (mounted) setState(() => this.data = (data as List).cast<Map>().map(Customer.fromMap).toList());
    // });
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
