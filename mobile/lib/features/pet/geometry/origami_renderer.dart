import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'mesh_types.dart';

class OrigamiMeshPainter extends CustomPainter {
  final Mesh mesh;
  final double energy;
  final double damage;
  final double light;

  OrigamiMeshPainter({
    required this.mesh,
    required this.energy,
    required this.damage,
    required this.light,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final projected = _projectVertices(mesh.vertices, size);
    final lightDir = _lightDirection(light);

    final faceEntries = <_FaceEntry>[];
    for (var i = 0; i < mesh.faces.length; i++) {
      final face = mesh.faces[i];
      if (face.opacity <= 0.01) {
        continue;
      }
      final a = mesh.vertices[face.a];
      final b = mesh.vertices[face.b];
      final c = mesh.vertices[face.c];

      final normal = (b - a).cross(c - a).normalized();
      final shade = (normal.dot(lightDir) * 0.5 + 0.5).clamp(0.0, 1.0);
      final depth = (a.z + b.z + c.z) / 3;
      faceEntries.add(_FaceEntry(face, shade, depth));
    }

    faceEntries.sort((a, b) => a.depth.compareTo(b.depth));

    for (final entry in faceEntries) {
      final face = entry.face;
      final path = Path()
        ..moveTo(projected[face.a].dx, projected[face.a].dy)
        ..lineTo(projected[face.b].dx, projected[face.b].dy)
        ..lineTo(projected[face.c].dx, projected[face.c].dy)
        ..close();

      final shade = entry.shade;
      final baseColor = Color.lerp(
        AppColors.paperShadow,
        AppColors.paperBase,
        0.22 + shade * 0.6,
      )!;

      final paint = Paint()
        ..color = baseColor.withOpacity(face.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);
    }

    _drawEdges(canvas, projected, mesh.faces);
    _drawGlow(canvas, size, energy);
    _drawDamageAccents(canvas, projected, damage);
  }

  @override
  bool shouldRepaint(covariant OrigamiMeshPainter oldDelegate) {
    return mesh != oldDelegate.mesh ||
        energy != oldDelegate.energy ||
        damage != oldDelegate.damage ||
        light != oldDelegate.light;
  }

  List<Offset> _projectVertices(List<Vec3> vertices, Size size) {
    final scale = size.shortestSide * 0.7;
    final center = Offset(size.width / 2, size.height / 2);
    final projected = <Offset>[];

    for (final v in vertices) {
      final px = v.x * scale;
      final py = v.y * scale;
      projected.add(center + Offset(px, py));
    }
    return projected;
  }

  Vec3 _lightDirection(double light) {
    final lx = -0.4 + 0.2 * math.sin(light * math.pi * 2);
    final ly = -0.6 + 0.15 * math.cos(light * math.pi * 2);
    return Vec3(lx, ly, 0.7).normalized();
  }

  void _drawEdges(Canvas canvas, List<Offset> projected, List<Face> faces) {
    final edgePaint = Paint()
      ..color = AppColors.paperDark.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    for (final face in faces) {
      final a = projected[face.a];
      final b = projected[face.b];
      final c = projected[face.c];
      canvas.drawLine(a, b, edgePaint);
      canvas.drawLine(b, c, edgePaint);
      canvas.drawLine(c, a, edgePaint);
    }
  }

  void _drawGlow(Canvas canvas, Size size, double energy) {
    final energyFactor = energy.clamp(0.0, 1.0);
    final glowPaint = Paint()
      ..color = AppColors.paperBase.withOpacity(0.06 + energyFactor * 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.32,
      glowPaint,
    );
  }

  void _drawDamageAccents(
      Canvas canvas, List<Offset> projected, double damage) {
    if (damage < 0.2 || projected.length < 4) {
      return;
    }

    final crackPaint = Paint()
      ..color = AppColors.paperDark.withOpacity(0.25 + damage * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = projected[0];
    final edge = projected[(projected.length / 2).floor()];
    canvas.drawLine(center, edge, crackPaint);

    if (damage > 0.6) {
      final accentPaint = Paint()
        ..color = AppColors.accentGold.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;

      canvas.drawLine(projected[1], projected[3], accentPaint);
    }
  }
}

class _FaceEntry {
  final Face face;
  final double shade;
  final double depth;

  _FaceEntry(this.face, this.shade, this.depth);
}
