import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kids_learning/modules/stories/data/models/story_model.dart';

/// Service for managing stories data with Firebase Firestore
/// Handles Firestore queries and user progress tracking
///
/// Note: This service expects direct URLs for images and audio
/// (e.g., from CDN, S3, or any hosting service) stored in Firestore.
/// No Firebase Storage integration needed.
class StoriesFirebaseService {
  static final StoriesFirebaseService _instance =
      StoriesFirebaseService._internal();
  factory StoriesFirebaseService() => _instance;
  StoriesFirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection reference for stories
  CollectionReference get _storiesCollection =>
      _firestore.collection('stories');

  /// Collection reference for user story progress
  CollectionReference get _userProgressCollection =>
      _firestore.collection('user_story_progress');

  /// Get all stories from Firestore
  /// Returns a stream of story lists for real-time updates
  Stream<List<StoryModel>> getAllStoriesStream() {
    return _storiesCollection
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => StoryModel.fromJson(
                  Map<String, dynamic>.from(doc.data() as Map),
                ),
              )
              .toList();
        });
  }

  /// Get all stories (one-time fetch)
  Future<List<StoryModel>> getAllStories() async {
    try {
      final snapshot = await _storiesCollection
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => StoryModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching stories: $e');
      return [];
    }
  }

  /// Get stories by category
  Future<List<StoryModel>> getStoriesByCategory(String category) async {
    try {
      final snapshot = await _storiesCollection
          .where('category', isEqualTo: category)
          .orderBy('order', descending: false)
          .get();

      return snapshot.docs
          .map(
            (doc) => StoryModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching stories by category: $e');
      return [];
    }
  }

  /// Get featured stories
  Future<List<StoryModel>> getFeaturedStories() async {
    try {
      final snapshot = await _storiesCollection
          .where('isFeatured', isEqualTo: true)
          .orderBy('order', descending: false)
          .limit(5)
          .get();

      return snapshot.docs
          .map(
            (doc) => StoryModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching featured stories: $e');
      return [];
    }
  }

  /// Get a specific story by ID
  Future<StoryModel?> getStoryById(String id) async {
    try {
      final doc = await _storiesCollection.doc(id).get();

      if (doc.exists) {
        return StoryModel.fromJson(
          Map<String, dynamic>.from(doc.data() as Map),
        );
      }
      return null;
    } catch (e) {
      print('Error fetching story: $e');
      return null;
    }
  }

  /// Get stories with pagination
  Future<List<StoryModel>> getStoriesPaginated({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _storiesCollection.orderBy('order', descending: false);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map(
            (doc) => StoryModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('Error fetching paginated stories: $e');
      return [];
    }
  }

  /// Search stories by title or description
  Future<List<StoryModel>> searchStories(String query) async {
    try {
      // Note: For production, use Algolia or ElasticSearch for better search
      final snapshot = await _storiesCollection.get();

      final lowercaseQuery = query.toLowerCase();
      return snapshot.docs
          .map(
            (doc) => StoryModel.fromJson(
              Map<String, dynamic>.from(doc.data() as Map),
            ),
          )
          .where(
            (story) =>
                story.title.toLowerCase().contains(lowercaseQuery) ||
                story.description.toLowerCase().contains(lowercaseQuery) ||
                story.tags.any(
                  (tag) => tag.toLowerCase().contains(lowercaseQuery),
                ),
          )
          .toList();
    } catch (e) {
      print('Error searching stories: $e');
      return [];
    }
  }

  /// Get user's reading progress for a story
  Future<UserStoryProgress?> getUserProgress(String storyId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _userProgressCollection
          .doc(userId)
          .collection('progress')
          .doc(storyId)
          .get();

      if (doc.exists) {
        return UserStoryProgress.fromJson(
          Map<String, dynamic>.from(doc.data() as Map),
        );
      }
      return null;
    } catch (e) {
      print('Error fetching user progress: $e');
      return null;
    }
  }

  /// Update user's reading progress
  Future<void> updateUserProgress({
    required String storyId,
    required int currentPage,
    required bool isCompleted,
    Duration? timeSpent,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final progressRef = _userProgressCollection
          .doc(userId)
          .collection('progress')
          .doc(storyId);

      await progressRef.set({
        'storyId': storyId,
        'currentPage': currentPage,
        'isCompleted': isCompleted,
        'lastReadAt': FieldValue.serverTimestamp(),
        if (timeSpent != null)
          'totalTimeSpent': FieldValue.increment(timeSpent.inSeconds),
        'userId': userId,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user progress: $e');
    }
  }

  /// Mark a story as completed
  Future<void> markStoryCompleted(String storyId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await updateUserProgress(
        storyId: storyId,
        currentPage: 0,
        isCompleted: true,
      );
    } catch (e) {
      print('Error marking story completed: $e');
    }
  }

  /// Get user's total reading stats
  Future<ReadingStats> getUserStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return const ReadingStats();

      final snapshot = await _userProgressCollection
          .doc(userId)
          .collection('progress')
          .where('isCompleted', isEqualTo: true)
          .get();

      int totalStoriesCompleted = snapshot.docs.length;
      int totalMinutesRead = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timeSpent = data['totalTimeSpent'] ?? 0;
        totalMinutesRead += timeSpent is int ? timeSpent : 0;
      }

      return ReadingStats(
        storiesCompleted: totalStoriesCompleted,
        minutesRead: totalMinutesRead ~/ 60,
      );
    } catch (e) {
      print('Error fetching user stats: $e');
      return const ReadingStats();
    }
  }

  /// Create a new story in Firestore
  Future<void> createStory(StoryModel story) async {
    try {
      await _storiesCollection.doc(story.id).set(story.toJson());
    } catch (e) {
      print('Error creating story: $e');
      rethrow;
    }
  }

  /// Update an existing story
  Future<void> updateStory(StoryModel story) async {
    try {
      await _storiesCollection.doc(story.id).update({
        ...story.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating story: $e');
      rethrow;
    }
  }

  /// Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      await _storiesCollection.doc(storyId).delete();
    } catch (e) {
      print('Error deleting story: $e');
      rethrow;
    }
  }
}

/// User's progress for a specific story
class UserStoryProgress {
  final String storyId;
  final int currentPage;
  final bool isCompleted;
  final DateTime? lastReadAt;
  final int totalTimeSpent; // in seconds
  final List<int> completedPages;

  const UserStoryProgress({
    required this.storyId,
    required this.currentPage,
    required this.isCompleted,
    this.lastReadAt,
    this.totalTimeSpent = 0,
    this.completedPages = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'currentPage': currentPage,
      'isCompleted': isCompleted,
      'lastReadAt': lastReadAt?.toIso8601String(),
      'totalTimeSpent': totalTimeSpent,
      'completedPages': completedPages,
    };
  }

  factory UserStoryProgress.fromJson(Map<String, dynamic> json) {
    return UserStoryProgress(
      storyId: json['storyId'] as String? ?? '',
      currentPage: json['currentPage'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'] as String)
          : null,
      totalTimeSpent: json['totalTimeSpent'] as int? ?? 0,
      completedPages:
          (json['completedPages'] as List<dynamic>?)?.cast<int>() ?? [],
    );
  }

  double get completionPercentage =>
      completedPages.isEmpty ? 0 : (completedPages.length / 100).clamp(0, 1);
}

/// User's overall reading statistics
class ReadingStats {
  final int storiesCompleted;
  final int minutesRead;

  const ReadingStats({this.storiesCompleted = 0, this.minutesRead = 0});
}
