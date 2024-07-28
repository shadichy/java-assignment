import 'dart:convert';

import 'package:assignment/provider/account.dart';
import 'package:assignment/provider/product.dart';
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

class ArtistFilter extends Filter<Artist> {
  final List<String> hasAlbums;
  final List<int> hasTracks;
  final String? name;
  final String? description;
  final DateTime? debutBefore;
  final DateTime? debutAfter;

  ArtistFilter({
    this.hasAlbums = const [],
    this.hasTracks = const [],
    this.name,
    this.description,
    this.debutBefore,
    this.debutAfter,
  });

  static final ArtistFilter all = ArtistFilter();

  @override
  Map<String, dynamic> toMap() => {
        "path": "artist",
        "hasAlbums": hasAlbums,
        "hasTracks": hasTracks,
        "name": name,
        "description": description,
        "debutBefore": nullDate(debutBefore),
        "debutAfter": nullDate(debutAfter),
      };

  @override
  Artist constructor(Map raw) => Artist.fromMap(raw);

  ArtistFilter copyWith({
    List<String>? hasAlbums,
    List<int>? hasTracks,
    String? name,
    String? description,
    DateTime? debutBefore,
    DateTime? debutAfter,
  }) {
    return ArtistFilter(
      name: name ?? this.name,
      hasAlbums: hasAlbums ?? this.hasAlbums,
      hasTracks: hasTracks ?? this.hasTracks,
      description: description ?? this.description,
      debutBefore: debutBefore ?? this.debutBefore,
      debutAfter: debutAfter ?? this.debutAfter,
    );
  }
}

class DiscFilter extends Filter<Disc> {
  final String? name;
  final DateTime? releaseBefore;
  final DateTime? releaseAfter;
  final int? stockHighest;
  final int? stockLowest;
  final double? priceHighest;
  final double? priceLowest;
  final List<int> hasArtists;

  DiscFilter({
    this.name,
    this.releaseBefore,
    this.releaseAfter,
    this.stockHighest,
    this.stockLowest,
    this.priceHighest,
    this.priceLowest,
    this.hasArtists = const [],
  });

  static final DiscFilter all = DiscFilter();

  @override
  Map<String, dynamic> toMap() => {
        "path": "disc",
        "name": name,
        "releaseBefore": nullDate(releaseBefore),
        "releaseAfter": nullDate(releaseAfter),
        "stockHighest": stockHighest,
        "stockLowest": stockLowest,
        "priceHighest": priceHighest,
        "priceLowest": priceLowest,
        "hasArtists": hasArtists,
      };

  @override
  Disc constructor(Map raw) => Disc.fromMap(raw);

  DiscFilter copyWith({
    String? name,
    DateTime? releaseBefore,
    DateTime? releaseAfter,
    int? stockHighest,
    int? stockLowest,
    double? priceHighest,
    double? priceLowest,
    List<int>? hasArtists,
  }) {
    return DiscFilter(
      name: name ?? this.name,
      releaseBefore: releaseBefore ?? this.releaseBefore,
      releaseAfter: releaseAfter ?? this.releaseAfter,
      stockHighest: stockHighest ?? this.stockHighest,
      stockLowest: stockLowest ?? this.stockLowest,
      priceHighest: priceHighest ?? this.priceHighest,
      priceLowest: priceLowest ?? this.priceLowest,
      hasArtists: hasArtists ?? this.hasArtists,
    );
  }
}

class InvoiceFilter extends Filter<Invoice> {
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

  InvoiceFilter copyWith({
    List<int>? hasDiscs,
    List<int>? hasCustomers,
    DateTime? before,
    DateTime? after,
  }) {
    return InvoiceFilter(
      hasDiscs: hasDiscs ?? this.hasDiscs,
      hasCustomers: hasCustomers ?? this.hasCustomers,
      before: before ?? this.before,
      after: after ?? this.after,
    );
  }
}

class CustomerFilter extends Filter<Customer> {
  final String? name;
  final String? email;
  final List<String> hasPhones;
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

  CustomerFilter copyWith({
    String? name,
    String? email,
    List<String>? hasPhones,
    DateTime? createdBefore,
    DateTime? createdAfter,
  }) {
    return CustomerFilter(
      name: name ?? this.name,
      email: email ?? this.email,
      hasPhones: hasPhones ?? this.hasPhones,
      createdBefore: createdBefore ?? this.createdBefore,
      createdAfter: createdAfter ?? this.createdAfter,
    );
  }
}
