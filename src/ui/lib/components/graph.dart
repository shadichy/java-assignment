// import 'package:fl_chart_app/presentation/resources/app_resources.dart';
import 'package:assignment/provider/product.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

final class _GraphViewData {
  final double maxRows;
  final double maxColumns;
  final List<FlSpot> data;
  final _GraphViewMode mode;
  const _GraphViewData._({
    required this.maxColumns,
    required this.maxRows,
    required this.mode,
    required this.data,
  });

  static Future<_GraphViewData> _static(
    _GraphViewMode mode,
    List<Invoice> iDataSample,
  ) async {
    double maxRows;
    double maxColumns;
    final List<FlSpot> data;
    final int maxTime;
    final List<Invoice> iData = List.of(iDataSample);
    switch (mode) {
      case _GraphViewMode.week:
        maxColumns = 7;
        maxTime = 86400 * 7;
        break;

      case _GraphViewMode.month:
        maxColumns = 4;
        maxTime = 86400 * 30;
        break;

      case _GraphViewMode.year:
        maxColumns = 12;
        maxTime = 86400 * 365;
        break;
    }
    const int pointsPerGap = 8;
    final int timeGap = (maxTime ~/ maxColumns) ~/ pointsPerGap;
    DateTime now = DateTime.now();
    int c = maxColumns.ceil() * pointsPerGap;
    // List<List<Invoice>> chunked = List.generate(maxColumns, (_) => []);
    data = [];
    while (c-- > 0) {
      now = now.subtract(Duration(seconds: timeGap));
      // chunked[c].addAll(_iData.where((e) => e.date.isAfter(now)));
      double total = 0;
      for (var e in iData.where((e) => e.date.isAfter(now))) {
        total += await e.totalPrice;
      }
      data.add(FlSpot(c / pointsPerGap, total));
      iData.removeWhere((e) => e.date.isAfter(now));
    }
    maxRows = 0;
    for (var s in data) {
      if (s.y > maxRows) maxRows = s.y;
    }

    return _GraphViewData._(
      maxColumns: maxColumns,
      maxRows: maxRows,
      mode: mode,
      data: data,
    );
  }
}

enum _GraphViewMode { week, month, year }

final class GraphView {
  // final int maxRows;
  // final int maxColumn;
  // List<Invoice> data;
  final _GraphViewMode _mode;
  const GraphView._(this._mode);
  Future<_GraphViewData> _getData(List<Invoice> data) async =>
      await _GraphViewData._static(_mode, data);

  int get index => _mode.index;
  String get name => _mode.name;

  int get days => switch (_mode) {
        _GraphViewMode.week => 7,
        _GraphViewMode.month => 30,
        _GraphViewMode.year => 365,
      };

  static GraphView week = const GraphView._(_GraphViewMode.week);
  static GraphView month = const GraphView._(_GraphViewMode.month);
  static GraphView year = const GraphView._(_GraphViewMode.year);

  static final List<GraphView> values = [week, month, year];

  @override
  int get hashCode => Object.hash(_mode, 0);

  @override
  bool operator ==(Object other) {
    return (other is GraphView) ? _mode == other._mode : false;
  }
}

class GraphLineChart extends StatefulWidget {
  final GraphView view;
  final List<Invoice> data;
  const GraphLineChart({super.key, required this.view, required this.data});

  @override
  State<GraphLineChart> createState() => _GraphLineChartState();
}

class _GraphLineChartState extends State<GraphLineChart> {
  late final _GraphViewData _data;
  bool init = false;

  @override
  void initState() {
    super.initState();
    (() async {
      _GraphViewData d = await widget.view._getData(widget.data);
      setState(() {
        _data = d;
        init = true;
      });
    })();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData d = Theme.of(context);
    ColorScheme c = d.colorScheme;
    TextTheme t = d.textTheme;
    if (!init) return const SizedBox();
    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      TextStyle? style = t.bodyLarge;
      int v = value.toInt();

      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 1,
        child: switch (widget.view._mode) {
          _GraphViewMode.week => switch (v) {
              0 => Text("Sun", style: style),
              2 => Text("Tue", style: style),
              4 => Text("Thu", style: style),
              6 => Text("Sat", style: style),
              _ => const SizedBox(),
            },
          _GraphViewMode.month => switch (v) {
              0 => Text("W1", style: style),
              1 => Text("W2", style: style),
              2 => Text("W3", style: style),
              3 => Text("W4", style: style),
              _ => const SizedBox(),
            },
          _GraphViewMode.year => switch (v) {
              1 => Text("FEB", style: style),
              4 => Text("MAY", style: style),
              7 => Text("AUG", style: style),
              10 => Text("NOV", style: style),
              _ => const SizedBox(),
            },
        },
      );
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.tertiaryContainer,
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: 1,
              getTitlesWidget: bottomTitleWidgets,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              // getTitlesWidget: leftTitleWidgets,
              showTitles: true,
              interval: _data.maxRows / 5,
              reservedSize: 60,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: c.onSurface, width: 1),
            left: const BorderSide(color: Colors.transparent),
            right: const BorderSide(color: Colors.transparent),
            top: const BorderSide(color: Colors.transparent),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _data.data,
            isCurved: true,
            color: c.tertiary,
            barWidth: 4,
            // isStrokeCapRound: true,
            curveSmoothness: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: 0,
        maxX: _data.maxColumns,
        maxY: _data.maxRows,
        minY: 0,
      ),
      // switch (view) {
      //   GraphView.week => weekViewData,
      //   GraphView.month => sampleData2,
      //   GraphView.year => sampleData2,
      // },
      curve: Curves.ease,
      duration: const Duration(milliseconds: 250),
    );
  }
}
