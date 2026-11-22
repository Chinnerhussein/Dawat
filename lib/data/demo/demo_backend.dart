// In-memory backend with sample data, so the app runs without a Firebase
// project. Data resets on every app restart.

import 'dart:async';
import 'dart:math';

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/notification.dart';
import '../models/planner.dart';
import '../models/service.dart';
import '../repositories/repositories.dart';
import 'demo_seed.dart';

class DemoBackend implements Backend {
  DemoBackend({bool seed = true}) {
    if (seed) DemoSeed.apply(this);
  }

  final _random = Random();
  final _changes = StreamController<void>.broadcast();

  final Map<String, AppUser> users = {};
  final Map<String, String> passwords = {}; // email -> password
  final Map<String, Service> services = {};
  final Map<String, Booking> bookings = {};
  final Map<String, Set<String>> wishlists = {};
  final Map<String, BudgetExpense> expenses = {};
  final Map<String, Guest> guests = {};
  final Map<String, ChecklistTask> tasks = {};
  final Map<String, AppNotification> notifications = {};
  SystemSettings settings = const SystemSettings();

  String? _currentUserId;

  /// Simulated network delay, so loading states are visible.
  Future<void> _latency() => Future.delayed(const Duration(milliseconds: 250));

  void _notify() => _changes.add(null);

  Stream<R> _watch<R>(R Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  String newId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  // ---------------------------------------------------------------- Auth

  @override
  AppUser? get currentUser => _currentUserId == null ? null : users[_currentUserId];

  @override
  Stream<AppUser?> userChanges() => _watch(() => currentUser);

  @override
  Future<AppUser> signIn(String email, String password) async {
    await _latency();
    final key = email.trim().toLowerCase();
    if (passwords[key] != password) {
      throw const AppException('Incorrect email or password.');
    }
    final user = users.values.firstWhere((u) => u.email.toLowerCase() == key);
    if (!user.isActive) {
      throw const AppException('This account has been suspended. Contact Dawat support.');
    }
    _currentUserId = user.id;
    _notify();
    return user;
  }

  @override
  Future<AppUser> register({required String email, required String password, required AppUser profile}) async {
    await _latency();
    final key = email.trim().toLowerCase();
    if (passwords.containsKey(key)) {
      throw const AppException('An account with this email already exists.');
    }
    passwords[key] = password;
    users[profile.id] = profile;
    _currentUserId = profile.id;
    _notify();
    return profile;
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _notify();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _latency();
    if (!passwords.containsKey(email.trim().toLowerCase())) {
      throw const AppException('No account uses this email.');
    }
  }

  @override
  Future<void> updateProfile(AppUser user) async {
    await _latency();
    users[user.id] = user;
    // Keep the provider name on listings in sync.
    if (user is ServiceProvider) {
      for (final s in services.values.where((s) => s.providerId == user.id).toList()) {
        services[s.id] = s.copyWith(providerName: user.businessName);
      }
    }
    _notify();
  }

  // ------------------------------------------------------------ Services

  @override
  Stream<List<Service>> watchServices({String? providerId}) => _watch(() {
    final list = services.values.where((s) => providerId == null || s.providerId == providerId).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  });

  @override
  Stream<List<ServiceProvider>> watchProviders() => _watch(() => users.values.whereType<ServiceProvider>().toList());

  @override
  Future<Service?> getService(String id) async => services[id];

  @override
  Future<Service> saveService(Service service) async {
    await _latency();
    services[service.id] = service;
    _notify();
    return service;
  }

  @override
  Future<void> deleteService(String id) async {
    await _latency();
    services.remove(id);
    _notify();
  }

  // ------------------------------------------------------------ Bookings

  List<Booking> _sortedBookings(bool Function(Booking) test) =>
      bookings.values.where(test).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));

  @override
  Stream<List<Booking>> watchCoupleBookings(String coupleId) =>
      _watch(() => _sortedBookings((b) => b.coupleId == coupleId));

  @override
  Stream<List<Booking>> watchProviderBookings(String providerId) =>
      _watch(() => _sortedBookings((b) => b.providerId == providerId));

  @override
  Stream<List<Booking>> watchAllBookings() => _watch(() => _sortedBookings((_) => true));

  @override
  Future<Booking> saveBooking(Booking booking) async {
    await _latency();
    bookings[booking.id] = booking;
    _notify();
    return booking;
  }

  // ------------------------------------------------------------ Wishlist

  @override
  Stream<Set<String>> watchWishlist(String userId) => _watch(() => {...?wishlists[userId]});

  @override
  Future<void> setFavorite(String userId, String serviceId, bool favorite) async {
    final set = wishlists.putIfAbsent(userId, () => {});
    favorite ? set.add(serviceId) : set.remove(serviceId);
    _notify();
  }

  // ------------------------------------------------------------- Planner

  @override
  Stream<List<BudgetExpense>> watchExpenses(String userId) => _watch(
    () =>
        expenses.values.where((e) => e.userId == userId).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))),
  );

  @override
  Future<void> saveExpense(BudgetExpense expense) async {
    expenses[expense.id] = expense;
    _notify();
  }

  @override
  Future<void> deleteExpense(String id) async {
    expenses.remove(id);
    _notify();
  }

  @override
  Stream<List<Guest>> watchGuests(String userId) => _watch(
    () => guests.values.where((g) => g.userId == userId).toList()..sort((a, b) => a.fullName.compareTo(b.fullName)),
  );

  @override
  Future<void> saveGuest(Guest guest) async {
    guests[guest.id] = guest;
    _notify();
  }

  @override
  Future<void> deleteGuest(String id) async {
    guests.remove(id);
    _notify();
  }

  @override
  Stream<List<ChecklistTask>> watchTasks(String userId) => _watch(
    () =>
        tasks.values.where((t) => t.userId == userId).toList()
          ..sort((a, b) => (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999))),
  );

  @override
  Future<void> saveTask(ChecklistTask task) async {
    tasks[task.id] = task;
    _notify();
  }

  @override
  Future<void> deleteTask(String id) async {
    tasks.remove(id);
    _notify();
  }

  // -------------------------------------------------------- Notifications

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) => _watch(
    () =>
        notifications.values.where((n) => n.userId == userId).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))),
  );

  @override
  Future<void> addNotification(AppNotification notification) async {
    notifications[notification.id] = notification;
    _notify();
  }

  @override
  Future<void> markNotificationRead(String id) async {
    final n = notifications[id];
    if (n != null) notifications[id] = n.markRead();
    _notify();
  }

  @override
  Future<void> markAllNotificationsRead(String userId) async {
    for (final n in notifications.values.where((n) => n.userId == userId).toList()) {
      notifications[n.id] = n.markRead();
    }
    _notify();
  }

  // ---------------------------------------------------------------- Admin

  @override
  Stream<List<AppUser>> watchUsers() => _watch(() => users.values.toList()..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Future<void> setUserActive(String userId, bool active) async {
    await _latency();
    final u = users[userId];
    if (u != null) users[userId] = u.withActive(active);
    _notify();
  }

  @override
  Future<void> setProviderApproval(String providerId, ApprovalStatus status) async {
    await _latency();
    final u = users[providerId];
    if (u is ServiceProvider) users[providerId] = u.copyWith(approval: status);
    _notify();
  }

  @override
  Stream<SystemSettings> watchSettings() => _watch(() => settings);

  @override
  Future<void> saveSettings(SystemSettings settings) async {
    await _latency();
    this.settings = settings;
    _notify();
  }
}
