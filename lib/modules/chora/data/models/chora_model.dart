import 'package:cloud_firestore/cloud_firestore.dart';

class ChoraModel {
  final String id;
  final String title;
  final String audioUrl;
  final String coverImage;
  final String backgroundImage;
  final String text;
  final int order;
  final double duration;
  final String author;

  const ChoraModel({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.coverImage,
    required this.backgroundImage,
    required this.text,
    required this.order,
    required this.duration,
    required this.author,
  });

  factory ChoraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChoraModel(
      id: doc.id,
      title: data['title'] ?? '',
      audioUrl: data['audio_url'] ?? '',
      coverImage: data['cover_image'] ?? '',
      backgroundImage: data['background_image'] ?? '',
      text: data['text'] ?? '',
      order: data['order'] ?? 0,
      duration: (data['duration'] ?? 0.0).toDouble(),
      author: data["author"] ?? "",
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'audio_url': audioUrl,
      'cover_image': coverImage,
      'background_image': backgroundImage,
      'text': text,
      'order': order,
      'duration': duration,
    };
  }

  List<String> get textLines {
    return text.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }
}
