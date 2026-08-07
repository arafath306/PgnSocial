import 'package:flutter/material.dart';

class NoTransitionPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  NoTransitionPageRoute({required this.child, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        );
}
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
