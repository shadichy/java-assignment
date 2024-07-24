
import 'package:assignment/components/disc.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/components/table.dart';
import 'package:assignment/provider/extensions.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/provider/product.dart';
import 'package:assignment/provider/settings.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class DiscFilter extends Filter<Disc>  {
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
}

enum ViewMode { icon, list }

class StorageFiltered extends StatefulWidget {
  final DiscFilter? filter;
  const StorageFiltered({
    super.key,
    this.filter,
  });

  @override
  State<StorageFiltered> createState() => _StorageFilteredState();
}

class _StorageFilteredState extends State<StorageFiltered> {
  late DiscFilter filter = widget.filter ?? DiscFilter.all;
  List<Disc> data = [];
  late String viewModeName;
  late IconData viewModeIcon;

  @override
  void initState() {
    super.initState();
    filter.fetch().then((data) {
      if (mounted) setState(() => this.data = data);
    }); 
    // Data().fetch({
    //   "method": "get",
    //   "path": "disc",
    // }).then((data) {
    //   List<Disc> d = (data as List).cast<Map>().map(Disc.fromMap).toList();
    //   if (filter.name != null) {
    //     d = d.where((e) => e.name.contains(filter.name!)).toList();
    //   }
    //   if (filter.releaseBefore != null) {
    //     d = d.where((e) {
    //       return e.releaseDate.isBefore(filter.releaseBefore!);
    //     }).toList();
    //   }
    //   if (filter.releaseAfter != null) {
    //     d = d.where((e) {
    //       return e.releaseDate.isAfter(filter.releaseAfter!);
    //     }).toList();
    //   }
    //   if (filter.priceHighest != null) {
    //     d = d.where((e) => e.price <= filter.priceHighest!).toList();
    //   }
    //   if (filter.priceLowest != null) {
    //     d = d.where((e) => e.price >= filter.priceLowest!).toList();
    //   }
    //   if (filter.stockHighest != null) {
    //     d = d.where((e) => e.stockCount <= filter.stockHighest!).toList();
    //   }
    //   if (filter.stockLowest != null) {
    //     d = d.where((e) => e.stockCount >= filter.stockLowest!).toList();
    //   }
    //   if (filter.hasArtists.isNotEmpty) {
    //     Set f = filter.hasArtists.toSet();
    //     d = d.where((e) {
    //       return e.artistIDs.toSet().intersection(f).isNotEmpty;
    //     }).toList();
    //   }
    //   if (mounted) setState(() => this.data = d);
    // });
    setViewMode(Settings().viewMode);
  }

  // static Widget viewMode

  void setViewMode(ViewMode mode) {
    setState(() {
      Settings().viewMode = mode;
      switch (mode) {
        case ViewMode.icon:
          viewModeName = "Card";
          viewModeIcon = Symbols.grid_view;
          break;
        case ViewMode.list:
          viewModeName = "List";
          viewModeIcon = Symbols.list;
          break;
        default:
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = data.isEmpty
        ? const SizedBox()
        : Settings().viewMode == ViewMode.icon
            ? Fill(SingleChildScrollView(
                child: CrossStartColumn(
                  data.map((e) => DiscCard(e)).chunked(3).map((e) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: e.toList(),
                    );
                  }),
                ),
              ))
            : DiscTable(
                children: data.map((d) => DiscTableRow(disc: d)).toList(),
              );
    return Fill(Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text("View: "),
          InkWell(
            onTap: () => setViewMode(
              ViewMode.values[-Settings().viewMode.index + 1],
            ),
            child: Chip(
              label: Text(viewModeName),
              avatar: Icon(viewModeIcon),
            ),
          ),
        ],
      ),
      const Separator(height: 16),
      content,
    ]));
  }
}

class StorageNoFilter extends StatelessWidget {
  const StorageNoFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return const StorageFiltered();
  }
}

class StorageInStock extends StatelessWidget {
  const StorageInStock({super.key});

  @override
  Widget build(BuildContext context) {
    return StorageFiltered(filter: DiscFilter(stockLowest: 0));
  }
}

class StorageOutOfStock extends StatelessWidget {
  const StorageOutOfStock({super.key});

  @override
  Widget build(BuildContext context) {
    return StorageFiltered(filter: DiscFilter(stockHighest: 0));
  }
}

class ArtistFilter extends Filter<Artist>  {
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
}

class ArtistFiltered extends StatefulWidget {
  const ArtistFiltered({super.key});

  @override
  State<ArtistFiltered> createState() => _ArtistFilteredState();
}

class _ArtistFilteredState extends State<ArtistFiltered> {
  ArtistFilter filter = ArtistFilter.all;

  List<Artist> data = [];

  @override
  void initState() {
    super.initState();
    // setViewMode(Settings().viewMode);
    fetch();
  }

  void fetch() {
    filter.fetch().then((data) {
      if (mounted) setState(() => this.data = data);
    });
    // Data().fetch({
    //   "method": "get",
    //   "path": "artist",
    // }).then((data) {
    //   List<Artist> d = (data as List).cast<Map>().map(Artist.fromMap).toList();
    //   if (filter.name != null) {
    //     d = d.where((e) => e.name.contains(filter.name!)).toList();
    //   }
    //   if (filter.description != null) {
    //     d = d.where((e) => e.description.contains(filter.name!)).toList();
    //   }
    //   if (filter.debutBefore != null) {
    //     d = d.where((e) {
    //       return e.debutDate.isBefore(filter.debutBefore!);
    //     }).toList();
    //   }
    //   if (filter.debutAfter != null) {
    //     d = d.where((e) {
    //       return e.debutDate.isAfter(filter.debutAfter!);
    //     }).toList();
    //   }
    //   if (filter.hasAlbums.isNotEmpty) {
    //     Set f = filter.hasAlbums.toSet();
    //     d = d.where((e) {
    //       return e.albums.keys.toSet().intersection(f).isNotEmpty;
    //     }).toList();
    //   }
    //   if (filter.hasTracks.isNotEmpty) {
    //     Set f = filter.hasTracks.toSet();
    //     d = d.where((e) {
    //       return e.trackIDs.toSet().intersection(f).isNotEmpty;
    //     }).toList();
    //   }
    //   if (mounted) setState(() => this.data = d);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Fill(Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () {},
            child: const Chip(
              label: Text("Filter"),
              avatar: Icon(Symbols.filter_alt),
            ),
          ),
        ],
      ),
      const Separator(height: 16),
      data.isEmpty
          ? const SizedBox()
          : ArtistTable(
              children: data.map((e) => ArtistTableRow(artist: e)).toList(),
            ),
    ]));
  }
}
