import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/bill_model.dart';
import '../models/savings_goal_model.dart';
import '../models/category_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  FirebaseAuth? get auth => _auth;
  FirebaseFirestore? get firestore => _firestore;

  User? get currentUser {
    if (!_isInitialized || _auth == null) return null;
    return _auth!.currentUser;
  }

  Stream<User?> get authStateChanges {
    if (!_isInitialized || _auth == null) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  /// Initialize Firebase app instance safely
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      debugPrint('[FirebaseService] Successfully initialized Firebase');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Initialization fallback (offline/demo): $e');
      _isInitialized = false;
      return false;
    }
  }

  // ==========================================
  // AUTHENTICATION METHODS
  // ==========================================

  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_isInitialized || _auth == null) {
      throw Exception('Firebase is not connected. Local mode enabled.');
    }
    final credential = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }
    return credential;
  }

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || _auth == null) {
      throw Exception('Firebase is not connected. Local mode enabled.');
    }
    return await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with email or automatically create account if it does not exist yet
  Future<UserCredential?> signInOrCreate({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (!_isInitialized || _auth == null) {
      throw Exception('Firebase is not connected. Local mode enabled.');
    }
    try {
      return await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'invalid-email') {
        final cred = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (displayName != null && displayName.isNotEmpty) {
          await cred.user?.updateDisplayName(displayName);
        }
        return cred;
      }
      rethrow;
    } catch (_) {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName);
      }
      return cred;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    if (!_isInitialized || _auth == null) {
      return null;
    }
    return await _auth!.signInAnonymously();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isInitialized || _auth == null) {
      throw Exception('Firebase is not connected. Local mode enabled.');
    }
    await _auth!.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (_isInitialized && _auth != null) {
      await _auth!.signOut();
    }
  }

  // ==========================================
  // ENSURE AUTHENTICATED USER
  // ==========================================

  Future<User?> ensureUser() async {
    if (!_isInitialized) await initialize();
    if (_auth?.currentUser != null) return _auth!.currentUser;

    // 1. Try primary registered account
    try {
      final cred = await _auth?.signInWithEmailAndPassword(
        email: 'nupur@example.com',
        password: 'Password123!',
      );
      if (cred?.user != null) {
        debugPrint('[FirebaseService] Auto-signed in as nupur@example.com');
        return cred!.user;
      }
    } catch (_) {}

    // 2. Try secondary verified account
    try {
      final cred = await _auth?.signInWithEmailAndPassword(
        email: 'nupur_test@example.com',
        password: 'Password123!',
      );
      if (cred?.user != null) {
        debugPrint('[FirebaseService] Auto-signed in as nupur_test@example.com');
        return cred!.user;
      }
    } catch (_) {}

    // 3. Fallback to anonymous sign-in
    try {
      final cred = await _auth?.signInAnonymously();
      debugPrint('[FirebaseService] Signed in anonymously');
      return cred?.user;
    } catch (e) {
      debugPrint('[FirebaseService] Anonymous sign-in failed: $e');
    }

    return null;
  }

  // ==========================================
  // REAL-TIME CLOUD FIRESTORE DATA PERSISTENCE
  // ==========================================

  /// Save or update a single transaction in BOTH Root and User collections
  Future<bool> saveTransaction(TransactionModel transaction, {String? userId}) async {
    if (!_isInitialized || _firestore == null) {
      await initialize();
      if (!_isInitialized || _firestore == null) return false;
    }

    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      // 1. Save to Root 'transactions' collection (instantly visible in Firebase Console root)
      await _firestore!
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson(), SetOptions(merge: true));

      // 2. Save to User subcollection if user ID available
      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc(transaction.id)
            .set(transaction.toJson(), SetOptions(merge: true));
      }

      debugPrint('[FirebaseService] ✅ Real-time transaction stored in Cloud Firestore: "${transaction.title}" (${transaction.amount})');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] ❌ Error storing transaction in Firestore: $e');
      return false;
    }
  }

  /// Delete a transaction from BOTH Root and User collections
  Future<bool> deleteTransaction(String transactionId, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      // Delete from Root
      await _firestore!.collection('transactions').doc(transactionId).delete();

      // Delete from User subcollection
      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc(transactionId)
            .delete();
      }
      debugPrint('[FirebaseService] Deleted transaction $transactionId from Firestore');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting transaction from Firestore: $e');
      return false;
    }
  }

  /// Save or update a budget in Root & User collections
  Future<bool> saveBudget(BudgetModel budget, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      await _firestore!
          .collection('budgets')
          .doc(budget.id)
          .set(budget.toJson(), SetOptions(merge: true));

      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('budgets')
            .doc(budget.id)
            .set(budget.toJson(), SetOptions(merge: true));
      }
      debugPrint('[FirebaseService] ✅ Real-time budget stored: "${budget.name}"');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error saving budget to Firestore: $e');
      return false;
    }
  }

  /// Delete a budget from Root & User collections
  Future<bool> deleteBudget(String budgetId, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      await _firestore!.collection('budgets').doc(budgetId).delete();
      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('budgets')
            .doc(budgetId)
            .delete();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting budget: $e');
      return false;
    }
  }

  /// Save or update a bill in Root & User collections
  Future<bool> saveBill(BillModel bill, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      await _firestore!
          .collection('bills')
          .doc(bill.id)
          .set(bill.toJson(), SetOptions(merge: true));

      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('bills')
            .doc(bill.id)
            .set(bill.toJson(), SetOptions(merge: true));
      }
      debugPrint('[FirebaseService] ✅ Real-time bill stored: "${bill.title}"');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error saving bill to Firestore: $e');
      return false;
    }
  }

  /// Delete a bill from Root & User collections
  Future<bool> deleteBill(String billId, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      await _firestore!.collection('bills').doc(billId).delete();
      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('bills')
            .doc(billId)
            .delete();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting bill: $e');
      return false;
    }
  }

  /// Save or update a savings goal in Root & User collections
  Future<bool> saveSavingsGoal(SavingsGoalModel goal, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      await _firestore!
          .collection('savings_goals')
          .doc(goal.id)
          .set(goal.toJson(), SetOptions(merge: true));

      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('savings_goals')
            .doc(goal.id)
            .set(goal.toJson(), SetOptions(merge: true));
      }
      debugPrint('[FirebaseService] ✅ Real-time savings goal stored: "${goal.name}"');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error saving savings goal: $e');
      return false;
    }
  }

  /// Delete a savings goal from Root & User collections
  Future<bool> deleteSavingsGoal(String goalId, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      await _firestore!.collection('savings_goals').doc(goalId).delete();
      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('savings_goals')
            .doc(goalId)
            .delete();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting savings goal: $e');
      return false;
    }
  }

  /// Save or update a category in Root & User collections
  Future<bool> saveCategory(CategoryModel cat, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      await _firestore!
          .collection('categories')
          .doc(cat.id)
          .set(cat.toJson(), SetOptions(merge: true));

      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('categories')
            .doc(cat.id)
            .set(cat.toJson(), SetOptions(merge: true));
      }
      debugPrint('[FirebaseService] ✅ Real-time category stored: "${cat.name}"');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error saving category: $e');
      return false;
    }
  }

  /// Delete a category from Root & User collections
  Future<bool> deleteCategory(String catId, {String? userId}) async {
    if (!_isInitialized || _firestore == null) return false;
    final user = await ensureUser();
    final uid = userId ?? user?.uid;

    try {
      await _firestore!.collection('categories').doc(catId).delete();
      if (uid != null) {
        await _firestore!
            .collection('users')
            .doc(uid)
            .collection('categories')
            .doc(catId)
            .delete();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Error deleting category: $e');
      return false;
    }
  }

  /// Fetch all historical transactions from Firestore
  Future<List<TransactionModel>> fetchTransactions(String userId) async {
    if (!_isInitialized || _firestore == null) return [];
    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FirebaseService] Error fetching transactions: $e');
      return [];
    }
  }

  /// Batch sync all local data to Cloud Firestore (both User subcollections and Root collections)
  Future<bool> syncAllToCloud({
    required String userId,
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required List<BillModel> bills,
    required List<SavingsGoalModel> savingsGoals,
  }) async {
    if (!_isInitialized || _firestore == null) return false;
    try {
      final batch = _firestore!.batch();
      final userDoc = _firestore!.collection('users').doc(userId);

      // Save sync metadata
      batch.set(
        userDoc,
        {
          'lastSyncedAt': FieldValue.serverTimestamp(),
          'devicePlatform': defaultTargetPlatform.toString(),
        },
        SetOptions(merge: true),
      );

      // Save transactions (User & Root)
      for (final tx in transactions) {
        batch.set(userDoc.collection('transactions').doc(tx.id), tx.toJson(), SetOptions(merge: true));
        batch.set(_firestore!.collection('transactions').doc(tx.id), tx.toJson(), SetOptions(merge: true));
      }

      // Save budgets (User & Root)
      for (final b in budgets) {
        batch.set(userDoc.collection('budgets').doc(b.id), b.toJson(), SetOptions(merge: true));
        batch.set(_firestore!.collection('budgets').doc(b.id), b.toJson(), SetOptions(merge: true));
      }

      // Save bills (User & Root)
      for (final bill in bills) {
        batch.set(userDoc.collection('bills').doc(bill.id), bill.toJson(), SetOptions(merge: true));
        batch.set(_firestore!.collection('bills').doc(bill.id), bill.toJson(), SetOptions(merge: true));
      }

      // Save savings goals (User & Root)
      for (final g in savingsGoals) {
        batch.set(userDoc.collection('savings_goals').doc(g.id), g.toJson(), SetOptions(merge: true));
        batch.set(_firestore!.collection('savings_goals').doc(g.id), g.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('[FirebaseService] Successfully synced all data to Firestore (Root & User collections) for $userId');
      return true;
    } catch (e) {
      debugPrint('[FirebaseService] Batch sync error: $e');
      return false;
    }
  }

  /// Pull all data from Firestore for a given user
  Future<Map<String, dynamic>?> pullCloudData(String userId) async {
    if (!_isInitialized || _firestore == null) return null;
    try {
      final userDoc = _firestore!.collection('users').doc(userId);

      final txSnap = await userDoc.collection('transactions').get();
      final budgetSnap = await userDoc.collection('budgets').get();
      final billsSnap = await userDoc.collection('bills').get();
      final goalsSnap = await userDoc.collection('savings_goals').get();

      return {
        'transactions': txSnap.docs.map((d) => TransactionModel.fromJson(d.data())).toList(),
        'budgets': budgetSnap.docs.map((d) => BudgetModel.fromJson(d.data())).toList(),
        'bills': billsSnap.docs.map((d) => BillModel.fromJson(d.data())).toList(),
        'savingsGoals': goalsSnap.docs.map((d) => SavingsGoalModel.fromJson(d.data())).toList(),
      };
    } catch (e) {
      debugPrint('[FirebaseService] Pull cloud data error: $e');
      return null;
    }
  }

  // ==========================================
  // FRIENDLY ERROR HANDLING
  // ==========================================

  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email. Please sign up first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase Console.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        default:
          return error.message ?? 'Authentication error occurred.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
