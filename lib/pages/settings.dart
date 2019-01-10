import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/prefs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  static const _eeDuration = const Duration(seconds: 2);
  final Prefs _prefs = Prefs();
  AnimationController _eeController;
  bool isDark;

  @override
  void initState() {
    super.initState();
    isDark = _prefs['isDark'] ?? false;
    _eeController = AnimationController(
      vsync: this,
    )..addListener(() {
        if (_eeController.value == 1.0) _eeController.value = 0.0;
        setState(() {});
      });
  }

  Widget _buildEE(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    Curve rotation = Interval(0.1, 0.7, curve: Curves.easeInOut);
    Curve opacityIn = Interval(0.0, 0.1, curve: Curves.easeInOut);
    Curve opacityOut = Interval(0.9, 1.0, curve: Curves.easeInOut);
    return Align(
      alignment: Alignment.bottomCenter,
      child: refreshState != RefreshIndicatorMode.armed &&
              refreshState != RefreshIndicatorMode.refresh
          ? null
          : Opacity(
              opacity: min(
                opacityIn.transform(_eeController.value),
                1.0 - opacityOut.transform(_eeController.value),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Transform.rotate(
                    angle: rotation.transform(_eeController.value) * 4 * pi,
                    child: Stack(
                      children: <Widget>[
                        Opacity(
                          opacity:
                              1.0 - rotation.transform(_eeController.value),
                          child: Icon(Icons.close),
                        ),
                        Opacity(
                          opacity: rotation.transform(_eeController.value),
                          child: Icon(Icons.check),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Well, you found me.',
                        style: Theme.of(context).textTheme.overline,
                      ),
                      Text(
                        'What\'s next?',
                        style: Theme.of(context).textTheme.overline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        return GroupListTile(
          heading: 'INTERFACE',
          children: <Widget>[
            SwitchListTile(
              title: const Text("Dark theme"),
              value: isDark,
              onChanged: (value) {
                _prefs['isDark'] = value;
                setState(() {
                  isDark = value;
                });
              },
            ),
          ],
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        titleSpacing: 24.0,
        centerTitle: true,
        elevation: 0.0,
        textTheme: Theme.of(context).textTheme,
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Theme.of(context).canvasColor,
      ),
      body: ScrollConfiguration(
        behavior: _NoFeedbackBehavior(),
        child: CustomScrollView(
          slivers: <Widget>[
            CupertinoSliverRefreshControl(
              refreshTriggerPullDistance:
                  MediaQuery.of(context).size.height * 0.1,
              refreshIndicatorExtent: 24.0,
              builder: _buildEE,
              onRefresh: () {
                _eeController.animateTo(1.0, duration: _eeDuration);
                return Future.delayed(_eeDuration);
              },
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(_buildListItem),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupListTile extends StatelessWidget {
  final String heading;
  final List<Widget> children;

  GroupListTile({
    Key key,
    @required this.heading,
    @required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(children.length + 2, (index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16.0, 28.0, 16.0, 4.0),
            child: Text(
              heading,
              style: Theme.of(context).textTheme.overline.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          );
        } else if (index <= children.length) {
          return children[index - 1];
        } else if (index == children.length + 1) {
          return Divider(
            height: 0.0,
          );
        } else {
          return null;
        }
      }),
    );
  }
}

class _NoFeedbackBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
          BuildContext context, Widget child, AxisDirection axisDirection) =>
      child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      CustomBouncingScrollPhysics();
}

class CustomBouncingScrollPhysics extends ScrollPhysics {
  const CustomBouncingScrollPhysics();

  @override
  CustomBouncingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return CustomBouncingScrollPhysics();
  }

  double frictionFactor(double overscrollFraction) =>
      0.05 * pow(1 - overscrollFraction, 2);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) return offset;

    final double overscrollPastStart =
        max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd =
        max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast = max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) return absDelta * gamma;
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: 0.0,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  double get minFlingVelocity => 100.0;

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        min(0.000816 * pow(existingVelocity.abs(), 1.967).toDouble(), 40000.0);
  }

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}
