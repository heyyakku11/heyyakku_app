class CategoryResponse {
  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final DateTime createdAt;

  const CategoryResponse({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.createdAt,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
