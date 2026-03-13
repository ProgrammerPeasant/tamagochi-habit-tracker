import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/pet_state.dart';
import '../geometry/origami_mesh.dart';
import '../geometry/origami_renderer.dart';

class OrigamiCompanion extends StatefulWidget {
  final PetState state;
  final double size;

  const OrigamiCompanion({
    super.key,
    required this.state,
    this.size = 260,
  });

  @override
  State<OrigamiCompanion> createState() => _OrigamiCompanionState();
}

class _OrigamiCompanionState extends State<OrigamiCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idleController;
  late double _complexityValue;
  late double _damageValue;

  final _meshGenerator = const OrigamiMeshGenerator();

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _complexityValue = widget.state.structureComplexity.toDouble();
    _damageValue = widget.state.damage.toDouble();
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  double get _complexityTarget => widget.state.structureComplexity.toDouble();

  double get _damageTarget => widget.state.damage.toDouble();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _complexityValue, end: _complexityTarget),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOutCubic,
      onEnd: () => _complexityValue = _complexityTarget,
      builder: (context, complexity, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: _damageValue, end: _damageTarget),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
          onEnd: () => _damageValue = _damageTarget,
          builder: (context, damage, child) {
            return AnimatedBuilder(
              animation: _idleController,
              builder: (context, _) {
                final energyFactor =
                    (widget.state.energy / 100).clamp(0.0, 1.0);
                final idleAmp =
                    lerpDouble(0.004, 0.018, mathPow(energyFactor, 0.8))!;
                final breathe = lerpDouble(
                    1 - idleAmp, 1 + idleAmp, _idleController.value)!;
                final drift = Offset(
                  lerpDouble(-6, 6, _idleController.value)!,
                  lerpDouble(6, -4, _idleController.value)!,
                );

                final mesh = _meshGenerator.buildMesh(
                  complexity: complexity.round(),
                  energy: widget.state.energy,
                  mood: widget.state.mood,
                  damage: damage.round(),
                  seed: 42,
                );

                return Transform.translate(
                  offset: drift,
                  child: Transform.scale(
                    scale: breathe,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: OrigamiMeshPainter(
                        mesh: mesh,
                        energy: energyFactor,
                        damage: (damage / 100).clamp(0.0, 1.0),
                        light: _idleController.value,
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

  double mathPow(double value, double power) {
    return math.pow(value, power).toDouble();
  }
}
