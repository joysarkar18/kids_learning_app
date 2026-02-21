import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gonit_problem_model.dart';
import '../gonit_dummy_data.dart';

class GanitRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'gonit_problems';

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _useDummyData = false;

  bool get hasMoreData {
    if (_useDummyData) return true;
    return _hasMore;
  }

  Future<List<GanitProblemModel>> fetchProblems({
    String? type,
    int limit = 20,
  }) async {
    if (_useDummyData) {
      return GanitDummyData.getProblems(
        difficulty: 1,
        type: type,
        count: limit,
      );
    }

    try {
      Query query = _firestore.collection(_collectionName);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      query = query.limit(limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty && _lastDocument == null) {
        debugPrint('Firestore collection empty, using dummy data');
        _useDummyData = true;
        return GanitDummyData.getProblems(
          difficulty: 1,
          type: type,
          count: limit,
        );
      }

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        return [];
      }

      _lastDocument = snapshot.docs.last;

      if (snapshot.docs.length < limit) {
        _hasMore = false;
      }

      final problems = snapshot.docs
          .map((doc) => GanitProblemModel.fromFirestore(doc))
          .toList();

      problems.shuffle();
      return problems;
    } catch (e) {
      debugPrint('Firestore error, using dummy data: $e');
      _useDummyData = true;
      return GanitDummyData.getProblems(
        difficulty: 1,
        type: type,
        count: limit,
      );
    }
  }

  void resetPagination() {
    _lastDocument = null;
    _hasMore = true;
  }
}
