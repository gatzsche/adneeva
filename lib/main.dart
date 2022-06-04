// @license
// Copyright (c) 2019 - 2021 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gg_router/gg_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import './src/application.dart';
import 'src/measure/data_recorder.dart';
import 'src/measure/types.dart';
import 'src/utils/is_test.dart';
import 'src/widgets/measurement_widget.dart';

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

class _GgRouterExampleState extends State<GgRouterExample>
    with WidgetsBindingObserver {
  final List<Function()> _dispose = [];
  late StreamController<String> _logController;
  final List<String> _logMessages = [];
  late Application _localApp;
  final rootNode = GgRouteTreeNode.newRoot;

  // ...........................................................................
  @override
  void initState() {
    super.initState();
    _initLog();
    _initApplications();
    _listenToRouteChanges();
    _listenToModeChanges();
    DataRecorder.delayMeasurements = const Duration(
      milliseconds: 100,
    ); // Makes measurement slow to see progress
  }

  // ...........................................................................
  @override
  void dispose() {
    _localApp.dispose();
    super.dispose();
  }

  // ...........................................................................
  void _initLog() {
    _logController = StreamController<String>.broadcast();

    final s = _logController.stream.listen((event) {
      _logMessages.add(event);
      print(event);
    });
    _dispose.add(s.cancel);
    _dispose.add(_logController.close);
  }

  // ...........................................................................
  void _initApplications() async {
    void log(String msg) => _logController.add(msg);

    _localApp = Application(name: 'localApp', log: log);
    if (!isTest) {
      await _localApp.waitForConnections();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // ...........................................................................
  void _listenToRouteChanges() {
    rootNode.onChange.listen(
      (_) {
        final currentPath = rootNode.stagedChild?.name;
        if (currentPath == MeasurementMode.nearby.string) {
          _localApp.mode.value = MeasurementMode.nearby;
        } else if (currentPath == MeasurementMode.tcp.string) {
          _localApp.mode.value = MeasurementMode.tcp;
        } else if (currentPath == MeasurementMode.btle.string) {
          _localApp.mode.value = MeasurementMode.btle;
        }
      },
    );
  }

  // ...........................................................................
  void _listenToModeChanges() {
    _localApp.mode.stream.listen(
      (mode) {
        rootNode.navigateTo(mode.string);
      },
    );
  }

  // ...........................................................................
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Adneeva',
      routerDelegate: GgRouterDelegate(
        child: _appContent,
        saveState: _saveState,
        restoreState: _restoreState,
        defaultRoute: '/tcp/measure',
        root: rootNode,
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
        title: const Text('Adneeva'),
        actions: <Widget>[
          _routeButton('TCP', MeasurementMode.tcp.string),
          _routeButton('Nearby', MeasurementMode.nearby.string),
          // _routeButton('BTLE', MeasurementMode.btle.string),
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
              MeasurementMode.tcp.string: _detailPage,
              MeasurementMode.nearby.string: _detailPage,
              MeasurementMode.btle.string: _detailPage,
              '*': _wildCardPage,
            },
            key: const ValueKey('mainRouter'),
            inAnimation: _zoomIn,
            outAnimation: _zoomOut,
            animationDuration: const Duration(milliseconds: 300),
            semanticLabels: const {
              '_INDEX_': 'Navigate to Index Page',
              'tcp': 'Navigate to TCP Page',
              'nearby': 'Navigate to Nearby Page',
              'btle': 'o BTLE Page',
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
  Widget _detailPage(BuildContext context) {
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
                  label: 'Log',
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
          'measure': (c) => _measurePage,
          'results': (c) => _sharePage,
          'info': (c) => _logPage,
        },
        key: const ValueKey('tcpRouter'),
        defaultRoute: 'measure',
        inAnimation: _moveIn,
        outAnimation: _moveOut,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ...........................................................................
  Widget get _measurePage {
    final result = MeasurementWidget(
      application: _localApp,
      key: const Key('measurePage'),
      log: _logController.stream,
    );

    return result;
  }

  // ...........................................................................
  Future<String> _tmpPath(String fileName) async {
    Directory tempDir = await getTemporaryDirectory();
    final targetPath = join(tempDir.path, fileName);
    return targetPath;
  }

  // ...........................................................................
  Future<void> _writeDataToFile(String data, String targetPath) async {
    File(targetPath).writeAsStringSync(data);
  }

  // ...........................................................................
  Widget _shareButton(List<String> measurementResults) => ElevatedButton(
        key: const Key('shareButton'),
        onPressed: () async {
          const fileName = 'measurement_result.csv';
          final targetPath = await _tmpPath(fileName);
          _writeDataToFile(measurementResults.last, targetPath);
          Share.shareFiles([targetPath], text: 'Measurement results');
        },
        child: const Text('Share'),
      );

  // ...........................................................................
  Widget get _sharePage {
    return Center(
      child: StreamBuilder(
        builder: (context, snapshot) {
          final measurmentResults = _localApp.measurementResults.value;
          return measurmentResults.isEmpty
              ? const Text('No measurements available')
              : _shareButton(measurmentResults);
        },
      ),
    );
  }

  // ...........................................................................
  Widget get _logWidget => StreamBuilder(
        stream: _logController.stream,
        builder: (context, snapshot) {
          scheduleMicrotask(
            () => _logViewScrollController.animateTo(
              _logViewScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
            ),
          );

          return ListView(
            controller: _logViewScrollController,
            children: _logMessages.map((e) => Text(e)).toList(),
          );
        },
      );

  // ...........................................................................
  Widget get _clearButton => Positioned(
        bottom: 0,
        right: 0,
        child: GestureDetector(
          onTapDown: (details) {},
          child: IconButton(
            icon: const Icon(Icons.clear),
            color: Colors.white.withOpacity(0.2),
            onPressed: () => setState(() {
              _logMessages.clear();
            }),
          ),
        ),
      );

  // ...........................................................................
  final _logViewScrollController = ScrollController();

  Widget get _logPage {
    return Builder(
      builder: (context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Container(
              color: Theme.of(context).disabledColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Stack(
                  children: [
                    _logWidget,
                    _clearButton,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ...........................................................................

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
