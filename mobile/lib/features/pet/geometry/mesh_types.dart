import 'dart:math' as math;

class Vec3 {
  final double x;
  final double y;
  final double z;

  const Vec3(this.x, this.y, this.z);

  Vec3 copyWith({double? x, double? y, double? z}) {
    return Vec3(x ?? this.x, y ?? this.y, z ?? this.z);
  }

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);

  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);

  Vec3 operator *(double scalar) => Vec3(x * scalar, y * scalar, z * scalar);

  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;

  Vec3 cross(Vec3 other) {
    return Vec3(
      y * other.z - z * other.y,
      z * other.x - x * other.z,
      x * other.y - y * other.x,
    );
  }

  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 normalized() {
    final len = length;
    if (len == 0) {
      return const Vec3(0, 0, 0);
    }
    return Vec3(x / len, y / len, z / len);
  }

  Vec3 lerp(Vec3 other, double t) {
    return Vec3(
      x + (other.x - x) * t,
      y + (other.y - y) * t,
      z + (other.z - z) * t,
    );
  }

  List<double> toList() => [x, y, z];
}

class Face {
  final int a;
  final int b;
  final int c;
  final double opacity;

  const Face(this.a, this.b, this.c, {this.opacity = 1.0});

  Face copyWith({double? opacity}) {
    return Face(a, b, c, opacity: opacity ?? this.opacity);
  }

  List<int> toList() => [a, b, c];
}

class Mesh {
  final List<Vec3> vertices;
  final List<Face> faces;

  const Mesh({required this.vertices, required this.faces});

  Mesh copyWith({List<Vec3>? vertices, List<Face>? faces}) {
    return Mesh(
      vertices: vertices ?? this.vertices,
      faces: faces ?? this.faces,
    );
  }
}
