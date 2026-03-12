import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/features/pet/geometry/origami_mesh.dart';

void main() {
  const generator = OrigamiMeshGenerator();

  test('mesh generation is deterministic for same input + seed', () {
    final meshA = generator.buildMesh(
      complexity: 50,
      energy: 70,
      mood: 60,
      damage: 30,
      seed: 42,
    );
    final meshB = generator.buildMesh(
      complexity: 50,
      energy: 70,
      mood: 60,
      damage: 30,
      seed: 42,
    );

    expect(meshA.vertices.length, meshB.vertices.length);
    for (var i = 0; i < meshA.vertices.length; i++) {
      expect(meshA.vertices[i].x, closeTo(meshB.vertices[i].x, 1e-6));
      expect(meshA.vertices[i].y, closeTo(meshB.vertices[i].y, 1e-6));
      expect(meshA.vertices[i].z, closeTo(meshB.vertices[i].z, 1e-6));
    }
  });

  test('interpolation stays smooth around stage boundary', () {
    final mesh38 = generator.buildMesh(
      complexity: 38,
      energy: 60,
      mood: 60,
      damage: 10,
      seed: 42,
    );
    final mesh41 = generator.buildMesh(
      complexity: 41,
      energy: 60,
      mood: 60,
      damage: 10,
      seed: 42,
    );

    final count = math.min(mesh38.vertices.length, mesh41.vertices.length);

    var total = 0.0;
    for (var i = 0; i < count; i++) {
      final dx = mesh38.vertices[i].x - mesh41.vertices[i].x;
      final dy = mesh38.vertices[i].y - mesh41.vertices[i].y;
      final dz = mesh38.vertices[i].z - mesh41.vertices[i].z;
      total += math.sqrt(dx * dx + dy * dy + dz * dz);
    }
    final avg = total / count;
    expect(avg < 0.35, isTrue);
  });
}
