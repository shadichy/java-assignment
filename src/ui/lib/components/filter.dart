import 'package:assignment/components/misc/component.dart';
import 'package:assignment/components/searcher.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class FilterDialog<T extends Filter> extends StatelessWidget {
  final List<TableRow> children;
  final T filter;
  const FilterDialog({
    super.key,
    required this.filter,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return AlertDialog(
      title: const Text("Filter invoices"),
      content: SizedBox(
        width: 600,   
        child: Table(
          columnWidths: const {0: IntrinsicColumnWidth()},
          children: children,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(color: c.outline),
            ),
          ),
          onPressed: Navigator.of(context).pop,
          child: Text(
            "Cancel",
            style: t.bodyMedium?.apply(
              color: c.onSurface,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, filter),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            backgroundColor: c.primaryContainer,
          ),
          child: Text(
            "Done",
            style: t.bodyMedium?.apply(
              color: c.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

class ArtistFilterDialog extends StatefulWidget {
  const ArtistFilterDialog({super.key});

  @override
  State<ArtistFilterDialog> createState() => _ArtistFilterDialogState();
}

class _ArtistFilterDialogState extends State<ArtistFilterDialog> {
  ArtistFilter filter = ArtistFilter.all;
  List<Disc> hasTracks = [];

  Future<void> setDisc() async {
    for (var d in filter.hasTracks) {
      hasTracks.add(await discFromID(d));
    }
    if (mounted) setState(() {});
  }

  void setFilter({
    List<String>? hasAlbums,
    List<int>? hasTracks,
    String? name,
    String? description,
    DateTime? debutBefore,
    DateTime? debutAfter,
  }) {
    setState(() {
      filter = filter.copyWith(
        hasAlbums: hasAlbums,
        hasTracks: hasTracks,
        name: name,
        description: description,
        debutBefore: debutBefore,
        debutAfter: debutAfter,
      );
    });
    if (hasTracks != null) setDisc();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    TableRows tableRowData = TableRows(context);

    var outlineInputBorder = tableRowData.inputBorder;

    TableRow Function(
      String,
      String, {
      void Function()? onTap,
    }) rawTextEdit = tableRowData.functional;

    TableRow Function(
      String, {
      String? defaultText,
      TextInputType? keyboardType,
      void Function(String)? onChanged,
    }) createRow = tableRowData.textFiled;

    return FilterDialog(filter: filter, children: [
      createRow("Name: ", onChanged: (v) => setFilter(name: v)),
      createRow("Description: ", onChanged: (v) => setFilter(description: v)),
      rawTextEdit(
        "Debut after: ",
        filter.debutAfter == null
            ? ""
            : DateFormat("dd/MM/yyyy").format(filter.debutAfter!),
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastDate: DateTime.now(),
        ).then((date) {
          if (!context.mounted || date == null) return;
          setFilter(debutAfter: date);
        }),
      ),
      rawTextEdit(
        "Debut before: ",
        filter.debutBefore == null
            ? ""
            : DateFormat("dd/MM/yyyy").format(filter.debutBefore!),
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastDate: DateTime.now(),
        ).then((date) {
          if (!context.mounted || date == null) return;
          setFilter(debutBefore: date);
        }),
      ),
      rawTextEdit(
        "Has tracks: ",
        hasTracks.map((e) => e.name).join(", "),
        onTap: () => showDialog<List<Disc>>(
          context: context,
          builder: (_) => SearchDialog<Disc>(
            title: Text(
              "Search Disc",
              style: t.bodyLarge?.apply(
                color: c.onSurface,
              ),
            ),
            itemBuilder: (_, item) => Text(item.name),
            selections: hasTracks,
            multipleSelectionBuilder: (_, i, cb) => Chip(
              label: Text(i.name),
              onDeleted: cb,
            ),
            searchMethod: (q) async => await DiscFilter(name: q).fetch(),
          ),
        ).then((v) {
          if (v == null) return;
          setFilter(hasTracks: v.map((e) => e.id).toList());
        }),
      ),
      TableRow(children: [
        const Text("Albums"),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: filter.hasAlbums.map<Widget>((e) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                IconButton(
                  onPressed: () {
                    filter.hasAlbums.remove(e);
                    setFilter();
                  },
                  icon: Icon(
                    Symbols.close,
                    color: c.error,
                  ),
                ),
                const VerticalSeparator(width: 8),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: e,
                    decoration: InputDecoration(border: outlineInputBorder),
                    onChanged: (v) {
                      filter.hasAlbums[filter.hasAlbums.indexOf(e)] = v;
                      setFilter();
                    },
                  ),
                ),
              ]),
            );
          }).toList()
            ..add(IconButton(
              onPressed: () {
                filter.hasAlbums.add("");
                setFilter();
              },
              icon: Icon(
                Symbols.add,
                color: c.tertiary,
              ),
            )),
        )
      ]),
    ]);
  }
}

class DiscFilterDialog extends StatefulWidget {
  const DiscFilterDialog({super.key});

  @override
  State<DiscFilterDialog> createState() => _DiscFilterDialogState();
}

