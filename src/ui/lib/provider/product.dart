import 'dart:convert';

import 'package:assignment/provider/account.dart';
import 'package:flutter/material.dart';

DateTime _epoch(int date) => DateTime.fromMillisecondsSinceEpoch(date * 1000);

String _dec(String? data) {
  return data == null ? "" : utf8.decode((data).runes.toList());
}

Future<Disc> discFromID(int id) async {
  try {
    return Data().getDiscs.firstWhere((e) => e.id == id);
  } catch (e) {
    return Disc.fromMap(await Data().fetch({
      "method": "get",
      "path": "disc",
      "id": id,
    }));
  }
}

Future<Customer> customerFromID(int id) async {
  try {
    return Data().getCustomers.firstWhere((e) => e.id == id);
  } catch (e) {
    return Customer.fromMap(await Data().fetch({
      "method": "get",
      "path": "customer",
      "id": id,
    }));
  }
}

Future<Artist> artistFromID(int id) async {
  try {
    return Data().getArtists.firstWhere((e) => e.id == id);
  } catch (e) {
    return Artist.fromMap(await Data().fetch({
      "method": "get",
      "path": "artist",
      "id": id,
    }));
  }
}

Future<List<Invoice>> _history(int customer) async => (await Data().fetch({
      "method": "get",
      "path": "invoice",
      "hasCustomers": [customer],
    }) as List)
        .map((e) => Invoice.fromMap(e))
        .toList();

abstract final class BaseAbstractProduct {
  final int id;
  BaseAbstractProduct({required this.id});

  @protected
  Map<String, dynamic> toMap();
  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() => jsonEncode(toMap());
}

final class Artist extends BaseAbstractProduct {
  final String name;
  final Map<String, List<int>> albums;

  final DateTime debutDate;
  final String description;

  List<int> get trackIDs => albums.values.fold([], (a, b) => [...a, ...b]);
  Future<List<Disc>> get tracks async {
    List<Disc> r = [];
    for (int track in trackIDs) {
      r.add(await discFromID(track));
    }
    return r;
  }

  int get trackCount => trackIDs.length;
  int get albumCount => albums.length - 1;

  Artist({
    required super.id,
    required this.name,
    required this.albums,
    int debutDate = 0,
    this.description = '',
  }) : debutDate = _epoch(debutDate);

  Artist.fromMap(Map data)
      : this(
          id: data["id"],
          name: _dec(data["name"]),
          debutDate: data["date"],
          description: _dec(data["description"]),
          albums: (data["albums"] as Map? ?? {}).map((k, v) {
            return MapEntry(
              k as String,
              (v as List).map((e) => (e as num).toInt()).toList(),
            );
          }),
        );

  Artist.fromJson(Map data) : this.fromMap(data);

  @override
  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "albums": albums,
        "debutDate": debutDate.millisecondsSinceEpoch ~/ 1000,
        "description": description,
      };

  @override
  int get hashCode => Object.hash(id, name, debutDate);

  @override
  bool operator ==(Object other) {
    if (other is! Artist) return false;
    return id == other.id && name == other.name && debutDate == other.debutDate;
  }

  Artist copyWith({
    String? name,
    Map<String, List<int>>? albums,
    int? debutDate,
    String? description,
  }) {
    return Artist(
      id: id,
      name: name ?? this.name,
      albums: albums ?? this.albums,
      debutDate: debutDate ?? this.debutDate.millisecondsSinceEpoch ~/ 1000,
      description: description ?? this.description,
    );
  }
}

final class Disc extends BaseAbstractProduct {
  final String name;
  final DateTime releaseDate;
  final List<int> artistIDs;
  final int stockCount;
  final double price;
  String? _image;

  Future<List<Artist>> get artists async {
    List<Artist> r = [];
    for (int track in artistIDs) {
      r.add(await artistFromID(track));
    }
    return r;
  }
  // List<Invoice> get history => _history(track: id);

  Disc({
    required super.id,
    required this.name,
    required int releaseDate,
    String? image,
    required this.artistIDs,
    required this.stockCount,
    required this.price,
  })  : _image = image,
        releaseDate = _epoch(releaseDate);

  static ImageProvider defaultImage =
      const AssetImage("assets/images/vinyl.png");

  ImageProvider get image {
    try {
      if (_image == null || _image == "") throw Exception();
      return NetworkImage(_image!);
    } catch (_) {
      return defaultImage;
    }
  }

  String? get imageURL => _image;

  Disc.fromMap(Map data)
      : this(
          id: data["id"],
          name: _dec(data["name"]),
          releaseDate: data["date"],
          artistIDs: (data["artists"] as List?)?.map((e) {
                return (e as num).toInt();
              }).toList() ??
              [],
          stockCount: data["stockCount"] ?? 0,
          price: data["price"] ?? 0,
          image: data["image"] as String?,
        );

  Disc.fromJson(Map data) : this.fromMap(data);

