import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Separator extends StatelessWidget {
  final double height;
  const Separator({super.key, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.transparent,
      height: height,
    );
  }
}

class VerticalSeparator extends StatelessWidget {
  final double width;
  const VerticalSeparator({super.key, this.width = 4});

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      color: Colors.transparent,
      width: width,
    );
  }
}

class Fill extends Expanded {
  const Fill(Widget child, {super.key, super.flex}) : super(child: child);
}

class CrossStartColumn extends Column {
  CrossStartColumn(
    Iterable<Widget> children, {
    super.key,
    super.mainAxisSize,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
  }) : super(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.toList(),
        );
}

class CrossStartRow extends Row {
  CrossStartRow(
    Iterable<Widget> children, {
    super.key,
    super.mainAxisSize,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
  }) : super(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.toList(),
        );
}

class TableRows {
  final BuildContext context;
  late final ThemeData _d;
  late final ColorScheme _c;
  late final OutlineInputBorder inputBorder;

  TableRows(this.context) {
    _d = Theme.of(context);
    _c = _d.colorScheme;
    inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(width: 1, color: _c.outline),
    );
  }

  TableRow textFiled(
    String header, {
    String? defaultText,
    TextInputType? keyboardType,
    void Function(String value)? onChanged,
  }) {
    return TableRow(children: [
      Container(
        alignment: Alignment.centerLeft,
        height: 60,
        padding: const EdgeInsets.only(right: 32),
        child: Text(header),
      ),
      TextFormField(
        initialValue: defaultText,
        keyboardType: keyboardType,
        decoration: InputDecoration(border: inputBorder),
        onChanged: onChanged,
      ),
    ]);
  }

  TableRow functional(
    String header,
    String content, {
    void Function()? onTap,
  }) {
    return TableRow(children: [
      Container(
        alignment: Alignment.centerLeft,
        height: 60,
        padding: const EdgeInsets.only(right: 32),
        child: Text(header),
      ),
      Row(children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(Symbols.edit, color: _c.onSurfaceVariant),
        ),
        const VerticalDivider(width: 8),
        Text(content),
      ]),
    ]);
  }
}
