class PetState {
  final int level;
  final int structureComplexity;
  final int damage;
  final int energy;
  final int mood;
  final PetStage stage;

  const PetState({
    required this.level,
    required this.structureComplexity,
    required this.damage,
    required this.energy,
    required this.mood,
    required this.stage,
  });

  PetState copyWith({
    int? level,
    int? structureComplexity,
    int? damage,
    int? energy,
    int? mood,
    PetStage? stage,
  }) {
    return PetState(
      level: level ?? this.level,
      structureComplexity: structureComplexity ?? this.structureComplexity,
      damage: damage ?? this.damage,
      energy: energy ?? this.energy,
      mood: mood ?? this.mood,
      stage: stage ?? this.stage,
    );
  }
}

enum PetStage {
  flatSheet,
  simpleFold,
  geometricAnimal,
  complexSculpture,
  architectural,
}

PetStage stageForComplexity(int complexity) {
  if (complexity < 20) {
    return PetStage.flatSheet;
  }
  if (complexity < 40) {
    return PetStage.simpleFold;
  }
  if (complexity < 60) {
    return PetStage.geometricAnimal;
  }
  if (complexity < 80) {
    return PetStage.complexSculpture;
  }
  return PetStage.architectural;
}

int levelForComplexity(int complexity) {
  if (complexity < 20) {
    return 1;
  }
  if (complexity < 40) {
    return 2;
  }
  if (complexity < 60) {
    return 3;
  }
  if (complexity < 80) {
    return 4;
  }
  return 5;
}
