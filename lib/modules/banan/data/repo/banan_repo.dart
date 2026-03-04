import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kids_learning/modules/banan/data/models/banan_data_model.dart';

class BananRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'banan_problems';

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  bool get hasMoreData => _hasMore;

  Future<List<BananProblemModel>> fetchProblems({
    String? language, // 'english' | 'bengali' | null (both)
    int limit = 10,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName);

      // Apply language filter if provided
      if (language != null) {
        query = query.where('language', isEqualTo: language);
      }

      // Order by difficulty
      query = query.orderBy('difficulty').limit(limit);

      // Apply pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      // If no docs are found, we've reached the end
      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        debugPrint('[BananRepo] No more problems found in Firebase.');
        return [];
      }

      // Update pagination cursor
      _lastDocument = snapshot.docs.last;

      // If we got fewer docs than requested, there are no more left to fetch
      if (snapshot.docs.length < limit) {
        _hasMore = false;
      }

      // Map Firestore docs to our Model
      final problems =
          snapshot.docs
              .map((doc) => BananProblemModel.fromFirestore(doc))
              .toList()
            ..shuffle();

      debugPrint(
        '[BananRepo] Fetched ${problems.length} problems from Firebase.',
      );
      return problems;
    } on FirebaseException catch (e) {
      // 🚨 CRITICAL: This will expose if you are missing a Firestore index
      debugPrint('[BananRepo] Firebase Error: ${e.code} - ${e.message}');

      // If the error contains a URL, it's asking you to create an index.
      if (e.message != null &&
          e.message!.contains('https://console.firebase.google.com')) {
        debugPrint(
          '👉 CLICK THE LINK IN THE ERROR ABOVE TO CREATE THE REQUIRED INDEX 👈',
        );
      }

      return [];
    } catch (e) {
      debugPrint('[BananRepo] General Error fetching data: $e');
      return [];
    }
  }

  void resetPagination() {
    _lastDocument = null;
    _hasMore = true;
  }
}
