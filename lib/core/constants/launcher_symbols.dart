import 'package:flutter/material.dart';

/// Símbolos que o utilizador pode atribuir a uma aplicação.
///
/// São ícones genéricos do Material, não logótipos. Reproduzir a marca de
/// outra aplicação seria copiar identidade visual — o plano é explícito a
/// dizer que não o fazemos — e são os símbolos neutros que dão ao ecrã
/// inicial um aspeto coerente, em vez de uma manta de logótipos coloridos.
///
/// O identificador em [key] é o que fica guardado nas preferências, por isso
/// nunca deve ser mudado depois de uma versão sair; o `IconData` pode mudar à
/// vontade.
enum LauncherSymbol {
  // Comunicação
  chat('chat', Icons.chat_bubble_outline_rounded, 'Conversa', SymbolGroup.comunicar),
  mail('mail', Icons.mail_outline_rounded, 'Correio', SymbolGroup.comunicar),
  call('call', Icons.call_outlined, 'Chamadas', SymbolGroup.comunicar),
  contacts('contacts', Icons.person_outline_rounded, 'Contactos', SymbolGroup.comunicar),
  // Não pode chamar-se `group`: colidiria com o campo `group` deste mesmo
  // enum, e o Dart resolveria o `this.group` do construtor para a constante.
  people('people', Icons.group_outlined, 'Grupo', SymbolGroup.comunicar),
  forum('forum', Icons.forum_outlined, 'Fórum', SymbolGroup.comunicar),
  send('send', Icons.send_outlined, 'Enviar', SymbolGroup.comunicar),
  work('work', Icons.work_outline_rounded, 'Profissional', SymbolGroup.comunicar),

  // Media
  music('music', Icons.music_note_rounded, 'Música', SymbolGroup.media),
  video('video', Icons.play_circle_outline_rounded, 'Vídeo', SymbolGroup.media),
  podcast('podcast', Icons.podcasts_rounded, 'Podcast', SymbolGroup.media),
  radio('radio', Icons.radio_outlined, 'Rádio', SymbolGroup.media),
  photo('photo', Icons.photo_outlined, 'Fotografias', SymbolGroup.media),
  camera('camera', Icons.photo_camera_outlined, 'Câmara', SymbolGroup.media),
  movie('movie', Icons.movie_outlined, 'Filmes', SymbolGroup.media),
  book('book', Icons.menu_book_rounded, 'Leitura', SymbolGroup.media),
  mic('mic', Icons.mic_none_rounded, 'Áudio', SymbolGroup.media),
  headphones('headphones', Icons.headphones_outlined, 'Auscultadores', SymbolGroup.media),

  // Dinheiro
  bank('bank', Icons.account_balance_outlined, 'Banco', SymbolGroup.dinheiro),
  card('card', Icons.credit_card_outlined, 'Cartão', SymbolGroup.dinheiro),
  wallet('wallet', Icons.account_balance_wallet_outlined, 'Carteira', SymbolGroup.dinheiro),
  savings('savings', Icons.savings_outlined, 'Poupança', SymbolGroup.dinheiro),
  chart('chart', Icons.show_chart_rounded, 'Investimentos', SymbolGroup.dinheiro),
  receipt('receipt', Icons.receipt_long_outlined, 'Faturas', SymbolGroup.dinheiro),
  cart('cart', Icons.shopping_cart_outlined, 'Compras', SymbolGroup.dinheiro),
  bag('bag', Icons.shopping_bag_outlined, 'Loja', SymbolGroup.dinheiro),

