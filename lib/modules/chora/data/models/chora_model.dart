import 'package:cloud_firestore/cloud_firestore.dart';

class ChoraModel {
  final String id;
  final String title;
  final String text;
  final String youtubeUrl;
  final String thumbnailUrl;
  final int order;

  const ChoraModel({
    required this.id,
    required this.title,
    required this.text,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.order,
  });

  factory ChoraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChoraModel(
      id: doc.id,
      title: data['title'] ?? '',
      text: data['text'] ?? '',
      youtubeUrl: data['youtube_url'] ?? '',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      order: data['order'] ?? 0,
    );
  }
}
