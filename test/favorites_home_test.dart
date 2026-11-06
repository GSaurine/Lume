// Mais favoritos na Home (plano, secção 25.1) e "Manter sempre de pé"
// (secção 25.2).
//
// Para ver os ecrãs em PNG (em build/screens/):
//   LUME_RENDER=1 flutter test test/favorites_home_test.dart

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/data/models/installed_app.dart';
import 'package:lume_launcher/data/models/launcher_settings.dart';
import 'package:lume_launcher/features/apps/presentation/app_list_screen.dart';
import 'package:lume_launcher/features/favorites/presentation/favorites_section.dart';
import 'package:lume_launcher/features/launcher/widgets/clock_widget.dart';
import 'package:lume_launcher/features/search/presentation/search_screen.dart';

import 'support/lume_harness.dart';

/// Os primeiros 20 nomes das apps de teste: o novo máximo.
final List<String> twenty =
    sampleApps().take(20).map((InstalledApp a) => a.name).toList(growable: false);

Map<String, Object> manyFavorites(
  FavoritesOverflow overflow, {
  int count = 20,
  Map<String, Object> extra = const <String, Object>{},
}) =>
    <String, Object>{
      'flutter.favorites': <String>[for (final String n in twenty.take(count)) packageOf(n)],
      'flutter.settings.favorites_limit': count,
      'flutter.settings.favorites_overflow': overflow.key,
      ...extra,
    };

final Finder scrollBox = find.byKey(const ValueKey<String>('favorites-scroll'));

/// O retângulo do ecrã que se vê: dentro do ecrã e, se houver caixa, dentro
/// dela — o que a caixa corta não se vê.
bool fullyVisible(WidgetTester tester, Rect rect, DeviceShape shape) {
  Rect area = Offset.zero & shape.size;
  if (scrollBox.evaluate().isNotEmpty) area = area.intersect(tester.getRect(scrollBox));
  return area.contains(rect.topLeft) && area.contains(rect.bottomRight - const Offset(1, 1));
}

int countVisible(WidgetTester tester, DeviceShape shape, Iterable<String> names) => names
    .where((String n) => fullyVisible(tester, tester.getRect(find.text(n)), shape))
    .length;

