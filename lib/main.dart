// @license
// Copyright (c) 2019 - 2021 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gg_router/gg_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './src/application.dart';

// coverage:ignore-start
void main() {
  runApp(const GgRouterExample());
}
// coverage:ignore-end

const debugShowCheckedModeBanner = false;

// .............................................................................
class GgRouterExample extends StatefulWidget {
  const GgRouterExample({Key? key}) : super(key: key);

  @override
  State<GgRouterExample> createState() => _GgRouterExampleState();
}

class _GgRouterExampleState extends State<GgRouterExample> {
  final _application = Application(name: 'application');

  // ...........................................................................
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _application.dispose();
    super.dispose();
  }

  // ...........................................................................
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mobile Adhoc Evaluator',
      routerDelegate: GgRouterDelegate(
        child: _appContent,
        saveState: _saveState,
        restoreState: _restoreState,
        defaultRoute: '/tcp/measure',
      ),
      routeInformationParser: GgRouteInformationParser(),
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(brightness: Brightness.dark),
      theme: ThemeData(brightness: Brightness.light),
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      showSemanticsDebugger: false,
    );
  }

  // ...........................................................................
  Widget get _appContent {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile AdHoc Evaluator'),
        actions: <Widget>[
          _routeButton('TCP', 'tcp'),
          _routeButton('Nearby', 'nearby'),
          _routeButton('BTLE', 'btle'),
          Container(
            width: debugShowCheckedModeBanner ? 50 : 0,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          _initErrorHandler(context);
          return GgRouter(
            {
              '_INDEX_': _indexPage,
              'tcp': _tcpPage,
              'nearby': _nearbyPage,
              'btle': _btlePage,
              '*': _wildCardPage,
            },
            key: const ValueKey('mainRouter'),
            inAnimation: _zoomIn,
            outAnimation: _zoomOut,
            semanticLabels: const {
              '_INDEX_': 'Navigate to Index Page',
              'tcp': 'Navigate to TCP Page',
              'nearby': 'Navigate to Nearby Page',
              'btle': 'Navigate to BTLE Page',
              '*': 'Another Page',
            },
          );
        },
      ),
    );
  }

  // ...........................................................................
  void _initErrorHandler(BuildContext context) {
    final node = GgRouter.of(context).node;
    node.errorHandler = null;
    node.errorHandler = (error) {
      final snackBar = SnackBar(
        content: Text(error.message),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.red,
      );

      scheduleMicrotask(
          () => ScaffoldMessenger.of(context).showSnackBar(snackBar));
    };
  }

  // ...........................................................................
  Widget _text(String text, BuildContext context, bool isStaged) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final onPrimaryInactive = onPrimary.withAlpha(120);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Text(
        text,
        style: TextStyle(color: isStaged ? onPrimary : onPrimaryInactive),
      ),
    );
  }

  // ...........................................................................
  Widget _bigIcon(BuildContext context, IconData icon) {
    return Center(
      child: Icon(
        icon,
        size: 200,
        color: const Color(0x33FFFFFF),
      ),
    );
  }

  // ...........................................................................
  Widget _routeButton(String title, String route) {
    return Builder(builder: (context) {
      final router = GgRouter.of(context);

      return StreamBuilder(
        stream: router.onActiveChildChange,
        builder: (context, snapshot) {
          final isStaged = router.routeNameOfActiveChild == route;
          final path = '$route/_LAST_';
          final semanticLabel = router.semanticLabelForPath(route);

          return Semantics(
            excludeSemantics: true,
            label: semanticLabel,
            child: TextButton(
              key: ValueKey(route),
              onPressed: () => router.navigateTo(path),
              child: _text(title, context, isStaged),
            ),
          );
        },
      );
    });
  }

  // ...........................................................................
  Widget _indexPage(BuildContext context) {
    return Center(
      key: const ValueKey('indexPage'),
      child: Text(
        'GgRouter',
        style: Theme.of(context).textTheme.headline2,
      ),
    );
  }

  // ...........................................................................
  Widget _wildCardPage(BuildContext context) {
    final routeName = GgRouter.of(context).routeName;

    return Center(
      key: const ValueKey('wildCardPage'),
      child: Text(
        'Wildcard: $routeName',
        key: ValueKey('WildCardText: $routeName'),
        style: Theme.of(context).textTheme.headline2,
      ),
    );
  }

  // ...........................................................................
  Widget _tcpPage(BuildContext context) {
    final router = GgRouter.of(context);

    return Scaffold(
      key: const ValueKey('tcpPage'),
      bottomNavigationBar: StreamBuilder(
          stream: router.onActiveChildChange,
          builder: (context, snapshot) {
            final index = router.indexOfActiveChild ?? 0;

            return BottomNavigationBar(
              currentIndex: index,
              items: const [
                BottomNavigationBarItem(
                  label: 'Measure',
                  icon: Icon(Icons.sports_basketball),
                ),
                BottomNavigationBarItem(
                  label: 'Results',
                  icon: Icon(Icons.sports_football),
                ),
                BottomNavigationBarItem(
                  label: 'Info',
                  icon: Icon(Icons.sports_handball),
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    router.navigateTo('measure/_LAST_');
                    break;
                  case 1:
                    router.navigateTo('results/_LAST_');
                    break;
                  case 2:
                    router.navigateTo('info/_LAST_');
                    break;
                }
              },
            );
          }),
      body: GgRouter(
        {
          'measure': (c) => _bigIcon(c, Icons.sports_basketball),
          'results': (c) => _bigIcon(c, Icons.sports_football),
          'info': (c) => _bigIcon(c, Icons.sports_handball),
        },
        key: const ValueKey('tcpRouter'),
        defaultRoute: 'measure',
        inAnimation: _moveIn,
        outAnimation: _moveOut,
      ),
    );
  }

  // ...........................................................................
  Widget _nearbyPage(BuildContext context) {
    final router = GgRouter.of(context);

    return Scaffold(
      key: const ValueKey('nearbyPage'),
      bottomNavigationBar: StreamBuilder(
          stream: router.onActiveChildChange,
          builder: (context, snapshot) {
            final index = router.indexOfActiveChild ?? 0;

            return BottomNavigationBar(
              currentIndex: index,
              items: const [
                BottomNavigationBarItem(
                  label: 'Bus',
                  icon: Icon(Icons.directions_bus),
                ),
                BottomNavigationBarItem(
                  label: 'Bike',
                  icon: Icon(Icons.directions_bike),
                ),
                BottomNavigationBarItem(
                  label: 'Car',
                  icon: Icon(Icons.directions_car),
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    router.navigateTo('bus');
                    break;
                  case 1:
                    router.navigateTo('bike');
                    break;
                  case 2:
                    router.navigateTo('car');
                    break;
                }
              },
            );
          }),
      body: GgRouter(
        {
          'bus': (c) => _bigIcon(c, Icons.directions_bus),
          'bike': (c) => _bigIcon(c, Icons.directions_bike),
          'car': (c) => _bigIcon(c, Icons.directions_car),
        },
        key: const ValueKey('/nearby'),
        defaultRoute: 'bus',
        inAnimation: _moveIn,
        outAnimation: _moveOut,
      ),
    );
  }

