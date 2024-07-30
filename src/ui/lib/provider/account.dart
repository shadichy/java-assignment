import 'dart:convert';
import 'package:assignment/provider/product.dart';
import 'package:http/http.dart';

final class Data {
  Data._();
  static final _i = Data._();
  factory Data() {
    return _i;
  }

  String hostname = "localhost";

  late final String username;
  late final String password;
  late final int httpPort;
  late final int httpsPort;
  late final int pid;

  final List<Artist> _artists = [];
  final List<Disc> _discs = [];
  final List<Customer> _customers = [];
  final List<Invoice> _invoices = [];

  List<Artist> get getArtists => _artists;
  List<Disc> get getDiscs => _discs;
  List<Customer> get getCustomers => _customers;
  List<Invoice> get getInvoices => _invoices;

  void init(String username, String password, int port, int pid) {
    this.username = username;
    this.password = password;
    httpPort = port;
    httpsPort = port + 1000;
    this.pid = pid;
  }

  String get encode =>
      'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  void addToCache<T extends BaseAbstractProduct>(
    dynamic origData,
    dynamic response,
    String path,
  ) {
    List<T> db = (switch (path) {
      "artist" => _artists,
      "disc" => _discs,
      "customer" => _customers,
      "invoice" => _invoices,
      _ => throw ClientException("Invalid path"),
    })
        .cast();

    Iterable<int> ids = db.map((e) => e.id);
    db.addAll((response is Map ? [response] : (response as List).cast<Map>())
        .map(switch (path) {
          "artist" => Artist.fromMap,
          "disc" => Disc.fromMap,
          "customer" => Customer.fromMap,
          "invoice" => Invoice.fromMap,
          _ => throw ClientException("Invalid path"),
        })
        .where((e) => !ids.contains(e.id))
        .cast());
  }

  Future fetch(Map body) async {
    var response = jsonDecode((await post(Uri.https("$hostname:$httpsPort"),
            headers: {"Authorization": encode}, body: jsonEncode(body)))
        .body);

    if (body["method"] == "get") {
      addToCache(body["data"], response, body["path"]);
    }

    return response;
  }
}
