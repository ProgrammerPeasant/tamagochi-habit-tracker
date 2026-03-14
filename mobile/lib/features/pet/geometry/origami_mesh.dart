import 'dart:math' as math;

import '../domain/pet_state.dart';
import 'mesh_types.dart';

class OrigamiMeshGenerator {
  const OrigamiMeshGenerator();

  Mesh buildMesh({
    required int complexity,
    required int energy,
    required int mood,
    required int damage,
    int seed = 42,
  }) {
    final clampedComplexity = complexity.clamp(0, 100);
    final clampedEnergy = energy.clamp(0, 100);
    final clampedMood = mood.clamp(0, 100);
    final clampedDamage = damage.clamp(0, 100);

    final stageIndex = _stageIndexForComplexity(clampedComplexity);
    final stageMin = _stageMin(stageIndex);
    final stageMax = _stageMax(stageIndex);
    final tRaw = stageMax == stageMin
        ? 0.0
        : (clampedComplexity - stageMin) / (stageMax - stageMin);
    final t = _easeInOutCubic(tRaw);

    final meshA = _baseMeshForStage(stageIndex, seed);
    final meshB = _baseMeshForStage(math.min(stageIndex + 1, 4), seed + 19);
    final morphed = _morphMeshes(meshA, meshB, t, seed + 97);

    final withMood = _applyMood(morphed, clampedMood, seed + 7);
    final withEnergy = _applyEnergy(withMood, clampedEnergy);
    final withDamage = _applyDamage(withEnergy, clampedDamage, seed + 33);

    return withDamage;
  }

  PetStage stageForComplexityValue(int complexity) {
    switch (_stageIndexForComplexity(complexity)) {
      case 0:
        return PetStage.flatSheet;
      case 1:
        return PetStage.simpleFold;
      case 2:
        return PetStage.geometricAnimal;
      case 3:
        return PetStage.complexSculpture;
      default:
        return PetStage.architectural;
    }
  }

  int _stageIndexForComplexity(int complexity) {
    if (complexity < 20) {
      return 0;
    }
    if (complexity < 40) {
      return 1;
    }
    if (complexity < 60) {
      return 2;
    }
    if (complexity < 80) {
      return 3;
    }
    return 4;
  }

  int _stageMin(int stageIndex) => [0, 20, 40, 60, 80][stageIndex];

  int _stageMax(int stageIndex) => [19, 39, 59, 79, 100][stageIndex];

  Mesh _baseMeshForStage(int stageIndex, int seed) {
    switch (stageIndex) {
      case 0:
        return _diamondGrid(steps: 1, scale: 1.0, bulge: 0.02, seed: seed);
      case 1:
        return _diamondGrid(steps: 2, scale: 1.0, bulge: 0.14, seed: seed);
      case 2:
        return _stage3Mesh(seed);
      case 3:
        return _stage4Mesh(seed);
      default:
        return _stage5Mesh(seed);
    }
  }

  Mesh _stage3Mesh(int seed) {
    final base = _diamondGrid(steps: 3, scale: 1.0, bulge: 0.24, seed: seed);
    final builder = _MeshBuilder.fromMesh(base);

    _addWing(builder, const Vec3(-1.2, -0.1, 0.08),
        const Vec3(-0.4, -0.25, 0.12), const Vec3(-0.6, 0.4, 0.18));
    _addWing(builder, const Vec3(1.2, -0.1, 0.08),
        const Vec3(0.4, -0.25, 0.12), const Vec3(0.6, 0.4, 0.18));

    _addSpine(builder,
        top: const Vec3(0, -1.15, 0.22),
        bottom: const Vec3(0, 0.85, 0.12));

    return builder.build();
  }

