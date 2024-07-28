import 'package:assignment/components/disc.dart';
import 'package:assignment/components/filter.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/components/table.dart';
import 'package:assignment/provider/extensions.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/provider/product.dart';
import 'package:assignment/provider/settings.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    setViewMode(Settings().viewMode);
  }

  @override
  void dispose() {
    Filters().discFilter = null;
    super.dispose();
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
    return StorageFiltered(filter: DiscFilter(stockLowest: 1));
  }
}

class StorageOutOfStock extends StatelessWidget {
  const StorageOutOfStock({super.key});

  @override
  Widget build(BuildContext context) {
    return StorageFiltered(filter: DiscFilter(stockHighest: 0));
  }
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
    fetch();
  }

  void fetch() {
    setState(() => data = []);
    filter.fetch().then((data) {
      if (mounted) setState(() => this.data = data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Fill(Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () => showDialog<ArtistFilter>(
              context: context,
              builder: (_) => const ArtistFilterDialog(),
            ).then((filter) {
              if (filter == null) return;
              this.filter = filter;
              fetch();
            }),
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
