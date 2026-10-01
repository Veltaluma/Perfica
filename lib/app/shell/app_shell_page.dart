import 'package:flutter/material.dart';

import '../../core/design_system/tokens/app_breakpoints.dart';
import '../../features/focus/presentation/focus_page.dart';
import '../../features/insights/presentation/insights_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../l10n/app_localizations.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({this.initialIndex = 0, super.key})
    : assert(initialIndex >= 0 && initialIndex <= 2);

  final int initialIndex;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  late int _index;
  late final List<Widget?> _pages;

  @override
  void initState() {
    super.initState();

    _index = widget.initialIndex;

    _pages = <Widget?>[null, null, null];

    _pages[_index] = _createPage(_index);
  }

  @override
  void didUpdateWidget(covariant AppShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialIndex == widget.initialIndex) {
      return;
    }

    _pages[widget.initialIndex] ??= _createPage(widget.initialIndex);

    _index = widget.initialIndex;
  }

  Widget _createPage(int index) {
    return switch (index) {
      0 => const TasksPage(),
      1 => const FocusPage(),
      2 => const InsightsPage(),
      _ => throw RangeError.range(index, 0, 2, 'index'),
    };
  }

  void _selectIndex(int value) {
    if (value == _index) {
      return;
    }

    _pages[value] ??= _createPage(value);

    setState(() {
      _index = value;
    });
  }

  List<Widget> get _stackChildren {
    return List<Widget>.generate(
      _pages.length,
      (index) => _pages[index] ?? const SizedBox.shrink(),
      growable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.check_circle_outline_rounded),
        selectedIcon: const Icon(Icons.check_circle_rounded),
        label: l.navTasks,
      ),
      NavigationDestination(
        icon: const Icon(Icons.timer_outlined),
        selectedIcon: const Icon(Icons.timer_rounded),
        label: l.navFocus,
      ),
      NavigationDestination(
        icon: const Icon(Icons.insights_outlined),
        selectedIcon: const Icon(Icons.insights_rounded),
        label: l.navInsights,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = IndexedStack(index: _index, children: _stackChildren);

        if (constraints.maxWidth >= AppBreakpoints.medium) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: _selectIndex,
                  destinations: destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                      )
                      .toList(growable: false),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _selectIndex,
            destinations: destinations,
          ),
        );
      },
    );
  }
}
