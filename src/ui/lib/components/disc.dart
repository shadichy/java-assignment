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
            image: image ?? Disc.defaultImage,
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
