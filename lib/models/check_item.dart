class CheckItem {
  final String id;
  final String category;
  final String title;
  final String description;
  bool isChecked;
  String? comment;
  final int orderIndex;

  CheckItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.isChecked = false,
    this.comment,
    required this.orderIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'isChecked': isChecked ? 1 : 0,
      'comment': comment,
      'orderIndex': orderIndex,
    };
  }

  factory CheckItem.fromMap(Map<String, dynamic> map) {
    return CheckItem(
      id: map['id'],
      category: map['category'],
      title: map['title'],
      description: map['description'],
      isChecked: map['isChecked'] == 1,
      comment: map['comment'],
      orderIndex: map['orderIndex'],
    );
  }
}
