import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mini_game_model.dart';

class MiniGameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'mini_games';

  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  bool get hasMoreData => _hasMoreData;

  Future<List<MiniGameModel>> fetchGames({int limit = 10}) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('order')
          .limit(limit);

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

      return snapshot.docs
          .map((doc) => MiniGameModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch mini games: $e');
    }
  }

  void resetPagination() {
    _lastDocument = null;
    _hasMoreData = true;
  }
}
