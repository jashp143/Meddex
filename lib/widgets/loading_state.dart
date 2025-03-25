import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  final String? message;
  final Widget? icon;
  final bool showSpinner;
  final Color? color;

  const LoadingState({
    super.key,
    this.message,
    this.icon,
    this.showSpinner = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(height: 16),
          ],
          if (showSpinner) ...[
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (message != null)
            Text(
              message!,
              style: TextStyle(
                fontSize: 16,
                color: color ?? Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // Factory constructors for common loading states
  factory LoadingState.error({
    String? message,
    VoidCallback? onRetry,
  }) {
    return LoadingState(
      message: message ?? 'An error occurred',
      icon: Icon(
        Icons.error_outline,
        size: 48,
        color: Colors.red,
      ),
      showSpinner: false,
      color: Colors.red,
    );
  }

  factory LoadingState.empty({
    String? message,
    IconData? icon,
  }) {
    return LoadingState(
      message: message ?? 'No data available',
      icon: Icon(
        icon ?? Icons.inbox_outlined,
        size: 48,
        color: Colors.grey,
      ),
      showSpinner: false,
      color: Colors.grey,
    );
  }
}
