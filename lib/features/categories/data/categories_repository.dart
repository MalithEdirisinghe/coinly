import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coinly/core/constants/transaction_categories.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';

class CategoriesRepository {
  CategoriesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<TransactionCategoryOption>> watchCustomCategories(String userId) {
    return _categoriesRef(userId).snapshots().map(
      (snapshot) =>
          snapshot.docs.map(_customCategoryFromDoc).toList(growable: false)
            ..sort((a, b) {
              final typeCompare = a.type.index.compareTo(b.type.index);
              if (typeCompare != 0) {
                return typeCompare;
              }
              return a.label.toLowerCase().compareTo(b.label.toLowerCase());
            }),
    );
  }

  Future<void> addCategory({
    required String userId,
    required String name,
    required TransactionType type,
    required String iconKey,
  }) {
    return _categoriesRef(userId).add({
      'name': name.trim(),
      'type': type.name,
      'iconKey': iconKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory({
    required String userId,
    required String categoryId,
    required String name,
    required TransactionType type,
    required String iconKey,
  }) {
    return _categoriesRef(userId).doc(categoryId).update({
      'name': name.trim(),
      'type': type.name,
      'iconKey': iconKey,
    });
  }

  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) {
    return _categoriesRef(userId).doc(categoryId).delete();
  }

  CollectionReference<Map<String, dynamic>> _categoriesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  TransactionCategoryOption _customCategoryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final type = (data['type'] as String?) == TransactionType.income.name
        ? TransactionType.income
        : TransactionType.expense;

    return TransactionCategories.custom(
      id: doc.id,
      label: data['name'] as String? ?? 'Untitled',
      type: type,
      iconKey: data['iconKey'] as String? ?? 'other',
    );
  }
}
