import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Credits to https://www.reddit.com/user/eibaan/ and his work
///
/// Dart Pad: https://dartpad.dev/?id=9d3fff7042376ad8a769aaf1acf0c97f&run=true
class Snow extends StatefulWidget {
  const Snow({
    required this.child,
    super.key,
    this.flakeCount = 140,
    this.minSpeed = 16,
    this.maxSpeed = 64,
    this.minRadius = 1,
    this.maxRadius = 4,
    this.windStrength = 20,
    this.swayStrength = 24,
    this.meltDuration = const Duration(seconds: 10),
    this.color = const Color(0xFFF8FBFF),
  });

  final Widget child;
  final int flakeCount;
  final double minSpeed;
  final double maxSpeed;
  final double minRadius;
  final double maxRadius;
  final double windStrength;
  final double swayStrength;
  final Duration meltDuration;
  final Color color;

  static SnowState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SnowScope>()?.state;

  @override
  State<Snow> createState() => SnowState();
}

class _SnowScope extends InheritedWidget {
  const _SnowScope({required this.state, required super.child});

  final SnowState state;

  @override
  bool updateShouldNotify(covariant _SnowScope oldWidget) => false;
}

class SnowState extends State<Snow> with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  final List<_Snowflake> _flakes = [];
  final Set<_SnowShelfState> _shelves = {};
  final Map<_SnowShelfState, Rect> _shelfRects = {};
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  Size _size = Size.zero;
  bool _pendingReseed = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _registerShelf(_SnowShelfState shelf) {
    _shelves.add(shelf);
  }

  void _unregisterShelf(_SnowShelfState shelf) {
    _shelves.remove(shelf);
    _shelfRects.remove(shelf);
  }

  void _onTick(Duration elapsed) {
    if (_size.isEmpty) {
      _lastElapsed = elapsed;
      return;
    }
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    final dt = delta.inMicroseconds / 1000000;
    if (dt <= 0) {
      return;
    }
    final clampedDt = dt > 0.05 ? 0.05 : dt;
    _time += clampedDt;
    _updateShelfRects();
    _advanceFlakes(clampedDt);
    _repaint.value = (_repaint.value + 1) & 0x7fffffff;
  }

  void _updateShelfRects() {
    final snowRenderObject = context.findRenderObject();
    if (snowRenderObject is! RenderBox || !snowRenderObject.hasSize) {
      return;
    }
    _shelfRects.clear();
    for (final shelf in _shelves.toList()) {
      if (!shelf.mounted) {
        _shelves.remove(shelf);
        continue;
      }
      final rect = shelf.rectInSnow(snowRenderObject);
      if (rect != null) {
        _shelfRects[shelf] = rect;
      }
    }
  }

  void _advanceFlakes(double dt) {
    final meltSeconds = widget.meltDuration.inMilliseconds / 1000.0;
    for (final flake in _flakes) {
      if (flake.isResting) {
        if ((_time - flake.restStart) > meltSeconds) {
          _resetFlake(flake, fromTop: true);
          continue;
        }
        final restRect = flake.restingOn == null
            ? null
            : _shelfRects[flake.restingOn];
        if (restRect == null) {
          _resetFlake(flake, fromTop: true);
          continue;
        }
        final clampedX = flake.position.dx
            .clamp(restRect.left + flake.radius, restRect.right - flake.radius)
            .toDouble();
        flake.position = Offset(clampedX, restRect.top - flake.radius);
        continue;
      }

      final sway =
          sin(_time * flake.swaySpeed + flake.phase) * flake.swayAmplitude;
      var nextX = flake.position.dx + (flake.drift + sway) * dt;
      final nextY = flake.position.dy + flake.speed * dt;

      final landing = _checkLanding(
        flake.position,
        Offset(nextX, nextY),
        flake.radius,
      );
      if (landing != null) {
        final clampedX = nextX
            .clamp(
              landing.rect.left + flake.radius,
              landing.rect.right - flake.radius,
            )
            .toDouble();
        flake
          ..isResting = true
          ..restStart = _time
          ..restingOn = landing.shelf
          ..position = Offset(clampedX, landing.rect.top - flake.radius);
        continue;
      }

      if (nextX < -flake.radius) {
        nextX = _size.width + flake.radius;
      } else if (nextX > _size.width + flake.radius) {
        nextX = -flake.radius;
      }
      flake.position = Offset(nextX, nextY);

      if (nextY > _size.height + flake.radius) {
        _resetFlake(flake, fromTop: true);
      }
    }
  }

  _Landing? _checkLanding(Offset current, Offset next, double radius) {
    _Landing? best;
    for (final entry in _shelfRects.entries) {
      final rect = entry.value;
      if (next.dy >= rect.top - radius &&
          current.dy < rect.top - radius &&
          next.dx >= rect.left - radius &&
          next.dx <= rect.right + radius) {
        if (best == null || rect.top < best.rect.top) {
          best = _Landing(entry.key, rect);
        }
      }
    }
    return best;
  }

  void _ensureFlakes() {
    if (_size.isEmpty) {
      return;
    }
    if (_flakes.length < widget.flakeCount) {
      final missing = widget.flakeCount - _flakes.length;
      for (var i = 0; i < missing; i++) {
        _flakes.add(_spawnFlake(fromTop: false));
      }
    } else if (_flakes.length > widget.flakeCount) {
      _flakes.removeRange(widget.flakeCount, _flakes.length);
    }
    if (_pendingReseed) {
      for (final flake in _flakes) {
        _resetFlake(flake, fromTop: false);
      }
      _pendingReseed = false;
    }
  }

  _Snowflake _spawnFlake({required bool fromTop}) {
    final flake = _Snowflake(
      position: Offset.zero,
      radius: widget.minRadius,
      speed: widget.minSpeed,
      drift: 0,
      swayAmplitude: 0,
      swaySpeed: 0,
      phase: 0,
      depth: 0,
    );
    _resetFlake(flake, fromTop: fromTop);
    return flake;
  }

  void _resetFlake(_Snowflake flake, {required bool fromTop}) {
    final depth = _rng.nextDouble();
    final radius = _lerp(widget.minRadius, widget.maxRadius, depth);
    final speed = _lerp(widget.minSpeed, widget.maxSpeed, depth);
    final drift = (_rng.nextDouble() * 2 - 1) * widget.windStrength;
    final swayAmplitude = widget.swayStrength * (0.3 + _rng.nextDouble() * 0.7);
    final swaySpeed = 0.6 + _rng.nextDouble() * 1.4;
    final phase = _rng.nextDouble() * pi * 2;
    final x = _rng.nextDouble() * _size.width;
    final y = fromTop
        ? -_rng.nextDouble() * _size.height
        : _rng.nextDouble() * _size.height;
    flake
      ..position = Offset(x, y)
      ..radius = radius
      ..speed = speed
      ..drift = drift
      ..swayAmplitude = swayAmplitude
      ..swaySpeed = swaySpeed
      ..phase = phase
      ..depth = depth
      ..isResting = false
      ..restingOn = null
      ..restStart = 0;
  }

  @override
  void didUpdateWidget(covariant Snow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flakeCount != widget.flakeCount ||
        oldWidget.minSpeed != widget.minSpeed ||
        oldWidget.maxSpeed != widget.maxSpeed ||
        oldWidget.minRadius != widget.minRadius ||
        oldWidget.maxRadius != widget.maxRadius ||
        oldWidget.windStrength != widget.windStrength ||
        oldWidget.swayStrength != widget.swayStrength) {
      _pendingReseed = true;
    }
  }

  @override
  Widget build(BuildContext context) => _SnowScope(
    state: this,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size.width.isFinite && size.height.isFinite) {
          if (size != _size) {
            _size = size;
            _pendingReseed = true;
          }
          _ensureFlakes();
        }
        return CustomPaint(
          foregroundPainter: _SnowPainter(
            flakes: _flakes,
            color: widget.color,
            repaint: _repaint,
          ),
          child: widget.child,
        );
      },
    ),
  );
}