  // Deslocações e vida
  map('map', Icons.map_outlined, 'Mapas', SymbolGroup.viver),
  car('car', Icons.directions_car_outlined, 'Carro', SymbolGroup.viver),
  transit('transit', Icons.directions_bus_outlined, 'Transportes', SymbolGroup.viver),
  flight('flight', Icons.flight_outlined, 'Viagens', SymbolGroup.viver),
  hotel('hotel', Icons.hotel_outlined, 'Alojamento', SymbolGroup.viver),
  restaurant('restaurant', Icons.restaurant_outlined, 'Restauração', SymbolGroup.viver),
  fitness('fitness', Icons.fitness_center_rounded, 'Exercício', SymbolGroup.viver),
  health('health', Icons.favorite_border_rounded, 'Saúde', SymbolGroup.viver),
  weather('weather', Icons.wb_sunny_outlined, 'Meteorologia', SymbolGroup.viver),
  home('home', Icons.home_outlined, 'Casa', SymbolGroup.viver),

  // Ferramentas
  calendar('calendar', Icons.calendar_today_rounded, 'Calendário', SymbolGroup.ferramentas),
  clock('clock', Icons.schedule_rounded, 'Relógio', SymbolGroup.ferramentas),
  notes('notes', Icons.sticky_note_2_outlined, 'Notas', SymbolGroup.ferramentas),
  tasks('tasks', Icons.check_circle_outline_rounded, 'Tarefas', SymbolGroup.ferramentas),
  calculator('calculator', Icons.calculate_outlined, 'Calculadora', SymbolGroup.ferramentas),
  files('files', Icons.folder_outlined, 'Ficheiros', SymbolGroup.ferramentas),
  cloud('cloud', Icons.cloud_outlined, 'Nuvem', SymbolGroup.ferramentas),
  browser('browser', Icons.public_rounded, 'Navegador', SymbolGroup.ferramentas),
  search('search', Icons.search_rounded, 'Pesquisa', SymbolGroup.ferramentas),
  settings('settings', Icons.settings_outlined, 'Definições', SymbolGroup.ferramentas),
  security('security', Icons.lock_outline_rounded, 'Segurança', SymbolGroup.ferramentas),
  id('id', Icons.badge_outlined, 'Identificação', SymbolGroup.ferramentas),
  translate('translate', Icons.translate_rounded, 'Tradução', SymbolGroup.ferramentas),
  code('code', Icons.code_rounded, 'Programação', SymbolGroup.ferramentas),

  // Lazer
  game('game', Icons.sports_esports_outlined, 'Jogos', SymbolGroup.lazer),
  sports('sports', Icons.sports_soccer_outlined, 'Desporto', SymbolGroup.lazer),
  news('news', Icons.article_outlined, 'Notícias', SymbolGroup.lazer),
  art('art', Icons.palette_outlined, 'Criatividade', SymbolGroup.lazer),
  pets('pets', Icons.pets_rounded, 'Animais', SymbolGroup.lazer),
  star('star', Icons.star_outline_rounded, 'Estrela', SymbolGroup.lazer),
  bolt('bolt', Icons.bolt_rounded, 'Atalho', SymbolGroup.lazer),
  circle('circle', Icons.circle_outlined, 'Círculo', SymbolGroup.lazer);

  const LauncherSymbol(this.key, this.icon, this.label, this.group);

  /// Identificador guardado nas preferências. Nunca mudar.
  final String key;
  final IconData icon;
  final String label;
  final SymbolGroup group;

  static LauncherSymbol? tryParse(String? key) {
    if (key == null) return null;
    for (final LauncherSymbol symbol in LauncherSymbol.values) {
      if (symbol.key == key) return symbol;
    }
    return null;
  }
}

/// Agrupa os símbolos no seletor, para não ser uma grelha de sessenta ícones
/// sem ordem nenhuma.
enum SymbolGroup {
  comunicar('Comunicar'),
  media('Media'),
  dinheiro('Dinheiro'),
  viver('Dia a dia'),
  ferramentas('Ferramentas'),
  lazer('Lazer');

  const SymbolGroup(this.label);

  final String label;

  List<LauncherSymbol> get symbols =>
      LauncherSymbol.values.where((LauncherSymbol s) => s.group == this).toList();
}
