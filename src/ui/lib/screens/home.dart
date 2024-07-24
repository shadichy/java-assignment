import 'package:assignment/components/invoice.dart';
import 'package:assignment/components/misc/component.dart';
import 'package:assignment/provider/cart.dart';
import 'package:assignment/screens/tabs/tab_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentTab = 0;
  int _currentSubTab = 0;

  @override
  void initState() {
    super.initState();
    Cart().notifier = () {
      if (mounted) setState(() {});
    };
  }

  void _setTab(int tab, [int? subtab]) {
    setState(() => _currentTab = tab);
    _setSubTab(subtab ?? 0);
  }

  void _setSubTab(int tab) {
    setState(() => _currentSubTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    List<SectionList> tabList = Tabs(context, _setTab).tabList;

    Widget buttonSide(IconData icon, void Function()? onPressed) {
      return Container(
        margin: const EdgeInsets.only(left: 16),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.surfaceContainerHighest,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: c.onSurfaceVariant,
        ),
      );
    }

    return Scaffold(
      body: Row(children: [
        Padding(
          padding: const EdgeInsets.only(top: 44, bottom: 56),
          child: NavigationRail(
            selectedIndex: _currentTab,
            onDestinationSelected: _setTab,
            leading: Column(children: [
              IconButton(
                icon: const Icon(
                  Symbols.menu,
                  size: 24,
                ),
                onPressed: () {},
              ),
              FloatingActionButton(
                elevation: 0,
                onPressed: () => showInvoiceDialog(
                  context: context,
                  callback: () => _setTab(1),
                ),
                backgroundColor: c.tertiaryContainer,
                child: Badge(
                  label: Cart().isEmpty
                      ? null
                      : Text(
                          "${Cart().length}",
                          style: t.labelSmall?.copyWith(color: c.onPrimary),
                        ),
                  child: Icon(
                    Symbols.shopping_cart,
                    size: 24,
                    color: c.onTertiaryContainer,
                  ),
                ),
              ),
              const Separator(height: 40),
            ]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Symbols.home),
                label: Text("Home"),
              ),
              NavigationRailDestination(
                icon: Icon(Symbols.database),
                label: Text("Storage"),
              ),
              NavigationRailDestination(
                icon: Icon(Symbols.payment),
                label: Text("Invoices"),
              ),
              NavigationRailDestination(
                icon: Icon(Symbols.people),
                label: Text("Customers"),
              ),
              NavigationRailDestination(
                icon: Icon(Symbols.settings),
                label: Text("Settings"),
              ),
            ],
          ),
        ),
        NavigationDrawer(
          selectedIndex: _currentSubTab,
          onDestinationSelected: _setSubTab,
          children: tabList[_currentTab].key,
        ),
        Fill(Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            Row(children: [
              Fill(SearchAnchor(
                builder: (context, controller) => SearchBar(
                  controller: controller,
                  leading: IconButton(
                    icon: const Icon(Symbols.menu),
                    onPressed: () {},
                  ),
                  trailing: [
                    IconButton(
                      icon: const Icon(Symbols.search),
                      onPressed: () {},
                    )
                  ],
                  hintText: "Search",
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.all(
                    c.surfaceContainerHighest,
                  ),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  )),
                ),
                suggestionsBuilder: (context, controller) => [
                  Tooltip(),
                ],
              )),
              buttonSide(Symbols.settings, () => _setTab(4)),
              buttonSide(Symbols.person, () => _setTab(4, 2)),
            ]),
            const Separator(height: 32),
            tabList[_currentTab].value[_currentSubTab]
          ]),
        )),
      ]),
    );
  }
}
