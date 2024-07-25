import 'package:assignment/components/disc.dart';
import 'package:assignment/components/editor.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/provider/account.dart';
import 'package:assignment/provider/cart.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiscTableRow {
  /// An identifier for the row.
  final LocalKey? key;

  /// A decoration to paint behind this row.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  final Decoration? decoration;

  final Disc disc;

  const DiscTableRow({
    this.key,
    this.decoration,
    required this.disc,
  });

  Future<TableRow> build(BuildContext context) async {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;

    return TableRow(
      key: key,
      decoration: decoration,
      children: [
        // Text(disc.id.toString()),
        DiscImage(image: disc.image, size: 64),
        Text(disc.name),
        // Text((await disc.artists).map((e) => e.name).join(", ")),
        CrossStartColumn(
          (await disc.artists).map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(e.name),
            );
          }),
          mainAxisSize: MainAxisSize.min,
        ),
        Text(DateFormat("dd/MM/yyyy").format(disc.releaseDate)),
        Text(disc.stockCount.toString()),
        Text(disc.price.toString()),
        TextButton(
          onPressed: () {
            if (disc.stockCount == 0) return;
            Cart().addToCart(disc);
          },
          style: TextButton.styleFrom(
            backgroundColor: c.tertiaryContainer,
          ),
          child: Text(
            "Invoice",
            style: t.bodyMedium?.apply(color: c.onTertiaryContainer),
          ),
        ),
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => SingleDiscEditDialog(disc: disc),
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: c.secondaryContainer,
          ),
          child: Text(
            "Edit",
            style: t.bodyMedium?.apply(color: c.onSecondaryContainer),
          ),
        ),
      ].map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: e,
        );
      }).toList(),
    );
  }
}

class DiscTable extends StatefulWidget {
  final List<DiscTableRow> children;
  const DiscTable({super.key, this.children = const []});

  @override
  State<DiscTable> createState() => _DiscTableState();
}

class _DiscTableState extends State<DiscTable> {
  List<TableRow> children = [];
  bool locked = false;

  @override
  Widget build(BuildContext context) {
    if (mounted && !locked) {
      setState(() => locked = true);
      (() async {
        for (var e in widget.children) {
          children.add(await e.build(context));
        }
        setState(() {});
      })();
    }

    return Fill(SingleChildScrollView(
      child: Table(
        // border: TableBorder(bottom: BorderSide(color: c.outlineVariant)),
        columnWidths: const {
          // 0: IntrinsicColumnWidth(),
          0: FixedColumnWidth(64),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
          4: IntrinsicColumnWidth(),
          5: IntrinsicColumnWidth(),
          6: FixedColumnWidth(100),
          7: FixedColumnWidth(100),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              // const Text("ID"),
              const SizedBox(),
              const Text("Name"),
              const Text("Artists"),
              const Text("Date"),
              const Text("In stock"),
              const Text("Price"),
              const SizedBox(),
              const SizedBox(),
            ].map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: e,
              );
            }).toList(),
          ),
          ...children,
        ],
      ),
    ));
  }
}

class InvoiceTableRow {
  /// An identifier for the row.
  final LocalKey? key;

  /// A decoration to paint behind this row.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  final Decoration? decoration;

  final Invoice invoice;

  InvoiceTableRow({
    this.key,
    this.decoration,
    required this.invoice,
  });

  Future<TableRow> build(BuildContext context) async {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;

    return TableRow(
      key: key,
      decoration: decoration,
      children: [
        // Text(invoice.id.toString()),
        Text((await invoice.customer).name),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: invoice.trackIDs.values.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text("${e}x"),
            );
          }).toList(),
        ),
        CrossStartColumn(
          (await invoice.tracks).map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(e.name),
            );
          }),
          mainAxisSize: MainAxisSize.min,
        ),
        Text(DateFormat("dd/MM/yyyy").format(invoice.date)),
        TextButton(
          onPressed: () => showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm deletion"),
              content: Text("Invoice ${invoice.id} will be deleted"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(color: c.tertiary),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: t.bodyMedium?.apply(color: c.tertiary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: c.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    "Confirm",
                    style: t.bodyMedium?.apply(color: c.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ).then((b) async {
            await Data().fetch({
              "method": "remove",
              "path": "invoice",
              "id": invoice.id,
            });
          }),
          style: TextButton.styleFrom(
            backgroundColor: c.tertiaryContainer,
          ),
          child: Text(
            "Remove",
            style: t.bodyMedium?.apply(color: c.onTertiaryContainer),
          ),
        ),
      ].map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: e,
        );
      }).toList(),
    );
  }
}

