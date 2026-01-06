class FirstAidGuide {
  final String id;
  final String title;
  final List<String> tags;
  final String size;
  final int steps;
  final int warnings;
  final List<String> treatmentContent;
  final List<String> warningContent;
  final String? language;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FirstAidGuide({
    required this.id,
    required this.title,
    required this.tags,
    required this.size,
    required this.steps,
    required this.warnings,
    required this.treatmentContent,
    required this.warningContent,
    this.language,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'tags': tags,
      'size': size,
      'steps': steps,
      'warnings': warnings,
      'treatmentContent': treatmentContent,
      'warningContent': warningContent,
      'language': language ?? 'English',
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory FirstAidGuide.fromMap(String id, Map<String, dynamic> map) {
    return FirstAidGuide(
      id: id,
      title: map['title'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      size: map['size'] ?? '0 MB',
      steps: map['steps'] ?? 0,
      warnings: map['warnings'] ?? 0,
      treatmentContent: List<String>.from(map['treatmentContent'] ?? []),
      warningContent: List<String>.from(map['warningContent'] ?? []),
      language: map['language'] ?? 'English',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  // Create a copy with updated fields
  FirstAidGuide copyWith({
    String? id,
    String? title,
    List<String>? tags,
    String? size,
    int? steps,
    int? warnings,
    List<String>? treatmentContent,
    List<String>? warningContent,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirstAidGuide(
      id: id ?? this.id,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      size: size ?? this.size,
      steps: steps ?? this.steps,
      warnings: warnings ?? this.warnings,
      treatmentContent: treatmentContent ?? this.treatmentContent,
      warningContent: warningContent ?? this.warningContent,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

