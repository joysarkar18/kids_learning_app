import 'package:cloud_firestore/cloud_firestore.dart';

class ChoraImageSegment {
  final String imagePath;
  final String text;
  final double startTime;
  final double endTime;

  const ChoraImageSegment({
    required this.imagePath,
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory ChoraImageSegment.fromJson(Map<String, dynamic> json) {
    return ChoraImageSegment(
      imagePath: json['image_path'] ?? '',
      text: json['text'] ?? '',
      startTime: (json['start_time'] ?? 0.0).toDouble(),
      endTime: (json['end_time'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_path': imagePath,
      'text': text,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

class ChoraModel {
  final String id;
  final String title;
  final String audioPath;
  final String thumbnailUrl;
  final int order;
  final List<ChoraImageSegment> imageSegments;
  final double duration;

  const ChoraModel({
    required this.id,
    required this.title,
    required this.audioPath,
    required this.thumbnailUrl,
    required this.order,
    required this.imageSegments,
    required this.duration,
  });

  factory ChoraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final segmentsJson = data['image_segments'] as List<dynamic>? ?? [];
    final imageSegments = segmentsJson
        .map((s) => ChoraImageSegment.fromJson(s as Map<String, dynamic>))
        .toList();

    return ChoraModel(
      id: doc.id,
      title: data['title'] ?? '',
      audioPath: data['audio_path'] ?? '',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      order: data['order'] ?? 0,
      imageSegments: imageSegments,
      duration: (data['duration'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'audio_path': audioPath,
      'thumbnail_url': thumbnailUrl,
      'order': order,
      'image_segments': imageSegments.map((s) => s.toJson()).toList(),
      'duration': duration,
    };
  }
}
