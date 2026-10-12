import 'dart:ui';

/// Parses an SVG path `d` attribute (as used by KanjiVG) into a [Path].
///
/// Supports M/L/H/V/C/S/Q/T/Z in absolute and relative form, implicit
/// command repetition, and compact number syntax ("-2.5-1", ".5.5", "1e-3").
/// Arcs (A) are not used by KanjiVG and are rejected.
Path parseSvgPath(String d) {
  final tokens = _tokenize(d);
  final path = Path();
  var i = 0;
  var cmd = '';
  var cx = 0.0, cy = 0.0; // current point
  var sx = 0.0, sy = 0.0; // subpath start
  var lastCtrlX = 0.0, lastCtrlY = 0.0; // for S/T reflection
  var lastCmd = '';

  double next() {
    if (i >= tokens.length || tokens[i] is! double) {
      throw FormatException('Expected number in SVG path', d);
    }
    return tokens[i++] as double;
  }

  bool hasNumber() => i < tokens.length && tokens[i] is double;

  while (i < tokens.length) {
    if (tokens[i] is String) {
      cmd = tokens[i++] as String;
    } else if (cmd.isEmpty) {
      throw FormatException('SVG path must start with a command', d);
    }
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? cx : 0.0, oy = rel ? cy : 0.0;

    switch (cmd.toUpperCase()) {
      case 'M':
        cx = ox + next();
        cy = oy + next();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        // Further pairs after M are implicit L commands.
        cmd = rel ? 'l' : 'L';
      case 'L':
        cx = ox + next();
        cy = oy + next();
        path.lineTo(cx, cy);
      case 'H':
        cx = ox + next();
        path.lineTo(cx, cy);
      case 'V':
        cy = (rel ? cy : 0.0) + next();
        path.lineTo(cx, cy);
      case 'C':
        final x1 = ox + next(), y1 = oy + next();
        final x2 = ox + next(), y2 = oy + next();
        cx = ox + next();
        cy = oy + next();
        path.cubicTo(x1, y1, x2, y2, cx, cy);
        lastCtrlX = x2;
        lastCtrlY = y2;
      case 'S':
        final reflect = 'CS'.contains(lastCmd.toUpperCase());
        final x1 = reflect ? 2 * cx - lastCtrlX : cx;
        final y1 = reflect ? 2 * cy - lastCtrlY : cy;
        final x2 = ox + next(), y2 = oy + next();
        cx = ox + next();
        cy = oy + next();
        path.cubicTo(x1, y1, x2, y2, cx, cy);
        lastCtrlX = x2;
        lastCtrlY = y2;
      case 'Q':
        final x1 = ox + next(), y1 = oy + next();
        cx = ox + next();
        cy = oy + next();
        path.quadraticBezierTo(x1, y1, cx, cy);
        lastCtrlX = x1;
        lastCtrlY = y1;
      case 'T':
        final reflect = 'QT'.contains(lastCmd.toUpperCase());
        final x1 = reflect ? 2 * cx - lastCtrlX : cx;
        final y1 = reflect ? 2 * cy - lastCtrlY : cy;
        cx = ox + next();
        cy = oy + next();
        path.quadraticBezierTo(x1, y1, cx, cy);
        lastCtrlX = x1;
        lastCtrlY = y1;
      case 'Z':
        path.close();
        cx = sx;
        cy = sy;
      default:
        throw FormatException('Unsupported SVG path command "$cmd"', d);
    }
    lastCmd = cmd;
    // A command letter followed by no further numbers ends here; Z takes none.
    if (cmd.toUpperCase() == 'Z' && hasNumber()) {
      throw FormatException('Unexpected number after Z', d);
    }
  }
  return path;
}

final _token = RegExp(r'[MmLlHhVvCcSsQqTtZzAa]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');
const _commands = 'MmLlHhVvCcSsQqTtZzAa';

List<Object> _tokenize(String d) => [
  for (final m in _token.allMatches(d))
    if (m[0]!.length == 1 && _commands.contains(m[0]!)) m[0]! else double.parse(m[0]!),
];
