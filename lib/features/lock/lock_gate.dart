// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';

import '../../core/auth/app_lock_service.dart';
import 'lock_screen.dart';

/// Hides the whole app behind the lock screen until it is unlocked.
///
/// The app's navigator stays alive (offstage) while locked, so the user
/// returns exactly where they were after unlocking.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.lock, required this.child});

  final AppLockService lock;
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _lockNavigatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        widget.lock.onPaused();
      case AppLifecycleState.resumed:
        widget.lock.onResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.lock,
      builder: (context, _) {
        final locked = widget.lock.state != AppLockState.unlocked;
        return Stack(
          children: [
            ExcludeFocus(
              excluding: locked,
              child: TickerMode(
                enabled: !locked,
                child: Offstage(offstage: locked, child: widget.child),
              ),
            ),
            if (locked)
              Positioned.fill(
                // Own navigator: lock screens get an Overlay for text fields
                // and tooltips without touching the app's navigation stack.
                child: Navigator(
                  key: _lockNavigatorKey,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => LockScreen(lock: widget.lock),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
