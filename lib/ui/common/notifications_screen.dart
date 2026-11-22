import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/notification.dart';
import '../../logic/session.dart';
import '../widgets/common.dart';

/// "Receive Push Notifications & Reminders" use case: the in-app inbox.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    if (user == null) return const SizedBox.shrink();
    final backend = context.backend;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => runGuarded(context, () => backend.markAllNotificationsRead(user.id)),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamView<List<AppNotification>>(
        stream: () => backend.watchNotifications(user.id),
        builder: (context, list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'You are all caught up',
              message: 'Booking updates and reminders will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = list[i];
              final accent = n.read ? context.colors.muted : context.scheme.primary;
              return Card(
                color: n.read ? null : context.colors.cardHigh,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: n.read ? null : () => backend.markNotificationRead(n.id),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.15),
                          child: Icon(n.icon, color: accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(n.title, style: context.text.titleSmall)),
                                  Text(timeAgo(n.createdAt), style: context.text.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.body, style: context.text.bodyMedium),
                            ],
                          ),
                        ),
                        if (!n.read) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(color: context.scheme.primary, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
