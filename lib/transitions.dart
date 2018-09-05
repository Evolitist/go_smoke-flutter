import 'package:flutter/material.dart';

class PaddingTransition extends AnimatedWidget {
  const PaddingTransition({
    Key key,
    @required Animation<EdgeInsets> padding,
    this.child,
  }) : super(key: key, listenable: padding);

  Animation<EdgeInsets> get padding => listenable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding.value,
      child: child,
    );
  }
}
