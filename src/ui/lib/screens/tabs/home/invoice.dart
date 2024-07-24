import 'package:assignment/components/disc.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/provider/product.dart';
import 'package:flutter/material.dart';

class HomeInvoice extends StatelessWidget {
  const HomeInvoice({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return Fill(Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.outline,
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: CrossStartColumn([
            DiscExtendedCard(Disc(
              id: 0,
              name: 'Em hat ai nghe',
              releaseDate: 0,
              artistIDs: [1, 2],
              stockCount: 10,
              price: 100,
              image: Image.network(
                "https://i.ytimg.com/vi/wssbBe_t-r4/maxresdefault.jpg",
              ).image,
            )),
            TextButton(onPressed: () {}, child: const Text("Add item")),
          ],
        ),
      ),
    ));
  }
}
