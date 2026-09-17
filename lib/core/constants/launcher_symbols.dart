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
  share('share', Icons.share_outlined, 'Partilhar', SymbolGroup.comunicar),
  atSign('at_sign', Icons.alternate_email_rounded, 'Arroba', SymbolGroup.comunicar),
  heart('heart', Icons.favorite_rounded, 'Coração', SymbolGroup.comunicar),
  handshake('handshake', Icons.handshake_outlined, 'Encontro', SymbolGroup.comunicar),
  support('support', Icons.support_agent_rounded, 'Apoio', SymbolGroup.comunicar),

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
  speaker('speaker', Icons.speaker_outlined, 'Coluna', SymbolGroup.media),
  tv('tv', Icons.tv_outlined, 'Televisão', SymbolGroup.media),
  album('album', Icons.album_outlined, 'Álbum', SymbolGroup.media),
  equalizer('equalizer', Icons.graphic_eq_rounded, 'Equalizador', SymbolGroup.media),
  cast('cast', Icons.cast_rounded, 'Transmitir', SymbolGroup.media),
  slideshow('slideshow', Icons.slideshow_rounded, 'Apresentação', SymbolGroup.media),

  // Dinheiro
  bank('bank', Icons.account_balance_outlined, 'Banco', SymbolGroup.dinheiro),
  card('card', Icons.credit_card_outlined, 'Cartão', SymbolGroup.dinheiro),
  wallet('wallet', Icons.account_balance_wallet_outlined, 'Carteira', SymbolGroup.dinheiro),
  savings('savings', Icons.savings_outlined, 'Poupança', SymbolGroup.dinheiro),
  chart('chart', Icons.show_chart_rounded, 'Investimentos', SymbolGroup.dinheiro),
  receipt('receipt', Icons.receipt_long_outlined, 'Faturas', SymbolGroup.dinheiro),
  cart('cart', Icons.shopping_cart_outlined, 'Compras', SymbolGroup.dinheiro),
  bag('bag', Icons.shopping_bag_outlined, 'Loja', SymbolGroup.dinheiro),
  coins('coins', Icons.paid_outlined, 'Dinheiro', SymbolGroup.dinheiro),
  gift('gift', Icons.card_giftcard_rounded, 'Presente', SymbolGroup.dinheiro),
  tag('tag', Icons.sell_outlined, 'Promoções', SymbolGroup.dinheiro),
  qr('qr', Icons.qr_code_2_rounded, 'Código QR', SymbolGroup.dinheiro),
  parcel('parcel', Icons.local_shipping_outlined, 'Encomendas', SymbolGroup.dinheiro),

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
  bike('bike', Icons.pedal_bike_rounded, 'Bicicleta', SymbolGroup.viver),
  walk('walk', Icons.directions_walk_rounded, 'A pé', SymbolGroup.viver),
  parking('parking', Icons.local_parking_rounded, 'Estacionamento', SymbolGroup.viver),
  fuel('fuel', Icons.local_gas_station_outlined, 'Combustível', SymbolGroup.viver),
  charging('charging', Icons.ev_station_outlined, 'Carregamento', SymbolGroup.viver),
  coffee('coffee', Icons.local_cafe_outlined, 'Café', SymbolGroup.viver),
  grocery('grocery', Icons.local_grocery_store_outlined, 'Supermercado', SymbolGroup.viver),
  pharmacy('pharmacy', Icons.medical_services_outlined, 'Farmácia', SymbolGroup.viver),
  school('school', Icons.school_outlined, 'Escola', SymbolGroup.viver),
  baby('baby', Icons.child_care_rounded, 'Criança', SymbolGroup.viver),
  plant('plant', Icons.local_florist_outlined, 'Plantas', SymbolGroup.viver),

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
  terminal('terminal', Icons.terminal_rounded, 'Terminal', SymbolGroup.ferramentas),
  database('database', Icons.storage_rounded, 'Dados', SymbolGroup.ferramentas),
  wifi('wifi', Icons.wifi_rounded, 'Rede', SymbolGroup.ferramentas),
  bluetooth('bluetooth', Icons.bluetooth_rounded, 'Bluetooth', SymbolGroup.ferramentas),
  battery('battery', Icons.battery_full_rounded, 'Bateria', SymbolGroup.ferramentas),
  backup('backup', Icons.backup_outlined, 'Cópia de segurança', SymbolGroup.ferramentas),
  printer('printer', Icons.print_outlined, 'Impressão', SymbolGroup.ferramentas),
  scanner('scanner', Icons.document_scanner_outlined, 'Digitalizar', SymbolGroup.ferramentas),
  edit('edit', Icons.edit_outlined, 'Editar', SymbolGroup.ferramentas),
  ruler('ruler', Icons.straighten_rounded, 'Medir', SymbolGroup.ferramentas),
  compass('compass', Icons.explore_outlined, 'Bússola', SymbolGroup.ferramentas),
  // Nem `key` nem `label`: chocariam com os campos deste enum, como já
  // aconteceu com `group`.
  passkey('passkey', Icons.vpn_key_outlined, 'Chaves', SymbolGroup.ferramentas),
  shield('shield', Icons.shield_outlined, 'Proteção', SymbolGroup.ferramentas),

  // Lazer
  game('game', Icons.sports_esports_outlined, 'Jogos', SymbolGroup.lazer),
  sports('sports', Icons.sports_soccer_outlined, 'Desporto', SymbolGroup.lazer),
  news('news', Icons.article_outlined, 'Notícias', SymbolGroup.lazer),
  art('art', Icons.palette_outlined, 'Criatividade', SymbolGroup.lazer),
  pets('pets', Icons.pets_rounded, 'Animais', SymbolGroup.lazer),
  star('star', Icons.star_outline_rounded, 'Estrela', SymbolGroup.lazer),
  bolt('bolt', Icons.bolt_rounded, 'Atalho', SymbolGroup.lazer),
  puzzle('puzzle', Icons.extension_outlined, 'Puzzle', SymbolGroup.lazer),
  dice('dice', Icons.casino_outlined, 'Sorte', SymbolGroup.lazer),
  trophy('trophy', Icons.emoji_events_outlined, 'Troféu', SymbolGroup.lazer),
  theater('theater', Icons.theater_comedy_outlined, 'Espetáculos', SymbolGroup.lazer),
  camping('camping', Icons.forest_outlined, 'Natureza', SymbolGroup.lazer),
  beach('beach', Icons.beach_access_outlined, 'Praia', SymbolGroup.lazer),
  moon('moon', Icons.nightlight_round, 'Noite', SymbolGroup.lazer),
  rocket('rocket', Icons.rocket_launch_outlined, 'Foguetão', SymbolGroup.lazer),
  diamond('diamond', Icons.diamond_outlined, 'Diamante', SymbolGroup.lazer),
  flag('flag', Icons.flag_outlined, 'Bandeira', SymbolGroup.lazer),
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

/// Agrupa os símbolos no seletor, para não ser uma grelha de mais de cem
/// ícones sem ordem nenhuma.
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
