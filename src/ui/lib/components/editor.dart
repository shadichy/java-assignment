import 'dart:async';

import 'package:assignment/components/disc.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/components/searcher.dart';
import 'package:assignment/provider/account.dart';
import 'package:assignment/provider/extensions.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class DiscEditor extends StatefulWidget {
  final Disc? disc;
  final void Function(Disc disc) callback;
  final void Function(int id)? removeCallback;
  const DiscEditor(
    this.disc, {
    super.key,
    required this.callback,
    this.removeCallback,
  });

  @override
  State<DiscEditor> createState() => _DiscEditorState();
}

class _DiscEditorState extends State<DiscEditor> {
  List<Artist> artists = [];
  List<String> artistNames = [];

  late Disc disc = widget.disc ??
      Disc(
        id: -1,
        name: "",
        releaseDate: 0,
        artistIDs: [],
        stockCount: 0,
        price: 0,
      );

  int count = 1;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    setArtist();
  }

  void setArtist() async {
    artists = await disc.artists;
    artistNames = artists.map((e) => e.name).toList();
    if (mounted) setState(() {});
  }

  void setDisc({
    String? name,
    int? releaseDate,
    List<int>? artistIDs,
    int? stockCount,
    double? price,
    String? image,
  }) {
    if (name == null &&
        releaseDate == null &&
        artistIDs == null &&
        stockCount == null &&
        price == null &&
        image == null) return;

    disc = disc.copyWith(
      name: name,
      releaseDate: releaseDate,
      artistIDs: artistIDs,
      stockCount: stockCount,
      price: price,
      image: image,
    );
    widget.callback(disc);
    artistIDs == null ? setState(() {}) : setArtist();
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

    return Flexible(
      fit: FlexFit.loose,
      child: CrossStartRow(
        [
          DiscImage(image: widget.disc?.image, size: 240),
          const VerticalDivider(width: 32),
          Fill(Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              createRow(
                "Track name",
                defaultText: disc.name,
                onChanged: (s) => setDisc(name: s),
              ),
              rawTextEdit(
                "Artists",
                artistNames.join(", "),
                onTap: () => showDialog<List<Artist>>(
                  context: context,
                  builder: (_) => SearchDialog<Artist>(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(),
                        Text(
                          "Search Artist",
                          style: t.bodyLarge?.apply(
                            color: c.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const ArtistAddDialog(),
                          ),      
                          icon: Icon(
                            Symbols.add,
                            color: c.tertiary,
                          ),
                        )
                      ],
                    ),
                    itemBuilder: (_, item) => Text(item.name),
                    selections: artists,
                    multipleSelectionBuilder: (_, i, cb) => Chip(
                      label: Text(i.name),
                      onDeleted: cb,
                    ),
                    searchMethod: (q) async =>
                        await ArtistFilter(name: q).fetch(),
                  ),
                ).then((v) {
                  if (v == null) return;
                  setDisc(artistIDs: v.map((e) => e.id).toList());
                }),
              ),
              createRow(
                "Image",
                defaultText: disc.imageURL,
                onChanged: (s) => setDisc(image: s),
              ),
              rawTextEdit(
                "Release date",
                DateFormat("dd/MM/yyyy").format(disc.releaseDate),
                onTap: () => showDatePicker(
                  context: context,
                  firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                  lastDate: DateTime.now(),
                ).then((date) {
                  if (mounted && date != null) {
                    setState(() {
                      setDisc(
                        releaseDate: date.millisecondsSinceEpoch ~/ 1000,
                      );
                    });
                  }
                }),
              ),
              createRow(
                "Stock count",
                defaultText: "${disc.stockCount}",
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setDisc(stockCount: int.tryParse(value) ?? 0);
                },
              ),
              createRow(
                "Price",
                defaultText: "${disc.price}",
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setDisc(price: double.tryParse(value) ?? 0.0);
                },
              ),
              if (widget.removeCallback != null)
                TableRow(children: [
                  TextButton(
                    onPressed: () => widget.removeCallback!(disc.id),
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
          ))
        ],
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }
}

class SingleDiscEditDialog extends StatefulWidget {
  final Disc disc;
  const SingleDiscEditDialog({super.key, required this.disc});

  @override
  State<SingleDiscEditDialog> createState() => _SingleDiscEditDialogState();
}

