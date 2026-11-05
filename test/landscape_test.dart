// Layout do Lume com o telemóvel de pé e deitado.
//
// Desenha a app com as dimensões de um Galaxy A16 5G e as definições de quem
// a usa, e falha se algum Column transbordar, se um favorito ficar fora do
// ecrã ou se as letras do índice alfabético ficarem sem espaço para se lerem.
//
// Para ver os ecrãs em PNG (em build/screens/):
//   LUME_RENDER=1 flutter test test/landscape_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume_launcher/features/apps/widgets/alphabet_index_bar.dart';
import 'package:lume_launcher/features/apps/widgets/app_tile.dart';
import 'package:lume_launcher/features/apps/widgets/letter_apps_panel.dart';
import 'package:lume_launcher/features/favorites/presentation/favorites_section.dart';
import 'package:lume_launcher/features/launcher/widgets/search_hint.dart';

import 'support/lume_harness.dart';

/// Os seis favoritos de origem, com nomes do mundo real.
const List<String> sixFavorites = <String>[
  'Navegador brave', 'LinkedIn', 'Banco', 'Instagram', 'WhatsApp', 'Spotify',
];

/// O máximo que as definições deixam guardar.
const List<String> tenFavorites = <String>[
  ...sixFavorites, 'YouTube', 'Telegram', 'Netflix', 'Uber',
];

Map<String, Object> favoritesPrefs([List<String> names = sixFavorites]) =>
    <String, Object>{
      'flutter.favorites': <String>[for (final String name in names) packageOf(name)],
    };

/// As definições de quem mais usa o Lume: serifada, relógio empilhado, ao
/// centro. O relógio empilhado é o mais alto dos cinco.
Map<String, Object> heavyPrefs() => <String, Object>{
      ...favoritesPrefs(),
      'flutter.settings.font_family': 'lora',
      'flutter.settings.clock_style': 'stacked',
      'flutter.settings.content_alignment': 'center',
    };

/// Tudo no máximo que as definições permitem: dez favoritos, letra a 135%,
/// espaçamento de 16 e ícones.
Map<String, Object> extremePrefs() => <String, Object>{
      ...heavyPrefs(),
      ...favoritesPrefs(tenFavorites),
      'flutter.settings.favorites_limit': 10,
      'flutter.settings.font_scale': 1.35,
      'flutter.settings.item_spacing': 16.0,
    };

/// Um cenário de Home: nome, preferências, favoritos esperados, se o Lume já é
/// o ecrã inicial (senão aparece o banner).
typedef Scenario = (String, Map<String, Object> Function(), List<String>, bool);

const List<Scenario> scenarios = <Scenario>[
  ('origem', favoritesPrefs, sixFavorites, true),
  ('pesado', heavyPrefs, sixFavorites, false),
  ('extremo', extremePrefs, tenFavorites, false),
];

void expectOnScreen(WidgetTester tester, DeviceShape shape, List<String> names) {
  final Rect screen = Offset.zero & shape.size;
  for (final String name in names) {
    final Finder text = find.text(name);
    expect(text, findsOneWidget, reason: 'falta o favorito $name');
    final Rect rect = tester.getRect(text);
    expect(
      screen.contains(rect.topLeft) && screen.contains(rect.bottomRight - const Offset(1, 1)),
      isTrue,
      reason: '$name está fora do ecrã: $rect',
    );
  }
}

