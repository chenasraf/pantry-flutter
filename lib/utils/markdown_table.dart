/// A GFM table split into cells, rewritable back to markdown. Cell text stays
/// raw markdown (inline formatting included); only the grid is structured.
class MarkdownTable {
  final List<String> header;

  /// The divider row's cells (`:---`, `:---:`, `---:`), kept as written so
  /// column alignment survives an edit.
  final List<String> alignments;
  final List<List<String>> rows;

  MarkdownTable({
    required this.header,
    required this.alignments,
    required this.rows,
  });

  int get columnCount => header.length;

  factory MarkdownTable.parse(String markdown) {
    final lines = markdown
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final header = _splitRow(lines[0]);
    final width = header.length;
    return MarkdownTable(
      header: header,
      alignments: _fit(_splitRow(lines[1]), width, '---'),
      rows: [
        for (final line in lines.skip(2)) _fit(_splitRow(line), width, ''),
      ],
    );
  }

  String toMarkdown() => [
    _joinRow(header),
    _joinRow(alignments),
    for (final row in rows) _joinRow(row),
  ].join('\n');

  /// Splits on unescaped pipes, dropping the optional outer ones.
  static List<String> _splitRow(String line) {
    var body = line;
    if (body.startsWith('|')) body = body.substring(1);
    if (body.endsWith('|') && !body.endsWith(r'\|')) {
      body = body.substring(0, body.length - 1);
    }
    final cells = <String>[];
    final current = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      final ch = body[i];
      if (ch == r'\' && i + 1 < body.length && body[i + 1] == '|') {
        current.write('|');
        i++;
      } else if (ch == '|') {
        cells.add(current.toString().trim());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    cells.add(current.toString().trim());
    return cells;
  }

  static String _joinRow(List<String> cells) =>
      '| ${cells.map((cell) => cell.replaceAll('|', r'\|')).join(' | ')} |';

  /// Rows in markdown may be short or long; pad or trim them to the header.
  static List<String> _fit(List<String> cells, int width, String filler) => [
    for (var i = 0; i < width; i++) i < cells.length ? cells[i] : filler,
  ];
}
