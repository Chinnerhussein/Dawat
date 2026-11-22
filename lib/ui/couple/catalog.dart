import 'package:material_ui/material_ui.dart';

import '../../data/models/app_user.dart';
import '../../data/models/service.dart';
import '../widgets/common.dart';

/// Services couples are allowed to see: active listings from approved,
/// active providers.
class Catalog {
  const Catalog(this.services, this.providers, this.favorites);

  final List<Service> services;
  final Map<String, ServiceProvider> providers;
  final Set<String> favorites;

  bool isFavorite(Service s) => favorites.contains(s.id);
}

class CatalogView extends StatelessWidget {
  const CatalogView({super.key, required this.userId, required this.builder});

  final String userId;
  final Widget Function(BuildContext context, Catalog catalog) builder;

  @override
  Widget build(BuildContext context) {
    final backend = context.backend;
    return StreamView<List<ServiceProvider>>(
      stream: backend.watchProviders,
      builder: (context, providers) => StreamView<List<Service>>(
        stream: () => backend.watchServices(),
        builder: (context, services) => StreamView<Set<String>>(
          stream: () => backend.watchWishlist(userId),
          builder: (context, favorites) {
            final visible = {
              for (final p in providers)
                if (p.approval == ApprovalStatus.approved && p.isActive) p.id: p,
            };
            final list = services.where((s) => s.isActive && visible.containsKey(s.providerId)).toList();
            return builder(context, Catalog(list, visible, favorites));
          },
        ),
      ),
    );
  }
}

Future<void> toggleFavorite(BuildContext context, String userId, Service s, bool isFavorite) => runGuarded(
  context,
  () => context.backend.setFavorite(userId, s.id, !isFavorite),
  success: isFavorite ? 'Removed from favorites' : 'Saved to favorites',
);
