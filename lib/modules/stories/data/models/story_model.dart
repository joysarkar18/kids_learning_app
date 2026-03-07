import 'package:equatable/equatable.dart';

/// Model representing a single story with multiple pages
/// Supports both local assets and remote URLs from Firebase
class StoryModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String coverImage; // Can be local path or URL
  final String category; // e.g., 'jungle', 'adventure', 'moral'
  final List<StoryPage> pages;
  final Duration estimatedDuration;
  final String? difficulty; // 'easy', 'medium', 'hard'
  final List<String> tags;
  final bool isFeatured;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImage,
    required this.category,
    required this.pages,
    this.estimatedDuration = const Duration(minutes: 5),
    this.difficulty,
    this.tags = const [],
    this.isFeatured = false,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  int get totalPages => pages.length;

  /// Check if cover image is a URL
  bool get isCoverImageUrl => coverImage.startsWith('http://') || coverImage.startsWith('https://');

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        coverImage,
        category,
        pages,
        estimatedDuration,
        difficulty,
        tags,
        isFeatured,
        order,
        createdAt,
        updatedAt,
      ];

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverImage': coverImage,
      'category': category,
      'pages': pages.map((page) => page.toJson()).toList(),
      'estimatedDuration': estimatedDuration.inMinutes,
      'difficulty': difficulty,
      'tags': tags,
      'isFeatured': isFeatured,
      'order': order,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create from Firebase JSON
  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverImage: json['coverImage'] as String? ?? '',
      category: json['category'] as String? ?? '',
      pages: (json['pages'] as List<dynamic>?)
              ?.map((page) => StoryPage.fromJson(page as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedDuration: Duration(
        minutes: json['estimatedDuration'] as int? ?? 5,
      ),
      difficulty: json['difficulty'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isFeatured: json['isFeatured'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

/// Model representing a single page in a story
/// Supports both local assets and remote URLs
class StoryPage extends Equatable {
  final int pageNumber;
  final String text;
  final String image; // Can be local path or URL
  final String? audio; // Can be local path or URL
  final String? narration; // Can be local path or URL
  final PageLayout? layout;
  final AnimationType? animationType;
  final String? backgroundImage; // Optional background for the page
  final List<InteractiveElement>? interactiveElements;

  const StoryPage({
    required this.pageNumber,
    required this.text,
    required this.image,
    this.audio,
    this.narration,
    this.layout,
    this.animationType,
    this.backgroundImage,
    this.interactiveElements,
  });

  /// Check if image is a URL
  bool get isImageUrl => image.startsWith('http://') || image.startsWith('https://');

  /// Check if audio is a URL
  bool get isAudioUrl => audio?.startsWith('http://') ?? false;

  /// Check if narration is a URL
  bool get isNarrationUrl => narration?.startsWith('http://') ?? false;

  @override
  List<Object?> get props => [
        pageNumber,
        text,
        image,
        audio,
        narration,
        layout,
        animationType,
        backgroundImage,
        interactiveElements,
      ];

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'text': text,
      'image': image,
      'audio': audio,
      'narration': narration,
      'layout': layout?.index,
      'animationType': animationType?.index,
      'backgroundImage': backgroundImage,
      'interactiveElements': interactiveElements?.map((e) => e.toJson()).toList(),
    };
  }

  /// Create from Firebase JSON
  factory StoryPage.fromJson(Map<String, dynamic> json) {
    return StoryPage(
      pageNumber: json['pageNumber'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      image: json['image'] as String? ?? '',
      audio: json['audio'] as String?,
      narration: json['narration'] as String?,
      layout: json['layout'] != null
          ? PageLayout.values[json['layout'] as int]
          : null,
      animationType: json['animationType'] != null
          ? AnimationType.values[json['animationType'] as int]
          : null,
      backgroundImage: json['backgroundImage'] as String?,
      interactiveElements: (json['interactiveElements'] as List<dynamic>?)
          ?.map((e) => InteractiveElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Layout options for story pages
enum PageLayout {
  imageTop, // Image on top, text below (default)
  imageBottom, // Text on top, image below
  imageLeft, // Image on left, text on right
  imageRight, // Text on left, image on right
  fullImage, // Full page image with overlay text
}

/// Animation types for page transitions
enum AnimationType {
  pageTurnRightToLeft, // Classic book page turn
  pageTurnLeftToRight, // Reverse page turn
  fade, // Simple fade transition
  slide, // Slide transition
  zoom, // Zoom in/out effect
  flip, // Flip card effect
}

/// Interactive elements that can be added to pages
class InteractiveElement extends Equatable {
  final String id;
  final InteractiveElementType type;
  final String content; // URL or text
  final double x; // Position (0-1)
  final double y; // Position (0-1)
  final double width; // Size (0-1)
  final double height; // Size (0-1)
  final String? action; // Action to trigger
  final String? feedback; // Visual/audio feedback

  const InteractiveElement({
    required this.id,
    required this.type,
    required this.content,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.action,
    this.feedback,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'content': content,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'action': action,
      'feedback': feedback,
    };
  }

  factory InteractiveElement.fromJson(Map<String, dynamic> json) {
    return InteractiveElement(
      id: json['id'] as String? ?? '',
      type: InteractiveElementType.values[json['type'] as int],
      content: json['content'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      width: (json['width'] as num?)?.toDouble() ?? 0.2,
      height: (json['height'] as num?)?.toDouble() ?? 0.2,
      action: json['action'] as String?,
      feedback: json['feedback'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        content,
        x,
        y,
        width,
        height,
        action,
        feedback,
      ];
}

/// Types of interactive elements
enum InteractiveElementType {
  button, // Clickable button
  image, // Tappable image
  audio, // Audio hotspot
  animation, // Animated element
  text, // Highlighted text
}