class InvoiceTable extends StatefulWidget {
  final List<InvoiceTableRow> children;
  const InvoiceTable({super.key, this.children = const []});

  @override
  State<InvoiceTable> createState() => _InvoiceTableState();
}

class _InvoiceTableState extends State<InvoiceTable> {
  List<TableRow> children = [];
  bool locked = false;

  @override
  Widget build(BuildContext context) {
    if (mounted && !locked) {
      setState(() => locked = true);
      (() async {
        for (var e in widget.children) {
          children.add(await e.build(context));
        }
        setState(() {});
      })();
    }

    return Fill(SingleChildScrollView(
      child: Table(
        // border: TableBorder(bottom: BorderSide(color: c.outlineVariant)),
        columnWidths: const {
          // 0: IntrinsicColumnWidth(),
          0: IntrinsicColumnWidth(),
          1: FixedColumnWidth(100),
          3: IntrinsicColumnWidth(),
          4: FixedColumnWidth(100),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              // const Text("ID"),
              const Text("Customer"),
              const SizedBox(),
              const Text("Discs"),
              const Text("Date"),
              const SizedBox(),
            ].map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: e,
              );
            }).toList(),
          ),
          ...children,
        ],
      ),
    ));
  }
}

class CustomerTableRow {
  /// An identifier for the row.
  final LocalKey? key;

  /// A decoration to paint behind this row.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  final Decoration? decoration;

  final Customer customer;

  const CustomerTableRow({
    this.key,
    this.decoration,
    required this.customer,
  });

  Future<TableRow> build(BuildContext context) async {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;

    return TableRow(
      key: key,
      decoration: decoration,
      children: [
        // Text(customer.id.toString()),
        // CustomerImage(image: customer.image, size: 64),
        Text(customer.name),
        Text(customer.email),
        // Text((await customer.artists).map((e) => e.name).join(", ")),
        CrossStartColumn(
          customer.phoneNo.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(e),
            );
          }),
          mainAxisSize: MainAxisSize.min,
        ),
        Text(DateFormat("dd/MM/yyyy").format(customer.createdDate)),
        // Text(customer.stockCount.toString()),
        // Text(customer.price.toString()),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            backgroundColor: c.tertiaryContainer,
          ),
          child: Text(
            "History",
            style: t.bodyMedium?.apply(color: c.onTertiaryContainer),
          ),
        ),
        TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => SingleCustomerEditDialog(customer: customer),
          ),
          style: TextButton.styleFrom(
            backgroundColor: c.secondaryContainer,
          ),
          child: Text(
            "Edit",
            style: t.bodyMedium?.apply(color: c.onSecondaryContainer),
          ),
        ),
      ].map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: e,
        );
      }).toList(),
    );
  }
}

class CustomerTable extends StatefulWidget {
  final List<CustomerTableRow> children;
  const CustomerTable({super.key, this.children = const []});

  @override
  State<CustomerTable> createState() => _CustomerTableState();
}

class _CustomerTableState extends State<CustomerTable> {
  List<TableRow> children = [];
  bool locked = false;