class _DiscFilterDialogState extends State<DiscFilterDialog> {
  DiscFilter filter = DiscFilter.all;
  List<Artist> hasArtists = [];

  Future<void> setArtist() async {
    for (var d in filter.hasArtists) {
      hasArtists.add(await artistFromID(d));
    }
    if (mounted) setState(() {});
  }

  void setFilter({
    String? name,
    DateTime? releaseBefore,
    DateTime? releaseAfter,
    int? stockHighest,
    int? stockLowest,
    double? priceHighest,
    double? priceLowest,
    List<int>? hasArtists,
  }) {
    setState(() {
      filter = filter.copyWith(
        name: name,
        releaseBefore: releaseBefore,
        releaseAfter: releaseAfter,
        stockHighest: stockHighest,
        stockLowest: stockLowest,
        priceHighest: priceHighest,
        priceLowest: priceLowest,
        hasArtists: hasArtists,
      );
    });
    if (hasArtists != null) setArtist();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    TableRows tableRowData = TableRows(context);

    TableRow Function(
      String,
      String, {
      void Function()? onTap,
    }) rawTextEdit = tableRowData.functional;

    TableRow Function(
      String, {
      String? defaultText,
      TextInputType? keyboardType,
      void Function(String)? onChanged,
    }) createRow = tableRowData.textFiled;

    return FilterDialog(filter: filter, children: [
      createRow("Name: ", onChanged: (v) => setFilter(name: v)),
      rawTextEdit(
        "Release after: ",
        filter.releaseAfter == null
            ? ""
            : DateFormat("dd/MM/yyyy").format(filter.releaseAfter!),
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastDate: DateTime.now(),
        ).then((date) {
          if (!context.mounted || date == null) return;
          setFilter(releaseAfter: date);
        }),
      ),
      rawTextEdit(
        "Release before: ",
        filter.releaseBefore == null
            ? ""
            : DateFormat("dd/MM/yyyy").format(filter.releaseBefore!),
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastDate: DateTime.now(),
        ).then((date) {
          if (!context.mounted || date == null) return;
          setFilter(releaseBefore: date);
        }),
      ),
      createRow(
        "Min in stock: ",
        onChanged: (v) => setFilter(stockLowest: int.tryParse(v)),
      ),
      createRow(
        "Max in stock: ",
        onChanged: (v) => setFilter(stockHighest: int.tryParse(v)),
      ),
      createRow(
        "Lowest price: ",
        onChanged: (v) => setFilter(priceLowest: double.tryParse(v)),
      ),
      createRow(
        "Highest price: ",
        onChanged: (v) => setFilter(priceHighest: double.tryParse(v)),
      ),
      rawTextEdit(
        "Has artist: ",
        hasArtists.map((e) => e.name).join(", "),
        onTap: () => showDialog<List<Artist>>(
          context: context,
          builder: (_) => SearchDialog<Artist>(
            title: Text(
              "Search Artist",
              style: t.bodyLarge?.apply(
                color: c.onSurface,
              ),
            ),
            itemBuilder: (_, item) => Text(item.name),
            selections: hasArtists,
            multipleSelectionBuilder: (_, i, cb) => Chip(
              label: Text(i.name),
              onDeleted: cb,
            ),
            searchMethod: (q) async => await ArtistFilter(name: q).fetch(),
          ),
        ).then((v) {
          if (v == null) return;
          setFilter(hasArtists: v.map((e) => e.id).toList());
        }),
      ),
    ]);
  }
}

class InvoiceFilterDialog extends StatefulWidget {
  const InvoiceFilterDialog({super.key});

  @override
  State<InvoiceFilterDialog> createState() => _InvoiceFilterDialogState();
}

class _InvoiceFilterDialogState extends State<InvoiceFilterDialog> {
  InvoiceFilter filter = InvoiceFilter.all;
  List<Disc> hasDiscs = [];
  List<Customer> hasCustomers = [];

  Future<void> setDisc() async {
    for (var d in filter.hasDiscs) {
      hasDiscs.add(await discFromID(d));
    }
    if (mounted) setState(() {});
  }

  Future<void> setCustomer() async {
    for (var d in filter.hasCustomers) {
      hasCustomers.add(await customerFromID(d));
    }
    if (mounted) setState(() {});
  }

