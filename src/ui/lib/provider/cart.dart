import 'package:assignment/provider/account.dart';
import 'package:assignment/provider/product.dart';

final class Cart {
  Cart._();
  static final Cart _c = Cart._();
  factory Cart() => _c;

  void Function()? notifier;

  Customer? customer;
  final Map<int, MapEntry<Disc, int>> _cart = {};

  void addToCart(Disc disc) {
    _cart.putIfAbsent(disc.id, () => MapEntry(disc, 1));
    (notifier ?? () {})();
  }

  void modify(Disc disc, [int? count]) {
    _cart[disc.id] = MapEntry(disc, count ?? 1);
    (notifier ?? () {})();
  }

  void removeFromCart(int id) {
    _cart.remove(id);
    (notifier ?? () {})();
  }

  bool get isEmpty => _cart.isEmpty;
  bool get isNotEmpty => _cart.isNotEmpty;
  int get length => _cart.length;
  Iterable<MapEntry<Disc, int>> get discs => _cart.values;

  Invoice get createInvoice {
    return Invoice(
      trackIDs: _cart.map((_, v) => MapEntry(v.key.id, v.value)),
      customerID: customer!.id,
      date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<void> checkout() async {
    await Data().fetch({
      "method": "add",
      "path": "invoice",
      "data": [createInvoice],
    }).then((r) => print(r));
    _cart.clear();
    customer = null;
    (notifier ?? () {})();
  }
}
