import 'package:assignment/components/graph.dart';
import 'package:assignment/screens/tabs/storage/filtered.dart';

class Settings {
  Settings._();
  static final Settings _s = Settings._();
  factory Settings() => _s;

  GraphView graphView = GraphView.month;

  ViewMode viewMode = ViewMode.icon;
}
