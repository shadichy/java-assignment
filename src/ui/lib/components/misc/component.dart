import 'package:flutter/material.dart';

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
