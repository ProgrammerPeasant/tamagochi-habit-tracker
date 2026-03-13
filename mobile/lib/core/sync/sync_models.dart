class SyncChange {
  final String entity;
  final String op;
  final String id;
  final String updatedAt;
  final Map<String, dynamic> payload;

  SyncChange({
    required this.entity,
    required this.op,
    required this.id,
    required this.updatedAt,
    required this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'entity': entity,
      'op': op,
      'id': id,
      'updated_at': updatedAt,
      'payload': payload,
    };
  }

  factory SyncChange.fromJson(Map<String, dynamic> json) {
    return SyncChange(
      entity: json['entity'] as String,
      op: json['op'] as String,
      id: json['id'] as String,
      updatedAt: json['updated_at'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

class SyncResponse {
  final String cursor;
  final List<SyncChange> changes;

  SyncResponse({required this.cursor, required this.changes});

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['changes'] as List<dynamic>? ?? [])
        .map((item) =>
            SyncChange.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return SyncResponse(cursor: json['cursor'] as String, changes: items);
  }
}
