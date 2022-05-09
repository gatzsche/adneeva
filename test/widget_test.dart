// @license
// Copyright (c) 2019 - 2021 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gg_easy_widget_test/gg_easy_widget_test.dart';
import 'package:gg_router/gg_router.dart';
import 'package:mobile_network_evaluator/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('GgRouterExample', () {
    // .........................................................................
    late GgEasyWidgetTest<GgRouterExample, dynamic> ggRouterExample;
    final key = GlobalKey(debugLabel: 'GgRouterExample');

    late GgRouterDelegate routerDelegate;
    late String currentUri;

    GgEasyWidgetTest? indexPage;
    GgEasyWidgetTest? tcpPage;
    GgEasyWidgetTest? nearbyPage;
    GgEasyWidgetTest? btlePage;

    late GgEasyWidgetTest tcpButton;
    late GgEasyWidgetTest nearbyButton;
    late GgEasyWidgetTest btleButton;

    GgEasyWidgetTest? bottomBarButton0;
    GgEasyWidgetTest? bottomBarButton1;
    GgEasyWidgetTest? bottomBarButton2;

    // .........................................................................
    void initSharedPreferences({String? state}) {
      final lastState = state ?? '{}';

      // .......................................
      // Put the lastState to shared preferences
      SharedPreferences.setMockInitialValues(
          {'lastApplicationState': lastState});
    }

    // .........................................................................
    GgEasyWidgetTest? page(String key, WidgetTester tester) {
      final finder = find.byKey(ValueKey(key));
      final elements = finder.evaluate();
      if (elements.isNotEmpty) {
        return GgEasyWidgetTest(finder, tester);
      }
      return null;
    }

    // .........................................................................
    void updatePages(WidgetTester tester) {
      indexPage = page('indexPage', tester);
      tcpPage = page('tcpPage', tester);
      nearbyPage = page('nearbyPage', tester);
      btlePage = page('btlePage', tester);
      currentUri = routerDelegate.currentConfiguration.location!;
    }

    // .........................................................................
    void updateHeaderBar(WidgetTester tester) {
      tcpButton = GgEasyWidgetTest(
        find.byKey(const ValueKey('tcp')),
        tester,
      );
      nearbyButton = GgEasyWidgetTest(
        find.byKey(const ValueKey('nearby')),
        tester,
      );
      btleButton = GgEasyWidgetTest(
        find.byKey(const ValueKey('btle')),
        tester,
      );
    }

    // .........................................................................
    void updateRouterDelegate(WidgetTester tester) {
      routerDelegate = (tester.widget(find.byType(MaterialApp)) as MaterialApp)
          .routerDelegate as GgRouterDelegate;
    }

    // .........................................................................
    void updateBottomBarButtons(WidgetTester tester) {
      final bottomNavigationBar = find.byType(BottomNavigationBar);

      final icons = find.descendant(
        of: bottomNavigationBar,
        matching: find.byType(Icon),
      );

      if (icons.evaluate().length == 3) {
        bottomBarButton0 = GgEasyWidgetTest(icons.at(0), tester);
        bottomBarButton1 = GgEasyWidgetTest(icons.at(1), tester);
        bottomBarButton2 = GgEasyWidgetTest(icons.at(2), tester);
      }
    }

    // .........................................................................
    void update(WidgetTester tester) {
      updatePages(tester);
      updateHeaderBar(tester);
      updateBottomBarButtons(tester);
    }

    // .........................................................................
    Future<void> pressBottomButton(int index, WidgetTester tester) async {
      final button = index == 0
          ? bottomBarButton0
          : index == 1
              ? bottomBarButton1
              : bottomBarButton2;

      final gesture = await tester.startGesture(button!.absoluteFrame.center);
      await gesture.up();
      await tester.pumpAndSettle();
      update(tester);
    }

    // .........................................................................
    Future<void> setUp(WidgetTester tester, {String? lastState}) async {
      initSharedPreferences(state: lastState);
      final widget = GgRouterExample(key: key);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      final ggRouterExampleFinder = find.byWidget(widget);
      ggRouterExample = GgEasyWidgetTest(ggRouterExampleFinder, tester);
      updateRouterDelegate(tester);
      update(tester);
    }

    // .........................................................................
    Future<void> tearDown(WidgetTester tester) async {
      await tester.pumpAndSettle();
    }

    // .........................................................................
    testWidgets('should only show the visible route page',
        (WidgetTester tester) async {
      // ................................
      // Check the inital size of the app
      await setUp(tester);
      expect(ggRouterExample.width, 800);
      expect(ggRouterExample.height, 600);
      routerDelegate.root.navigateTo('_INDEX_');
      await tester.pumpAndSettle();
      update(tester);

      // ........................................
      // Initially the index page should be shown
      expect(indexPage, isNotNull);
      expect(tcpPage, isNull);
      expect(nearbyPage, isNull);
      expect(btlePage, isNull);

      // ..................................
      // Click on tcp menu item
      // => TCP page should only be shown
      await tcpButton.press();
      update(tester);
      expect(tcpPage, isNotNull);
      expect(nearbyPage, isNull);
      expect(btlePage, isNull);
      expect(currentUri, startsWith('tcp/'));

      // ..................................
      // Click on nearbys menu item
      // => Nearbys page should only be shown
      await nearbyButton.press();
      update(tester);
      expect(tcpPage, isNull);
      expect(nearbyPage, isNotNull);
      expect(btlePage, isNull);
      expect(currentUri, startsWith('nearby/'));

      // .........................
      // Click on btle menu item
      // => Nearbys page should only be shown
      await btleButton.press();
      update(tester);
      expect(tcpPage, isNull);
      expect(nearbyPage, isNull);
      expect(btlePage, isNotNull);
      expect(currentUri, startsWith('btle/'));

      await tearDown(tester);
    });

    // .........................................................................
    testWidgets('tcp show a bottom navigation bar with tree items',
        (WidgetTester tester) async {
      await setUp(tester);

      // .......................
      // Jump to the tcp page
      await tcpButton.press();
      update(tester);

      // ..........................
      // Click on the first button
      // => Measure page should open
      await pressBottomButton(0, tester);
      expect(currentUri, startsWith('tcp/basketball'));

      // ..........................
      // Click on the second button
      // => Measure page should open
      await pressBottomButton(1, tester);
      expect(currentUri, startsWith('tcp/football'));

      // ..........................
      // Click on the third button
      // => Handball page should open
      await pressBottomButton(2, tester);
      expect(currentUri, startsWith('tcp/handball'));

      await tearDown(tester);
    });

    // .........................................................................
    testWidgets('nearby should show a bottom navigation bar with tree items',
        (WidgetTester tester) async {
      await setUp(tester);

      // .......................
      // Jump to the tcp page
      await tcpButton.press();
      update(tester);

      // .............................
      // Switch to nearby page
      await nearbyButton.press();

      // ..........................
      // Click on the first button
      // => Measure page should open
      await pressBottomButton(0, tester);
      expect(currentUri, startsWith('nearby/bus'));

      // ..........................
      // Click on the second button
      // => Measure page should open
      await pressBottomButton(1, tester);
      expect(currentUri, startsWith('nearby/bike'));

      // ..........................
      // Click on the third button
      // => Handball page should open
      await pressBottomButton(2, tester);
      expect(currentUri, startsWith('nearby/car'));

      await tearDown(tester);
    });

    // .........................................................................
    testWidgets('btle should show a bottom navigation bar with tree items',
        (WidgetTester tester) async {
      await setUp(tester);

      // .............................
      // Switch to nearby page
      await btleButton.press();
      update(tester);

      // ..........................
      // Click on the first button
      // => Measure page should open
      await pressBottomButton(0, tester);
      expect(currentUri, startsWith('btle/airport'));

      // ..........................
      // Click on the second button
      // => Measure page should open
      await pressBottomButton(1, tester);
      expect(currentUri, startsWith('btle/park'));

      // ..........................
      // Click on the third button
      // => Handball page should open
      await pressBottomButton(2, tester);
      expect(currentUri, startsWith('btle/hospital'));

      await tearDown(tester);
    });

    // .........................................................................
    testWidgets(
        'when switching from transporations page back to tcp page, '
        'the last opened tcp sub-page should be opeend',
        (WidgetTester tester) async {
      await setUp(tester);

      // .......................
      // Jump to the tcp page
      await tcpButton.press();
      update(tester);

      // .............................
      // Open the football tcp page
      await pressBottomButton(1, tester);
      expect(currentUri, startsWith('tcp/football'));

      // .............................
      // Open the nearbys page
      await nearbyButton.press();
      update(tester);
      expect(currentUri, startsWith('nearby'));

      // .............................
      // Switch back to tcp page
      // => last opened page should be visible again
      await tcpButton.press();
      update(tester);
      expect(currentUri, startsWith('tcp/football'));

      await tearDown(tester);
    });

    // .........................................................................
    testWidgets(
        'when clicking on basket ball page, a dialog should open.'
        'The dialog should show a check box. '
        'Checking the checkbox should change the visit param in the URI. '
        'Changing the visit param in the URI should change the checkbox. '
        'Clicking the close button should switch back.',
        (WidgetTester tester) async {
      await setUp(tester);

      // .......................
      // Jump to the tcp page
      await tcpButton.press();
      update(tester);
      expect(currentUri, startsWith('tcp/basketball'));

      // ....................................................
      // Click on the basket ball in the center of the screen
      final gesture =
          await tester.startGesture(ggRouterExample.absoluteFrame.center);
      await gesture.up();
      update(tester);

      // ................................
      // A dialog should have been opened
      expect(currentUri, startsWith('tcp/basketball/popover'));
      await tester.pumpAndSettle();

      // ..........................
      // There should be a checkbox
      // The checkbox should not be checked
      var checkBox = GgEasyWidgetTest(find.byType(CheckboxListTile), tester);
      var checkBoxWidget = checkBox.widget as CheckboxListTile;
      expect(checkBoxWidget.value, false);
      update(tester);
      expect(currentUri, 'tcp/basketball/popover?visit=false');

      // ........................
      // Let's click the checkbox
      // => The checkbox should be checked now
      await checkBox.press();
      update(tester);
      checkBox = GgEasyWidgetTest(find.byType(CheckboxListTile), tester);
      checkBoxWidget = checkBox.widget as CheckboxListTile;
      expect(checkBoxWidget.value, true);
      expect(currentUri, 'tcp/basketball/popover?visit=true');

      // ..............
      // Change the URI
      // => checkbox should change also
      routerDelegate.setNewRoutePath(
        const RouteInformation(location: 'tcp/basketball/popover?visit=false'),
      );
      await tester.pumpAndSettle();
      update(tester);
      checkBox = GgEasyWidgetTest(find.byType(CheckboxListTile), tester);
      checkBoxWidget = checkBox.widget as CheckboxListTile;
      expect(checkBoxWidget.value, false);

      // ..............................
      // Finally let's close the dialog
      // => dialog is removed from the URI
      final dialogCloseButton = GgEasyWidgetTest(
        find.byKey(const ValueKey('GgNavigationPageCloseButton')),
        tester,
      );
      await dialogCloseButton.press();
      await tester.pumpAndSettle();
      update(tester);
      expect(currentUri, 'tcp/basketball?visit=false');

      await tearDown(tester);
    });

    testWidgets(
        'when clicking on basket ball page, a dialog should open. '
        'Clicking on "Details" should open a detail page. '
        'Clicking on "Even more Details" should open another detail page. '
        'Clicking on the "back button" should navigate to the previous page. '
        'Clicking on the "close button" should close the dialog. ',
        (WidgetTester tester) async {
      await setUp(tester);

      // ................
      // Open the popover
      routerDelegate.root.navigateTo('/tcp/basketball/popover');
      await tester.pumpAndSettle();
      expect(routerDelegate.root.stagedChildPath, 'tcp/basketball/popover');

      // ..................
      // Click on "Details"
      final detailsButtonFinder = find.byKey(const ValueKey('Details Button'));
      expect(detailsButtonFinder, findsOneWidget);
      var gesture = await tester.press(detailsButtonFinder);
      await gesture.up();
      await tester.pumpAndSettle();

      // Check if the details page was opened
      expect(routerDelegate.root.stagedChildPath,
          'tcp/basketball/popover/details');

      // .......................
      // Click on "More details"
      final moreDetailsButtonFinder =
          find.byKey(const ValueKey('More Details Button'));
      expect(moreDetailsButtonFinder, findsOneWidget);
      gesture = await tester.press(moreDetailsButtonFinder);
      await gesture.up();
      await tester.pumpAndSettle();

      // Check if the details page was opened
      expect(routerDelegate.root.stagedChildPath,
          'tcp/basketball/popover/details/more-details');

      // ........................
      // Click on the back button
      final dialogBackButton = GgEasyWidgetTest(
        find.byKey(const ValueKey('GgNavigationPageBackButton')),
        tester,
      );
      await dialogBackButton.press();
      await tester.pumpAndSettle();

      // Check if we have navigated back
      expect(routerDelegate.root.stagedChildPath,
          'tcp/basketball/popover/details');

      // ..............................
      // Finally let's close the dialog
      // => dialog is removed from the URI
      final dialogCloseButton = GgEasyWidgetTest(
        find.byKey(const ValueKey('GgNavigationPageCloseButton')),
        tester,
      );
      await dialogCloseButton.press();
      await tester.pumpAndSettle();
      update(tester);
      expect(currentUri, 'tcp/basketball?visit=false');
    });

    // .........................................................................
    testWidgets('opening an unknown URL should show an error in the snack bar',
        (WidgetTester tester) async {
      await setUp(tester);

      routerDelegate
          .setNewRoutePath(const RouteInformation(location: 'tcp/superhero'));
      await tester.pumpAndSettle();
      final snackBar =
          GgEasyWidgetTest(find.byType(SnackBar), tester).widget as SnackBar;
      expect((snackBar.content as Text).data,
          'Route "/tcp" has no child named "superhero" nor does your GgRouter define a "*" wild card route.');

      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tearDown(tester);
    });

    // .........................................................................
    testWidgets('navigating to /xyz should open the wildcard page.',
        (WidgetTester tester) async {
      await setUp(tester);

      routerDelegate.setNewRoutePath(const RouteInformation(location: '/xyz'));
      await tester.pumpAndSettle();

      // Check if /xyz is the path of the staged child
      expect(routerDelegate.root.stagedChildPath, 'xyz');

      // Check if the name of the wild card route could be accessed
      // using the context.
      expect(find.byKey(const ValueKey('WildCardText: xyz')), findsOneWidget);

      await tearDown(tester);
    });

    // .........................................................................
    testWidgets('The last state should be loaded from shared preferences.',
        (WidgetTester tester) async {
      // ................................................................
      // Define an application state which makes transportion/bus visible
      // by default.

      const stagedChildKey = GgRouteTreeNode.stagedChildJsonKey;
      const lastState = '''
      {
        "$stagedChildKey":"nearby",
        "nearby":{
        "$stagedChildKey":"bus"
        }
      }
      ''';

      // .......................................
      // Start the application, and expect that it is on nearby/bus
      await setUp(tester, lastState: lastState);
      await tester.pumpAndSettle();
      update(tester);
      expect(routerDelegate.root.stagedChildPath, 'nearby/bus');
      expect(indexPage, isNull);
      expect(tcpPage, isNull);
      expect(nearbyPage, isNotNull);
      expect(btlePage, isNull);
    });

    // .........................................................................
    testWidgets('State changes should be saved to shared preferences',
        (WidgetTester tester) async {
      initSharedPreferences();

      const stagedChildKey = GgRouteTreeNode.stagedChildJsonKey;
      // .......................................
      // Start the application, and expect that it is on nearby/bus
      await setUp(tester);
      routerDelegate.root.navigateTo('btle/hospital');
      await tester.pumpAndSettle();
      update(tester);
      expect(indexPage, isNull);
      expect(tcpPage, isNull);
      expect(nearbyPage, isNull);
      expect(btlePage, isNotNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('lastApplicationState'),
          contains('"$stagedChildKey":"hospital"'));
    });

    // .........................................................................
    testWidgets('Semantic labels should be assigned correctly',
        (WidgetTester tester) async {
      await setUp(tester);
      expect(find.bySemanticsLabel('Navigate to TCP Page'), findsOneWidget);
      expect(find.bySemanticsLabel('Navigate to Nearby Page'), findsOneWidget);
      expect(find.bySemanticsLabel('Navigate to BTLE Page'), findsOneWidget);
    });
  });
}
