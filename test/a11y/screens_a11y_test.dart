// Accessibility audit of a slice of screens (flutter_a11y_test, layer "runtime").
//
// Each test pumps one real screen inside the suite's own provider scope and
// default mocks (test_provider_scope.dart), on both platforms of kPlatformVariant,
// and runs the audit battery. Findings are RECORDED, not asserted: the
// RuntimeFindingsSink in test/flutter_test_config.dart writes them to
// .a11y/flutter/runtime-findings.json and `a11y_check_flutter scan` decides,
// against the committed baseline, what fails CI.
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_a11y_test/flutter_a11y_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderOrFamily;
import 'package:flutter_test/flutter_test.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_angle.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_batch_storage.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_theme.dart';
import 'package:lichess_mobile/src/view/board_editor/board_editor_screen.dart';
import 'package:lichess_mobile/src/view/clock/clock_tool_screen.dart';
import 'package:lichess_mobile/src/view/coordinate_training/coordinate_training_screen.dart';
import 'package:lichess_mobile/src/view/home/home_tab_screen.dart';
import 'package:lichess_mobile/src/view/learn/learn_tab_screen.dart';
import 'package:lichess_mobile/src/view/more/more_tab_screen.dart';
import 'package:lichess_mobile/src/view/puzzle/puzzle_tab_screen.dart';
import 'package:lichess_mobile/src/view/settings/board_settings_screen.dart';
import 'package:lichess_mobile/src/view/settings/settings_screen.dart';
import 'package:lichess_mobile/src/view/settings/sound_settings_screen.dart';
import 'package:lichess_mobile/src/view/settings/theme_settings_screen.dart';
import 'package:lichess_mobile/src/view/watch/watch_tab_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helpers.dart';
import '../test_provider_scope.dart';
import '../view/puzzle/example_data.dart';

class MockPuzzleBatchStorage() extends Mock implements PuzzleBatchStorage;

/// The platform of the current kPlatformVariant run, as a screen id suffix.
String platformTag() =>
    debugDefaultTargetPlatformOverride == TargetPlatform.iOS ? 'ios' : 'android';

Future<void> audit(
  WidgetTester tester,
  String screen,
  Widget home, {
  Map<ProviderOrFamily, Override>? overrides,
}) async {
  final app = await makeTestProviderScopeApp(tester, home: home, overrides: overrides);
  await tester.pumpWidget(app);
  // The suite's own tests pump fixed durations rather than pumpAndSettle: progress
  // indicators and glass effects animate indefinitely.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
  final screenId = '$screen@${platformTag()}';
  final result = await auditScreen(tester, screenId: screenId);
  // ignore: avoid_print
  print('a11y $screenId: ${result.findings.length} finding(s)');
}

void main() {
  setUpAll(() {
    registerFallbackValue(PuzzleBatch(solved: IList(const []), unsolved: IList([puzzle])));
  });

  setUp(() {
    // Screens under ImmersiveMode (clock tool) toggle wakelock_plus, a pigeon channel with
    // no host under `flutter test`: answer it (same as game_screen_test.dart).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (data) async => data,
    );
  });

  group('tabs', () {
    testWidgets('home', (tester) async {
      await audit(tester, 'home', const HomeTabScreen());
    }, variant: kPlatformVariant);

    testWidgets('puzzles', (tester) async {
      final storage = MockPuzzleBatchStorage();
      when(() => storage.fetch(userId: null, angle: const PuzzleTheme(PuzzleThemeKey.mix)))
          .thenAnswer((_) async => batch);
      when(() => storage.fetchAllAngles(userId: null)).thenAnswer((_) async => IList(const []));
      await audit(
        tester,
        'puzzles',
        const PuzzleTabScreen(),
        overrides: {
          puzzleBatchStorageProvider: puzzleBatchStorageProvider.overrideWith((ref) => storage),
        },
      );
    }, variant: kPlatformVariant);

    testWidgets('learn', (tester) async {
      await audit(tester, 'learn', const LearnTabScreen());
    }, variant: kPlatformVariant);

    testWidgets('watch', (tester) async {
      await audit(tester, 'watch', const WatchTabScreen());
    }, variant: kPlatformVariant);

    testWidgets('more', (tester) async {
      await audit(tester, 'more', const MoreTabScreen());
    }, variant: kPlatformVariant);
  });

  group('settings', () {
    testWidgets('settings', (tester) async {
      await audit(tester, 'settings', const SettingsScreen());
    }, variant: kPlatformVariant);

    testWidgets('theme', (tester) async {
      await audit(tester, 'settings/theme', const ThemeSettingsScreen());
    }, variant: kPlatformVariant);

    testWidgets('board', (tester) async {
      await audit(tester, 'settings/board', const BoardSettingsScreen());
    }, variant: kPlatformVariant);

    testWidgets('sound', (tester) async {
      await audit(tester, 'settings/sound', const SoundSettingsScreen());
    }, variant: kPlatformVariant);
  });

  group('tools', () {
    testWidgets('clock', (tester) async {
      await audit(tester, 'tools/clock', const ClockToolScreen());
    }, variant: kPlatformVariant);

    testWidgets('coordinate training', (tester) async {
      await audit(tester, 'tools/coordinate-training', const CoordinateTrainingScreen());
    }, variant: kPlatformVariant);

    testWidgets('board editor', (tester) async {
      await audit(tester, 'tools/board-editor', const BoardEditorScreen());
    }, variant: kPlatformVariant);
  });
}
