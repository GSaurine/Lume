import '../constants/launcher_symbols.dart';
import 'text_normalizer.dart';

/// Adivinha que símbolo assenta numa aplicação.
///
/// Existem duas camadas, por esta ordem:
///
/// 1. uma tabela de *packages* conhecidos — as aplicações que quase toda a
///    gente tem, onde vale a pena acertar sempre;
/// 2. palavras-chave no nome e no package, para o resto.
///
/// A segunda camada é a que resolve o caso dos bancos: são milhares e não
/// valia a pena listá-los, mas quase todos têm "bank" ou "banco" no nome ou no
/// package. Quando falha, o utilizador escolhe à mão — e a escolha dele ganha
/// sempre a estas duas.
abstract final class SymbolGuesser {
  static LauncherSymbol? guess({required String name, required String packageName}) {
    final String package = packageName.toLowerCase();
    final LauncherSymbol? known = _knownPackages[package];
    if (known != null) return known;

    final String haystack = '${TextNormalizer.fold(name)} $package';
    for (final (String keyword, LauncherSymbol symbol) in _keywords) {
      if (haystack.contains(keyword)) return symbol;
    }
    return null;
  }

  /// Aplicações que quase toda a gente tem. Mapeadas pelo package, que é
  /// estável; o nome muda com o idioma do telemóvel.
  static const Map<String, LauncherSymbol> _knownPackages = <String, LauncherSymbol>{
    // Social e mensagens
    'com.whatsapp': LauncherSymbol.chat,
    'com.whatsapp.w4b': LauncherSymbol.chat,
    'org.telegram.messenger': LauncherSymbol.send,
    'com.facebook.orca': LauncherSymbol.chat,
    'com.facebook.katana': LauncherSymbol.people,
    'com.instagram.android': LauncherSymbol.camera,
    'com.snapchat.android': LauncherSymbol.camera,
    'com.linkedin.android': LauncherSymbol.work,
    'com.twitter.android': LauncherSymbol.forum,
    'com.reddit.frontpage': LauncherSymbol.forum,
    'com.discord': LauncherSymbol.forum,
    'com.pinterest': LauncherSymbol.art,
    'org.thoughtcrime.securesms': LauncherSymbol.security,
    'com.google.android.apps.messaging': LauncherSymbol.chat,

    // Media
    'com.spotify.music': LauncherSymbol.music,
    'com.google.android.youtube': LauncherSymbol.video,
    'com.google.android.apps.youtube.music': LauncherSymbol.music,
    'com.zhiliaoapp.musically': LauncherSymbol.video,
    'com.netflix.mediaclient': LauncherSymbol.movie,
    'com.amazon.avod.thirdpartyclient': LauncherSymbol.movie,
    'com.soundcloud.android': LauncherSymbol.music,
    'com.shazam.android': LauncherSymbol.mic,
    'tv.twitch.android.app': LauncherSymbol.video,
    'com.google.android.apps.photos': LauncherSymbol.photo,
    'deezer.android.app': LauncherSymbol.music,

    // Navegadores e correio
    'com.android.chrome': LauncherSymbol.browser,
    'org.mozilla.firefox': LauncherSymbol.browser,
    'com.brave.browser': LauncherSymbol.browser,
    'com.opera.browser': LauncherSymbol.browser,
    'com.microsoft.emmx': LauncherSymbol.browser,
    'com.duckduckgo.mobile.android': LauncherSymbol.security,
    'com.google.android.gm': LauncherSymbol.mail,
    'com.microsoft.office.outlook': LauncherSymbol.mail,

    // Trabalho
    'com.microsoft.teams': LauncherSymbol.work,
    'com.Slack': LauncherSymbol.work,
    'us.zoom.videomeetings': LauncherSymbol.video,
    'com.google.android.apps.docs': LauncherSymbol.cloud,
    'com.dropbox.android': LauncherSymbol.cloud,
    'com.github.android': LauncherSymbol.code,
    'com.notion.id': LauncherSymbol.notes,
    'com.google.android.keep': LauncherSymbol.notes,

    // Dinheiro e compras
    'com.paypal.android.p2pmobile': LauncherSymbol.wallet,
    'com.google.android.apps.walletnfcrel': LauncherSymbol.wallet,
    'com.revolut.revolut': LauncherSymbol.card,
    'com.wise.android': LauncherSymbol.card,
    'com.coinbase.android': LauncherSymbol.chart,
    'com.binance.dev': LauncherSymbol.chart,
    'com.amazon.mShop.android.shopping': LauncherSymbol.cart,
    'com.alibaba.aliexpresshd': LauncherSymbol.cart,
    'com.einnovation.temu': LauncherSymbol.cart,
    'com.android.vending': LauncherSymbol.bag,

    // Deslocações
    'com.google.android.apps.maps': LauncherSymbol.map,
    'com.waze': LauncherSymbol.map,
    'com.ubercab': LauncherSymbol.car,
    'com.bolt.client': LauncherSymbol.car,
    'com.booking': LauncherSymbol.hotel,
    'com.airbnb.android': LauncherSymbol.hotel,
    'com.ryanair.cheapflights': LauncherSymbol.flight,

    // Sistema
    'com.android.settings': LauncherSymbol.settings,
    'com.android.dialer': LauncherSymbol.call,
    'com.google.android.dialer': LauncherSymbol.call,
    'com.android.contacts': LauncherSymbol.contacts,
    'com.google.android.contacts': LauncherSymbol.contacts,
    'com.android.camera2': LauncherSymbol.camera,
    'com.google.android.GoogleCamera': LauncherSymbol.camera,
    'com.android.deskclock': LauncherSymbol.clock,
    'com.google.android.deskclock': LauncherSymbol.clock,
    'com.google.android.calendar': LauncherSymbol.calendar,
    'com.google.android.calculator': LauncherSymbol.calculator,
    'com.android.documentsui': LauncherSymbol.files,
    'com.google.android.apps.nbu.files': LauncherSymbol.files,

    // Saúde, aprendizagem, jogos
    'com.strava': LauncherSymbol.fitness,
    'com.fitbit.FitbitMobile': LauncherSymbol.fitness,
    'com.duolingo': LauncherSymbol.translate,
    'com.google.android.apps.translate': LauncherSymbol.translate,
    'com.valvesoftware.android.steam.community': LauncherSymbol.game,
  };

