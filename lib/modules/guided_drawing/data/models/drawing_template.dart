/// A drawing template — just images, no waypoints.
/// The outline image IS the guide; the reference shows the goal.
class DrawingTemplate {
  final String id;
  final String name;
  final String category; // 'fruit', 'animal', 'shape', etc.

  /// Black outlines on pure white — shown faintly during tracing,
  /// then used as the flood-fill canvas during coloring.
  final String outlineImage;

  /// Fully colored reference — shown as preview/goal.
  final String referenceImage;

  const DrawingTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.outlineImage,
    required this.referenceImage,
  });

  bool get isNetworkImage =>
      outlineImage.startsWith('http://') ||
      outlineImage.startsWith('https://');

  /// Create from Firestore document
  factory DrawingTemplate.fromJson(Map<String, dynamic> json) {
    return DrawingTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      outlineImage: json['outlineImage'] as String,
      referenceImage: json['referenceImage'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'outlineImage': outlineImage,
        'referenceImage': referenceImage,
      };
}
