// Firebase implementation of the repositories (report §8): Firebase
// Authentication for accounts, Cloud Firestore for records and Firebase Cloud
// Messaging for device tokens.
//
// Collections follow the ER diagram (§7.3):
//   users, services, bookings, wishlists, guests, budget_expenses
// plus tasks, notifications and settings/system.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/notification.dart';
import '../models/planner.dart';
import '../models/service.dart';
import '../repositories/repositories.dart';

class FirebaseBackend implements Backend {
  FirebaseBackend({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  AppUser? _currentUser;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _services => _db.collection('services');
  CollectionReference<Map<String, dynamic>> get _bookings => _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _wishlists => _db.collection('wishlists');
  CollectionReference<Map<String, dynamic>> get _expenses => _db.collection('budget_expenses');
  CollectionReference<Map<String, dynamic>> get _guests => _db.collection('guests');
  CollectionReference<Map<String, dynamic>> get _tasks => _db.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _notifications => _db.collection('notifications');
  DocumentReference<Map<String, dynamic>> get _settings => _db.collection('settings').doc('system');

  @override
  String newId() => _db.collection('_').doc().id;

  List<T> _list<T>(QuerySnapshot<Map<String, dynamic>> snap, T Function(String, Map<String, dynamic>) fromMap) =>
      snap.docs.map((d) => fromMap(d.id, d.data())).toList();

  // ---------------------------------------------------------------- Auth

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> userChanges() {
    // Switches to the signed-in user's profile document whenever the auth
    // state changes.
    late StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? docSub;
    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.authStateChanges().listen((user) {
          docSub?.cancel();
          if (user == null) {
            _currentUser = null;
            controller.add(null);
            return;
          }
          docSub = _users.doc(user.uid).snapshots().listen((doc) {
            final data = doc.data();
            _currentUser = data == null ? null : AppUser.fromMap(doc.id, data);
            controller.add(_currentUser);
          }, onError: controller.addError);
        }, onError: controller.addError);
      },
      onCancel: () async {
        await docSub?.cancel();
        await authSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final doc = await _users.doc(cred.user!.uid).get();
      final data = doc.data();
      if (data == null) {
        await _auth.signOut();
        throw const AppException('This account has no Dawat profile.');
      }
      final user = AppUser.fromMap(doc.id, data);
      if (!user.isActive) {
        await _auth.signOut();
        throw const AppException('This account has been suspended. Contact Dawat support.');
      }
      _currentUser = user;
      unawaited(_registerDeviceToken(user.id));
      return user;
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    }
  }

  @override
  Future<AppUser> register({required String email, required String password, required AppUser profile}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;
      // Re-create the profile under the Firebase uid.
      final user = AppUser.fromMap(uid, profile.toMap());
      await _users.doc(uid).set(user.toMap());
      _currentUser = user;
      unawaited(_registerDeviceToken(uid));
      return user;
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e));
    }
  }

  @override
  Future<void> updateProfile(AppUser user) async {
    await _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
    if (user is ServiceProvider) {
      final batch = _db.batch();
      final mine = await _services.where('providerId', isEqualTo: user.id).get();
      for (final d in mine.docs) {
        batch.update(d.reference, {'providerName': user.businessName});
      }
      await batch.commit();
    }
  }

  StreamSubscription<String>? _fcmSub;

  /// Registers this device with Firebase Cloud Messaging and stores its
  /// installation id on the user, so a Cloud Function can send pushes to it.
  Future<void> _registerDeviceToken(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await _fcmSub?.cancel();
      _fcmSub = messaging.onRegistered.listen((fid) {
        _users.doc(uid).set({
          'fcmTokens': FieldValue.arrayUnion([fid]),
        }, SetOptions(merge: true));
      });
      await messaging.register();
    } catch (e) {
      // Push is optional (e.g. web without a VAPID key); the app keeps working.
      debugPrint('FCM token registration skipped: $e');
    }
  }

  String _authMessage(FirebaseAuthException e) => switch (e.code) {
    'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Choose a password with at least 8 characters.',
    'invalid-email' => 'Enter a valid email address.',
    'too-many-requests' => 'Too many attempts. Wait a minute and try again.',
    'network-request-failed' => 'No connection. Check your internet and try again.',
    _ => e.message ?? 'Something went wrong. Try again.',
  };

  // ------------------------------------------------------------ Services

  @override
  Stream<List<Service>> watchServices({String? providerId}) {
    Query<Map<String, dynamic>> q = _services;
    if (providerId != null) q = q.where('providerId', isEqualTo: providerId);
    return q.snapshots().map((s) => _list(s, Service.fromMap)..sort((a, b) => b.rating.compareTo(a.rating)));
  }

  @override
  Stream<List<ServiceProvider>> watchProviders() => _users
      .where('role', isEqualTo: UserRole.provider.name)
      .snapshots()
      .map((s) => _list(s, AppUser.fromMap).whereType<ServiceProvider>().toList());

  @override
  Future<Service?> getService(String id) async {
    final d = await _services.doc(id).get();
    final data = d.data();
    return data == null ? null : Service.fromMap(d.id, data);
  }

  @override
  Future<Service> saveService(Service service) async {
    await _services.doc(service.id).set(service.toMap());
    return service;
  }

  @override
  Future<void> deleteService(String id) => _services.doc(id).delete();

  // ------------------------------------------------------------ Bookings

  Stream<List<Booking>> _bookingQuery(Query<Map<String, dynamic>> q) =>
      q.snapshots().map((s) => _list(s, Booking.fromMap)..sort((a, b) => a.eventDate.compareTo(b.eventDate)));

  @override
  Stream<List<Booking>> watchCoupleBookings(String coupleId) =>
      _bookingQuery(_bookings.where('coupleId', isEqualTo: coupleId));

  @override
  Stream<List<Booking>> watchProviderBookings(String providerId) =>
      _bookingQuery(_bookings.where('providerId', isEqualTo: providerId));

  @override
  Stream<List<Booking>> watchAllBookings() => _bookingQuery(_bookings);

  @override
  Future<Booking> saveBooking(Booking booking) async {
    await _bookings.doc(booking.id).set(booking.toMap());
    return booking;
  }

  // ------------------------------------------------------------ Wishlist

  @override
  Stream<Set<String>> watchWishlist(String userId) => _wishlists
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()['serviceId'] as String).toSet());

  @override
  Future<void> setFavorite(String userId, String serviceId, bool favorite) {
    final ref = _wishlists.doc('${userId}_$serviceId');
    return favorite ? ref.set({'userId': userId, 'serviceId': serviceId}) : ref.delete();
  }

  // ------------------------------------------------------------- Planner

  @override
  Stream<List<BudgetExpense>> watchExpenses(String userId) => _expenses
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (s) =>
            _list(s, BudgetExpense.fromMap)
              ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))),
      );

  @override
  Future<void> saveExpense(BudgetExpense expense) => _expenses.doc(expense.id).set(expense.toMap());

  @override
  Future<void> deleteExpense(String id) => _expenses.doc(id).delete();

  @override
  Stream<List<Guest>> watchGuests(String userId) => _guests
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => _list(s, Guest.fromMap)..sort((a, b) => a.fullName.compareTo(b.fullName)));

  @override
  Future<void> saveGuest(Guest guest) => _guests.doc(guest.id).set(guest.toMap());

  @override
  Future<void> deleteGuest(String id) => _guests.doc(id).delete();

  @override
  Stream<List<ChecklistTask>> watchTasks(String userId) => _tasks
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (s) =>
            _list(s, ChecklistTask.fromMap)
              ..sort((a, b) => (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999))),
      );

  @override
  Future<void> saveTask(ChecklistTask task) => _tasks.doc(task.id).set(task.toMap());

  @override
  Future<void> deleteTask(String id) => _tasks.doc(id).delete();

  // -------------------------------------------------------- Notifications

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => _notifications
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (s) =>
            _list(s, AppNotification.fromMap)
              ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))),
      );

  @override
  Future<void> addNotification(AppNotification notification) =>
      _notifications.doc(notification.id).set(notification.toMap());

  @override
  Future<void> markNotificationRead(String id) => _notifications.doc(id).update({'read': true});

  @override
  Future<void> markAllNotificationsRead(String userId) async {
    final unread = await _notifications.where('userId', isEqualTo: userId).where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------- Admin

  @override
  Stream<List<AppUser>> watchUsers() =>
      _users.snapshots().map((s) => _list(s, AppUser.fromMap)..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<void> setUserActive(String userId, bool active) => _users.doc(userId).update({'isActive': active});

  @override
  Future<void> setProviderApproval(String providerId, ApprovalStatus status) =>
      _users.doc(providerId).update({'approval': status.name});

  @override
  Stream<SystemSettings> watchSettings() => _settings.snapshots().map((d) => SystemSettings.fromMap(d.data()));

  @override
  Future<void> saveSettings(SystemSettings settings) => _settings.set(settings.toMap());
}
