import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/farmer/data/cahyadsn_region_service.dart';

class OsmMapPoint {
  const OsmMapPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class OsmMapPreview extends StatefulWidget {
  const OsmMapPreview({
    super.key,
    required this.center,
    required this.initialZoom,
    this.markerPoint,
    this.boundary,
    this.interactive = true,
    this.onTap,
  });

  final OsmMapPoint center;
  final int initialZoom;
  final OsmMapPoint? markerPoint;
  final List<List<CahyadsnBoundaryPoint>>? boundary;
  final bool interactive;
  final ValueChanged<OsmMapPoint>? onTap;

  @override
  State<OsmMapPreview> createState() => _OsmMapPreviewState();
}

class _OsmMapPreviewState extends State<OsmMapPreview> {
  static const _tileSize = 256.0;
  late int _zoom;
  late OsmMapPoint _center;
  int _gestureStartZoom = 0;
  Offset? _gestureAnchorWorld;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom.clamp(3, 17).toInt();
    _center = widget.center;
  }

  @override
  void didUpdateWidget(covariant OsmMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialZoom != widget.initialZoom ||
        oldWidget.center.latitude != widget.center.latitude ||
        oldWidget.center.longitude != widget.center.longitude) {
      _zoom = widget.initialZoom.clamp(3, 17).toInt();
      _center = widget.center;
    }
  }

  Offset _worldPointAt(OsmMapPoint point, int zoom) {
    final scale = math.pow(2, zoom).toDouble() * _tileSize;
    final latitude = point.latitude.clamp(-85.05112878, 85.05112878);
    final radians = latitude * math.pi / 180;
    final x = (point.longitude + 180) / 360 * scale;
    final y =
        (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) /
        2 *
        scale;
    return Offset(x, y);
  }

  OsmMapPoint _geoPointAt(Offset world, int zoom) {
    final worldSize = _tileSize * math.pow(2, zoom).toDouble();
    final wrappedX = ((world.dx % worldSize) + worldSize) % worldSize;
    final clampedY = world.dy.clamp(0.0, worldSize);
    final longitude = wrappedX / worldSize * 360 - 180;
    final mercator = math.pi * (1 - 2 * clampedY / worldSize);
    final sinh = (math.exp(mercator) - math.exp(-mercator)) / 2;
    final latitude = math.atan(sinh) * 180 / math.pi;
    return OsmMapPoint(latitude, longitude);
  }

  void _zoomBy(int delta, Size viewportSize) {
    final nextZoom = (_zoom + delta).clamp(3, 17).toInt();
    if (nextZoom == _zoom) return;

    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final anchor = widget.markerPoint ?? _center;
    final anchorScreen =
        _worldPointAt(anchor, _zoom) -
        _worldPointAt(_center, _zoom) +
        viewportCenter;
    final nextCenterWorld =
        _worldPointAt(anchor, nextZoom) - (anchorScreen - viewportCenter);

    setState(() {
      _zoom = nextZoom;
      _center = _geoPointAt(nextCenterWorld, nextZoom);
    });
  }

  void _startGesture(ScaleStartDetails details, Size viewportSize) {
    if (!widget.interactive) return;
    _gestureStartZoom = _zoom;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    _gestureAnchorWorld =
        _worldPointAt(_center, _zoom) +
        (details.localFocalPoint - viewportCenter);
  }

  void _updateGesture(ScaleUpdateDetails details, Size viewportSize) {
    if (!widget.interactive) return;
    final anchor = _gestureAnchorWorld;
    if (anchor == null) return;

    final zoomDelta = math.log(details.scale) / math.ln2;
    final nextZoom = (_gestureStartZoom + zoomDelta)
        .round()
        .clamp(3, 17)
        .toInt();
    final scaleFactor = math.pow(2, nextZoom - _gestureStartZoom).toDouble();
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final nextCenterWorld =
        anchor * scaleFactor - (details.localFocalPoint - viewportCenter);

    setState(() {
      _zoom = nextZoom;
      _center = _geoPointAt(nextCenterWorld, nextZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final centerWorld = _worldPointAt(_center, _zoom);
        final viewportOrigin = Offset(
          centerWorld.dx - size.width / 2,
          centerWorld.dy - size.height / 2,
        );
        final firstX = (viewportOrigin.dx / _tileSize).floor();
        final lastX = ((viewportOrigin.dx + size.width) / _tileSize).floor();
        final firstY = (viewportOrigin.dy / _tileSize).floor();
        final lastY = ((viewportOrigin.dy + size.height) / _tileSize).floor();
        final tileCount = math.pow(2, _zoom).toInt();

        return Listener(
          onPointerSignal: widget.interactive
              ? (event) {
                  if (event is PointerScrollEvent) {
                    _zoomBy(event.scrollDelta.dy > 0 ? -1 : 1, size);
                  }
                }
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) => _startGesture(details, size),
            onScaleUpdate: (details) => _updateGesture(details, size),
            onScaleEnd: (_) => _gestureAnchorWorld = null,
            onTapUp: widget.onTap == null
                ? null
                : (details) {
                    widget.onTap!(
                      _geoPointAt(
                        viewportOrigin + details.localPosition,
                        _zoom,
                      ),
                    );
                  },
            child: ColoredBox(
              color: const Color(0xFFE8ECEF),
              child: Stack(
                children: [
                  for (var x = firstX; x <= lastX; x++)
                    for (var y = firstY; y <= lastY; y++)
                      if (y >= 0 && y < tileCount)
                        Positioned(
                          left: x * _tileSize - viewportOrigin.dx,
                          top: y * _tileSize - viewportOrigin.dy,
                          width: _tileSize,
                          height: _tileSize,
                          child: Image.network(
                            'https://tile.openstreetmap.org/$_zoom/${((x % tileCount) + tileCount) % tileCount}/$y.png',
                            key: ValueKey('tile-$_zoom-$x-$y'),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) =>
                                const ColoredBox(color: Color(0xFFE8ECEF)),
                          ),
                        ),
                  if (widget.boundary != null && widget.boundary!.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _BoundaryPainter(
                            rings: widget.boundary!,
                            viewportOrigin: viewportOrigin,
                            zoom: _zoom,
                          ),
                        ),
                      ),
                    ),
                  if (widget.markerPoint != null)
                    Positioned(
                      left:
                          _worldPointAt(widget.markerPoint!, _zoom).dx -
                          viewportOrigin.dx -
                          21,
                      top:
                          _worldPointAt(widget.markerPoint!, _zoom).dy -
                          viewportOrigin.dy -
                          42,
                      child: const IgnorePointer(
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 42,
                          color: AppColors.primaryContainer,
                          shadows: [
                            Shadow(
                              color: Color(0x55000000),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.interactive)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Column(
                        children: [
                          _MapIconButton(
                            icon: Icons.add,
                            tooltip: 'Perbesar peta',
                            onPressed: _zoom >= 17
                                ? null
                                : () => _zoomBy(1, size),
                          ),
                          const SizedBox(height: 4),
                          _MapIconButton(
                            icon: Icons.remove,
                            tooltip: 'Perkecil peta',
                            onPressed: _zoom <= 3
                                ? null
                                : () => _zoomBy(-1, size),
                          ),
                          const SizedBox(height: 4),
                          _MapIconButton(
                            icon: Icons.center_focus_strong_rounded,
                            tooltip: 'Kembali ke wilayah',
                            onPressed: () => setState(() {
                              _center = widget.center;
                              _zoom = widget.initialZoom.clamp(3, 17).toInt();
                            }),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoundaryPainter extends CustomPainter {
  const _BoundaryPainter({
    required this.rings,
    required this.viewportOrigin,
    required this.zoom,
  });

  final List<List<CahyadsnBoundaryPoint>> rings;
  final Offset viewportOrigin;
  final int zoom;

  static const _tileSize = 256.0;

  Offset _toScreen(CahyadsnBoundaryPoint point) {
    final scale = math.pow(2, zoom).toDouble() * _tileSize;
    final latitude = point.latitude.clamp(-85.05112878, 85.05112878);
    final radians = latitude * math.pi / 180;
    final x = (point.longitude + 180) / 360 * scale;
    final y =
        (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) /
        2 *
        scale;
    return Offset(x - viewportOrigin.dx, y - viewportOrigin.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final path = Path()..fillType = PathFillType.evenOdd;

    for (final ring in rings) {
      if (ring.length < 3) continue;
      final first = _toScreen(ring.first);
      path.moveTo(first.dx, first.dy);
      for (final point in ring.skip(1)) {
        final screenPoint = _toScreen(point);
        path.lineTo(screenPoint.dx, screenPoint.dy);
      }
      path.close();
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x3858A835)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BoundaryPainter oldDelegate) =>
      oldDelegate.rings != rings ||
      oldDelegate.viewportOrigin != viewportOrigin ||
      oldDelegate.zoom != zoom;
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.95),
        elevation: 2,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 19,
              color: onPressed == null
                  ? AppColors.placeholder
                  : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
