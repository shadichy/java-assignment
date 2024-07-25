import 'package:assignment/components/disc.dart';
import 'package:assignment/components/editor.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/components/searcher.dart';
import 'package:assignment/provider/cart.dart';
import 'package:assignment/provider/extensions.dart';
import 'package:assignment/provider/product.dart';
import 'package:assignment/screens/tabs/customers/filtered.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class _InvoiceDisc extends StatefulWidget {
  final Disc disc;
  final int count;
  final void Function(Disc disc, int count) callback;
  final void Function() updateCallback;
  const _InvoiceDisc._({
    required this.disc,
    required this.count,
    required this.callback,
    required this.updateCallback,
  });

  @override
  State<_InvoiceDisc> createState() => _InvoiceDiscState();
}

class _InvoiceDiscState extends State<_InvoiceDisc> {
  List<String> artists = [];
  late TextEditingController controller;
  int count = 1;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    (() async {
      artists = (await widget.disc.artists).map((e) => e.name).toList();
      if (mounted) setState(() {});
    })();
    _setCountNoCB(widget.count);
    controller = TextEditingController(text: "$count  ");
  }

  void _setCountNoCB(int count) {
    this.count = count;
    setState(() => totalPrice = widget.disc.price * count);
  }

  void setCount(int count) {
    _setCountNoCB(count);
    widget.callback(widget.disc, count);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    var outlineInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: c.outline),
    );
    TableRow createRow(String header, Widget content) {
      return TableRow(children: [
        Container(
          alignment: Alignment.centerLeft,
          height: 40,
          padding: const EdgeInsets.only(right: 32),
          child: Text(header),
        ),
        content,
      ]);
    }

    return Flexible(
      fit: FlexFit.loose,
      child: CrossStartRow(
        [
          DiscImage(image: widget.disc.image, size: 240),
          const VerticalDivider(width: 32),
          Fill(CrossStartColumn([
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              children: [
                createRow("Track name", Text(widget.disc.name)),
                createRow("Artists", Text(artists.join(", "))),
                createRow(
                  "Release date",
                  Text(
                    DateFormat("dd/MM/yyyy").format(widget.disc.releaseDate),
                  ),
                ),
                createRow(
                  "Items",
                  Row(children: [
                    IconButton(
                      onPressed: () {
                        if (count > 0) --count;
                        setState(() => controller.text = "$count");
                        setCount(count);
                      },
                      icon: const Icon(Symbols.arrow_back_ios),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: outlineInputBorder,
                        ),
                        onChanged: (v) =>
                            setState(() => setCount(int.tryParse(v) ?? 0)),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (count < widget.disc.stockCount) ++count;
                        setState(() => controller.text = "$count");
                        setCount(count);
                      },
                      icon: const Icon(Symbols.arrow_forward_ios),
                    ),
                  ]),
                ),
                createRow(
                  "Total price",
                  Text(
                    "\$$totalPrice",
                    style: t.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TableRow(children: [
                  TextButton(
                    onPressed: () {
                      Cart().removeFromCart(widget.disc.id);
                      widget.updateCallback();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: c.tertiaryContainer,
                    ),
                    child: Text(
                      "Remove",
                      style: t.bodyMedium?.apply(color: c.onTertiaryContainer),
                    ),
                  ),
                  const SizedBox(),
                ]),
              ],
            ),
          ]))
        ],
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }
}

class InvoiceDialog extends StatefulWidget {
  // final Iterable<MapEntry<Disc, int>> data;

  final void Function() callback;
  const InvoiceDialog({
    super.key,
    // this.data = const [],
    required this.callback,
  });

