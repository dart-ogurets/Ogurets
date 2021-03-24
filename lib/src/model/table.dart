part of ogurets;

class GherkinTable extends IterableBase<Map<dynamic, dynamic>> {
  final String _SPACER = "\t\t  ";

  List<String> _columnNames = [];
  List<Map> _table = [];

  Iterator<Map<dynamic, dynamic>> get iterator => _table.iterator;

  int get length => _table.length;

  bool get empty => _table.isEmpty;

  bool get isValid => _columnNames.isNotEmpty;

  List<String> get names => _columnNames;

  void addRow(row) {
    if (_columnNames.isEmpty) {
      _columnNames.addAll(row);
    } else {
      _table.add(Map.fromIterables(_columnNames, row));
    }
  }

  /// Gherkin table
  List<String> gherkinRows() {
    List<String> rows = [];

    if (_table.isNotEmpty) {
      rows.add("$_SPACER|${_columnNames.join(" | ")}|");

      for (var row in _table) {
        rows.add("$_SPACER|${row.values.join(" | ")}|");
      }
    }

    return rows;
  }

  String toString() {
    return _table.toString();
  }
}
