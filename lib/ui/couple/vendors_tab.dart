import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/app_user.dart';
import '../../data/models/service.dart';
import '../widgets/common.dart';
import 'catalog.dart';
import 'couple_shell.dart';
import 'home_tab.dart';

enum SortBy { rating, priceLow, priceHigh }

/// "Browse & Filter Services" use case: by type, city and price (§6.4).
class VendorsTab extends StatefulWidget {
  const VendorsTab({super.key, required this.couple});
  final Couple couple;

  @override
  State<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends State<VendorsTab> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  ServiceCategory? _category;
  String? _city;
  double? _maxPrice;
  SortBy _sort = SortBy.rating;
  bool _freeOnWeddingDay = false;
  CoupleShellState? _shell;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shell == null) {
      _shell = CoupleShell.of(context);
      _shell!.vendorFilter.addListener(_onExternalFilter);
      _shell!.vendorSearchFocus.addListener(_onFocusRequest);
    }
  }

  void _onExternalFilter() => setState(() => _category = _shell!.vendorFilter.value);
  void _onFocusRequest() => WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());

  @override
  void dispose() {
    _shell?.vendorFilter.removeListener(_onExternalFilter);
    _shell?.vendorSearchFocus.removeListener(_onFocusRequest);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  int get _activeFilters => [_city != null, _maxPrice != null, _freeOnWeddingDay].where((x) => x).length;

  List<Service> _apply(List<Service> all) {
    final q = _search.text.trim().toLowerCase();
    final wedding = widget.couple.weddingDate;
    final list = all.where((s) {
      if (_category != null && s.category != _category) return false;
      if (_city != null && s.city != _city) return false;
      if (_maxPrice != null && s.price > _maxPrice!) return false;
      if (_freeOnWeddingDay && wedding != null && !s.checkAvailability(wedding)) return false;
      if (q.isNotEmpty &&
          !('${s.title} ${s.providerName} ${s.category.label} ${cityName(s.city)} ${s.description}'
              .toLowerCase()
              .contains(q))) {
        return false;
      }
      return true;
    }).toList();
    switch (_sort) {
      case SortBy.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortBy.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case SortBy.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(VoidCallback f) {
            setState(f);
            setSheet(() {});
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: ctx.text.headlineMedium),
                  const SizedBox(height: 18),
                  Text('City', style: ctx.text.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any city'),
                        selected: _city == null,
                        onSelected: (_) => update(() => _city = null),
                      ),
                      for (final c in kCities)
                        ChoiceChip(
                          label: Text(cityName(c)),
                          selected: _city == c,
                          onSelected: (_) => update(() => _city = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Maximum price', style: ctx.text.titleSmall),
                      const Spacer(),
                      Text(
                        _maxPrice == null ? 'Any' : money(_maxPrice!),
                        style: ctx.text.labelLarge?.copyWith(color: ctx.colors.roseGold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxPrice ?? 5000,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    label: _maxPrice == null ? 'Any' : money(_maxPrice!),
                    onChanged: (v) => update(() => _maxPrice = v >= 5000 ? null : v),
                  ),
                  if (widget.couple.weddingDate != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Free on our wedding day'),
                      subtitle: Text(fmtDateLong(widget.couple.weddingDate!)),
                      value: _freeOnWeddingDay,
                      onChanged: (v) => update(() => _freeOnWeddingDay = v),
                    ),
                  const SizedBox(height: 8),
                  Text('Sort by', style: ctx.text.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<SortBy>(
                    segments: const [
                      ButtonSegment(value: SortBy.rating, label: Text('Top rated')),
                      ButtonSegment(value: SortBy.priceLow, label: Text('Lowest price')),
                      ButtonSegment(value: SortBy.priceHigh, label: Text('Highest')),
                    ],
                    selected: {_sort},
                    onSelectionChanged: (s) => update(() => _sort = s.first),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => update(() {
                            _city = null;
                            _maxPrice = null;
                            _freeOnWeddingDay = false;
                            _sort = SortBy.rating;
                          }),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Show results')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: CatalogView(
      userId: widget.couple.id,
      builder: (context, catalog) {
        final results = _apply(catalog.services);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('Vendors', style: context.text.displaySmall),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        focusNode: _searchFocus,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search vendors and services',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(_search.clear),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: _activeFilters > 0,
                      label: Text('$_activeFilters'),
                      backgroundColor: context.scheme.primary,
                      textColor: context.scheme.onPrimary,
                      child: IconButton.outlined(
                        tooltip: 'Filters',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(54, 54),
                          side: BorderSide(color: context.colors.outline),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _openFilters,
                        icon: const Icon(Icons.tune),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                    ),
                    for (final c in ServiceCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            c.icon,
                            size: 16,
                            color: _category == c ? context.scheme.onPrimary : context.colors.muted,
                          ),
                          label: Text(c.label),
                          selected: _category == c,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _category = _category == c ? null : c),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                  style: context.text.bodySmall,
                ),
              ),
            ),
            if (results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off,
                  title: 'No vendors match',
                  message: 'Try another category, a different city or a higher price limit.',
                  action: 'Clear filters',
                  onAction: () => setState(() {
                    _category = null;
                    _city = null;
                    _maxPrice = null;
                    _freeOnWeddingDay = false;
                    _search.clear();
                  }),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = results[i];
                    final fav = catalog.isFavorite(s);
                    return ServiceTile(
                      service: s,
                      isFavorite: fav,
                      onFavorite: () => toggleFavorite(context, widget.couple.id, s, fav),
                      onTap: () => openService(context, s.id),
                    );
                  },
                ),
              ),
          ],
        );
      },
    ),
  );
}
