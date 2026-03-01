import 'package:cloud_firestore/cloud_firestore.dart';

class MiniGameModel {
  final String id;
  final String name;
  final String playUrl;
  final String icon;
  final int order;

  const MiniGameModel({
    required this.id,
    required this.name,
    required this.playUrl,
    required this.icon,
    required this.order,
  });

  factory MiniGameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MiniGameModel(
      id: doc.id,
      name: data['name'] ?? '',
      playUrl: data['playUrl'] ?? '',
      icon: data['icon'] ?? '',
      order: data['order'] ?? 0,
    );
  }
}
