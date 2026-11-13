part of '../../ogurets.dart';

class GherkinTable extends IterableBase<Map<dynamic, dynamic>> {
  final String _spacer = "\t\t  ";

  final List<String> _columnNames = [];
  final List<Map> _table = [];

  @override
  Iterator<Map<dynamic, dynamic>> get iterator => _table.iterator;

  @override
  int get length => _table.length;

  bool get empty => _table.isEmpty;

  bool get isValid => _columnNames.isNotEmpty;

  List<String> get names => _columnNames;

  void addRow(List<String> row) {
    if (_columnNames.isEmpty) {
      _columnNames.addAll(row);
    } else {
      _table.add(Map.fromIterables(_columnNames, row));
    }
  }

  /// Adds [rows] keyed by [header]. The first header added becomes [names];
  /// later headers (e.g. from additional `Examples` blocks) only key their own rows.
  void _addRows(List<String> header, Iterable<List<String>> rows) {
    if (_columnNames.isEmpty) {
      _columnNames.addAll(header);
    }
    for (final row in rows) {
      _table.add(Map.fromIterables(header, row));
    }
  }

  /// Gherkin table
  List<String> gherkinRows() {
    List<String> rows = [];

    if (_table.isNotEmpty) {
      rows.add("$_spacer|${_columnNames.join(" | ")}|");

      for (var row in _table) {
        rows.add("$_spacer|${row.values.join(" | ")}|");
      }
    }

    return rows;
  }

  @override
  String toString() {
    return _table.toString();
  }
}
