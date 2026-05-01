import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/wallet_entity.dart';

class WalletRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  WalletRemoteDatasource(this._firestore, this._auth);

  Future<WalletEntity> getWallet() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to access wallet.');
    }

    final walletRef = _firestore.collection('wallets').doc(user.uid);
    final walletDoc = await walletRef.get();

    if (!walletDoc.exists) {
      await walletRef.set({
        'user_id': user.uid,
        'balance': 0.0,
        'currency': 'LKR',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    final data = (await walletRef.get()).data() ?? <String, dynamic>{};
    return WalletEntity(
      id: walletRef.id,
      userId: data['user_id'] as String? ?? user.uid,
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'LKR',
    );
  }

  Future<WalletEntity> topUp(double amount) async {
    if (amount <= 0) {
      throw Exception('Top-up amount must be greater than zero.');
    }
    final wallet = await getWallet();
    final walletRef = _firestore.collection('wallets').doc(wallet.userId);
    final txRef = walletRef.collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(walletRef);
      final current = (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0;
      final updated = current + amount;
      transaction.update(walletRef, {
        'balance': updated,
        'updated_at': FieldValue.serverTimestamp(),
      });
      transaction.set(txRef, {
        'type': 'TOP_UP',
        'amount': amount,
        'platform_fee': 0.0,
        'status': 'COMPLETED',
        'description': 'Wallet top-up',
        'created_at': FieldValue.serverTimestamp(),
      });
    });

    return getWallet();
  }

  Future<WalletEntity> withdraw(double amount) async {
    if (amount <= 0) {
      throw Exception('Withdrawal amount must be greater than zero.');
    }

    final wallet = await getWallet();
    final walletRef = _firestore.collection('wallets').doc(wallet.userId);
    final txRef = walletRef.collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(walletRef);
      final current = (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0;
      if (amount > current) {
        throw Exception('Insufficient wallet balance.');
      }
      final updated = current - amount;
      transaction.update(walletRef, {
        'balance': updated,
        'updated_at': FieldValue.serverTimestamp(),
      });
      transaction.set(txRef, {
        'type': 'HOST_PAYOUT',
        'amount': amount,
        'platform_fee': 0.0,
        'status': 'PENDING',
        'description': 'Withdrawal request',
        'created_at': FieldValue.serverTimestamp(),
      });
    });

    return getWallet();
  }

  Future<List<TransactionEntity>> getTransactions() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('wallets')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('created_at', descending: true)
        .limit(30)
        .get();

    return snapshot.docs.map((doc) {
      final j = doc.data();
      return TransactionEntity(
        id: doc.id,
        type: j['type'] as String? ?? 'TOP_UP',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        platformFee: (j['platform_fee'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'COMPLETED',
        description: j['description'] as String?,
        createdAt: (j['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> saveBankDetails({
    required String bankName,
    required String accountHolder,
    required String accountNumber,
    required String branch,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to save bank details.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'bank_details': {
        'bank_name': bankName,
        'account_holder': accountHolder,
        'account_number': accountNumber,
        'branch': branch,
        'updated_at': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}
