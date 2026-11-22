import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/app_user.dart';
import '../../data/models/service.dart';
import '../../logic/session.dart';
import 'budget_tab.dart';
import 'checklist_tab.dart';
import 'home_tab.dart';
import 'more_tab.dart';
import 'vendors_tab.dart';

/// Bride & Groom area. Bottom navigation follows the report's concept UI
/// (Appendix B): Home, Vendors, Checklist, Budget, More.
class CoupleShell extends StatefulWidget {
  const CoupleShell({super.key});

  static CoupleShellState of(BuildContext context) => context.findAncestorStateOfType<CoupleShellState>()!;

  @override
  State<CoupleShell> createState() => CoupleShellState();
}

class CoupleShellState extends State<CoupleShell> {
  int _index = 0;
  final vendorFilter = ValueNotifier<ServiceCategory?>(null);
  final vendorSearchFocus = ValueNotifier<int>(0);

  void openVendors({ServiceCategory? category, bool focusSearch = false}) {
    vendorFilter.value = category;
    if (focusSearch) vendorSearchFocus.value++;
    setState(() => _index = 1);
  }

  void openTab(int index) => setState(() => _index = index);

  @override
  void dispose() {
    vendorFilter.dispose();
    vendorSearchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    if (user is! Couple) return const SizedBox.shrink();
    final tabs = [
      HomeTab(couple: user),
      VendorsTab(couple: user),
      ChecklistTab(couple: user),
      BudgetTab(couple: user),
      MoreTab(couple: user),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: openTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Vendors',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Checklist',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