  Mesh _stage4Mesh(int seed) {
    final base = _diamondGrid(steps: 4, scale: 1.0, bulge: 0.36, seed: seed);
    final builder = _MeshBuilder.fromMesh(base);

    _addLayer(builder, scale: 0.75, z: 0.32, rotation: 0.18);
    _addLayer(builder, scale: 0.55, z: 0.48, rotation: -0.22);
    _addLayer(builder, scale: 0.4, z: 0.62, rotation: 0.4);

    _addBalcony(builder, left: true, z: 0.2);
    _addBalcony(builder, left: false, z: 0.25);

    _addSpire(builder, height: 0.8, scale: 0.22);

    return builder.build();
  }

  Mesh _stage5Mesh(int seed) {
    final base = _diamondGrid(steps: 6, scale: 1.0, bulge: 0.62, seed: seed);
    final builder = _MeshBuilder.fromMesh(base);

    _addLayer(builder, scale: 0.85, z: 0.38, rotation: 0.1);
    _addLayer(builder, scale: 0.65, z: 0.56, rotation: -0.25);
    _addLayer(builder, scale: 0.45, z: 0.74, rotation: 0.4);
    _addLayer(builder, scale: 0.32, z: 0.9, rotation: -0.5);

    _addCantilever(builder, left: true, depth: 0.55, z: 0.38);
    _addCantilever(builder, left: false, depth: 0.55, z: 0.44);

    _addSpire(builder, height: 1.2, scale: 0.3);
    _addSpire(builder,
        height: 0.9, scale: 0.18, offset: const Vec3(0.2, -0.2, 0));

    return builder.build();
  }

  Mesh _diamondGrid({
    required int steps,
    required double scale,
    required double bulge,
    required int seed,
  }) {
    final vertices = <Vec3>[];
    final faces = <Face>[];
    final indexMap = <String, int>{};

    for (var i = -steps; i <= steps; i++) {
      for (var j = -steps; j <= steps; j++) {
        if (i.abs() + j.abs() > steps) {
          continue;
        }
        final x = (i / steps) * scale;
        final y = (j / steps) * scale;
        final weight = 1 - ((i.abs() + j.abs()) / steps);
        final z = bulge * weight;
        final idx = vertices.length;
        vertices.add(Vec3(x, y, z));
        indexMap['$i:$j'] = idx;
      }
    }

    for (var i = -steps; i < steps; i++) {
      for (var j = -steps; j < steps; j++) {
        if (i.abs() + j.abs() >= steps) {
          continue;
        }
        final a = indexMap['$i:$j'];
        final b = indexMap['${i + 1}:$j'];
        final c = indexMap['$i:${j + 1}'];
        final d = indexMap['${i + 1}:${j + 1}'];
        if (a == null || b == null || c == null) {
          continue;
        }
        faces.add(Face(a, b, c));
        if (d != null) {
          faces.add(Face(b, d, c));
        }
      }
    }

    return Mesh(vertices: vertices, faces: faces);
  }

  Mesh _morphMeshes(Mesh from, Mesh to, double t, int seed) {
    if (t <= 0) {
      return from;
    }
    if (t >= 1) {
      return to;
    }

    final targetCount = to.vertices.length;
    final remappedFrom = _remapVertices(from.vertices, targetCount, seed);
    final remappedTo = _remapVertices(to.vertices, targetCount, seed + 11);

    final blended = <Vec3>[];
    for (var i = 0; i < targetCount; i++) {
      blended.add(remappedFrom[i].lerp(remappedTo[i], t));
    }

    return Mesh(vertices: blended, faces: to.faces);
  }

  List<Vec3> _remapVertices(List<Vec3> source, int targetCount, int seed) {
    if (source.isEmpty) {
      return List.generate(targetCount, (_) => const Vec3(0, 0, 0));
    }

    final indexed = source
        .asMap()
        .entries
        .map((entry) => _PolarVertex(entry.key, entry.value))
        .toList();
    indexed.sort((a, b) => a.angle.compareTo(b.angle));

    final result = <Vec3>[];
    for (var i = 0; i < targetCount; i++) {
      final t = i / math.max(1, targetCount - 1);
      final pick = (t * (indexed.length - 1)).round();
      final jitter = ((_hash(seed, i) - 0.5) * 0.2).round();
      final idx = (pick + jitter).clamp(0, indexed.length - 1);
      result.add(indexed[idx].vertex);
    }
    return result;
  }

