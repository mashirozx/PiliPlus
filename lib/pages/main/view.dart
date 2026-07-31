import 'dart:io';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/floating_navigation_bar.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/main_layout.dart';
import 'package:PiliPlus/common/widgets/route_aware_mixin.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/utils/android/android_helper.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/extension/context_ext.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/mobile_observer.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:win32/win32.dart' as kernel32;
import 'package:window_manager/window_manager.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends PopScopeState<MainApp>
    with
        RouteAware,
        RouteAwareMixin,
        WidgetsBindingObserver,
        WindowListener,
        TrayListener {
  final _mainController = Get.put(MainController());
  late final _setting = GStorage.setting;
  late EdgeInsets _padding;
  late ColorScheme _colorScheme;
  Brightness? _brightness;

  @override
  bool get initCanPop => false;

  @override
  void initState() {
    super.initState();
    addObserverMobile(this);
    if (PlatformUtils.isDesktop) {
      windowManager
        ..addListener(this)
        ..setPreventClose(true);
      if (_mainController.showTrayIcon) {
        trayManager.addListener(this);
        _handleTray();
      }
    } else {
      // FlutterSmartDialog throws
      PiliScheme.init();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _padding = MediaQuery.viewPaddingOf(context);
    _colorScheme = ColorScheme.of(context);
    final brightness = _colorScheme.brightness;
    NetworkImgLayer.reduce =
        NetworkImgLayer.reduceLuxColor != null && brightness.isDark;
    if (PlatformUtils.isDesktop) {
      if (_brightness != brightness) {
        _brightness = brightness;
        windowManager.setBrightness(brightness);
      }
    }
    if (!_mainController.useSideBar) {
      _mainController.useBottomNav = MediaQuery.sizeOf(context).isPortrait;
    }
  }

  @override
  void didPopNext() {
    addObserverMobile(this);
    _mainController
      ..checkUnreadDynamic()
      ..checkDefaultSearch(true)
      ..checkUnread(_mainController.useBottomNav);
    super.didPopNext();
  }

  @override
  void didPushNext() {
    removeObserverMobile(this);
    super.didPushNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mainController
        ..checkUnreadDynamic()
        ..checkDefaultSearch(true)
        ..checkUnread(_mainController.useBottomNav);
    }
  }

  @override
  void dispose() {
    if (PlatformUtils.isDesktop) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    removeObserverMobile(this);
    PiliScheme.listener?.cancel();
    GStorage.close();
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    _setting.put(SettingBoxKey.isWindowMaximized, true);
  }

  @override
  void onWindowUnmaximize() {
    _setting.put(SettingBoxKey.isWindowMaximized, false);
  }

  @override
  Future<void> onWindowMoved() async {
    if (PlPlayerController.instance?.isDesktopPip ?? false) {
      return;
    }
    final Offset offset = await windowManager.getPosition();
    _setting.put(SettingBoxKey.windowPosition, [offset.dx, offset.dy]);
  }

  @override
  Future<void> onWindowResized() async {
    if (PlPlayerController.instance?.isDesktopPip ?? false) {
      return;
    }
    final Rect bounds = await windowManager.getBounds();
    _setting.putAll({
      SettingBoxKey.windowSize: [bounds.width, bounds.height],
      SettingBoxKey.windowPosition: [bounds.left, bounds.top],
    });
  }

  @override
  void onWindowClose() {
    if (_mainController.showTrayIcon && _mainController.minimizeOnExit) {
      windowManager.hide();
      _onHideWindow();
    } else {
      _onClose();
    }
  }

  Future<void> _onClose() async {
    await GStorage.compact();
    await GStorage.close();
    await trayManager.destroy();
    if (Platform.isWindows) {
      // flutter_inappwebview
      // 6.2.0-beta.2+ https://github.com/pichillilorenzo/flutter_inappwebview/issues/2482
      // 6.1.5 https://github.com/pichillilorenzo/flutter_inappwebview/issues/2512#issuecomment-3031039587
      final hProcess = kernel32.GetCurrentProcess();
      kernel32.TerminateProcess(hProcess, 0);
    } else {
      exit(0);
    }
  }

  @override
  void onWindowMinimize() {
    _onHideWindow();
  }

  @override
  void onWindowRestore() {
    _onShowWindow();
  }

  void _onHideWindow() {
    if (_mainController.pauseOnMinimize) {
      if (PlPlayerController.instance case final player?) {
        if (_mainController.isPlaying = player.playerStatus.isPlaying) {
          player.pause();
        }
      } else {
        _mainController.isPlaying = false;
      }
    }
  }

  void _onShowWindow() {
    if (_mainController.pauseOnMinimize && _mainController.isPlaying) {
      PlPlayerController.instance?.play();
    }
  }

  @override
  Future<void> onTrayIconMouseDown() async {
    if (await windowManager.isVisible()) {
      _onHideWindow();
      windowManager.hide();
    } else {
      _onShowWindow();
      windowManager.show();
    }
  }

  @override
  Future<void> onTrayIconRightMouseDown() async {
    // ignore: deprecated_member_use
    trayManager.popUpContextMenu(bringAppToFront: true);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
      case 'exit':
        _onClose();
    }
  }

  Future<void> _handleTray() async {
    if (Platform.isWindows) {
      await trayManager.setIcon(Assets.logoIco);
    } else {
      await trayManager.setIcon(Assets.logoLarge);
    }
    if (!Platform.isLinux) {
      await trayManager.setToolTip(Constants.appName);
    }

    Menu trayMenu = Menu(
      items: [
        MenuItem(key: 'show', label: '显示窗口'),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: '退出 ${Constants.appName}'),
      ],
    );
    await trayManager.setContextMenu(trayMenu);
  }

  @pragma('vm:prefer-inline')
  static void _onBack() {
    if (Platform.isAndroid) {
      PiliAndroidHelper.back();
    }
  }

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (_mainController.directExitOnBack) {
      _onBack();
    } else {
      if (_mainController.selectedIndex.value != 0) {
        _mainController
          ..setIndex(0)
          ..barOffset?.value = 0.0
          ..showBottomBar?.value = true
          ..setSearchBar();
      } else {
        _onBack();
      }
    }
  }

  Widget? get _bottomNav {
    Widget? bottomNav;
    if (_mainController.navigationBars.length > 1) {
      if (_mainController.floatingNavBar) {
        bottomNav = Obx(
          () => FloatingNavigationBar(
            onDestinationSelected: _mainController.setIndex,
            selectedIndex: _mainController.selectedIndex.value,
            destinations: _mainController.navigationBars
                .map(
                  (e) => FloatingNavigationDestination(
                    label: e.label,
                    icon: _buildIcon(type: e),
                    selectedIcon: _buildIcon(type: e, selected: true),
                  ),
                )
                .toList(),
          ),
        );
      } else if (_mainController.enableMYBar) {
        bottomNav = Obx(
          () => _AnimatedMaterialNavigationBar(
            selectedIndex: _mainController.selectedIndex.value,
            onDestinationSelected: _mainController.setIndex,
            destinations: _mainController.navigationBars
                .map(
                  (e) => NavigationDestination(
                    label: e.label,
                    icon: _buildIcon(type: e),
                    selectedIcon: _buildIcon(type: e, selected: true),
                  ),
                )
                .toList(),
          ),
        );
      } else {
        bottomNav = Obx(
          () => _BottomBarSwipeDetector(
            selectedIndex: _mainController.selectedIndex.value,
            destinationCount: _mainController.navigationBars.length,
            onDestinationSelected: _mainController.setIndex,
            child: BottomNavigationBar(
              currentIndex: _mainController.selectedIndex.value,
              onTap: _mainController.setIndex,
              iconSize: 16,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: .fixed,
              items: _mainController.navigationBars
                  .map(
                    (e) => BottomNavigationBarItem(
                      label: e.label,
                      icon: _buildIcon(type: e),
                      activeIcon: _buildIcon(type: e, selected: true),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      }

      if (_mainController.hideBottomBar) {
        if (_mainController.barOffset case final barOffset?) {
          return Obx(
            () => FractionalTranslation(
              translation: Offset(
                0.0,
                barOffset.value / Style.topBarHeight,
              ),
              child: bottomNav,
            ),
          );
        }
        if (_mainController.showBottomBar case final showBottomBar?) {
          return Obx(
            () => AnimatedSlide(
              curve: Curves.easeInOutCubicEmphasized,
              duration: const Duration(milliseconds: 500),
              offset: Offset(0, showBottomBar.value ? 0 : 1),
              child: bottomNav,
            ),
          );
        }
      }
    }

    return bottomNav;
  }

  Widget _sideBar() {
    if (_mainController.navigationBars.length > 1) {
      if (context.isTablet && _mainController.optTabletNav) {
        return Padding(
          padding: const .only(top: 25),
          child: MediaQuery.removePadding(
            context: context,
            removeRight: true,
            child: DrawerTheme(
              data: DrawerThemeData(width: 130 + _padding.left),
              child: Obx(
                () => _AnimatedTabletNavigationDrawer(
                  onDestinationSelected: _mainController.setIndex,
                  selectedIndex: _mainController.selectedIndex.value,
                  destinationCount: _mainController.navigationBars.length,
                  flex: 5,
                  header: Expanded(flex: 4, child: userAndSearchVertical()),
                  destinationBuilder: (index, key) {
                    final destination = _mainController.navigationBars[index];
                    return NavigationDrawerDestination(
                      key: key,
                      label: Text(destination.label),
                      icon: _buildIcon(type: destination),
                      selectedIcon: _buildIcon(type: destination, selected: true),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }
      return Obx(
        () => NavigationRail(
          groupAlignment: 0.5,
          labelType: .selected,
          leading: userAndSearchVertical(),
          backgroundColor: Colors.transparent,
          onDestinationSelected: _mainController.setIndex,
          selectedIndex: _mainController.selectedIndex.value,
          destinations: _mainController.navigationBars
              .map(
                (e) => NavigationRailDestination(
                  label: Text(e.label),
                  icon: _buildIcon(type: e),
                  selectedIcon: _buildIcon(type: e, selected: true),
                ),
              )
              .toList(),
        ),
      );
    }
    return Container(
      width: 80,
      margin: .only(top: 12 + _padding.top, left: _padding.left),
      child: userAndSearchVertical(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_mainController.mainTabBarView) {
      child = TabBarView(
        controller: _mainController.controller,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: _mainController.useBottomNav ? .horizontal : .vertical,
        children: _mainController.navigationBars.map((i) => i.page).toList(),
      );
    } else {
      child = PageView(
        controller: _mainController.controller,
        physics: const NeverScrollableScrollPhysics(),
        children: _mainController.navigationBars.map((i) => i.page).toList(),
      );
    }

    Widget? sideBar;
    Widget? bottomNav;
    final EdgeInsets padding;
    if (_mainController.useBottomNav) {
      bottomNav = _bottomNav;
      if (bottomNav != null) {
        bottomNav = MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: bottomNav,
        );
      }
      padding = .only(
        top: _padding.top,
        left: _padding.left,
        right: _padding.right,
      );
    } else {
      sideBar = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: _colorScheme.outline.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: _sideBar(),
      );
      padding = .only(top: _padding.top, right: _padding.right);
    }

    child = Material(
      child: MainLayout(
        sideBar: sideBar,
        bottomNav: bottomNav,
        body: Padding(padding: padding, child: child),
      ),
    );

    if (PlatformUtils.isMobile) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: _colorScheme.brightness,
          statusBarIconBrightness: _colorScheme.brightness.reverse,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: _colorScheme.brightness.reverse,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _buildIcon({required NavigationBarType type, bool selected = false}) {
    final icon = selected ? type.selectIcon : type.icon;
    return type == .dynamics
        ? Obx(
            () {
              final dynCount = _mainController.dynCount.value;
              return Badge(
                isLabelVisible: dynCount > 0,
                label: _mainController.dynamicBadgeMode == .number
                    ? Text(dynCount.toString())
                    : null,
                padding: const .symmetric(horizontal: 6),
                child: icon,
              );
            },
          )
        : icon;
  }

  Widget userAndSearchVertical() {
    return Column(
      children: [
        userAvatar(colorScheme: _colorScheme, mainController: _mainController),
        const SizedBox(height: 8),
        msgBadge(_mainController),
        IconButton(
          tooltip: '搜索',
          icon: const Icon(
            Icons.search_outlined,
            semanticLabel: '搜索',
          ),
          onPressed: () => Get.toNamed('/search'),
        ),
      ],
    );
  }
}

class _BottomBarSwipeDetector extends StatefulWidget {
  const _BottomBarSwipeDetector({
    required this.selectedIndex,
    required this.destinationCount,
    required this.onDestinationSelected,
    required this.child,
  });

  final int selectedIndex;
  final int destinationCount;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  @override
  State<_BottomBarSwipeDetector> createState() =>
      _BottomBarSwipeDetectorState();
}

class _AnimatedMaterialNavigationBar extends StatefulWidget {
  const _AnimatedMaterialNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  State<_AnimatedMaterialNavigationBar> createState() =>
      _AnimatedMaterialNavigationBarState();
}

class _AnimatedMaterialNavigationBarState
    extends State<_AnimatedMaterialNavigationBar>
    with SingleTickerProviderStateMixin {
  static const _indicatorWidth = 64.0;
  static const _indicatorHeight = 32.0;
  // Matches NavigationBar's selected icon position when its label is shown.
  static const _indicatorTop = 15.0;

  late final AnimationController _indicatorController;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(_AnimatedMaterialNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _indicatorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationBarTheme = NavigationBarTheme.of(context);
    final theme = Theme.of(context);
    final indicatorColor =
        navigationBarTheme.indicatorColor ??
        theme.colorScheme.secondaryContainer;

    return _BottomBarSwipeDetector(
      selectedIndex: widget.selectedIndex,
      destinationCount: widget.destinations.length,
      onDestinationSelected: widget.onDestinationSelected,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / widget.destinations.length;
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color:
                      navigationBarTheme.backgroundColor ??
                      theme.colorScheme.surfaceContainer,
                ),
              ),
              AnimatedBuilder(
                animation: _indicatorController,
                builder: (context, child) {
                  final progress = Curves.easeInOutCubicEmphasized.transform(
                    _indicatorController.value,
                  );
                  final distance =
                      (widget.selectedIndex - _previousIndex).abs() * itemWidth;
                  final expansion = (progress * 2).clamp(0.0, 1.0);
                  final contraction = ((progress - .5) * 2).clamp(0.0, 1.0);
                  final movingRight = widget.selectedIndex >= _previousIndex;
                  final startLeft =
                      _previousIndex * itemWidth +
                      (itemWidth - _indicatorWidth) / 2;
                  final left = movingRight
                      ? startLeft + distance * contraction
                      : startLeft - distance * expansion;
                  final width =
                      _indicatorWidth + distance * (expansion - contraction);
                  return Positioned(
                    left: left,
                    top: _indicatorTop,
                    width: width,
                    height: _indicatorHeight,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: indicatorColor,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  );
                },
              ),
              NavigationBarTheme(
                data: navigationBarTheme.copyWith(
                  backgroundColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                ),
                child: NavigationBar(
                  maintainBottomViewPadding: true,
                  onDestinationSelected: widget.onDestinationSelected,
                  selectedIndex: widget.selectedIndex,
                  destinations: widget.destinations,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedTabletNavigationDrawer extends StatefulWidget {
  const _AnimatedTabletNavigationDrawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinationCount,
    required this.destinationBuilder,
    required this.header,
    required this.flex,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int destinationCount;
  final NavigationDrawerDestination Function(int index, Key key)
  destinationBuilder;
  final Widget header;
  final int flex;

  @override
  State<_AnimatedTabletNavigationDrawer> createState() =>
      _AnimatedTabletNavigationDrawerState();
}

class _AnimatedTabletNavigationDrawerState
    extends State<_AnimatedTabletNavigationDrawer>
    with SingleTickerProviderStateMixin {
  static const _indicatorHeight = 56.0;
  final _drawerKey = GlobalKey();
  late final AnimationController _indicatorController;
  late List<GlobalKey> _destinationKeys;
  List<Rect>? _destinationRects;
  late int _previousIndex;
  double? _dragStartY;

  @override
  void initState() {
    super.initState();
    _destinationKeys = List.generate(
      widget.destinationCount,
      (_) => GlobalKey(),
    );
    _previousIndex = widget.selectedIndex;
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measureDestinations(),
    );
  }

  @override
  void didUpdateWidget(_AnimatedTabletNavigationDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationCount != oldWidget.destinationCount) {
      _destinationKeys = List.generate(
        widget.destinationCount,
        (_) => GlobalKey(),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _measureDestinations(),
      );
    }
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _indicatorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _measureDestinations() {
    final drawerBox =
        _drawerKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || drawerBox == null) {
      return;
    }
    final destinationRects = <Rect>[];
    for (final key in _destinationKeys) {
      final destinationBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (destinationBox == null) {
        return;
      }
      final offset = destinationBox.localToGlobal(
        Offset.zero,
        ancestor: drawerBox,
      );
      destinationRects.add(
        Rect.fromLTWH(
          12,
          offset.dy + (destinationBox.size.height - _indicatorHeight) / 2,
          drawerBox.size.width - 24,
          _indicatorHeight,
        ),
      );
    }
    setState(() => _destinationRects = destinationRects);
  }

  void _handlePointerUp(PointerUpEvent event) {
    final dragStartY = _dragStartY;
    _dragStartY = null;
    if (dragStartY == null) {
      return;
    }
    final dragDistance = event.position.dy - dragStartY;
    if (dragDistance.abs() < 48) {
      return;
    }
    final nextIndex = widget.selectedIndex + (dragDistance < 0 ? 1 : -1);
    if (nextIndex >= 0 && nextIndex < widget.destinationCount) {
      widget.onDestinationSelected(nextIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerTheme = NavigationDrawerTheme.of(context);
    final theme = Theme.of(context);
    final indicatorColor =
        drawerTheme.indicatorColor ?? theme.colorScheme.secondaryContainer;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _dragStartY = event.position.dy,
      onPointerUp: _handlePointerUp,
      onPointerCancel: (_) => _dragStartY = null,
      child: Stack(
        key: _drawerKey,
        children: [
          if (_destinationRects case final destinationRects?)
            AnimatedBuilder(
              animation: _indicatorController,
              builder: (context, child) {
                final from = destinationRects[_previousIndex];
                final to = destinationRects[widget.selectedIndex];
                final progress = Curves.easeInOutCubicEmphasized.transform(
                  _indicatorController.value,
                );
                final distance = (to.top - from.top).abs();
                final expansion = (progress * 2).clamp(0.0, 1.0);
                final contraction = ((progress - .5) * 2).clamp(0.0, 1.0);
                final movingDown = to.top >= from.top;
                final top = movingDown
                    ? from.top + distance * contraction
                    : from.top - distance * expansion;
                final height =
                    from.height + distance * (expansion - contraction);
                return Positioned(
                  left: from.left,
                  top: top,
                  width: from.width,
                  height: height,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: indicatorColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                );
              },
            ),
          NavigationDrawerTheme(
            data: drawerTheme.copyWith(indicatorColor: Colors.transparent),
            child: NavigationDrawer(
              backgroundColor: Colors.transparent,
              flex: widget.flex,
              header: widget.header,
              tilePadding: const .symmetric(vertical: 5, horizontal: 12),
              onDestinationSelected: widget.onDestinationSelected,
              selectedIndex: widget.selectedIndex,
              children: List.generate(
                widget.destinationCount,
                (index) => widget.destinationBuilder(
                  index,
                  _destinationKeys[index],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBarSwipeDetectorState extends State<_BottomBarSwipeDetector> {
  double? _dragStartX;

  void _handlePointerUp(PointerUpEvent event) {
    final dragStartX = _dragStartX;
    _dragStartX = null;
    if (dragStartX == null) {
      return;
    }
    final dragDistance = event.position.dx - dragStartX;
    if (dragDistance.abs() < 48) {
      return;
    }
    final nextIndex = widget.selectedIndex + (dragDistance < 0 ? 1 : -1);
    if (nextIndex >= 0 && nextIndex < widget.destinationCount) {
      widget.onDestinationSelected(nextIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _dragStartX = event.position.dx,
      onPointerUp: _handlePointerUp,
      onPointerCancel: (_) => _dragStartX = null,
      child: widget.child,
    );
  }
}
