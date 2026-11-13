import 'package:flutter/material.dart';

/// Redirects before constructing a screen that needs an authenticated user.
class SessionGuard extends StatefulWidget {
  final bool Function() hasSession;
  final WidgetBuilder builder;

  const SessionGuard({
    super.key,
    required this.hasSession,
    required this.builder,
  });

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    if (widget.hasSession()) return widget.builder(context);
    if (!_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
    }
    return const SizedBox.shrink();
  }
}