  Mesh _applyEnergy(Mesh mesh, int energy) {
    final factor = 0.6 + 0.4 * (energy / 100);
    final vertices =
        mesh.vertices.map((v) => Vec3(v.x, v.y, v.z * factor)).toList();
    return mesh.copyWith(vertices: vertices);
  }

  Mesh _applyMood(Mesh mesh, int mood, int seed) {
    final normalized = (mood / 100).clamp(0.0, 1.0);
    final distortion = (1 - normalized).clamp(0.0, 1.0);
    final mirrorBlend = math.pow(distortion, 1.8) * 0.85;
    final noiseAmp = math.pow(distortion, 1.2) * 0.07;
    final skewAmp = math.pow(distortion, 1.15) * 0.1;
    final wobbleAmp = math.pow(distortion, 1.1) * 0.05;
    final squash = 1 - distortion * 0.35;

    final vertices = <Vec3>[];
    for (var i = 0; i < mesh.vertices.length; i++) {
      final v = mesh.vertices[i];
      final mirrored = Vec3(-v.x, v.y, v.z);
      var blended = v.lerp(mirrored, mirrorBlend);
      blended = Vec3(blended.x * squash, blended.y, blended.z);

      if (distortion > 0) {
        final nx = (_hash(seed + 3, i) - 0.5) * noiseAmp;
        final ny = (_hash(seed + 7, i) - 0.5) * noiseAmp;
        final nz = (_hash(seed + 11, i) - 0.5) * noiseAmp;
        final skew = math.sin(v.y * math.pi) * skewAmp;
        final wobble = math.cos(v.x * math.pi) * wobbleAmp;
        blended = Vec3(
          blended.x + nx + skew,
          blended.y + ny + wobble,
          blended.z + nz,
        );
      }

      vertices.add(blended);
    }
    return mesh.copyWith(vertices: vertices);
  }

  Mesh _applyDamage(Mesh mesh, int damage, int seed) {
    final factor = (damage / 100).clamp(0.0, 1.0);
    final vertices = <Vec3>[];
    for (var i = 0; i < mesh.vertices.length; i++) {
      final v = mesh.vertices[i];
      var next = v;
      if (factor > 0.2) {
        final amp = (factor - 0.2) * 0.06;
        final nx = (_hash(seed, i) - 0.5) * amp;
        final ny = (_hash(seed + 5, i) - 0.5) * amp;
        final nz = (_hash(seed + 9, i) - 0.5) * amp;
        next = Vec3(next.x + nx, next.y + ny, next.z + nz);
      }
      if (factor > 0.5) {
        final sag = (factor - 0.5) * 0.3;
        next = Vec3(next.x * (1 - sag * 0.2), next.y * (1 - sag * 0.2),
            next.z - sag * 0.2);
      }
      vertices.add(next);
    }

    final faces = <Face>[];
    for (var i = 0; i < mesh.faces.length; i++) {
      var opacity = 1.0;
      if (factor > 0.8) {
        final collapseChance = (factor - 0.8) / 0.2;
        final rnd = _hash(seed + 17, i);
        opacity = rnd < collapseChance ? 0.2 : 1.0;
      }
      faces.add(mesh.faces[i].copyWith(opacity: opacity));
    }

    return mesh.copyWith(vertices: vertices, faces: faces);
  }

  void _addLayer(_MeshBuilder builder,
      {required double scale, required double z, required double rotation}) {
    final points = _rotatedDiamond(scale, rotation, z);
    builder.addQuad(points[0], points[1], points[2], points[3]);
  }

  void _addWing(_MeshBuilder builder, Vec3 a, Vec3 b, Vec3 c) {
    builder.addTriangle(a, b, c);
  }

