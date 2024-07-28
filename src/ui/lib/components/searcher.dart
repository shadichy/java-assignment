  import 'dart:async';
import 'package:assignment/components/misc/component.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SearchDialog<T> extends StatefulWidget {
  final Widget? title;
  final String? hintText;
  final Widget Function(
    BuildContext context,
    T item,
    void Function() deleteCallback,
  )? multipleSelectionBuilder;
  final List<T> selections;
  final Widget? Function(BuildContext context, T item) itemBuilder;
  final FutureOr<List<T>> Function(String query) searchMethod;
  const SearchDialog({
    super.key,
    this.title,
    this.multipleSelectionBuilder,
    this.selections = const [],
    required this.itemBuilder,
    required this.searchMethod,
    this.hintText,
  });

  @override
  State<SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<SearchDialog<T>> {
  List<T> items = [];
  late Set<T> selections = widget.selections.toSet();
  late bool hasMultiple = widget.multipleSelectionBuilder != null;

  Future<void> onSearch(String query) async {
    items = await widget.searchMethod(query);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    onSearch("");
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    return SimpleDialog(
      title: widget.title,
      titleTextStyle: t.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      titlePadding: const EdgeInsets.fromLTRB(32.0, 24.0, 32.0, 0.0),
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.only(bottom: 8),
          height: 64,
          child: TextField(
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              prefixIcon: const Icon(Symbols.search),
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide(color: c.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide(color: c.outline),
              ),
            ),
            onChanged: onSearch,
          ),
        ),
        if (hasMultiple)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selections.map((e) {
                return widget.multipleSelectionBuilder!(context, e, () {
                  setState(() => selections.remove(e));
                });
              }).toList(),
            ),
          ),
        SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          width: MediaQuery.of(context).size.width * .8,
          child: ListView.builder(
            itemBuilder: (context, index) {
              return SimpleDialogOption(
                onPressed: (hasMultiple)
                    ? () => setState(() => selections.add(items[index]))
                    : () => Navigator.of(context).pop(items[index]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: widget.itemBuilder(context, items[index]),
                ),
              );
            },
            itemCount: items.length,
            shrinkWrap: true,
          ),
        ),
        if (hasMultiple)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
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
              const VerticalSeparator(width: 16),
              TextButton(
                onPressed: () => Navigator.pop(context, selections.toList()),
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
              const VerticalSeparator(width: 16),
            ],
          ),
      ],
    );
  }
}
