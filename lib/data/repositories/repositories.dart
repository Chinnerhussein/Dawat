// Repository interfaces. The UI and logic layers only talk to these, so the
// app runs the same against the in-memory demo backend or Firebase.

import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/notification.dart';
import '../models/planner.dart';
import '../models/service.dart';

/// Thrown for problems the user can fix (wrong password, email taken…).
class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Register Account / Login use cases.
abstract interface class AuthRepository {
  Stream<AppUser?> userChanges();
  AppUser? get currentUser;
  Future<AppUser> signIn(String email, String password);
  Future<AppUser> register({required String email, required String password, required AppUser profile});
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> updateProfile(AppUser user);
}

/// Browse & Filter Services, View Prices & Availability,
/// Manage Services & Pricing use cases.
abstract interface class ServiceRepository {
  Stream<List<Service>> watchServices({String? providerId});

  /// Public business profiles of all service providers.
  Stream<List<ServiceProvider>> watchProviders();
  Future<Service?> getService(String id);
  Future<Service> saveService(Service service);
  Future<void> deleteService(String id);
}

/// Book Services & Make Payment, Manage Incoming Bookings use cases.
abstract interface class BookingRepository {
  Stream<List<Booking>> watchCoupleBookings(String coupleId);
  Stream<List<Booking>> watchProviderBookings(String providerId);
  Stream<List<Booking>> watchAllBookings();
  Future<Booking> saveBooking(Booking booking);
}

/// Manage Wishlist / Favorites use case.
abstract interface class WishlistRepository {
  Stream<Set<String>> watchWishlist(String userId);
  Future<void> setFavorite(String userId, String serviceId, bool favorite);
}

/// Manage Budget & Expenses, Manage Guest List & RSVPs, and checklist tasks.
abstract interface class PlannerRepository {
  Stream<List<BudgetExpense>> watchExpenses(String userId);
  Future<void> saveExpense(BudgetExpense expense);
  Future<void> deleteExpense(String id);

  Stream<List<Guest>> watchGuests(String userId);
  Future<void> saveGuest(Guest guest);
  Future<void> deleteGuest(String id);

  Stream<List<ChecklistTask>> watchTasks(String userId);
  Future<void> saveTask(ChecklistTask task);
  Future<void> deleteTask(String id);
}

/// Receive Push Notifications & Reminders use case.
abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);
  Future<void> addNotification(AppNotification notification);
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead(String userId);
}

/// Manage Users, Providers & System Settings use case.
abstract interface class AdminRepository {
  Stream<List<AppUser>> watchUsers();
  Future<void> setUserActive(String userId, bool active);
  Future<void> setProviderApproval(String providerId, ApprovalStatus status);
  Stream<SystemSettings> watchSettings();
  Future<void> saveSettings(SystemSettings settings);
}

/// Everything the app needs from a backend.
abstract interface class Backend
    implements
        AuthRepository,
        ServiceRepository,
        BookingRepository,
        WishlistRepository,
        PlannerRepository,
        NotificationRepository,
        AdminRepository {
  /// Generates a new unique document id.
  String newId();
}
