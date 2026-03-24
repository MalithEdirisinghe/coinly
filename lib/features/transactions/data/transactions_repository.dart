import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coinly/features/transactions/domain/transaction_item.dart';

class TransactionsRepository {
  TransactionsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const Duration transactionsCacheDuration = Duration(minutes: 10);

  final FirebaseFirestore _firestore;
  final Map<String, CachedTransactionsPage> _transactionsCache = {};

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
    required String categoryId,
    required String categoryLabel,
    required String categoryIconKey,
  }) async {
    final transaction = TransactionItem(
      id: '',
      title: title,
      amount: amount,
      type: type,
      createdAt: DateTime.now(),
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      categoryIconKey: categoryIconKey,
    );

    await _transactionsRef(userId).add(transaction.toMap());
    invalidateTransactionsCache(userId);
  }

  Future<void> deleteTransaction({
    required String userId,
    required String transactionId,
  }) async {
    await _transactionsRef(userId).doc(transactionId).delete();
    _removeFromCache(userId, transactionId);
  }

  Future<TransactionsPageResult> fetchTransactionsPage({
    required String userId,
    int limit = 20,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _transactionsRef(
      userId,
    ).orderBy('createdAt', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final transactions = snapshot.docs
        .map(TransactionItem.fromFirestore)
        .toList(growable: false);

    return TransactionsPageResult(
      transactions: transactions,
      lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      hasMore: snapshot.docs.length == limit,
    );
  }

  CachedTransactionsPage? getCachedTransactionsPage(String userId) {
    return _transactionsCache[userId];
  }

  bool hasFreshTransactionsCache(
    String userId, {
    Duration maxAge = transactionsCacheDuration,
  }) {
    final cache = _transactionsCache[userId];
    if (cache == null) {
      return false;
    }

    return DateTime.now().difference(cache.updatedAt) < maxAge;
  }

  void cacheTransactionsPage({
    required String userId,
    required List<TransactionItem> transactions,
    required QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    required bool hasMore,
  }) {
    _transactionsCache[userId] = CachedTransactionsPage(
      transactions: List.unmodifiable(transactions),
      lastDocument: lastDocument,
      hasMore: hasMore,
      updatedAt: DateTime.now(),
    );
  }

  void invalidateTransactionsCache(String userId) {
    _transactionsCache.remove(userId);
  }

  void _removeFromCache(String userId, String transactionId) {
    final cache = _transactionsCache[userId];
    if (cache == null) {
      return;
    }

    final updatedTransactions = cache.transactions
        .where((item) => item.id != transactionId)
        .toList(growable: false);

    _transactionsCache[userId] = cache.copyWith(
      transactions: updatedTransactions,
      updatedAt: DateTime.now(),
    );
  }

  CollectionReference<Map<String, dynamic>> _transactionsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }
}

class TransactionsPageResult {
  const TransactionsPageResult({
    required this.transactions,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TransactionItem> transactions;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class CachedTransactionsPage {
  const CachedTransactionsPage({
    required this.transactions,
    required this.lastDocument,
    required this.hasMore,
    required this.updatedAt,
  });

  final List<TransactionItem> transactions;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
  final DateTime updatedAt;

  CachedTransactionsPage copyWith({
    List<TransactionItem>? transactions,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool? hasMore,
    DateTime? updatedAt,
  }) {
    return CachedTransactionsPage(
      transactions: transactions ?? this.transactions,
      lastDocument: lastDocument ?? this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
