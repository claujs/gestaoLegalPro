import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../theme/design_tokens.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final int navIndex;
  final ValueChanged<int> onNavChange;
  final String? title;
  final List<Widget>? actions;
  final bool showRail;
  final Key? pageKey;

  const AppShell({
    super.key,
    required this.child,
    required this.navIndex,
    required this.onNavChange,
    this.title,
    this.actions,
    required this.showRail,
    this.pageKey,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showRailLocal = showRail && width >= AppTokens.bpTablet;

    final rail = NavigationRail(
      selectedIndex: navIndex,
      onDestinationSelected: onNavChange,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.folder_open),
          selectedIcon: Icon(Icons.folder),
          label: Text('Processos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.description),
          label: Text('Documentos'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.event),
          label: Text('Agenda'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people),
          label: Text('Clientes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.smart_toy),
          label: Text('Assistente'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Config'),
        ),
      ],
    );

    final header = AnimatedContainer(
      duration: AppTokens.dMed,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s24,
        vertical: AppTokens.s12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(.06),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!showRailLocal)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Expanded(
            child: Text(
              title ?? '',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ...?actions,
        ],
      ),
    );

    return Scaffold(
      drawer: showRailLocal
          ? null
          : Drawer(
              child: SafeArea(child: SingleChildScrollView(child: rail)),
            ),
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: Row(
                children: [
                  if (showRailLocal) rail,
                  Expanded(
                    child: PageTransitionSwitcher(
                      transitionBuilder:
                          (child, animation, secondaryAnimation) =>
                              SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType: SharedAxisTransitionType.scaled,
                                child: child,
                              ),
                      child: Container(
                        key: pageKey ?? ValueKey('p-$navIndex-${title ?? ''}'),
                        color: Theme.of(context).colorScheme.surface,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showRailLocal
          ? null
          : NavigationBar(
              selectedIndex: navIndex.clamp(0, 2),
              onDestinationSelected: (i) => onNavChange(i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_open),
                  label: 'Processos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.description),
                  label: 'Docs',
                ),
              ],
            ),
    );
  }
}