class _SingleDiscEditDialogState extends State<SingleDiscEditDialog> {
  late Disc disc = widget.disc;
  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Edit disc"),
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Symbols.close),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(disc),
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
            await Data().fetch({
              "method": "update",
              "path": "disc",
              "data": disc,
            }).then((r) => print(r));
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
            "Done",
            style: t.bodyMedium?.apply(
              color: c.onPrimaryContainer,
            ),
          ),
        ),
      ],
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 800,
        child: DiscEditor(
          widget.disc,
          callback: (disc) => setState(() => this.disc = disc),
          removeCallback: (id) async {
            await Data().fetch({
              "method": "delete",
              "path": "disc",
              "id": disc.id,
            }).then((r) => print(r));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class DiscAddDialog extends StatefulWidget {
  const DiscAddDialog({super.key});

  @override
  State<DiscAddDialog> createState() => _DiscAddDialogState();
}

class _DiscAddDialogState extends State<DiscAddDialog> {
  List<Disc?> discs = [
    Disc(
      id: 0,
      name: "",
      releaseDate: 0,
      artistIDs: [],
      stockCount: 0,
      price: 0,
    )
  ];
  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Add discs"),
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Symbols.close),
          )
        ],
      ),
      actions: [
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
            await Data().fetch({
              "method": "add",
              "path": "disc",
              "data": discs.where((d) => d != null).toList()
            }).then((r) => print(r));
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
            "Done",
            style: t.bodyMedium?.apply(
              color: c.onPrimaryContainer,
            ),
          ),
        ),
      ],
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 800,
        height: 400,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ...discs.where((e) => e != null).map<Widget>((e) {
              return DiscEditor(
                e,
                // showRemove: true,
                callback: (disc) => setState(() => discs[disc.id] = disc),
                removeCallback: (id) => setState(() => discs[id] = null),
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
                  onPressed: () => setState(() {
                    discs.add(Disc(
                      id: discs.length,
                      name: "",
                      releaseDate: 0,
                      artistIDs: [],
                      stockCount: 0,
                      price: 0,
                    ));
                  }),
                  label: Text(
                    "Add disc",
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
    );
  }
}

class ArtistEditor extends StatefulWidget {
  final Artist? artist;
  final void Function(Artist artist) callback;
  final FutureOr<void> Function(int id)? removeCallback;
  const ArtistEditor({
    super.key,
    this.artist,
    required this.callback,
    this.removeCallback,
  });

  @override
  State<ArtistEditor> createState() => _ArtistEditorState();
}

class _ArtistEditorState extends State<ArtistEditor> {
  late Artist artist = widget.artist ?? Artist(id: -1, name: "", albums: {});
  List<MapEntry<String, List<Disc>>> albums = [];

  void setAlbums() async {
    albums.clear();
    for (var e in artist.albums.entries) {
      var k = e.key, v = e.value;
      List<Disc> ds = [];
      for (var d in v) {
        try {
          ds.add(await discFromID(d));
        } catch (_) {}
      }
      albums.add(MapEntry(k, ds));
    }
    if (mounted) setState(() {});
  }

  void setArtist({
    String? name,
    List<MapEntry<String, List<Disc>>>? albums,
    int? debutDate,
    String? description,
  }) {
    artist = artist.copyWith(
      name: name,
      debutDate: debutDate,
      description: description,
    );
    if (albums != null) {
      artist = artist.copyWith(
        albums: Map.fromEntries(
          albums.map((e) => MapEntry(e.key, e.value.map((d) => d.id).toList())),
        ),
      );
    }
    widget.callback(artist);
    albums == null ? setState(() {}) : setAlbums();
  }

  @override
  void initState() {
    super.initState();
    setAlbums();
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

    return Flexible(
      fit: FlexFit.loose,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        children: [
          createRow(
            "Artist name",
            defaultText: artist.name,
            onChanged: (s) => setArtist(name: s),
          ),
          createRow(
            "Description",
            defaultText: artist.description,
            onChanged: (s) => setArtist(description: s),
          ),
          rawTextEdit(
            "Debut date",
            DateFormat("dd/MM/yyyy").format(artist.debutDate),
            onTap: () => showDatePicker(
              context: context,
              firstDate: DateTime.fromMillisecondsSinceEpoch(0),
              lastDate: DateTime.now(),
            ).then((date) {
              if (!mounted || date == null) return;
              setArtist(debutDate: date.millisecondsSinceEpoch ~/ 1000);
            }),
          ),
          TableRow(children: [
            const Text("Albums"),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: albums.map<Widget>((e) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                      children: [
                    IconButton(
                      onPressed: () => setArtist(albums: albums..remove(e)),
                      icon: Icon(
                        Symbols.close,
                        color: c.error,
                      ),
                    ),
                    IconButton(
                      onPressed: () => showDialog<List<Disc>>(
                        context: context,
                        builder: (_) {
                          return SearchDialog<Disc>(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(),
                                Text(
                                  "Search Disc",
                                  style: t.bodyLarge?.apply(
                                    color: c.onSurface,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => const DiscAddDialog(),
                                  ),
                                  icon: Icon(
                                    Symbols.add,
                                    color: c.tertiary,
                                  ),
                                )
                              ],
                            ),
                            itemBuilder: (_, i) => Text(i.name),
                            searchMethod: (q) async =>
                                await DiscFilter(name: q).fetch(),
                            selections: e.value,
                            multipleSelectionBuilder: (_, i, cb) => Chip(
                              label: Text(i.name),
                              onDeleted: cb,
                            ),
                          );
                        },
                      ).then((value) {
                        if (value == null) return;
                        albums[albums.indexOf(e)] = (MapEntry(e.key, value));
                        setArtist(albums: albums);
                      }),
                      icon: Icon(
                        Symbols.edit,
                        color: c.tertiary,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: e.key,
                        decoration: InputDecoration(border: outlineInputBorder),
                        onChanged: (v) {
                          albums[albums.indexOf(e)] = (MapEntry(v, e.value));
                          setArtist(albums: albums);
                        },
                      ),
                    ),
                    Text(e.value.map((e) => e.name).join(", ")),
                  ].separatedBy(const VerticalSeparator(width: 8)).toList()),
                );
              }).toList()
                ..add(IconButton(
                  onPressed: () {
                    albums.add(const MapEntry("key", []));
                    setArtist(albums: albums);
                  },
                  icon: Icon(
                    Symbols.add,
                    color: c.tertiary,
                  ),
                )),
            )
          ]),
          if (widget.removeCallback != null)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton(
                  onPressed: () => widget.removeCallback!(artist.id),
                  style: TextButton.styleFrom(
                      backgroundColor: c.tertiaryContainer,
                      padding: const EdgeInsets.all(16)),
                  child: Text(
                    "Remove",
                    style: t.bodyMedium?.apply(color: c.onTertiaryContainer),
                  ),
                ),
              ),
              const SizedBox(),
            ]),
        ],
      ),
    );
  }
}