  /// Palavras-chave, da mais específica para a mais genérica: a primeira que
  /// aparecer ganha, e por isso a ordem é significativa. Uma galeria chamada
  /// "Fotos e Vídeos" fica com o ícone de fotografia porque "foto" está
  /// listado antes de "video"; trocá-los mudava o resultado.
  ///
  /// Há entradas em português e em inglês para o mesmo símbolo porque as
  /// aplicações vêm nas duas línguas e as palavras não se parecem: "câmara"
  /// não contém "camera". Os plurais em -ões também precisam de entrada
  /// própria — "cartões" não contém "cartao".
  static const List<(String, LauncherSymbol)> _keywords = <(String, LauncherSymbol)>[
    ('banco', LauncherSymbol.bank),
    ('bank', LauncherSymbol.bank),
    ('caixa', LauncherSymbol.bank),
    ('credito', LauncherSymbol.card),
    ('cartao', LauncherSymbol.card),
    ('cartoes', LauncherSymbol.card),
    ('carteira', LauncherSymbol.wallet),
    ('wallet', LauncherSymbol.wallet),
    ('payment', LauncherSymbol.wallet),
    ('poupanc', LauncherSymbol.savings),
    ('invest', LauncherSymbol.chart),
    ('trading', LauncherSymbol.chart),
    ('crypto', LauncherSymbol.chart),
    ('bolsa', LauncherSymbol.chart),
    ('fatura', LauncherSymbol.receipt),
    ('invoice', LauncherSymbol.receipt),

    ('autenticacao', LauncherSymbol.id),
    ('identidade', LauncherSymbol.id),
    ('password', LauncherSymbol.security),
    ('authenticator', LauncherSymbol.security),
    ('vpn', LauncherSymbol.security),

    ('calendar', LauncherSymbol.calendar),
    ('agenda', LauncherSymbol.calendar),
    ('relogio', LauncherSymbol.clock),
    ('clock', LauncherSymbol.clock),
    ('alarm', LauncherSymbol.clock),
    ('calculad', LauncherSymbol.calculator),
    ('calculat', LauncherSymbol.calculator),
    ('tradu', LauncherSymbol.translate),
    ('translat', LauncherSymbol.translate),
    ('dicionario', LauncherSymbol.book),

    ('podcast', LauncherSymbol.podcast),
    ('radio', LauncherSymbol.radio),
    ('musica', LauncherSymbol.music),
    ('music', LauncherSymbol.music),
    ('camera', LauncherSymbol.camera),
    ('camara', LauncherSymbol.camera),
    ('galeria', LauncherSymbol.photo),
    ('gallery', LauncherSymbol.photo),
    ('foto', LauncherSymbol.photo),
    ('photo', LauncherSymbol.photo),
    ('video', LauncherSymbol.video),
    ('filme', LauncherSymbol.movie),
    ('cinema', LauncherSymbol.movie),

    ('mensag', LauncherSymbol.chat),
    ('messag', LauncherSymbol.chat),
    ('email', LauncherSymbol.mail),
    ('correio', LauncherSymbol.mail),
    ('telefone', LauncherSymbol.call),
    ('contact', LauncherSymbol.contacts),
    ('contacto', LauncherSymbol.contacts),

    ('mapa', LauncherSymbol.map),
    ('maps', LauncherSymbol.map),
    ('comboio', LauncherSymbol.transit),
    ('metro', LauncherSymbol.transit),
    ('transport', LauncherSymbol.transit),
    ('voo', LauncherSymbol.flight),
    ('flight', LauncherSymbol.flight),
    ('hotel', LauncherSymbol.hotel),
    ('restaurante', LauncherSymbol.restaurant),
    ('delivery', LauncherSymbol.restaurant),

    ('noticia', LauncherSymbol.news),
    ('news', LauncherSymbol.news),
    ('jornal', LauncherSymbol.news),
    ('meteo', LauncherSymbol.weather),
    ('weather', LauncherSymbol.weather),
    ('tempo', LauncherSymbol.weather),
    ('saude', LauncherSymbol.health),
    ('health', LauncherSymbol.health),
    ('fitness', LauncherSymbol.fitness),
    ('treino', LauncherSymbol.fitness),
    ('desporto', LauncherSymbol.sports),
    ('sport', LauncherSymbol.sports),

    ('compras', LauncherSymbol.cart),
    ('shop', LauncherSymbol.cart),
    ('store', LauncherSymbol.bag),
    ('loja', LauncherSymbol.bag),

    ('browser', LauncherSymbol.browser),
    ('navegador', LauncherSymbol.browser),
    ('ficheiro', LauncherSymbol.files),
    ('arquivo', LauncherSymbol.files),
    ('files', LauncherSymbol.files),
    ('drive', LauncherSymbol.cloud),
    ('cloud', LauncherSymbol.cloud),
    ('nuvem', LauncherSymbol.cloud),
    ('nota', LauncherSymbol.notes),
    ('note', LauncherSymbol.notes),
    ('tarefa', LauncherSymbol.tasks),
    ('task', LauncherSymbol.tasks),
    ('todo', LauncherSymbol.tasks),
    ('definic', LauncherSymbol.settings),
    ('settings', LauncherSymbol.settings),
    ('config', LauncherSymbol.settings),

    ('jogo', LauncherSymbol.game),
    ('game', LauncherSymbol.game),
    ('leitura', LauncherSymbol.book),
    ('livro', LauncherSymbol.book),
    ('reader', LauncherSymbol.book),
    ('animal', LauncherSymbol.pets),
  ];
}