// ...........................................................................
  Widget _btlePage(BuildContext context) {
    final router = GgRouter.of(context);
    // return Container(color: Colors.green);

    return Scaffold(
      bottomNavigationBar: StreamBuilder(
          key: const ValueKey('btlePage'),
          stream: router.onActiveChildChange,
          builder: (context, snapshot) {
            final index = router.indexOfActiveChild ?? 0;

            return BottomNavigationBar(
              currentIndex: index,
              items: const [
                BottomNavigationBarItem(
                  label: 'Airpot',
                  icon: Icon(Icons.airplanemode_active),
                ),
                BottomNavigationBarItem(
                  label: 'Park',
                  icon: Icon(Icons.park),
                ),
                BottomNavigationBarItem(
                  label: 'Hospital',
                  icon: Icon(Icons.local_hospital),
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    router.navigateTo('airport');
                    break;
                  case 1:
                    router.navigateTo('park');
                    break;
                  case 2:
                    router.navigateTo('hospital');
                    break;
                }
              },
            );
          }),
      body: GgRouter(
        {
          'airport': (c) => _bigIcon(c, Icons.airplanemode_active),
          'park': (c) => _bigIcon(c, Icons.park),
          'hospital': (c) => _bigIcon(c, Icons.local_hospital),
        },
        key: const ValueKey('/btle'),
        defaultRoute: 'airport',
        inAnimation: _moveIn,
        outAnimation: _moveOut,
      ),
    );
  }

  // ...........................................................................
  Future<void> _saveState(String state) async {
    (await (SharedPreferences.getInstance()))
        .setString('lastApplicationState', state);
  }

  // ...........................................................................
  Future<String?> _restoreState() async {
    final result = (await (SharedPreferences.getInstance()))
        .getString('lastApplicationState');
    return result;
  }

  // ...........................................................................
  Widget _zoomOut(
    BuildContext context,
    Animation animation,
    Widget child,
    Size size,
  ) {
    // In the first part of the animation the old widget is faded out
    final scale = animation.value < 0.5
        ? Curves.easeInOut.transform(1.0 - (animation.value * 2.0))
        : 0.0;

    return Transform.scale(
      scale: scale,
      child: child,
    );
  }

  // ...........................................................................
  Widget _zoomIn(
    BuildContext context,
    Animation animation,
    Widget child,
    Size size,
  ) {
    // In the second part of the animation the new widget is faded in
    final scale = animation.value >= 0.5
        ? Curves.easeInOut.transform(((animation.value - 0.5) * 2.0))
        : 0.0;

    return Transform.scale(
      scale: scale,
      child: child,
    );
  }

  // ...........................................................................
  Widget _moveIn(
    BuildContext context,
    Animation animation,
    Widget child,
    Size size,
  ) {
    final w = size.width;
    final h = size.height;
    final index = GgRouter.of(context).indexOfChildAnimatingIn;

    final fromLeft = Offset(-w * (1.0 - animation.value), 0);
    final fromBottom = Offset(0, h * (1.0 - animation.value));
    final fromRight = Offset(w * (1.0 - animation.value), 0);

    Offset offset = index == 0
        ? fromLeft
        : index == 1
            ? fromBottom
            : fromRight;

    return Transform.translate(
      offset: offset,
      child: child,
    );
  }

  // ...........................................................................
  Widget _moveOut(
    BuildContext context,
    Animation animation,
    Widget child,
    Size size,
  ) {
    final w = size.width;
    final h = size.height;
    final index = GgRouter.of(context).indexOfChildAnimatingOut;

    final toRight = Offset(w * (animation.value), 0);
    final toBottom = Offset(0, h * (animation.value));
    final toLeft = Offset(w * (-animation.value), 0);

    Offset offset = index == 0
        ? toLeft
        : index == 1
            ? toBottom
            : toRight;

    return Transform.translate(
      offset: offset,
      child: child,
    );
  }
}