class SingleArtistEditDialog extends StatefulWidget {
  final Artist artist;
  const SingleArtistEditDialog({super.key, required this.artist});

  @override
  State<SingleArtistEditDialog> createState() => _SingleArtistEditDialogState();
}

class _SingleArtistEditDialogState extends State<SingleArtistEditDialog> {
  late Artist artist = widget.artist;
  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Edit artist"),
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Symbols.close),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(artist),
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
            await Data().fetch({
              "method": "update",
              "path": "artist",
              "data": artist,
            }).then((r) => print(r));
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
            "Done",
            style: t.bodyMedium?.apply(
              color: c.onPrimaryContainer,
            ),
          ),
        ),
      ],
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 600,
        child: ArtistEditor(
          artist: widget.artist,
          callback: (artist) => setState(() => this.artist = artist),
          removeCallback: (id) async {
            await Data().fetch({
              "method": "delete",
              "path": "artist",
              "id": artist.id,
            }).then((r) => print(r));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class ArtistAddDialog extends StatefulWidget {
  const ArtistAddDialog({super.key});

  @override
  State<ArtistAddDialog> createState() => _ArtistAddDialogState();
}

class _ArtistAddDialogState extends State<ArtistAddDialog> {
  List<Artist?> artists = [
    Artist(
      id: 0,
      name: "",
      albums: {},
    )
  ];
  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Add artists"),
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Symbols.close),
          )
        ],
      ),
      actions: [
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
            await Data().fetch({
              "method": "add",
              "path": "artist",
              "data": artists.where((d) => d != null).toList()
            }).then((r) => print(r));
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
            "Done",
            style: t.bodyMedium?.apply(
              color: c.onPrimaryContainer,
            ),
          ),
        ),
      ],
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 600,
        height: 400,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ...artists.where((e) => e != null).map<Widget>((e) {
              return ArtistEditor(
                artist: e,
                // showRemove: true,
                callback: (a) => setState(() => artists[a.id] = a),
                removeCallback: (id) => setState(() => artists[id] = null),
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
                  onPressed: () => setState(() {
                    artists.add(Artist(
                      id: artists.length,
                      name: "",
                      albums: {},
                    ));
                  }),
                  label: Text(
                    "Add artist",
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
    );
  }
}

class CustomerEditor extends StatefulWidget {
  final Customer? customer;
  final void Function(Customer customer) callback;
  final void Function(int id)? removeCallback;
  final bool isAdd;
  const CustomerEditor({
    super.key,
    this.customer,
    required this.callback,
    this.removeCallback,
    this.isAdd = false,
  });

  @override
  State<CustomerEditor> createState() => _CustomerEditorState();
}

class _CustomerEditorState extends State<CustomerEditor> {
  late Customer customer = widget.customer ??
      Customer(
        id: -1,
        name: "",
        phoneNo: [],
        createdDate:
            widget.isAdd ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : 0,
      );

  void setCustomer({
    String? name,
    List<String>? phoneNo,
    int? createdDate,
    String? email,
  }) {
    setState(() {
      customer = customer.copyWith(
        name: name,
        phoneNo: phoneNo,
        createdDate: createdDate,
        email: email,
      );
    });
    widget.callback(customer);
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

    return Flexible(
      fit: FlexFit.loose,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        children: [
          createRow(
            "Customer name",
            defaultText: customer.name,
            onChanged: (s) => setCustomer(name: s),
          ),
          createRow(
            "Email",
            defaultText: customer.email,
            onChanged: (s) => setCustomer(email: s),
          ),
          if (!widget.isAdd)
            rawTextEdit(
              "Create date",
              DateFormat("dd/MM/yyyy").format(customer.createdDate),
              onTap: () => showDatePicker(
                context: context,
                firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                lastDate: DateTime.now(),
              ).then((date) {
                if (!mounted || date == null) return;
                setCustomer(createdDate: date.millisecondsSinceEpoch ~/ 1000);
              }),
            ),
          TableRow(children: [
            const Text("Phone numbers"),
            CrossStartColumn(
              customer.phoneNo.map<Widget>((e) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    IconButton(
                      onPressed: () => setState(() {
                        setCustomer(phoneNo: customer.phoneNo..removeLast());
                      }),
                      icon: Icon(
                        Symbols.close,
                        color: c.error,
                      ),
                    ),
                    const VerticalSeparator(width: 8),
                    SizedBox(
                      width: 240,
                      child: TextFormField(
                        initialValue: e,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(border: outlineInputBorder),
                        // onChanged: (v)=>,
                      ),
                    ),
                  ]),
                );
              }).toList()
                ..add(IconButton(
                  onPressed: () => setState(() {
                    setCustomer(phoneNo: customer.phoneNo..add(""));
                  }),
                  icon: Icon(
                    Symbols.add,
                    color: c.tertiary,
                  ),
                )),
              mainAxisSize: MainAxisSize.min,
            )
          ]),
          if (widget.removeCallback != null)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton(
                  onPressed: () => widget.removeCallback!(customer.id),
                  style: TextButton.styleFrom(
                      backgroundColor: c.tertiaryContainer,
                      padding: const EdgeInsets.all(16)),
                  child: Text(
                    "Remove",
                    style: t.bodyMedium?.apply(color: c.onTertiaryContainer),
                  ),
                ),
              ),
              const SizedBox(),
            ]),
        ],
      ),
    );
  }
}

