import 'dart:ui';

import 'package:flutter/material.dart';

class SizeSavingDelegate extends SingleChildLayoutDelegate {
  Size parentSize = Size.square(0.0);
  Size childSize = Size.square(0.0);

  double get diffHeight => parentSize.height - childSize.height;

  double get childWidth => childSize.width;

  double get childHeight => childSize.height;

  @override
  bool shouldRelayout(SingleChildLayoutDelegate oldDelegate) {
    SizeSavingDelegate old = oldDelegate as SizeSavingDelegate;
    return old.childSize != childSize || old.parentSize != parentSize;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    this.parentSize = size;
    this.childSize = childSize;
    return Offset(0.0, diffHeight);
  }
}

class Trigger extends ChangeNotifier {
  void fire() => notifyListeners();
}
