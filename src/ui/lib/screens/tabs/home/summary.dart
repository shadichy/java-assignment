import 'package:assignment/components/disc.dart';
import 'package:assignment/components/graph.dart';
import 'package:assignment/components/invoice.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/provider/account.dart';
import 'package:assignment/provider/product.dart';
import 'package:assignment/provider/settings.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomeSummary extends StatefulWidget {
  const HomeSummary({super.key});

  @override
  State<HomeSummary> createState() => _HomeSummaryState();
}

class _HomeSummaryState extends State<HomeSummary> {
  List<Invoice> data = [];
  Map<int, int> soldByProduct = {};
  Map<int, Disc> productTable = {};
  Map<int, Artist> artistTable = {};
  double revenue = 0;
  double comparison = 0;
  int product = 0;
  List<MapEntry<String, IconData>> chipPair = {
    "1 Week": Symbols.calendar_view_week,
    "1 Month": Symbols.calendar_view_month,
    "1 Year": Symbols.calendar_month,
  }.entries.toList();

  @override
  void initState() {
    super.initState();
    setViewMode(Settings().graphView);
  }

  void setViewMode(GraphView view) {
    Settings().graphView = view;
    int days = view.days;
    DateTime now = DateTime.now();
    setState(() => data = []);
    Data().fetch({
      "method": "get",
      "path": "invoice",
      "after":
          now.subtract(Duration(days: days * 2)).millisecondsSinceEpoch ~/ 1000,
    }).then((r) async {
      if ((r as List).isEmpty) return;
      DateTime thisMonth = now.subtract(Duration(days: days));
      var m = r.map((e) => Invoice.fromMap(e as Map));
      data = m.where((e) => e.date.isAfter(thisMonth)).toList();
      revenue = 0;
      product = 0;
      for (var t in data.fold<List<MapEntry<int, int>>>(
        [],
        (p, n) => [...p, ...n.trackIDs.entries],
      )) {
        var k = t.key, v = t.value;
        soldByProduct[k] = (soldByProduct[k] ?? 0) + v;
        if (productTable[k] == null) {
          Disc d = await discFromID(k);
          productTable[k] = d;
          for (int a in d.artistIDs) {
            if (artistTable[a] != null) continue;
            artistTable[a] = await artistFromID(a);
          }
        }
        revenue += productTable[k]!.price * v;
        product += v; 
      }
      double pRevenue = 0;
      for (var e in m.where((e) => e.date.isBefore(thisMonth))) {
        pRevenue += await e.totalPrice;
      }
      comparison = pRevenue == 0 ? 100 : 100 * revenue / pRevenue;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;

    if (data.isNotEmpty) {
      content = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.outline,
            width: 1,
          ),
        ),
        child: Column(children: [
          Fill(Row(children: [
            Fill(Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: CrossStartColumn([
                  const Text("Sale"),
                  const Separator(height: 4),
                  Text(
                    "Estimated",
                    style: t.bodySmall?.copyWith(
                      color: c.onSurfaceVariant,
                    ),
                  ),
                ]),
              ),
              SizedBox(
                height: 240 ,
                child: GraphLineChart(view: Settings().graphView, data: data),
              ),
            ])),
            Padding(
              padding: const EdgeInsets.all(16),
              child: VerticalDivider(color: c.outlineVariant),
            ),
            SizedBox(
              height: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CrossStartColumn([
                    const Text("Revenue"),
                    Text(
                      "\$${revenue.floor()}",
                      style: t.displayMedium?.copyWith(
                        color: c.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]),
                  CrossStartColumn([
                    const Text("Comparison"),
                    Row(children: [
                      Icon(
                        Symbols.arrow_circle_up,
                        color: c.onPrimaryContainer,
                        size: 40,
                      ),
                      const VerticalSeparator(width: 8),
                      Text(
                        "${comparison.floor()}%",
                        style: t.displayMedium?.copyWith(
                          color: c.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                  ]),
                  CrossStartColumn([
                    const Text("Product sold"),
                    Row(children: [
                      Icon(
                        Symbols.album,
                        color: c.onPrimaryContainer,
                        size: 40,
                      ),
                      const VerticalSeparator(width: 8),
                      Text(
                        "$product",
                        style: t.displayMedium?.copyWith(
                          color: c.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                  ]),
                ],
              ),
            ),
          ])),
          Row(children: [
            Fill(CrossStartColumn([
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text("Most sold"),
              ),
              ListView(
                shrinkWrap: true,
                children: (() {
                  List<MapEntry<int, int>> top = soldByProduct.entries.toList();
                  top.sort((m, n) => n.value.compareTo(m.value));
                  return top.take(2).map((m) {
                    Disc? d = productTable[m.key];
                    if (d == null) return const SizedBox();
                    return ListTile(
                      leading: DiscImage(image: d.image, size: 64),
                      title: Text(d.name),
                      subtitle: Text(d.artistIDs.map((e) {
                        return artistTable[e]?.name ?? "";
                      }).join(", ")),
                    );
                  }).toList();
                })(),
              )
            ])),
            Fill(CrossStartColumn([
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text("Trendings"),
              ),
              ListView(
                shrinkWrap: true,
                children: (() {
                  List<MapEntry<int, double>> top = soldByProduct
                      .map((k, v) =>
                          MapEntry(k, v * (productTable[k]?.price ?? 1.0)))
                      .entries
                      .toList();
                  top.sort((m, n) => n.value.compareTo(m.value));
                  return top.take(2).map((m) {
                    Disc? d = productTable[m.key];
                    if (d == null) return const SizedBox();
                    return ListTile(
                      leading: DiscImage(image: d.image, size: 64),
                      title: Text(d.name),
                      subtitle: Text(d.artistIDs.map((e) {
                        return artistTable[e]?.name ?? "";
                      }).join(", ")),
                    );
                  }).toList();
                })(),
              )
            ])),
          ])
        ]),
      );
    } else {
      content = Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("No data"),
            InkWell(
              onTap: () => showInvoiceDialog(
                context: context,
                callback: () => setViewMode(Settings().graphView),
              ),
              child: Text(
                "Import...",
                style: t.bodyMedium?.apply(color: c.primary),
              ),
            )
          ],
        ),
      );
    }

    return Fill(Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text("Duration: "),
          InkWell(
            onTap: () => showDialog<GraphView>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text("Select view mode"),
                children: List.generate(
                  GraphView.values.length,
                  (i) => ListTile(
                    title: Text(GraphView.values[i].name),
                    leading: Icon(chipPair[i].value),
                    onTap: () => Navigator.of(context).pop(GraphView.values[i]),
                  ),
                ),
              ),
            ).then((d) {
              if (d != null) setViewMode(d);
            }),
            child: Chip(
              label: Text(chipPair[Settings().graphView.index].key),
              avatar: Icon(chipPair[Settings().graphView.index].value),
            ),
          ),
        ],
      ),
      const Separator(height: 16),
      Fill(content)
    ]));
  }
}