  @override
  Widget build(BuildContext context) {
    if (mounted && !locked) {
      setState(() => locked = true);
      (() async {
        for (var e in widget.children) {
          children.add(await e.build(context));
        }
        setState(() {});
      })();
    }

    return Fill(SingleChildScrollView(
      child: Table(
        // border: TableBorder(bottom: BorderSide(color: c.outlineVariant)),
        columnWidths: const {
          // 0: IntrinsicColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: IntrinsicColumnWidth(),
          3: IntrinsicColumnWidth(),
          4: FixedColumnWidth(100),
          5: FixedColumnWidth(100),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              // const Text("ID"),
              const Text("Name"),
              const Text("Email"),
              const Text("Phone numbers"),
              const Text("Created date"),
              const SizedBox(),
              const SizedBox(),
            ].map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: e,
              );
            }).toList(),
          ),
          ...children,
        ],
      ),
    ));
  }
}

class ArtistTableRow {
  /// An identifier for the row.
  final LocalKey? key;

  /// A decoration to paint behind this row.
  ///
  /// Row decorations fill the horizontal and vertical extent of each row in
  /// the table, unlike decorations for individual cells, which might not fill
  /// either.
  final Decoration? decoration;

  final Artist artist;

  const ArtistTableRow({
    this.key,
    this.decoration,
    required this.artist,
  });

  Future<TableRow> build(BuildContext context) async {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;

    List<String> albums = artist.albums.keys.toList();
    albums.remove("uncategoried");

    return TableRow(
      key: key,
      decoration: decoration,
      children: [
        // Text(artist.id.toString()),
        // ArtistImage(image: artist.image, size: 64),
        Text(artist.name),
        Text(artist.description),
        // Text((await artist.artists).map((e) => e.name).join(", ")),
        Text(DateFormat("dd/MM/yyyy").format(artist.debutDate)),
        CrossStartColumn(
          albums.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(e),
            );
          }),
          mainAxisSize: MainAxisSize.min,
        ),
        // Text(artist.stockCount.toString()),
        // Text(artist.price.toString()),
        TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => SingleArtistEditDialog(artist: artist),
          ),
          style: TextButton.styleFrom(
            backgroundColor: c.tertiaryContainer,
          ),
          child: Text(
            "Edit",
            style: t.bodyMedium?.apply(color: c.onTertiaryContainer),
          ),
        ),
        TextButton(
          onPressed: () => showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm deletion"),
              content: Text(
                  "Artist ${artist.id} and related tracks will be deleted"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(color: c.tertiary),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: t.bodyMedium?.apply(color: c.tertiary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: c.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    "Confirm",
                    style: t.bodyMedium?.apply(color: c.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ).then((b) async {
            await Data().fetch({
              "method": "remove",
              "path": "artist",
              "id": artist.id,
            });
          }),
          style: TextButton.styleFrom(
            backgroundColor: c.secondaryContainer,
          ),
          child: Text(
            "Remove",
            style: t.bodyMedium?.apply(color: c.onSecondaryContainer),
          ),
        ),
      ].map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: e,
        );
      }).toList(),
    );
  }
}

class ArtistTable extends StatefulWidget {
  final List<ArtistTableRow> children;
  const ArtistTable({super.key, this.children = const []});

  @override
  State<ArtistTable> createState() => _ArtistTableState();
}

class _ArtistTableState extends State<ArtistTable> {
  List<TableRow> children = [];
  bool locked = false;

  @override
  Widget build(BuildContext context) {
    if (mounted && !locked) {
      setState(() => locked = true);
      (() async {
        for (var e in widget.children) {
          children.add(await e.build(context));
        }
        setState(() {});
      })();
    }

    return Fill(SingleChildScrollView(
      child: Table(
        // border: TableBorder(bottom: BorderSide(color: c.outlineVariant)),
        columnWidths: const {
          // 0: IntrinsicColumnWidth(),
          0: IntrinsicColumnWidth(),
          1: FixedColumnWidth(200),
          2: IntrinsicColumnWidth(),
          4: FixedColumnWidth(100),
          6: FixedColumnWidth(100),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              // const Text("ID"),
              const Text("Name"),
              const Text("Description"),
              const Text("Debut date"),
              const Text("Albums"),
              const SizedBox(),
              const SizedBox(),
            ].map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: e,
              );
            }).toList(),
          ),
          ...children,
        ],
      ),
    ));
  }
}
