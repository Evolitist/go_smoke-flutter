import 'dart:ui';

import 'package:flutter/material.dart';

class SizeSavingDelegate extends SingleChildLayoutDelegate {
  Size childSize = Size.square(0.0);
  double diffHeight = 0.0;

  double get childWidth => childSize.width;

  double get childHeight => childSize.height;

  @override
  bool shouldRelayout(SingleChildLayoutDelegate oldDelegate) {
    SizeSavingDelegate old = oldDelegate as SizeSavingDelegate;
    return old.childSize != childSize || old.diffHeight != diffHeight;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    this.childSize = childSize;
    diffHeight = size.height - childSize.height;
    return Offset(0.0, diffHeight);
  }
}