class SingleCustomerEditDialog extends StatefulWidget {
  final Customer customer;
  const SingleCustomerEditDialog({super.key, required this.customer});

  @override
  State<SingleCustomerEditDialog> createState() =>
      _SingleCustomerEditDialogState();
}

class _SingleCustomerEditDialogState extends State<SingleCustomerEditDialog> {
  late Customer customer = widget.customer;
  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Edit customer"),
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Symbols.close),
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(customer),
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
            await Data().fetch({
              "method": "update",
              "path": "customer",
              "data": customer,
            }).then((r) => print(r));
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
            "Done",
            style: t.bodyMedium?.apply(
              color: c.onPrimaryContainer,
            ),
          ),
        ),
      ],
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 600,
        child: CustomerEditor(
          customer: widget.customer,
          callback: (customer) => setState(() => this.customer = customer),
          removeCallback: (id) async {
            await Data().fetch({
              "method": "delete",
              "path": "customer",
              "id": customer.id,
            }).then((r) => print(r));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class CustomerAddDialog extends StatefulWidget {
  const CustomerAddDialog({super.key});

  @override
  State<CustomerAddDialog> createState() => _CustomerAddDialogState();
}

class _CustomerAddDialogState extends State<CustomerAddDialog> {
  List<Customer?> customers = [
    Customer(
      id: 0,
      name: "",
      phoneNo: [],
      createdDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    )
  ];
  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Add customers"),
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Symbols.close),
          )
        ],
      ),
      actions: [
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
            await Data().fetch({
              "method": "add",
              "path": "customer",
              "data": customers.where((d) => d != null).toList()
            }).then((r) => print(r));
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
            "Done",
            style: t.bodyMedium?.apply(
              color: c.onPrimaryContainer,
            ),
          ),
        ),
      ],
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 600,
        height: 400,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ...customers.where((e) => e != null).map<Widget>((e) {
              return CustomerEditor(
                customer: e,
                isAdd: true,
                callback: (a) => setState(() => customers[a.id] = a),
                removeCallback: (id) => setState(() => customers[id] = null),
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
                  onPressed: () => setState(() {
                    customers.add(Customer(
                      id: customers.length,
                      name: "",
                      phoneNo: [],
                      createdDate:
                          DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    ));
                  }),
                  label: Text(
                    "Add customer",
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
    );
  }
}