  @override
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  Customer? customer = Cart().customer;
  Iterable<MapEntry<Disc, int>> data = Cart().discs;
  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Create invoice"),
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Symbols.close),
          )
        ],
      ),
      actions: [
        // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Total: "),
            const VerticalSeparator(width: 4),
            Text(
              "\$${data.fold(0.0, (p, n) => p + n.key.price * n.value)}",
              style: t.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            )
          ],
        ),
        const VerticalSeparator(width: 8),
        // Row(children: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(color: c.outline),
            ),
          ),
          child: Text(
            "Cancel",
            style: t.bodyMedium?.apply(
              color: c.onSurface,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            if (customer == null) {
              await showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text("No customer specified"),
                  content: Text("Please select an user"),
                ),
              );
              return;
            }
            Cart().customer = customer;
            await Cart().checkout();
            if (context.mounted) Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            backgroundColor: c.primaryContainer,
          ),
          child: Text(
            "Invoice",
            style: t.bodyMedium?.apply(
              color: c.onPrimaryContainer,
            ),
          ),
        ),
        // ])
        // ])
      ],
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 1000,
        height: 400,
        child: Flexible(
          fit: FlexFit.loose,
          child: CrossStartRow(
            [
              SizedBox(
                width: 300,
                child: Column(children: [
                  TextButton(
                    onPressed: () => showDialog<Customer>(
                      context: context,
                      builder: (_) => SearchDialog<Customer>(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(),
                            Text(
                              "Search Customer",
                              style: t.bodyLarge?.apply(
                                color: c.onSurface,
                              ),
                            ),
                            IconButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => const CustomerAddDialog(),
                              ),
                              // style: TextButton.styleFrom(
                              //   padding: const EdgeInsets.all(16),
                              //   shape: RoundedRectangleBorder(
                              //     borderRadius: BorderRadius.circular(32),
                              //     side: BorderSide(color: c.tertiary),
                              //   ),
                              // ),
                              icon: Icon(
                                Symbols.add,
                                color: c.tertiary,
                              ),
                            )
                          ],
                        ),
                        itemBuilder: (_, item) => Text(item.name),
                        searchMethod: (q) async =>
                            await CustomerFilter(name: q).fetch(),
                      ),
                    ).then((value) {
                      if (value == null) return;
                      Cart().customer = value;
                      if (context.mounted) setState(() => customer = value);
                    }),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(64),
                        side: BorderSide(width: 1, color: c.outline),
                      ),
                      iconColor: c.tertiary,
                      padding: const EdgeInsets.all(20),
                    ),
                    child: Text(
                      "Select customer",
                      style: t.bodyLarge?.apply(color: c.tertiary),
                    ),
                  ),
                  const Separator(height: 16),
                  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                    },
                    children: [
                      TableRow(children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Customer name: "),
                        ),
                        Text(customer?.name ?? "")
                      ]),
                      TableRow(children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Email: "),
                        ),
                        Text(customer?.email ?? "")
                      ]),
                      TableRow(children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Phone numbers: "),
                        ),
                        CrossStartColumn(
                            customer?.phoneNo.map((e) => Text(e)) ?? [])
                      ]),
                    ],
                  ),
                ]),
              ),
              VerticalDivider(
                width: 32,
                thickness: 1,
                indent: 32,
                endIndent: 32,
                color: c.outlineVariant,
              ),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ...data.map<Widget>((e) {
                      return _InvoiceDisc._(
                        disc: e.key,
                        count: e.value,
                        callback: Cart().modify,
                        updateCallback: () =>
                            setState(() => data = Cart().discs),
                      );
                    }).separatedBy(Divider(
                      height: 32,
                      thickness: 1,
                      color: c.outlineVariant,
                      indent: 32,
                      endIndent: 32,
                    )),
                    const Separator(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.callback();
                          },
                          label: Text(
                            "Add product",
                            style: t.bodyMedium?.apply(
                              color: c.onSecondaryContainer,
                            ),
                          ),
                          icon: Icon(
                            Symbols.add,
                            color: c.onSecondaryContainer,
                          ),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                              side: BorderSide(color: c.secondaryContainer),
                            ),
                            padding: const EdgeInsets.all(16),
                            backgroundColor: c.secondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
            mainAxisSize: MainAxisSize.min,
          ),
        ),
      ),
    );
  }
}

Future<T?> showInvoiceDialog<T>({
  required BuildContext context,
  required void Function() callback,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
}) async {
  return await showDialog(
    context: context,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
    builder: (context) => InvoiceDialog(callback: callback),
  );
}
