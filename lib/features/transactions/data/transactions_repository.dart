import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';

class TransactionsRepository {
  TransactionsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<TransactionItem>> watchTransactions(String userId) {
    return _transactionsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TransactionItem.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<void> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required TransactionType type,
  }) {
    final transaction = TransactionItem(
      id: '',
      title: title,
      amount: amount,
      type: type,
      createdAt: DateTime.now(),
    );

    return _transactionsRef(userId).add(transaction.toMap());
  }

  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) {
    return _transactionsRef(userId).doc(transactionId).delete();
  }

  CollectionReference<Map<String, dynamic>> _transactionsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }
}
