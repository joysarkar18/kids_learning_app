import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chora_model.dart';

class ChoraRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'choras';

  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  bool get hasMoreData => _hasMoreData;

  Future<List<ChoraModel>> fetchChoras({int limit = 20}) async {
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

      return snapshot.docs.map((doc) => ChoraModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch choras: $e');
    }
  }

  void resetPagination() {
    _lastDocument = null;
    _hasMoreData = true;
  }
}
