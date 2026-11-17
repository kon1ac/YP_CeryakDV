import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

/// Следит за активностью пользователя и завершает сеанс при простое.
class InactivityWatcher extends StatefulWidget {
  const InactivityWatcher({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 3),
    this.warnBefore = const Duration(seconds: 30),
  });

  final Widget child;
  final Duration timeout;
  final Duration warnBefore;

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher>
    with WidgetsBindingObserver {
  Timer? _idleTimer;
  Timer? _warnTimer;
  bool _dialogOpen = false;

  Duration get _warnAfter {
    final value = widget.timeout - widget.warnBefore;
    return value.isNegative ? Duration.zero : value;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armTimers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onActivity();
    }
  }

  void _cancelTimers() {
    _idleTimer?.cancel();
    _warnTimer?.cancel();
    _idleTimer = null;
    _warnTimer = null;
  }

  void _armTimers() {
    _cancelTimers();
    final auth = context.read<AuthNotifier>();
    if (!auth.isAuthenticated) return;

    _warnTimer = Timer(_warnAfter, _showWarning);
    _idleTimer = Timer(widget.timeout, _expireSession);
  }

  void _onActivity() {
    if (_dialogOpen) return;
    _armTimers();
  }

  Future<void> _showWarning() async {
    if (!mounted || _dialogOpen) return;
    final auth = context.read<AuthNotifier>();
    if (!auth.isAuthenticated) return;

    _dialogOpen = true;
    final remain = widget.warnBefore;
    final stay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Сеанс скоро завершится'),
        content: Text(
          'Нет активности около ${widget.timeout.inMinutes} мин. '
          'Выход через ${remain.inSeconds} с.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Выйти'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (!mounted) return;

    if (stay == true) {
      _armTimers();
      return;
    }
    await context.read<AuthNotifier>().logout();
  }

  Future<void> _expireSession() async {
    if (!mounted) return;
    if (_dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop(false);
      _dialogOpen = false;
    }
    final auth = context.read<AuthNotifier>();
    if (!auth.isAuthenticated) return;
    await auth.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Сеанс завершён из‑за бездействия')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authenticated =
        context.select<AuthNotifier, bool>((auth) => auth.isAuthenticated);

    if (!authenticated) {
      _cancelTimers();
    } else if (_idleTimer == null && !_dialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _armTimers();
      });
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onActivity(),
      onPointerSignal: (_) => _onActivity(),
      child: widget.child,
    );
  }
}
