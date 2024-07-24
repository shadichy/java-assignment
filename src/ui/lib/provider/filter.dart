import 'dart:convert';

import 'package:assignment/provider/account.dart';
import 'package:assignment/provider/product.dart';
import 'package:assignment/screens/tabs/customers/filtered.dart';
import 'package:assignment/screens/tabs/invoices/filtered.dart';
import 'package:assignment/screens/tabs/storage/filtered.dart';
import 'package:flutter/material.dart';

final class Filters {
  Filters._();
  static final Filters _f = Filters._();
  factory Filters() => _f;

  DiscFilter? discFilter;

  InvoiceFilter? invoiceFilter;

  CustomerFilter? customerFilter;
}

abstract class Filter<T extends BaseAbstractProduct> {
  @protected
  Map<String, dynamic> toMap();

  @protected
  T constructor(Map raw);

  int? nullDate(DateTime? date) =>
      date == null ? null : date.millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() => jsonEncode(toMap());

  Future<List<T>> fetch() async {
    Map<String, dynamic> map = toMap();
    map.removeWhere((_, v) => v == null);
    map["method"] = "get";
    return ((await Data().fetch(map)) as List)
        .cast<Map>()
        .map(constructor)
        .toList();
  }
}
