import 'package:assignment/components/editor.dart';
import 'package:assignment/components/filter.dart';
import 'package:assignment/components/invoice.dart';
import 'package:assignment/provider/filter.dart';
import 'package:assignment/screens/tabs/home/summary.dart';
import 'package:assignment/screens/tabs/invoices/filtered.dart';
import 'package:assignment/screens/tabs/customers/filtered.dart';
import 'package:assignment/screens/tabs/settings/about.dart';
import 'package:assignment/screens/tabs/settings/appearance.dart';
import 'package:assignment/screens/tabs/settings/common.dart';
import 'package:assignment/screens/tabs/settings/personal.dart';
import 'package:assignment/screens/tabs/storage/filtered.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

final class SectionList {
  final List<Widget> key, value;
  SectionList(this.key, this.value)
      : assert(
          key.whereType<NavigationDrawerDestination>().length <= value.length,
          "Length of key destinations and values must be the same",
        );
}

final class Tabs {
  late final List<SectionList> tabList;
  final void Function(int tab, [int? subtab]) tabCallback;

  Tabs(BuildContext context, this.tabCallback) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;

    Widget filterButton(void Function()? onPressed) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton.icon(
          onPressed: onPressed,
          label: Text(
            "Filter",
            style: t.bodyLarge?.apply(color: c.tertiary),
          ),
          icon: const Icon(Symbols.filter_alt),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(64),
              side: BorderSide(width: 1, color: c.outline),
            ),
            iconColor: c.tertiary,
            padding: const EdgeInsets.all(20),
          ),
        ),
      );
    }

    tabList = [
      SectionList([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text("Home"),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Symbols.monitoring),
          label: Text("Summary"),
        ),
        ListTile(
          leading: const Icon(Symbols.north_east),
          title: const Text("Create invoice"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          onTap: () => showInvoiceDialog(
            context: context,
            callback: () => tabCallback(1),
          ),
        ),
        ListTile(
          leading: const Icon(Symbols.import_export),
          title: const Text("Import new CDs"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          onTap: () => showDialog(
            context: context,
            builder: (context) => const DiscAddDialog(),
          ),
        ),
      ], [
        const HomeSummary(),
        // const HomeInvoice(),
        // const HomeImport(),
      ]),
      SectionList([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text("Storage"),
        ),
        filterButton(
          () => showDialog<DiscFilter>(
            context: context,
            builder: (_) => const DiscFilterDialog(),
          ).then((filter) {
            if (filter == null) return;
            Filters().discFilter = filter;
            tabCallback(1, 3);
          }),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Symbols.all_match),
          label: Text("All"),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Symbols.event_available),
          label: Text("In stock"),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Symbols.outbound),
          label: Text("Out of stock"),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Symbols.filter),
          label: const Text("Filtered"),
          enabled: Filters().discFilter != null,
        ),
        ListTile(
          leading: const Icon(Symbols.add),
          title: const Text("Add discs"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          onTap: () => showDialog(
            context: context,
            builder: (_) => const DiscAddDialog(),
          ),
        ),
        Divider(
          height: 24,
          thickness: 1,
          indent: 24,
          endIndent: 24,
          color: c.outlineVariant,
        ),
        const NavigationDrawerDestination(
          icon: Icon(Symbols.outbound),
          label: Text("Artist data"),
        ),
        ListTile(
          leading: const Icon(Symbols.add),
          title: const Text("Add artists"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          onTap: () => showDialog(
            context: context,
            builder: (_) => const ArtistAddDialog(),
          ),
        ),
      ], [
        const StorageNoFilter(),
        const StorageInStock(),
        // SizedBox(),
        const StorageOutOfStock(),
        StorageFiltered(filter: Filters().discFilter),
        const ArtistFiltered(),
      ]),
      SectionList([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text("Invoices"),
        ),
        filterButton(
          () => showDialog<InvoiceFilter>(
            context: context,
            builder: (_) => const InvoiceFilterDialog(),
          ).then((filter) {
            if (filter == null) return;
            Filters().invoiceFilter = filter;
            tabCallback(2, 1);
          }),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Symbols.all_match),
          label: Text("All"),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Symbols.filter),
          label: const Text("Filtered"),
          enabled: Filters().invoiceFilter != null,
        ),
        ListTile(
          leading: const Icon(Symbols.north_east),
          title: const Text("Create invoice"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          onTap: () => showInvoiceDialog(
            context: context,
            callback: () => tabCallback(1),
          ),
        ),
      ], [
        const InvoicesNoFilter(),
        InvoicesFiltered(filter: Filters().invoiceFilter),
      ]),
      SectionList([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text("Customers"),
        ),
        filterButton(
          () => showDialog<CustomerFilter>(
            context: context,
            builder: (_) => const CustomerFilterDialog(),
          ).then((filter) {
            if (filter == null) return;
            Filters().customerFilter = filter;
            tabCallback(2, 1);
          }),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Symbols.all_match),
          label: Text("All"),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Symbols.filter),
          label: const Text("Filtered"),
          enabled: Filters().customerFilter != null,
        ),
        ListTile(
          leading: const Icon(Symbols.add),
          title: const Text("Add customer"),
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          onTap: () => showDialog(
            context: context,
            builder: (_) => const CustomerAddDialog(),
          ),
        ),
      ], [
        const CustomersNoFilter(),
        CustomersFiltered(filter: Filters().customerFilter),
      ]),
      SectionList(const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text("Settings"),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.all_match),
          label: Text("Common"),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.filter),
          label: Text("Appearance"),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.person),
          label: Text("Personal"),
        ),
        NavigationDrawerDestination(
          icon: Icon(Symbols.info),
          label: Text("About"),
        ),
      ], [
        const SettingsCommon(),
        const SettingsAppearance(),
        const SettingsPersonal(),
        const SettingsAbout(),
      ])
    ];
  }
}
