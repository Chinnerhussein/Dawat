// In-app notifications and reminders ("Receive Push Notifications &
// Reminders" use case). Each notification stores a type plus parameters, and
// the app renders it in the reader's language.

enum NotificationType {
  bookingRequested, // to provider
  bookingAccepted, // to couple
  bookingDeclined, // to couple
  bookingCancelled, // to provider
  paymentReceived, // to provider
  providerApproved, // to provider
  providerRejected, // to provider
  reminder, // to couple: a checklist task is due soon
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    this.params = const {},
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final NotificationType type;

  /// Values for the message template, e.g. `{service: 'Lalav Hall', date: '2026-06-14'}`.
  final Map<String, String> params;
  final bool read;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type.name,
    'params': params,
    'read': read,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) => AppNotification(
    id: id,
    userId: m['userId'] as String,
    type: NotificationType.values.byName((m['type'] as String?) ?? 'reminder'),
    params: ((m['params'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
    read: (m['read'] as bool?) ?? false,
    createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? ''),
  );

  AppNotification markRead() =>
      AppNotification(id: id, userId: userId, type: type, params: params, read: true, createdAt: createdAt);
}

/// Admin-controlled system settings ("Manage Users, Providers & System
/// Settings" use case).
class SystemSettings {
  const SystemSettings({
    this.allowProviderSignup = true,
    this.requireProviderApproval = true,
    this.maintenanceMode = false,
    this.enabledCities = const ['erbil', 'sulaymaniyah', 'duhok', 'zakho', 'halabja', 'kirkuk'],
  });

  final bool allowProviderSignup;
  final bool requireProviderApproval;

  /// When on, couples and providers see a maintenance notice; admins can
  /// still sign in.
  final bool maintenanceMode;
  final List<String> enabledCities;

  Map<String, dynamic> toMap() => {
    'allowProviderSignup': allowProviderSignup,
    'requireProviderApproval': requireProviderApproval,
    'maintenanceMode': maintenanceMode,
    'enabledCities': enabledCities,
  };

  factory SystemSettings.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const SystemSettings();
    return SystemSettings(
      allowProviderSignup: (m['allowProviderSignup'] as bool?) ?? true,
      requireProviderApproval: (m['requireProviderApproval'] as bool?) ?? true,
      maintenanceMode: (m['maintenanceMode'] as bool?) ?? false,
      enabledCities: ((m['enabledCities'] as List?) ?? const SystemSettings().enabledCities).cast<String>(),
    );
  }

  SystemSettings copyWith({
    bool? allowProviderSignup,
    bool? requireProviderApproval,
    bool? maintenanceMode,
    List<String>? enabledCities,
  }) => SystemSettings(
    allowProviderSignup: allowProviderSignup ?? this.allowProviderSignup,
    requireProviderApproval: requireProviderApproval ?? this.requireProviderApproval,
    maintenanceMode: maintenanceMode ?? this.maintenanceMode,
    enabledCities: enabledCities ?? this.enabledCities,
  );
}