class SnowShelf extends StatefulWidget {
  const SnowShelf({required this.child, super.key});

  final Widget child;

  @override
  State<SnowShelf> createState() => _SnowShelfState();
}

class _SnowShelfState extends State<SnowShelf> {
  SnowState? _snow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final snow = Snow.maybeOf(context);
    if (snow != _snow) {
      _snow?._unregisterShelf(this);
      _snow = snow;
      _snow?._registerShelf(this);
    }
  }

  @override
  void dispose() {
    _snow?._unregisterShelf(this);
    super.dispose();
  }

  Rect? rectInSnow(RenderBox snowRender) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final size = renderObject.size;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final bottomRight = renderObject.localToGlobal(
      Offset(size.width, size.height),
    );
    final localTopLeft = snowRender.globalToLocal(topLeft);
    final localBottomRight = snowRender.globalToLocal(bottomRight);
    return Rect.fromPoints(localTopLeft, localBottomRight);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Snowflake {
  _Snowflake({
    required this.position,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.swayAmplitude,
    required this.swaySpeed,
    required this.phase,
    required this.depth,
  });

  Offset position;
  double radius;
  double speed;
  double drift;
  double swayAmplitude;
  double swaySpeed;
  double phase;
  double depth;
  bool isResting = false;
  double restStart = 0;
  _SnowShelfState? restingOn;
}

class _Landing {
  const _Landing(this.shelf, this.rect);

  final _SnowShelfState shelf;
  final Rect rect;
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({required this.flakes, required this.color, super.repaint});

  final List<_Snowflake> flakes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final flake in flakes) {
      final opacity = 0.4 + flake.depth * 0.6;
      paint.color = color.withValues(alpha: opacity);
      canvas.drawCircle(flake.position, flake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.flakes != flakes;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
