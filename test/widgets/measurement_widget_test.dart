// @license
// Copyright (c) 2019 - 2022 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gg_easy_widget_test/gg_easy_widget_test.dart';
import 'package:mobile_network_evaluator/src/application.dart';
import 'package:mobile_network_evaluator/src/measure/data_recorder.dart';
import 'package:mobile_network_evaluator/src/widgets/measurement_widget.dart';

void main() {
  group('MeasurementWidget', () {
    // .........................................................................
    final key = GlobalKey(debugLabel: 'MeasurementWidget');
    late Application localApp;
    late Application remoteApp;
    DataRecorder.delayMeasurements = true;

    // ...........................................................................
    Finder startButton() => find.byKey(const Key('startButton'));
    Finder stopButton() => find.byKey(const Key('stopButton'));
    Finder measurementResults() => find.byKey(const Key('measurmentResults'));

    // .........................................................................
    Future<void> setUp(WidgetTester tester) async {
      localApp = exampleApplication(name: 'LocalApp');
      remoteApp = exampleApplication(name: 'RemoteApp');

      final widget = MeasurementWidget(key: key, application: localApp);
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: widget),
      );

      // ...........
      // Get widgets
      GgEasyWidgetTest(find.byWidget(widget), tester);
    }

    // .........................................................................
    Future<void> tearDown(WidgetTester tester) async {
      await tester.pump();
    }

    // .........................................................................
    testWidgets('should work correctly', (WidgetTester tester) async {
      await setUp(tester);

      // .....................................
      // At the beginning we show an indicator
      // showing that the apps are not connected
      expect(find.byKey(const Key('waitingForRemoteWidget')), findsOneWidget);

      // ...........................
      // Now let's connect the apps.
      Application.fakeConnect(localApp, remoteApp);
      await tester.pump();

      // Spinner is gone
      expect(find.byKey(const Key('waitingForRemoteWidget')), findsNothing);

      // Start button is shown instead
      expect(startButton(), findsOneWidget);

      // ............................
      // Let's press the start button
      await tester.tap(startButton());

      // Let's connect the measurement core
      Application.fakeConnectMeasurmentCore(localApp, remoteApp);
      await tester.pump(const Duration(milliseconds: 50));

      // The start button turns into a stop button
      expect(stopButton(), findsOneWidget);

      // After the measurments are done, the stop button goes back
      // to a start button
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(stopButton(), findsNothing);
      expect(startButton(), findsOneWidget);

      // Once measurement results are available they will show up
      expect(measurementResults(), findsOneWidget);

      // ..............
      // Detailed tests

      // ........
      // Cleanup
      await tearDown(tester);
    });
  });
}
