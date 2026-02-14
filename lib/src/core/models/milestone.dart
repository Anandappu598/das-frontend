class Milestone {
  final String id;
  final String name;
  final bool completed;
  final int weight;

  Milestone({
    required this.id,
    required this.name,
    required this.completed,
    required this.weight,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String,
      name: json['name'] as String,
      completed: json['completed'] as bool? ?? false,
      weight: json['weight'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
      'weight': weight,
    };
  }
}
