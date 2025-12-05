import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get instance => _firestore;

  Future<void> enableOfflinePersistence() async {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      Logger.info('Firestore offline persistence enabled');
    } catch (e) {
      Logger.error('Failed to enable offline persistence', e);
    }
  }

  Future<DocumentReference<Map<String, dynamic>>> addDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      Logger.info('Adding document to $collection');
      final docRef = await _firestore.collection(collection).add(data);
      Logger.info('Document added with ID: ${docRef.id}');
      return docRef;
    } catch (e) {
      Logger.error('Failed to add document', e);
      rethrow;
    }
  }

  Future<void> setDocument(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      Logger.info('Setting document $collection/$docId');
      await _firestore.collection(collection).doc(docId).set(
            data,
            SetOptions(merge: merge),
          );
      Logger.info('Document set successfully');
    } catch (e) {
      Logger.error('Failed to set document', e);
      rethrow;
    }
  }

  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      Logger.info('Updating document $collection/$docId');
      await _firestore.collection(collection).doc(docId).update(data);
      Logger.info('Document updated successfully');
    } catch (e) {
      Logger.error('Failed to update document', e);
      rethrow;
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    try {
      Logger.info('Deleting document $collection/$docId');
      await _firestore.collection(collection).doc(docId).delete();
      Logger.info('Document deleted successfully');
    } catch (e) {
      Logger.error('Failed to delete document', e);
      rethrow;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    String collection,
    String docId,
  ) async {
    try {
      Logger.info('Getting document $collection/$docId');
      final snapshot = await _firestore.collection(collection).doc(docId).get();
      return snapshot;
    } catch (e) {
      Logger.error('Failed to get document', e);
      rethrow;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    String collection, {
    Query<Map<String, dynamic>>? Function(CollectionReference<Map<String, dynamic>>)? queryBuilder,
  }) async {
    try {
      Logger.info('Getting collection $collection');
      var query = _firestore.collection(collection) as Query<Map<String, dynamic>>;
      
      if (queryBuilder != null) {
        query = queryBuilder(_firestore.collection(collection))!;
      }
      
      final snapshot = await query.get();
      Logger.info('Retrieved ${snapshot.docs.length} documents');
      return snapshot;
    } catch (e) {
      Logger.error('Failed to get collection', e);
      rethrow;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument(
    String collection,
    String docId,
  ) {
    Logger.info('Streaming document $collection/$docId');
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collection, {
    Query<Map<String, dynamic>>? Function(CollectionReference<Map<String, dynamic>>)? queryBuilder,
  }) {
    Logger.info('Streaming collection $collection');
    var query = _firestore.collection(collection) as Query<Map<String, dynamic>>;
    
    if (queryBuilder != null) {
      query = queryBuilder(_firestore.collection(collection))!;
    }
    
    return query.snapshots();
  }

  Future<void> batchWrite(
    List<Map<String, dynamic>> operations,
  ) async {
    try {
      Logger.info('Starting batch write with ${operations.length} operations');
      final batch = _firestore.batch();

      for (final operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String?;
        final data = operation['data'] as Map<String, dynamic>?;

        final docRef = docId != null
            ? _firestore.collection(collection).doc(docId)
            : _firestore.collection(collection).doc();

        switch (type) {
          case 'set':
            batch.set(docRef, data!);
            break;
          case 'update':
            batch.update(docRef, data!);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
      Logger.info('Batch write completed successfully');
    } catch (e) {
      Logger.error('Batch write failed', e);
      rethrow;
    }
  }

  Future<void> incrementField(
    String collection,
    String docId,
    String field,
    num incrementValue,
  ) async {
    try {
      Logger.info('Incrementing $field by $incrementValue in $collection/$docId');
      await _firestore.collection(collection).doc(docId).update({
        field: FieldValue.increment(incrementValue),
      });
      Logger.info('Field incremented successfully');
    } catch (e) {
      Logger.error('Failed to increment field', e);
      rethrow;
    }
  }

  Future<void> arrayUnion(
    String collection,
    String docId,
    String field,
    List<dynamic> elements,
  ) async {
    try {
      Logger.info('Adding elements to array $field in $collection/$docId');
      await _firestore.collection(collection).doc(docId).update({
        field: FieldValue.arrayUnion(elements),
      });
      Logger.info('Array union completed');
    } catch (e) {
      Logger.error('Failed to union array', e);
      rethrow;
    }
  }

  Future<void> arrayRemove(
    String collection,
    String docId,
    String field,
    List<dynamic> elements,
  ) async {
    try {
      Logger.info('Removing elements from array $field in $collection/$docId');
      await _firestore.collection(collection).doc(docId).update({
        field: FieldValue.arrayRemove(elements),
      });
      Logger.info('Array remove completed');
    } catch (e) {
      Logger.error('Failed to remove from array', e);
      rethrow;
    }
  }

  Timestamp now() => Timestamp.now();
  
  Timestamp fromDateTime(DateTime dateTime) => Timestamp.fromDate(dateTime);
  
  DateTime toDateTime(Timestamp timestamp) => timestamp.toDate();
}