  void _addSpine(_MeshBuilder builder,
      {required Vec3 top, required Vec3 bottom}) {
    builder.addQuad(
      Vec3(top.x - 0.1, top.y + 0.05, top.z),
      Vec3(top.x + 0.1, top.y + 0.05, top.z),
      Vec3(bottom.x + 0.15, bottom.y - 0.1, bottom.z),
      Vec3(bottom.x - 0.15, bottom.y - 0.1, bottom.z),
    );
  }

  void _addBalcony(_MeshBuilder builder,
      {required bool left, required double z}) {
    final sign = left ? -1 : 1;
    builder.addQuad(
      Vec3(sign * 1.1, -0.2, z),
      Vec3(sign * 0.7, -0.4, z + 0.05),
      Vec3(sign * 0.4, 0.2, z + 0.02),
      Vec3(sign * 0.8, 0.35, z),
    );
  }

  void _addCantilever(_MeshBuilder builder,
      {required bool left, required double depth, required double z}) {
    final sign = left ? -1 : 1;
    builder.addQuad(
      Vec3(sign * 1.2, -0.1, z),
      Vec3(sign * (1.2 + depth * 0.3), -0.2, z - 0.05),
      Vec3(sign * (1.1 + depth * 0.2), 0.35, z + 0.05),
      Vec3(sign * 0.9, 0.2, z + 0.02),
    );
  }

  void _addSpire(_MeshBuilder builder,
      {required double height, required double scale, Vec3? offset}) {
    final center = offset ?? const Vec3(0, 0, 0);
    builder.addTriangle(
      Vec3(center.x, center.y - height, center.z + height * 0.2),
      Vec3(center.x + scale, center.y - height * 0.4, center.z),
      Vec3(center.x - scale, center.y - height * 0.4, center.z),
    );
  }

  List<Vec3> _rotatedDiamond(double scale, double rotation, double z) {
    final points = [
      const Vec3(0, -1, 0),
      const Vec3(1, 0, 0),
      const Vec3(0, 1, 0),
      const Vec3(-1, 0, 0),
    ];

    return points.map((p) {
      final rx = p.x * math.cos(rotation) - p.y * math.sin(rotation);
      final ry = p.x * math.sin(rotation) + p.y * math.cos(rotation);
      return Vec3(rx * scale, ry * scale, z);
    }).toList();
  }

  double _easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    }
    final k = -2 * t + 2;
    return 1 - (k * k * k) / 2;
  }

  double _hash(int seed, int index) {
    final value = math.sin(seed * 12.9898 + index * 78.233) * 43758.5453;
    return value - value.floorToDouble();
  }
}

class _MeshBuilder {
  final List<Vec3> vertices;
  final List<Face> faces;

  _MeshBuilder(this.vertices, this.faces);

  factory _MeshBuilder.fromMesh(Mesh mesh) {
    return _MeshBuilder(
        List<Vec3>.from(mesh.vertices), List<Face>.from(mesh.faces));
  }

  int addVertex(Vec3 vertex) {
    vertices.add(vertex);
    return vertices.length - 1;
  }

  void addTriangle(Vec3 a, Vec3 b, Vec3 c) {
    final ia = addVertex(a);
    final ib = addVertex(b);
    final ic = addVertex(c);
    faces.add(Face(ia, ib, ic));
  }

  void addQuad(Vec3 a, Vec3 b, Vec3 c, Vec3 d) {
    final ia = addVertex(a);
    final ib = addVertex(b);
    final ic = addVertex(c);
    final id = addVertex(d);
    faces.add(Face(ia, ib, ic));
    faces.add(Face(ia, ic, id));
  }

  Mesh build() => Mesh(vertices: vertices, faces: faces);
}

class _PolarVertex {
  final int index;
  final Vec3 vertex;
  final double angle;

  _PolarVertex(this.index, this.vertex)
      : angle = math.atan2(vertex.y, vertex.x);
}


