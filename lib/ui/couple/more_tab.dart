import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../common/account_menu.dart';
import '../widgets/common.dart';
import 'bookings_screen.dart';
import 'catalog.dart';
import 'guests_screen.dart';
import 'home_tab.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key, required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('More', style: context.text.displaySmall),
        const SizedBox(height: 16),
        AccountHeader(
          user: couple,
          subtitle: couple.weddingDate == null ? 'Bride & Groom' : 'Wedding on ${fmtDate(couple.weddingDate!)}',
        ),
        const SizedBox(height: 16),
        MenuCard(
          items: [
            MenuItem(Icons.event_note_outlined, 'My bookings', () => _push(context, BookingsScreen(couple: couple))),
            MenuItem(Icons.favorite_border, 'Favorites', () => _push(context, FavoritesScreen(couple: couple))),
            MenuItem(Icons.people_outline, 'Guest list & RSVPs', () => _push(context, GuestsScreen(couple: couple))),
          ],
        ),
        const SizedBox(height: 16),
        const AccountMenu(),
      ],
    ),
  );

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

/// "Manage Wishlist / Favorites" use case.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.couple});
  final Couple couple;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Favorites')),
    body: CatalogView(
      userId: couple.id,
      builder: (context, catalog) {
        final favs = catalog.services.where(catalog.isFavorite).toList();
        if (favs.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            message: 'Tap the heart on any vendor to save it here and compare later.',
          );
        }
        final total = favs.fold<double>(0, (a, s) => a + s.price);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('${favs.length} saved · from ${money(total)} together', style: context.text.bodySmall),
            const SizedBox(height: 12),
            for (final s in favs) ...[
              ServiceTile(
                service: s,
                isFavorite: true,
                onFavorite: () => toggleFavorite(context, couple.id, s, true),
                onTap: () => openService(context, s.id),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    ),
  );
}