void main() {
  setUpAll(loadRealFonts);

  group('Encolher', () {
    testWidgets('20 favoritos de pé cabem todos, sem deslizar', (WidgetTester tester) async {
      final LayoutErrors errors = LayoutErrors()..start();
      try {
        await pumpLume(tester, DeviceShape.portrait,
            prefs: manyFavorites(FavoritesOverflow.shrink));
        await renderIfAsked(tester, 'favoritos_20_encolher_retrato');
      } finally {
        errors.stop();
      }
      expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
      expect(scrollBox, findsNothing);
      expect(countVisible(tester, DeviceShape.portrait, twenty), 20);
      await unmountLume(tester);
    });

    testWidgets('10 favoritos de pé ficam numa coluna, mais pequenos',
        (WidgetTester tester) async {
      await pumpLume(tester, DeviceShape.portrait,
          prefs: manyFavorites(FavoritesOverflow.shrink, count: 10));
      await renderIfAsked(tester, 'favoritos_10_encolher_retrato');

      expect(scrollBox, findsNothing);
      expect(countVisible(tester, DeviceShape.portrait, twenty.take(10)), 10);
      // Uma coluna: todos com a mesma margem esquerda.
      final Set<double> lefts = <double>{
        for (final String n in twenty.take(10)) tester.getRect(find.text(n)).left.roundToDouble(),
      };
      expect(lefts, hasLength(1));
      await unmountLume(tester);
    });

    testWidgets('20 favoritos deitado: no limite, desliza em vez de cortar',
        (WidgetTester tester) async {
      final LayoutErrors errors = LayoutErrors()..start();
      try {
        await pumpLume(tester, DeviceShape.landscape,
            prefs: manyFavorites(FavoritesOverflow.shrink));
        await renderIfAsked(tester, 'favoritos_20_encolher_paisagem');
      } finally {
        errors.stop();
      }
      expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
      expect(scrollBox, findsOneWidget);
      // Duas colunas no mínimo legível: quase todos à vista.
      expect(countVisible(tester, DeviceShape.landscape, twenty), greaterThanOrEqualTo(16));
      await unmountLume(tester);
    });
  });

  group('Deslizar numa caixa', () {
    testWidgets('mantém o tamanho e desliza dentro da caixa', (WidgetTester tester) async {
      final LayoutErrors errors = LayoutErrors()..start();
      try {
        await pumpLume(tester, DeviceShape.portrait,
            prefs: manyFavorites(FavoritesOverflow.scroll));
        await renderIfAsked(tester, 'favoritos_20_caixa_retrato');
      } finally {
        errors.stop();
      }
      expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
      expect(scrollBox, findsOneWidget);

      final double before = tester.getRect(find.text(twenty.first)).top;
      await tester.dragFrom(tester.getCenter(scrollBox), const Offset(0, -250));
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text(twenty.first)).top, lessThan(before - 150),
          reason: 'a lista devia ter subido');
      expect(find.byType(SearchScreen), findsNothing,
          reason: 'deslizar dentro da caixa não deve abrir a pesquisa');
      await renderIfAsked(tester, 'favoritos_20_caixa_retrato_deslizada');
      await unmountLume(tester);
    });

    testWidgets('fora da caixa, deslizar para cima continua a abrir a pesquisa',
        (WidgetTester tester) async {
      await pumpLume(tester, DeviceShape.portrait,
          prefs: manyFavorites(FavoritesOverflow.scroll));

      await tester.flingFrom(
        tester.getCenter(find.byType(ClockWidget)),
        const Offset(0, -300),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      await unmountLume(tester);
    });

    testWidgets('dentro da caixa, deslizar para o lado continua a ser gesto da Home',
        (WidgetTester tester) async {
      await pumpLume(tester, DeviceShape.portrait,
          prefs: manyFavorites(FavoritesOverflow.scroll));

      await tester.flingFrom(tester.getCenter(scrollBox), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.byType(AppListScreen), findsOneWidget);
      await unmountLume(tester);
    });

    testWidgets('tocar num favorito dentro da caixa abre-o', (WidgetTester tester) async {
      final LumeSession session = await pumpLume(tester, DeviceShape.portrait,
          prefs: manyFavorites(FavoritesOverflow.scroll));

      await tester.tap(find.text('Banco'), warnIfMissed: false);
      // Sem toque duplo configurado não há espera nenhuma.
      await tester.pump(const Duration(milliseconds: 20));
      expect(session.platform.launched, <String>[packageOf('Banco')]);
      await unmountLume(tester);
    });

    testWidgets('com toque duplo configurado, o toque simples espera e abre na mesma',
        (WidgetTester tester) async {
      final LumeSession session = await pumpLume(
        tester,
        DeviceShape.portrait,
        prefs: manyFavorites(
          FavoritesOverflow.scroll,
          extra: <String, Object>{'flutter.settings.gesture.double_tap': 'open_settings'},
        ),
      );

      await tester.tap(find.text('Banco'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 20));
      expect(session.platform.launched, isEmpty,
          reason: 'ainda à espera de ver se vem um segundo toque');
      await tester.pump(kDoubleTapTimeout);
      expect(session.platform.launched, <String>[packageOf('Banco')]);
      await unmountLume(tester);
    });

    testWidgets('carregar em Home volta a caixa ao início', (WidgetTester tester) async {
      final LumeSession session = await pumpLume(tester, DeviceShape.portrait,
          prefs: manyFavorites(FavoritesOverflow.scroll));
      final double top = tester.getRect(find.text(twenty.first)).top;

      await tester.dragFrom(tester.getCenter(scrollBox), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text(twenty.first)).top, lessThan(top));

      session.platform.androidEvents
          .add(const LauncherPlatformEvent(type: LauncherEventType.homePressed));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text(twenty.first)).top, top);
      await unmountLume(tester);
    });

    testWidgets('com poucos favoritos não há caixa e os gestos passam por cima deles',
        (WidgetTester tester) async {
      await pumpLume(tester, DeviceShape.portrait,
          prefs: manyFavorites(FavoritesOverflow.scroll, count: 6));
      expect(scrollBox, findsNothing);

      await tester.flingFrom(
        tester.getCenter(find.text(twenty[2])),
        const Offset(0, -300),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      await unmountLume(tester);
    });

    testWidgets('deitado também não transborda', (WidgetTester tester) async {
      final LayoutErrors errors = LayoutErrors()..start();
      try {
        await pumpLume(tester, DeviceShape.landscape,
            prefs: manyFavorites(FavoritesOverflow.scroll));
        await renderIfAsked(tester, 'favoritos_20_caixa_paisagem');
      } finally {
        errors.stop();
      }
      expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
      expect(scrollBox, findsOneWidget);
      await unmountLume(tester);
    });
  });

  group('Manter sempre de pé', () {
    testWidgets('de origem segue a rotação do sistema', (WidgetTester tester) async {
      final LumeSession session = await pumpLume(tester, DeviceShape.portrait);
      expect(session.preferredOrientations, isEmpty);
      await unmountLume(tester);
    });

    testWidgets('ligado, pede ao Android para ficar de pé', (WidgetTester tester) async {
      final LumeSession session = await pumpLume(
        tester,
        DeviceShape.portrait,
        prefs: <String, Object>{'flutter.settings.lock_portrait': true},
      );
      expect(session.preferredOrientations, <String>['DeviceOrientation.portraitUp']);
      await unmountLume(tester);
    });
  });

  group('FavoritesLayout.choose', () {
    // Letra de 24 com altura 1,25: linha de 30. Sem ícones, um favorito ocupa
    // 30 + 2 × (8 + espaçamento): 58 com o espaçamento 6, 46 compacto.
    FavoritesLayout choose({
      required double height,
      double width = 300,
      int count = 6,
      FavoritesOverflow overflow = FavoritesOverflow.shrink,
    }) =>
        FavoritesLayout.choose(
          count: count,
          availableHeight: height,
          availableWidth: width,
          fontSizeAt: (double scale) => 24 * scale,
          lineHeightFactor: 1.25,
          preferredSpacing: 6,
          showIcons: false,
          overflow: overflow,
        );

    (int, double, double, bool) describe(FavoritesLayout l) =>
        (l.columns, l.spacing, l.scale, l.scrolls);

    test('com altura de sobra, fica como a pessoa escolheu', () {
      expect(describe(choose(height: 400)), (1, 6.0, 1.0, false));
    });

    test('primeiro aperta o espaçamento', () {
      // 6 × 58 = 348 não cabe em 300; 6 × 46 = 276 cabe.
      expect(describe(choose(height: 300)), (1, 0.0, 1.0, false));
    });

    test('depois encolhe a letra, antes de partir em colunas', () {
      // A 90%: linha de 27, 6 × 43 = 258.
      expect(describe(choose(height: 260, width: 400)), (1, 0.0, 0.9, false));
    });

    test('só passa a duas colunas quando nem o mínimo cabe numa', () {
      // No mínimo (16/24): linha de 20, 6 × 36 = 216 > 200. Duas colunas
      // com o tamanho escolhido: 3 × 58 = 174.
      expect(describe(choose(height: 200, width: 400)), (2, 6.0, 1.0, false));
    });

    test('em duas colunas encolhe até os nomes caberem', () {
      // Colunas de 200, menos 2 × 24 de margem: 152 para o nome. Um nome de
      // 180 só cabe a 80% (144).
      FavoritesLayout withNames(List<double> widths) => FavoritesLayout.choose(
            count: widths.length,
            availableHeight: 200,
            availableWidth: 400,
            fontSizeAt: (double scale) => 24 * scale,
            lineHeightFactor: 1.25,
            preferredSpacing: 6,
            showIcons: false,
            nameWidths: widths,
          );

      expect(describe(withNames(List<double>.filled(6, 180))), (2, 6.0, 0.8, false));
      // Nomes que não cabem a nenhum tamanho: encolher não adianta, fica o
      // maior que cabe na altura.
      expect(describe(withNames(List<double>.filled(6, 400))), (2, 6.0, 1.0, false));
    });

    test('um nome muito comprido não arrasta os outros para o mínimo', () {
      // Como no telemóvel: cinco nomes que cabem e um ("Autenticação Gov")
      // que não cabe nem no mínimo. Fica o tamanho escolhido.
      final FavoritesLayout layout = FavoritesLayout.choose(
        count: 6,
        availableHeight: 200,
        availableWidth: 400,
        fontSizeAt: (double scale) => 24 * scale,
        lineHeightFactor: 1.25,
        preferredSpacing: 6,
        showIcons: false,
        nameWidths: <double>[140, 140, 140, 140, 140, 400],
      );
      expect(describe(layout), (2, 6.0, 1.0, false));
    });

    test('estreito demais para duas colunas e baixo demais: desliza no mínimo', () {
      final FavoritesLayout layout = choose(height: 100);
      expect((layout.columns, layout.scrolls), (1, true));
      expect(layout.scale, closeTo(16 / 24, 1e-9));
    });

    test('Deslizar numa caixa nunca mexe no tamanho', () {
      expect(describe(choose(height: 300, overflow: FavoritesOverflow.scroll)),
          (1, 6.0, 1.0, true));
      expect(describe(choose(height: 400, overflow: FavoritesOverflow.scroll)),
          (1, 6.0, 1.0, false));
    });

    test('o mínimo legível respeita a letra e o ícone', () {
      double floor(double fontSize, {required bool icons}) => FavoritesLayout.minimumScale(
            fontSizeAt: (double scale) => fontSize * scale,
            showIcons: icons,
          );
      // 16/24 = 0,67 para a letra, mas o ícone não desce de 24/34 = 0,71.
      expect(floor(24, icons: true), closeTo(24 / 34, 1e-9));
      expect(floor(24, icons: false), closeTo(16 / 24, 1e-9));
      // Com a letra já pequena não há para onde encolher.
      expect(floor(15, icons: false), 1);
    });
  });
}
