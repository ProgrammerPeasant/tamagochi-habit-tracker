import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_time.dart';
import '../../../core/storage/memory_store.dart';
import '../domain/pet_state.dart';

class PetLocalDataSource {
  static const _id = 'main';

  Future<PetState?> getPetState() async {
    if (kIsWeb) {
      return MemoryStore.instance.petState;
    }

    final db = await AppDatabase.instance.database;
    final rows = await db.query('pet_state',
        where: 'id = ?', whereArgs: [_id], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final complexity = row['structure_complexity'] as int? ?? 0;
    return PetState(
      level: row['level'] as int? ?? levelForComplexity(complexity),
      structureComplexity: complexity,
      damage: row['damage'] as int? ?? 0,
      energy: row['energy'] as int? ?? 0,
      mood: row['mood'] as int? ?? 0,
      stage: stageForComplexity(complexity),
    );
  }

  Future<void> upsertPetState(PetState state, DateTime updatedAt) async {
    if (kIsWeb) {
      MemoryStore.instance.petState = state;
      return;
    }

    final db = await AppDatabase.instance.database;
    await db.insert(
      'pet_state',
      {
        'id': _id,
        'level': state.level,
        'structure_complexity': state.structureComplexity,
        'damage': state.damage,
        'energy': state.energy,
        'mood': state.mood,
        'updated_at': DbTime.format(updatedAt),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
