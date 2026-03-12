import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/pet_state.dart';

class OrigamiCompanion extends StatefulWidget {
  final PetState state;
  final double size;

  const OrigamiCompanion({
    super.key,
    required this.state,
    this.size = 240,
  });

  @override
  State<OrigamiCompanion> createState() => _OrigamiCompanionState();
}

class _OrigamiCompanionState extends State<OrigamiCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;
  late double _foldValue;
  late double _damageValue;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _foldValue = _foldTarget;
    _damageValue = _damageTarget;
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  double get _foldTarget => (widget.state.structureComplexity / 100).clamp(0.0, 1.0);

  double get _damageTarget => (widget.state.damage / 100).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _foldValue, end: _foldTarget),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      onEnd: () => _foldValue = _foldTarget,
      builder: (context, fold, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: _damageValue, end: _damageTarget),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          onEnd: () => _damageValue = _damageTarget,
          builder: (context, damage, child) {
            return AnimatedBuilder(
              animation: _idleController,
              builder: (context, _) {
                final energyFactor = (widget.state.energy / 100).clamp(0.0, 1.0);
                final amp = lerpDouble(0.006, 0.02, energyFactor)!;
                final breathe = lerpDouble(1 - amp, 1 + amp, _idleController.value)!;
                final drift = Offset(
                  lerpDouble(-8, 10, _idleController.value)!,
                  lerpDouble(10, -6, _idleController.value)!,
                );

                return Transform.translate(
                  offset: drift,
                  child: Transform.scale(
                    scale: breathe,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: OrigamiPainter(
                        fold: fold,
                        damage: damage,
                        energy: widget.state.energy / 100,
                        mood: widget.state.mood / 100,
                        light: _idleController.value,
                        stage: widget.state.stage,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class OrigamiPainter extends CustomPainter {
  final double fold;
  final double damage;
  final double energy;
  final double mood;
  final double light;
  final PetStage stage;

  OrigamiPainter({
    required this.fold,
    required this.damage,
    required this.energy,
    required this.mood,
    required this.light,
    required this.stage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.width * 0.36;
    final moodFactor = mood.clamp(0.0, 1.0);
    final energyFactor = energy.clamp(0.0, 1.0);
    final damageFactor = damage.clamp(0.0, 1.0);

    final asym = (1 - moodFactor) * base * 0.18;
    final sag = (1 - energyFactor) * base * 0.06 + damageFactor * base * 0.08;
    final foldShift = lerpDouble(4, 26, fold + energyFactor * 0.2)!;

    final lightOffset = Offset(
      lerpDouble(-18, 14, light)!,
      lerpDouble(-12, 18, light)!,
    );

    final jitter = Offset(
      sin(light * pi * 2) * damageFactor * 6,
      cos(light * pi * 2) * damageFactor * 4,
    );

    final top = center + Offset(asym * 0.4, -base * 1.05 - foldShift * 0.2) + jitter;
    final right = center + Offset(base * 1.1 + asym * 0.6 + foldShift * 0.1, 0) + jitter;
    final bottom = center + Offset(-asym * 0.2, base * 1.05 + sag + foldShift * 0.2) + jitter;
    final left = center + Offset(-base * 1.1 - asym * 0.6 - foldShift * 0.1, -asym * 0.1) + jitter;

    final basePath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final baseRect = Rect.fromCenter(center: center, width: base * 3, height: base * 3);

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.paperBase.withOpacity(0.98),
          AppColors.paperShadow.withOpacity(0.92),
        ],
      ).createShader(baseRect);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.save();
    canvas.translate(lightOffset.dx, lightOffset.dy);
    canvas.drawPath(basePath, shadowPaint);
    canvas.restore();

    canvas.drawPath(basePath, basePaint);

    switch (stage) {
      case PetStage.flatSheet:
        _drawStage1(canvas, center, base, top, bottom, left, right, moodFactor);
      case PetStage.simpleFold:
        _drawStage2(canvas, center, base, top, bottom, left, right, foldShift, moodFactor);
      case PetStage.geometricAnimal:
        _drawStage3(canvas, center, base, foldShift, moodFactor);
      case PetStage.complexSculpture:
        _drawStage4(canvas, center, base, foldShift, moodFactor);
      case PetStage.architectural:
        _drawStage5(canvas, center, base, foldShift, moodFactor);
    }

    _drawCreases(canvas, top, bottom, left, right, energyFactor);
    _drawDamage(canvas, center, base, damageFactor);
    _drawGlow(canvas, center, base, energyFactor);
  }

  @override
  bool shouldRepaint(covariant OrigamiPainter oldDelegate) {
    return fold != oldDelegate.fold ||
        damage != oldDelegate.damage ||
        energy != oldDelegate.energy ||
        mood != oldDelegate.mood ||
        light != oldDelegate.light ||
        stage != oldDelegate.stage;
  }

  void _drawStage1(
    Canvas canvas,
    Offset center,
    double base,
    Offset top,
    Offset bottom,
    Offset left,
    Offset right,
    double moodFactor,
  ) {
    final ridgePaint = Paint()
      ..color = AppColors.paperDark.withOpacity(0.15 + moodFactor * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(top, bottom, ridgePaint);
    canvas.drawLine(left, right, ridgePaint);
  }

  void _drawStage2(
    Canvas canvas,
    Offset center,
    double base,
    Offset top,
    Offset bottom,
    Offset left,
    Offset right,
    double foldShift,
    double moodFactor,
  ) {
    final lift = base * 0.18 + foldShift * 0.2;
    final midTopLeft = Offset.lerp(top, left, 0.5)! + Offset(0, -lift);
    final midTopRight = Offset.lerp(top, right, 0.5)! + Offset(0, -lift);
    final midBottomLeft = Offset.lerp(bottom, left, 0.5)! + Offset(0, lift * 0.4);
    final midBottomRight = Offset.lerp(bottom, right, 0.5)! + Offset(0, lift * 0.4);

    _drawPlane(canvas, [top, midTopRight, center, midTopLeft], moodFactor * 0.3);
    _drawPlane(canvas, [bottom, midBottomRight, center, midBottomLeft], moodFactor * 0.15);
  }

  void _drawStage3(
    Canvas canvas,
    Offset center,
    double base,
    double foldShift,
    double moodFactor,
  ) {
    final angle = 0.22 + foldShift * 0.004;
    final scale = 0.75;

    final points = _rotatedDiamond(center, base * 0.9, angle, scale);
    _drawPlane(canvas, points, 0.35 + moodFactor * 0.2);

    final wingLeft = [
      Offset(center.dx - base * 0.2, center.dy - base * 0.1),
      Offset(center.dx - base * 0.8, center.dy - base * 0.2),
      Offset(center.dx - base * 0.5, center.dy + base * 0.3),
    ];
    _drawPlane(canvas, wingLeft, 0.2);

    final wingRight = [
      Offset(center.dx + base * 0.2, center.dy - base * 0.1),
      Offset(center.dx + base * 0.8, center.dy - base * 0.2),
      Offset(center.dx + base * 0.5, center.dy + base * 0.3),
    ];
    _drawPlane(canvas, wingRight, 0.2);
  }

  void _drawStage4(
    Canvas canvas,
    Offset center,
    double base,
    double foldShift,
    double moodFactor,
  ) {
    final layer1 = _rotatedDiamond(center, base * 0.92, 0.15, 0.8);
    final layer2 = _rotatedDiamond(center, base * 0.7, -0.2, 0.7);
    final layer3 = _rotatedDiamond(center, base * 0.55, 0.35, 0.6);

    _drawPlane(canvas, layer1, 0.32 + moodFactor * 0.2);
    _drawPlane(canvas, layer2, 0.28 + moodFactor * 0.15);
    _drawPlane(canvas, layer3, 0.22 + moodFactor * 0.1);

    final spine = [
      Offset(center.dx - base * 0.1, center.dy - base * 1.0),
      Offset(center.dx + base * 0.1, center.dy - base * 1.0),
      Offset(center.dx + base * 0.2, center.dy + base * 0.8),
      Offset(center.dx - base * 0.2, center.dy + base * 0.8),
    ];
    _drawPlane(canvas, spine, 0.25);

    final braceOffset = foldShift * 0.02;
    final brace = [
      Offset(center.dx - base * 0.7, center.dy + braceOffset),
      Offset(center.dx - base * 0.2, center.dy - base * 0.3),
      Offset(center.dx - base * 0.1, center.dy + base * 0.4),
    ];
    _drawPlane(canvas, brace, 0.2);
  }

  void _drawStage5(
    Canvas canvas,
    Offset center,
    double base,
    double foldShift,
    double moodFactor,
  ) {
    final layers = <List<Offset>>[
      _rotatedDiamond(center, base * 1.0, 0.12, 0.85),
      _rotatedDiamond(center, base * 0.78, -0.18, 0.75),
      _rotatedDiamond(center, base * 0.6, 0.32, 0.65),
      _rotatedDiamond(center, base * 0.45, -0.45, 0.55),
    ];

    var weight = 0.36 + moodFactor * 0.2;
    for (final layer in layers) {
      _drawPlane(canvas, layer, weight);
      weight -= 0.05;
    }

    final spire = [
      Offset(center.dx, center.dy - base * 1.4),
      Offset(center.dx + base * 0.2, center.dy - base * 0.8),
      Offset(center.dx, center.dy - base * 0.4),
      Offset(center.dx - base * 0.2, center.dy - base * 0.8),
    ];
    _drawPlane(canvas, spire, 0.3);

    final wingLeft = [
      Offset(center.dx - base * 0.9, center.dy + base * 0.2),
      Offset(center.dx - base * 0.4, center.dy - base * 0.1),
      Offset(center.dx - base * 0.2, center.dy + base * 0.6),
    ];
    _drawPlane(canvas, wingLeft, 0.18 + foldShift * 0.002);

    final wingRight = [
      Offset(center.dx + base * 0.9, center.dy + base * 0.2),
      Offset(center.dx + base * 0.4, center.dy - base * 0.1),
      Offset(center.dx + base * 0.2, center.dy + base * 0.6),
    ];
    _drawPlane(canvas, wingRight, 0.18 + foldShift * 0.002);
  }

  void _drawPlane(Canvas canvas, List<Offset> points, double shade) {
    final path = Path()..addPolygon(points, true);
    final bounds = path.getBounds();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.paperBase.withOpacity(0.85 - shade * 0.2),
          AppColors.paperShadow.withOpacity(0.8 + shade * 0.1),
        ],
      ).createShader(bounds);

    canvas.drawPath(path, paint);
  }

  void _drawCreases(Canvas canvas, Offset top, Offset bottom, Offset left, Offset right, double energy) {
    final ridgePaint = Paint()
      ..color = AppColors.paperDark.withOpacity(0.2 + energy * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 + energy * 0.5;

    canvas.drawLine(top, bottom, ridgePaint);
    canvas.drawLine(left, right, ridgePaint);
  }

  void _drawDamage(Canvas canvas, Offset center, double base, double damageFactor) {
    if (damageFactor < 0.2) {
      return;
    }

    final crackPaint = Paint()
      ..color = AppColors.paperDark.withOpacity(0.2 + damageFactor * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawLine(
      Offset(center.dx - base * 0.4, center.dy - base * 0.2),
      Offset(center.dx + base * 0.35, center.dy + base * 0.25),
      crackPaint,
    );

    if (damageFactor > 0.45) {
      canvas.drawLine(
        Offset(center.dx + base * 0.1, center.dy - base * 0.5),
        Offset(center.dx - base * 0.2, center.dy + base * 0.45),
        crackPaint,
      );
    }

    if (damageFactor > 0.7) {
      canvas.drawLine(
        Offset(center.dx - base * 0.6, center.dy + base * 0.1),
        Offset(center.dx + base * 0.55, center.dy - base * 0.15),
        crackPaint,
      );
    }
  }

  void _drawGlow(Canvas canvas, Offset center, double base, double energyFactor) {
    final glowPaint = Paint()
      ..color = AppColors.paperBase.withOpacity(0.08 + energyFactor * 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

    canvas.drawCircle(center, base * 0.65, glowPaint);
  }

  List<Offset> _rotatedDiamond(Offset center, double radius, double angle, double scale) {
    final points = [
      Offset(0, -radius),
      Offset(radius, 0),
      Offset(0, radius),
      Offset(-radius, 0),
    ];

    return points.map((point) {
      final rotated = Offset(
        point.dx * cos(angle) - point.dy * sin(angle),
        point.dx * sin(angle) + point.dy * cos(angle),
      );
      return center + Offset(rotated.dx * scale, rotated.dy * scale);
    }).toList();
  }
}
