import 'package:kids_learning/modules/stories/data/models/story_model.dart';
import 'package:kids_learning/modules/stories/data/services/stories_firebase_service.dart';

/// Result class for paginated story queries
class PaginatedStoryResult {
  final List<StoryModel> stories;
  final bool hasMore;

  PaginatedStoryResult({required this.stories, required this.hasMore});
}

/// Repository for managing stories data
/// Supports both Firebase (cloud) and local fallback data
class StoryRepository {
  static final StoryRepository _instance = StoryRepository._internal();
  factory StoryRepository() => _instance;
  StoryRepository._internal();

  final StoriesFirebaseService _firebaseService = StoriesFirebaseService();
  
  /// Cache for stories to reduce Firebase calls
  List<StoryModel>? _cachedStories;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  /// Check if cache is valid
  bool get _isCacheValid {
    if (_cachedStories == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }

  /// Get all stories from Firebase with caching
  /// Returns empty list if Firebase is unavailable
  Future<List<StoryModel>> getAllStories() async {
    // Return cached data if valid
    if (_isCacheValid) {
      return _cachedStories!;
    }

    try {
      // Try to fetch from Firebase
      final stories = await _firebaseService.getAllStories();

      if (stories.isNotEmpty) {
        _cachedStories = stories;
        _cacheTimestamp = DateTime.now();
        return stories;
      }
    } catch (e) {
      print('Firebase fetch failed: $e');
    }

    // Return empty list if no data available
    _cachedStories = [];
    _cacheTimestamp = DateTime.now();
    return [];
  }

  /// Get all stories as a stream (real-time updates from Firebase)
  Stream<List<StoryModel>> getAllStoriesStream() {
    return _firebaseService.getAllStoriesStream();
  }

  /// Get stories with pagination
  /// Returns a PaginatedStoryResult containing stories and hasMore flag
  Future<PaginatedStoryResult> getStoriesPaginated({
    required int limit,
    required int page,
  }) async {
    // For local data, implement pagination manually
    final allStories = await getAllStories();
    
    final startIndex = page * limit;
    if (startIndex >= allStories.length) {
      return PaginatedStoryResult(stories: [], hasMore: false);
    }
    
    final endIndex = (startIndex + limit > allStories.length)
        ? allStories.length
        : startIndex + limit;
    
    final stories = allStories.sublist(startIndex, endIndex);
    final hasMore = endIndex < allStories.length;
    
    return PaginatedStoryResult(stories: stories, hasMore: hasMore);
  }

  /// Get stories by category
  Future<List<StoryModel>> getStoriesByCategory(String category) async {
    try {
      final stories = await _firebaseService.getStoriesByCategory(category);
      if (stories.isNotEmpty) {
        return stories;
      }
    } catch (e) {
      print('Firebase fetch failed: $e');
    }

    // Fallback to local filtering
    return getAllStories().then((allStories) =>
        allStories.where((story) => story.category == category).toList());
  }

  /// Get a specific story by ID
  Future<StoryModel?> getStoryById(String id) async {
    try {
      // Try Firebase first
      final story = await _firebaseService.getStoryById(id);
      if (story != null) {
        return story;
      }
    } catch (e) {
      print('Firebase fetch failed: $e');
    }

    // Fallback to local data
    final allStories = await getAllStories();
    try {
      return allStories.firstWhere((story) => story.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get featured stories
  Future<List<StoryModel>> getFeaturedStories() async {
    try {
      final stories = await _firebaseService.getFeaturedStories();
      if (stories.isNotEmpty) {
        return stories;
      }
    } catch (e) {
      print('Firebase fetch failed: $e');
    }

    // Fallback to local data
    final allStories = await getAllStories();
    return allStories.where((story) => story.isFeatured).take(5).toList();
  }

  /// Search stories by query
  Future<List<StoryModel>> searchStories(String query) async {
    if (query.isEmpty) return [];

    try {
      final stories = await _firebaseService.searchStories(query);
      if (stories.isNotEmpty) {
        return stories;
      }
    } catch (e) {
      print('Firebase search failed: $e');
    }

    // Fallback to local search
    final allStories = await getAllStories();
    final lowercaseQuery = query.toLowerCase();
    return allStories.where((story) =>
        story.title.toLowerCase().contains(lowercaseQuery) ||
        story.description.toLowerCase().contains(lowercaseQuery) ||
        story.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))).toList();
  }

  /// Get user's reading progress for a story
  Future<UserStoryProgress?> getUserProgress(String storyId) async {
    return await _firebaseService.getUserProgress(storyId);
  }

  /// Update user's reading progress
  Future<void> updateUserProgress({
    required String storyId,
    required int currentPage,
    required bool isCompleted,
    Duration? timeSpent,
  }) async {
    await _firebaseService.updateUserProgress(
      storyId: storyId,
      currentPage: currentPage,
      isCompleted: isCompleted,
      timeSpent: timeSpent,
    );
  }

  /// Mark a story as completed
  Future<void> markStoryCompleted(String storyId) async {
    await _firebaseService.markStoryCompleted(storyId);
  }

  /// Get user's reading statistics
  Future<ReadingStats> getUserStats() async {
    return await _firebaseService.getUserStats();
  }

  /// Clear the cache
  void clearCache() {
    _cachedStories = null;
    _cacheTimestamp = null;
  }

  /// Refresh data from Firebase
  Future<void> refresh() async {
    clearCache();
    await getAllStories();
  }
}
