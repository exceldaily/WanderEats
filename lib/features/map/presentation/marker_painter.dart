import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/theme/wb_tokens.dart';
import '../domain/map_marker_style.dart';

/// Rasterises WanderBites pins and cluster bubbles.
///
/// Drawn with Canvas rather than shipped as image assets: one code path covers
/// every state and device pixel ratio, colours stay tied to the design tokens,
/// and adding a state costs a switch arm instead of eight PNG exports.
///
/// Every result is cached by [WbMarkerSpec.cacheKey]. Rasterising is the
/// expensive part - a dense city pans through the same dozen specs constantly,
/// so the cache is what keeps this off the frame budget.
class WbMarkerPainter {
  WbMarkerPainter({required this.pixelRatio});

  final double pixelRatio;

  final Map<String, ui.Image> _cache = {};

  /// Bitmap for [spec], rasterised once per (spec, pixelRatio).
  Future<ui.Image> image(WbMarkerSpec spec) async {
    final cached = _cache[spec.cacheKey];
    if (cached != null) return cached;
    final image = spec.isCluster ? await _paintCluster(spec) : await _paintPin(spec);
    _cache[spec.cacheKey] = image;
    return image;
  }

  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }

  /// A teardrop is what every map uses. WanderBites uses a rounded plate on a
  /// short stem: recognisable at a glance in a screenshot, and the flat face
  /// gives the count badge somewhere to sit.
  Future<ui.Image> _paintPin(WbMarkerSpec spec) {
    final palette = _paletteFor(spec.kind);
    final selected = spec.kind == WbMarkerKind.selected;

    // Logical sizes; scaled to device pixels at record time.
    final double plate = selected ? 34 : 28;
    const double stem = 9;
    final double shadow = 4;
    final width = plate + shadow * 2;
    final height = plate + stem + shadow * 2;

    return _record(width, height, (canvas) {
      final cx = width / 2;
      final cy = shadow + plate / 2;
      final r = plate / 2;

      // Stem first, so the plate paints over its flat top.
      final stemPath = Path()
        ..moveTo(cx - 5, cy + r - 2)
        ..quadraticBezierTo(cx, cy + r + stem + 1, cx + 5, cy + r - 2)
        ..close();

      canvas.drawShadow(
        Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
          ..addPath(stemPath, Offset.zero),
        Colors.black.withValues(alpha: 0.45),
        selected ? 4 : 2,
        false,
      );

      final fill = Paint()..color = palette.fill;
      canvas.drawPath(stemPath, fill);
      canvas.drawCircle(Offset(cx, cy), r, fill);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 3 : 2
          ..color = palette.border,
      );

      _drawGlyph(canvas, Offset(cx, cy), r, spec.kind, palette.onFill);

      if (spec.recCount > 1 && spec.kind == WbMarkerKind.followedTaster) {
        _drawBadge(canvas, Offset(cx + r - 3, cy - r + 3), spec.recCount);
      }
    });
  }

  /// Clusters read as one WanderBites object, not a generic numbered circle:
  /// a soft halo, a solid plate, the count, and the word "bites" so the number
  /// means something.
  Future<ui.Image> _paintCluster(WbMarkerSpec spec) {
    final n = spec.clusterCount;
    // Grows with density but flattens out, so a 400-pin cluster does not
    // swallow the screen.
    final double plate = 40 + math.min(18, math.log(n) * 5.2);
    const double halo = 7;
    final size = plate + halo * 2;

    return _record(size, size, (canvas) {
      final c = Offset(size / 2, size / 2);
      final r = plate / 2;

      canvas.drawCircle(c, r + halo, Paint()..color = WbColors.voyage.withValues(alpha: 0.16));
      canvas.drawCircle(c, r + halo * 0.45, Paint()..color = WbColors.voyage.withValues(alpha: 0.22));
      canvas.drawShadow(
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        Colors.black.withValues(alpha: 0.4),
        3,
        false,
      );
      canvas.drawCircle(c, r, Paint()..color = WbColors.voyage);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = WbColors.cream.withValues(alpha: 0.9),
      );

      final count = _layout(
        n > 99 ? '99+' : '$n',
        color: WbColors.cream,
        size: n > 99 ? 13 : 15,
        weight: FontWeight.w800,
      );
      final label = _layout(
        'bites',
        color: WbColors.cream.withValues(alpha: 0.75),
        size: 8,
        weight: FontWeight.w600,
        letterSpacing: 0.4,
      );
      final block = count.height + label.height - 3;
      count.paint(canvas, Offset(c.dx - count.width / 2, c.dy - block / 2));
      label.paint(canvas, Offset(c.dx - label.width / 2, c.dy - block / 2 + count.height - 3));
    });
  }

  void _drawGlyph(
    Canvas canvas,
    Offset center,
    double r,
    WbMarkerKind kind,
    Color color,
  ) {
    final icon = switch (kind) {
      WbMarkerKind.saved => Icons.bookmark_rounded,
      WbMarkerKind.visited => Icons.check_rounded,
      WbMarkerKind.trending => Icons.local_fire_department_rounded,
      WbMarkerKind.hiddenGem => Icons.auto_awesome_rounded,
      WbMarkerKind.followedTaster => Icons.person_rounded,
      WbMarkerKind.selected || WbMarkerKind.standard => Icons.restaurant_rounded,
    };

    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: r * 1.15,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      )
      ..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  void _drawBadge(Canvas canvas, Offset center, int count) {
    const r = 8.0;
    canvas.drawCircle(center, r, Paint()..color = WbColors.ember);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = WbColors.cream,
    );
    final text = _layout(
      count > 9 ? '9+' : '$count',
      color: WbColors.cream,
      size: 9,
      weight: FontWeight.w800,
    );
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  TextPainter _layout(
    String text, {
    required Color color,
    required double size,
    required FontWeight weight,
    double letterSpacing = 0,
  }) {
    return TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: 1.05,
        ),
      ),
    )..layout();
  }

  Future<ui.Image> _record(
    double width,
    double height,
    void Function(Canvas) draw,
  ) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio);
    draw(canvas);
    return recorder.endRecording().toImage(
      (width * pixelRatio).ceil(),
      (height * pixelRatio).ceil(),
    );
  }

  _Palette _paletteFor(WbMarkerKind kind) => switch (kind) {
    WbMarkerKind.selected => const _Palette(WbColors.ember, WbColors.cream, WbColors.cream),
    WbMarkerKind.followedTaster => const _Palette(WbColors.voyage, WbColors.cream, WbColors.cream),
    WbMarkerKind.saved => const _Palette(WbColors.emberSoft, WbColors.ember, WbColors.ember),
    WbMarkerKind.visited => const _Palette(WbColors.success, WbColors.cream, WbColors.cream),
    WbMarkerKind.trending => const _Palette(WbColors.markerTrending, WbColors.cream, WbColors.ink),
    WbMarkerKind.hiddenGem => const _Palette(WbColors.voyageLight, WbColors.cream, WbColors.cream),
    WbMarkerKind.standard => const _Palette(WbColors.cream, WbColors.voyage, WbColors.voyage),
  };
}

class _Palette {
  const _Palette(this.fill, this.border, this.onFill);
  final Color fill;
  final Color border;
  final Color onFill;
}