  @override
  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "releaseDate": releaseDate.millisecondsSinceEpoch ~/ 1000,
        "image": _image,
        "artists": artistIDs,
        "stockCount": stockCount,
        "price": price,
      };

  @override
  int get hashCode => Object.hash(id, name, releaseDate, artistIDs);

  @override
  bool operator ==(Object other) {
    if (other is! Disc) return false;
    return id == other.id &&
        name == other.name &&
        releaseDate == other.releaseDate &&
        artistIDs == other.artistIDs;
  }

  Disc copyWith({
    String? name,
    int? releaseDate,
    List<int>? artistIDs,
    int? stockCount,
    double? price,
    String? image,
  }) {
    return Disc(
        id: id,
        name: name ?? this.name,
        releaseDate:
            releaseDate ?? this.releaseDate.millisecondsSinceEpoch ~/ 1000,
        artistIDs: artistIDs ?? this.artistIDs,
        stockCount: stockCount ?? this.stockCount,
        price: price ?? this.price,
        image: image ?? _image);
  }
}

final class Customer extends BaseAbstractProduct {
  final String name;
  final List<String> phoneNo;
  final DateTime createdDate;
  final String email;

  Future<List<Invoice>> get buyingHistory async => await _history(id);
  Future<List<Disc>> get boughtProducts async {
    List<Disc> r = [];
    for (Invoice invoice in await buyingHistory) {
      r.addAll(await invoice.tracks);
    }
    return r;
  }

  Customer({
    required super.id,
    required this.name,
    required this.phoneNo,
    required int createdDate,
    this.email = "",
  }) : createdDate = _epoch(createdDate);

  Customer.fromMap(Map data)
      : this(
          id: data["id"],
          name: _dec(data["name"]),
          phoneNo: (data["phoneNo"] as List?)?.cast<String>() ?? [],
          createdDate: data["date"],
          email: _dec(data["email"]),
        );

  Customer.fromJson(Map data) : this.fromMap(data);

  @override
  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "phoneNo": phoneNo,
        "createdDate": createdDate.millisecondsSinceEpoch ~/ 1000,
        "email": email,
      };

  @override
  int get hashCode => Object.hash(id, name, phoneNo, createdDate);

  @override
  bool operator ==(Object other) {
    if (other is! Customer) return false;
    return id == other.id &&
        name == other.name &&
        createdDate == other.createdDate &&
        phoneNo.toSet().intersection(other.phoneNo.toSet()).isNotEmpty;
  }

  Customer copyWith({
    String? name,
    List<String>? phoneNo,
    int? createdDate,
    String? email,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phoneNo: phoneNo ?? this.phoneNo,
      createdDate:
          createdDate ?? this.createdDate.millisecondsSinceEpoch ~/ 1000,
      email: email ?? this.email,
    );
  }
}

final class Invoice extends BaseAbstractProduct {
  final Map<int, int> trackIDs;
  final int customerID;
  final DateTime date;
  final double discount;

  Future<List<Disc>> get tracks async {
    List<Disc> r = [];
    for (int track in trackIDs.keys) {
      r.add(await discFromID(track));
    }
    return r;
  }

  Future<Customer> get customer async => await customerFromID(customerID);

  Future<double> get totalPrice async {
    double finalPrice = -discount;
    for (var e in trackIDs.entries) {
      finalPrice += (await discFromID(e.key)).price * e.value;
    }
    return finalPrice;
  }

  Invoice({
    int? id,
    required this.trackIDs,
    required this.customerID,
    required int date,
    this.discount = 0.0,
  })  : date = _epoch(date),
        super(id: id ?? Object.hash(trackIDs, customerID, date));

  Invoice.fromMap(Map data)
      : this(
          id: (data["id"] as int?),
          trackIDs: (data["tracks"] as Map).map((k, v) {
            return MapEntry(int.parse(k), (v as num).toInt());
          }),
          customerID: data["customer"],
          date: data["date"],
          discount: data["discount"] ?? 0,
        );

  Invoice.fromJson(Map data) : this.fromMap(data);

  @override
  Map<String, dynamic> toMap() => {
        "tracks": trackIDs.map((k, v) => MapEntry("$k", v)),
        "customer": customerID,
        "date": date.millisecondsSinceEpoch ~/ 1000,
        "discount": discount,
      };

  Invoice copyWith({
    Map<int, int>? trackIDs,
    int? customerID,
    int? date,
    double? discount,
  }) {
    return Invoice(
      trackIDs: trackIDs ?? this.trackIDs,
      customerID: customerID ?? this.customerID,
      date: date ?? this.date.millisecondsSinceEpoch ~/ 1000,
      discount: discount ?? this.discount,
    );
  }

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) {
    if (other is! Invoice) return false;
    return trackIDs == other.trackIDs &&
        customerID == other.customerID &&
        date == other.date;
  }
}
