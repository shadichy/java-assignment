import 'package:assignment/components/editor.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/provider/cart.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class DiscImage extends StatelessWidget {
  final ImageProvider? image;
  final double size;
  const DiscImage({super.key, this.size = 240, this.image});

  @override
  Widget build(BuildContext context) {
    ColorScheme c = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size / 8),
      child: Container(
        padding: EdgeInsets.all(11 * size / 60),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: image ??
                const NetworkImage(
                    "data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20width='32'%20height='32'%3E%3Cdefs%3E%3Cstyle%20type='text/css'%3E@font-face%20{%20font-family:%20'Material%20Symbols%20Outlined';%20src:%20url%28https://fonts.gstatic.com/s/materialsymbolsoutlined/v190/kJEhBvYX7BgnkSrUwT8OhrdQw4oELdPIeeII9v6oFsI.woff2%29%20format%28'woff2'%29;}%20text%20{font-family:'Material%20Symbols%20Outlined';%20font-size:%2032px;%20text-anchor:%20middle;%20dominant-baseline:%20text-bottom;%20fill:%20grey;}%3C/style%3E%3C/defs%3E%3Ctext%20xmlns='http://www.w3.org/2000/svg'%20x='50%'%20y='100%'%3E&%23xe019;%3C/text%3E%3C/svg%3E|width=32,height=32"),
            fit: BoxFit.cover,
          ),
          border: Border.all(width: size / 24, color: c.outline),
        ),
        child: Container(
          padding: EdgeInsets.all(7 * size / 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.outlineVariant,
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface,
              border: Border.all(width: size / 24, color: c.outline),
            ),
          ),
        ),
      ),
    );
  }
}

class DiscCard extends StatefulWidget {
  final Disc disc;
  const DiscCard(this.disc, {super.key});

  @override
  State<DiscCard> createState() => _DiscCardState();
}

class _DiscCardState extends State<DiscCard> {
  List<String> artistNames = [];
  MenuController ctl = MenuController();

  @override
  void initState() {
    super.initState();
    (() async {
      artistNames.addAll((await widget.disc.artists).map((e) => e.name));
      setState(() {});
    })();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return SizedBox(
      width: 240,
      child: Card.outlined(
        child: Column(children: [
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(children: [
              Positioned(
                top: 16,
                left: 16,
                child: CrossStartColumn([
                  Text("Stock: ", style: t.bodySmall),
                  Text(
                    "${widget.disc.stockCount}",
                    style: t.bodyLarge?.copyWith(
                      color: c.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: MenuAnchor(
                  controller: ctl,
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => SingleDiscEditDialog(
                            disc: widget.disc,
                          ),
                        );
                        ctl.close();
                      },
                      child: const Text("Edit"),
                    ),
                    MenuItemButton(
                      onPressed: () {
                        ctl.close();
                      },
                      child: const Text("Delete"),
                    ),
                  ],
                  child: IconButton(
                    onPressed: () => ctl.isOpen ? ctl.close() : ctl.open(),
                    icon: const Icon(Symbols.more_vert),
                  ),
                ),
              ),
              DiscImage(size: 240, image: widget.disc.image)
            ]),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            horizontalTitleGap: 10,
            title: Text(
              widget.disc.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(artistNames.join(', ')),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            // alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "\$${widget.disc.price}/CD",
                  style: t.bodyLarge?.copyWith(
                    color: c.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (widget.disc.stockCount == 0) return;
                    Cart().addToCart(widget.disc);
                  },
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(width: 1, color: c.outline),
                    ),
                  ),
                  child: Text(
                    "Invoice",
                    style: t.bodyMedium?.copyWith(color: c.primary),
                  ),
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }
}

class DiscExtendedCard extends StatefulWidget {
  final Disc disc;
  final bool baseEditable;
  const DiscExtendedCard(
    this.disc, {
    super.key,
    this.baseEditable = false,
  });

  @override
  State<DiscExtendedCard> createState() => _DiscExtendedCardState();
}

class _DiscExtendedCardState extends State<DiscExtendedCard> {
  late final Disc disc = widget.disc;
  late List<Artist> artists = [];

  @override
  void initState() {
    super.initState();
    (() async {
      List<Artist> artists = await disc.artists;
      setState(() => this.artists = artists);
    })();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    TableRow textBlock(String title, String content, [bool editable = false]) {
      return TableRow(
        children: [
          Text(title),
          const VerticalSeparator(width: 10),
          editable
              ? TextField(
                  decoration: InputDecoration(
                    hintText: content,
                    labelText: content,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(width: 1, color: c.outline),
                    ),
                  ),
                )
              : Text(content)
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          child: DiscImage(image: disc.image, size: 240),
        ),
        Fill(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("title"),
              const Divider(height: 32, color: Colors.transparent),
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(120),
                  1: FixedColumnWidth(10),
                },
                children: [
                  textBlock("Track name", disc.name, widget.baseEditable),
                  textBlock("Artists", artists.map((e) => e.name).join(", ")),
                  textBlock("Release date", disc.releaseDate.toString()),
                  textBlock("In stock", "${disc.stockCount}"),
                  textBlock("Price/CD", "\$${disc.price}"),
                ],
              ),
              const Text("History"),
            ],
          ),
        )
      ],
    );
  }
}
