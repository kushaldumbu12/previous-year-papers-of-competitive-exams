class CategoryModel {
  final String id;
  final String name;
  final bool isHidden;
  final String description;
  final String iconName;
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    this.isHidden = false,
    this.description = '',
    this.iconName = 'category',
    this.order = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isHidden': isHidden,
      'description': description,
      'iconName': iconName,
      'order': order,
    };
  }

  factory CategoryModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return CategoryModel(
      id: docId,
      name: data['name'] ?? docId,
      isHidden: data['isHidden'] ?? false,
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'category',
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    bool? isHidden,
    String? description,
    String? iconName,
    int? order,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isHidden: isHidden ?? this.isHidden,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      order: order ?? this.order,
    );
  }
}