  void setFilter({
    List<int>? hasDiscs,
    List<int>? hasCustomers,
    DateTime? before,
    DateTime? after,
  }) {
    setState(() {
      filter = filter.copyWith(
        hasDiscs: hasDiscs,
        hasCustomers: hasCustomers,
        before: before,
        after: after,
      );
    });
    if (hasDiscs != null) setDisc();
    if (hasCustomers != null) setCustomer();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    TableRows tableRowData = TableRows(context);

    TableRow Function(
      String,
      String, {
      void Function()? onTap,
    }) rawTextEdit = tableRowData.functional;

    return FilterDialog(filter: filter, children: [
      rawTextEdit(
        "Has discs: ",
        hasDiscs.map((e) => e.name).join(", "),
        onTap: () => showDialog<List<Disc>>(
          context: context,
          builder: (_) => SearchDialog<Disc>(
            title: Text(
              "Search Disc",
              style: t.bodyLarge?.apply(
                color: c.onSurface,
              ),
            ),
            itemBuilder: (_, item) => Text(item.name),
            selections: hasDiscs,
            multipleSelectionBuilder: (_, i, cb) => Chip(
              label: Text(i.name),
              onDeleted: cb,
            ),
            searchMethod: (q) async => await DiscFilter(name: q).fetch(),
          ),
        ).then((v) {
          if (v == null) return;
          setFilter(hasDiscs: v.map((e) => e.id).toList());
        }),
      ),
      rawTextEdit(
        "Has customers: ",
        hasCustomers.map((e) => e.name).join(", "),
        onTap: () => showDialog<List<Customer>>(
          context: context,
          builder: (_) => SearchDialog<Customer>(
            title: Text(
              "Search Customer",
              style: t.bodyLarge?.apply(
                color: c.onSurface,
              ),
            ),
            itemBuilder: (_, item) => Text(item.name),
            selections: hasCustomers,
            multipleSelectionBuilder: (_, i, cb) => Chip(
              label: Text(i.name),
              onDeleted: cb,
            ),
            searchMethod: (q) async => await CustomerFilter(name: q).fetch(),
          ),
        ).then((v) {
          if (v == null) return;
          setFilter(hasCustomers: v.map((e) => e.id).toList());
        }),
      ),
      rawTextEdit(
        "Transacs after: ",
        filter.after == null
            ? ""
            : DateFormat("dd/MM/yyyy").format(filter.after!),
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastDate: DateTime.now(),
        ).then((date) {
          if (!context.mounted || date == null) return;
          setFilter(after: date);
        }),
      ),
      rawTextEdit(
        "Transacs before: ",
        filter.before == null
            ? ""
            : DateFormat("dd/MM/yyyy").format(filter.before!),
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastDate: DateTime.now(),
        ).then((date) {
          if (!context.mounted || date == null) return;
          setFilter(before: date);
        }),
      ),
    ]);
  }
}

class CustomerFilterDialog extends StatefulWidget {
  const CustomerFilterDialog({super.key});

  @override
  State<CustomerFilterDialog> createState() => _CustomerFilterDialogState();
}

class _CustomerFilterDialogState extends State<CustomerFilterDialog> {
  CustomerFilter filter = CustomerFilter.all;

  void setFilter({
    String? name,
    String? email,
    List<String>? hasPhones,
    DateTime? createdBefore,
    DateTime? createdAfter,
  }) {
    setState(() {
      filter = filter.copyWith(
        name: name,
        email: email,
        hasPhones: hasPhones,
        createdBefore: createdBefore,
        createdAfter: createdAfter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TableRows tableRowData = TableRows(context);

    var outlineInputBorder = tableRowData.inputBorder;

    TableRow Function(
      String,
      String, {
      void Function()? onTap,
    }) rawTextEdit = tableRowData.functional;

    TableRow Function(
      String, {
      String? defaultText,
      TextInputType? keyboardType,
      void Function(String)? onChanged,
    }) createRow = tableRowData.textFiled;

    return FilterDialog(filter: filter, children: [
      createRow("Name: ", onChanged: (v) => setFilter(name: v)),
      createRow("Email: ", onChanged: (v) => setFilter(email: v)),
      TableRow(children: [
        const Text("Albums"),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: filter.hasPhones.map<Widget>((e) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                IconButton(
                  onPressed: () {
                    filter.hasPhones.remove(e);
                    setFilter();
                  },
                  icon: Icon(
                    Symbols.close,
                    color: c.error,
                  ),
                ),
                const VerticalSeparator(width: 8),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: e,
                    decoration: InputDecoration(border: outlineInputBorder),
                    onChanged: (v) {
                      filter.hasPhones[filter.hasPhones.indexOf(e)] = v;
                      setFilter();
                    },
                  ),
                ),
              ]),
            );
          }).toList()
            ..add(IconButton(
              onPressed: () {
                filter.hasPhones.add("");
                setFilter();
              },
              icon: Icon(
                Symbols.add,
                color: c.tertiary,
              ),
            )),
        )
      ]),
      rawTextEdit(
        "Created after: ",
        filter.createdAfter == null
            ? ""
            : DateFormat("dd/MM/yyyy").format(filter.createdAfter!),
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastDate: DateTime.now(),
        ).then((date) {
          if (!context.mounted || date == null) return;
          setFilter(createdAfter: date);
        }),
      ),
      rawTextEdit(
        "Created before: ",
        filter.createdBefore == null
            ? ""
            : DateFormat("dd/MM/yyyy").format(filter.createdBefore!),
        onTap: () => showDatePicker(
          context: context,
          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
          lastDate: DateTime.now(),
        ).then((date) {
          if (!context.mounted || date == null) return;
          setFilter(createdBefore: date);
        }),
      ),
    ]);
  }
}
