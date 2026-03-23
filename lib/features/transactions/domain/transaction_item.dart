import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

class TransactionItem extends Equatable {
  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime createdAt;

  factory TransactionItem.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final timestamp = data['createdAt'];

    return TransactionItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: (data['type'] as String?) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object> get props => [id, title, amount, type, createdAt];
}
