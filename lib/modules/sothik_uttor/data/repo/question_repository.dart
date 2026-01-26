import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class QuestionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'questionAnswer';

  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  bool get hasMoreData => _hasMoreData;

  Future<List<QuestionModel>> fetchQuestions({int limit = 50}) async {
    try {
      Query query = _firestore.collection(_collectionName).limit(limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMoreData = false;
        return [];
      }

      _lastDocument = snapshot.docs.last;

      if (snapshot.docs.length < limit) {
        _hasMoreData = false;
      }

      final questions = snapshot.docs
          .map((doc) => QuestionModel.fromFirestore(doc))
          .toList();

      // Shuffle the questions
      questions.shuffle();

      return questions;
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  void resetPagination() {
    _lastDocument = null;
    _hasMoreData = true;
  }
}