void main() {
  setUpAll(loadRealFonts);

  for (final DeviceShape shape in <DeviceShape>[
    DeviceShape.portrait,
    DeviceShape.landscape,
  ]) {
    group('Home em ${shape.name}', () {
      for (final (String label, Map<String, Object> Function() prefs, List<String> names,
              bool isDefault) in scenarios) {
        testWidgets('não transborda e mostra todos os favoritos — $label',
            (WidgetTester tester) async {
          final LayoutErrors errors = LayoutErrors()..start();
          try {
            await pumpLume(tester, shape, prefs: prefs(), defaultLauncher: isDefault);
            await renderIfAsked(tester, 'home_${shape.name}_$label');
          } finally {
            errors.stop();
          }

          expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
          expectOnScreen(tester, shape, names);
          await unmountLume(tester);
        });
      }

      testWidgets('as letras do índice alfabético cabem', (WidgetTester tester) async {
        await pumpLume(tester, shape, prefs: favoritesPrefs());

        final Finder bar = find.byType(AlphabetIndexBar);
        expect(bar, findsOneWidget);
        final double barHeight = tester.getSize(bar).height;
        final int shown = find
            .descendant(of: bar, matching: find.byType(Text))
            .evaluate()
            .length;

        final TextStyle style =
            Theme.of(tester.element(bar)).textTheme.labelSmall!;
        final double lineHeight = style.fontSize! * (style.height ?? 1.2);
        final double slot = barHeight / shown;

        expect(
          slot,
          greaterThanOrEqualTo(lineHeight),
          reason: '$shown letras em ${barHeight.toStringAsFixed(0)}dp dão '
              '${slot.toStringAsFixed(1)}dp a cada uma, e a letra precisa de '
              '${lineHeight.toStringAsFixed(1)}dp',
        );
        await unmountLume(tester);
      });

      testWidgets('tocar no índice abre o painel da letra e mostra-a na barra',
          (WidgetTester tester) async {
        final LayoutErrors errors = LayoutErrors()..start();
        try {
          await pumpLume(tester, shape, prefs: favoritesPrefs());
          final Finder bar = find.byType(AlphabetIndexBar);
          await tester.tapAt(tester.getCenter(bar));
          await tester.pumpAndSettle();

          final Finder panel = find.byType(LetterAppsPanel);
          expect(panel, findsOneWidget);
          // A primeira linha do painel é a letra escolhida.
          final String letter = tester
              .widget<Text>(find.descendant(of: panel, matching: find.byType(Text)).first)
              .data!;
          expect(
            find.descendant(of: bar, matching: find.text(letter)),
            findsOneWidget,
            reason: 'a letra $letter tem de aparecer na barra, mesmo resumida',
          );
          await renderIfAsked(tester, 'painel_letra_${shape.name}');
        } finally {
          errors.stop();
        }
        expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
        await unmountLume(tester);
      });

      testWidgets('o menu de uma aplicação não transborda', (WidgetTester tester) async {
        final LayoutErrors errors = LayoutErrors()..start();
        try {
          await pumpLume(tester, shape, prefs: favoritesPrefs());
          await tester.longPress(find.text('Banco'), warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(find.text('Escolher ícone'), findsOneWidget);
          await renderIfAsked(tester, 'menu_app_${shape.name}');
        } finally {
          errors.stop();
        }
        expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
        await unmountLume(tester);
      });

      testWidgets('a pesquisa com o teclado aberto mostra o campo e resultados',
          (WidgetTester tester) async {
        final LayoutErrors errors = LayoutErrors()..start();
        try {
          await pumpLume(
            tester,
            shape,
            prefs: <String, Object>{
              ...favoritesPrefs(),
              'flutter.settings.font_scale': 1.35,
            },
          );
          await tester.tap(find.byType(SearchHint));
          await tester.pumpAndSettle();

          // O teclado do Samsung deitado: uns 230dp. O Flutter pede sempre
          // IME_FLAG_NO_FULLSCREEN, por isso não passa a ecrã inteiro.
          tester.view.viewInsets = FakeViewPadding(
            bottom: (shape.isLandscape ? 230 : 330) * DeviceShape.pixelRatio,
          );
          await tester.pumpAndSettle();
          await renderIfAsked(tester, 'pesquisa_vazia_${shape.name}');

          await tester.enterText(find.byType(TextField), 'n');
          await tester.pumpAndSettle();
          await renderIfAsked(tester, 'pesquisa_${shape.name}');

          final double keyboardTop =
              shape.size.height - tester.view.viewInsets.bottom / DeviceShape.pixelRatio;
          final Rect field = tester.getRect(find.byType(TextField));
          expect(field.bottom, lessThanOrEqualTo(keyboardTop),
              reason: 'o campo de pesquisa ficou por baixo do teclado');

          // Contam só os resultados inteiros entre o topo e o campo: o
          // ListView também constrói itens fora do ecrã, e encontrá-los na
          // árvore não quer dizer que se vejam.
          final Rect visibleArea =
              Rect.fromLTRB(0, shape.padding.top, shape.size.width, field.top);
          final int visible = find
              .byType(AppTile)
              .evaluate()
              .map((Element e) => tester.getRect(find.byWidget(e.widget)))
              .where((Rect r) =>
                  visibleArea.contains(r.topLeft) &&
                  visibleArea.contains(r.bottomRight - const Offset(1, 1)))
              .length;
          expect(visible, greaterThanOrEqualTo(3),
              reason: 'só $visible resultados à vista com o teclado aberto');
        } finally {
          errors.stop();
        }
        expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
        await unmountLume(tester);
      });

      testWidgets('o menu rápido da Home não transborda', (WidgetTester tester) async {
        final LayoutErrors errors = LayoutErrors()..start();
        try {
          await pumpLume(tester, shape, prefs: favoritesPrefs());
          // Logo acima do "Pesquisar", encostado à esquerda: de pé fica por
          // baixo dos favoritos, deitado por baixo do relógio. Nada tocável
          // por cima, por isso o toque chega à camada de gestos.
          final Rect hint = tester.getRect(find.byType(SearchHint));
          await tester.longPressAt(Offset(hint.left + 16, hint.top - 24));
          await tester.pumpAndSettle();
          expect(find.text('Definições do Lume'), findsOneWidget);
          await renderIfAsked(tester, 'menu_rapido_${shape.name}');
        } finally {
          errors.stop();
        }
        expect(errors.overflows, isEmpty, reason: errors.overflows.join('\n'));
        await unmountLume(tester);
      });
    });
  }

  group('AlphabetIndexBar.labelsThatFit', () {
    final List<String> letters = <String>[
      for (int c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++) String.fromCharCode(c),
      '#',
    ];

    test('com espaço para todas, devolve a lista tal como está', () {
      expect(AlphabetIndexBar.labelsThatFit(letters, 27), letters);
      expect(AlphabetIndexBar.labelsThatFit(letters, 40), letters);
    });

    test('sem espaço, alterna letra e ponto, da primeira à última', () {
      final List<String?> labels = AlphabetIndexBar.labelsThatFit(letters, 18);
      expect(labels.length, 17);
      expect(labels.first, 'A');
      expect(labels.last, '#');
      for (int i = 0; i < labels.length; i++) {
        expect(labels[i] == null, i.isOdd, reason: 'posição $i');
      }
    });

    test('com quase nada, fica a primeira e a última', () {
      expect(AlphabetIndexBar.labelsThatFit(letters, 2), <String?>['A', '#']);
    });

    test('a letra escolhida aparece mesmo quando estaria escondida', () {
      final List<String?> plain = AlphabetIndexBar.labelsThatFit(letters, 18);
      final String hidden = letters.firstWhere((String l) => !plain.contains(l));

      final List<String?> labels =
          AlphabetIndexBar.labelsThatFit(letters, 18, selected: hidden);
      expect(labels, contains(hidden));
      expect(labels.length, plain.length);
    });
  });

  group('FavoritesLayout.choose', () {
    // Linha de 30 com espaçamento 6: 30 + 2 × (8 + 6) = 58 por favorito;
    // compacta, 30 + 16 = 46.
    FavoritesLayout choose({required double height, double width = 300}) =>
        FavoritesLayout.choose(
          count: 6,
          availableHeight: height,
          availableWidth: width,
          lineHeight: 30,
          preferredSpacing: 6,
          showIcons: false,
        );

    test('com altura de sobra, uma coluna com o espaçamento escolhido', () {
      final FavoritesLayout layout = choose(height: 400);
      expect((layout.columns, layout.spacing, layout.fits), (1, 6.0, true));
    });

    test('um pouco apertado, aperta o espaçamento antes de partir em colunas', () {
      final FavoritesLayout layout = choose(height: 300);
      expect((layout.columns, layout.spacing, layout.fits), (1, 0.0, true));
    });

    test('muito apertado e largo, passa a duas colunas', () {
      final FavoritesLayout layout = choose(height: 200, width: 400);
      expect((layout.columns, layout.spacing, layout.fits), (2, 6.0, true));
    });

    test('apertado e estreito, admite que não cabe', () {
      final FavoritesLayout layout = choose(height: 100);
      expect((layout.columns, layout.fits), (1, false));
    });
  });
}
