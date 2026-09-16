# Lume

Launcher Android minimalista: relógio, favoritos, índice alfabético, pesquisa e
gestos. Tudo local, sem backend, sem contas e sem permissão de Internet.

Implementação do [plano do projeto](launcher-android-plano-projeto.md).

```text
┌─────────────────────────────┐
│          22:34              │
│     Segunda, 15 Setembro    │
│                             │
│  WhatsApp                   │
│  YouTube                 A  │
│  Spotify                 B  │
│  Chrome                  C  │
│  Telegram                D  │
│                          …  │
│          ↑ Pesquisar        │
└─────────────────────────────┘
```

## Estado

| Fase | Objetivo | Estado |
|---|---|---|
| 1 | Projeto Flutter, lint, Riverpod, tema | feito |
| 2 | Reconhecido como Home Launcher | feito |
| 3 | Descoberta de aplicativos | feito |
| 4 | Abrir aplicativos | feito |
| 5 | Home Screen | feito |
| 6 | Pesquisa + Swipe Up | feito |
| 7 | Favoritos + Long Press | feito |
| 8 | Settings | feito |
| 9 | Temas claro/escuro/sistema | feito |
| 10 | Performance | arranque a frio em 489 ms no dispositivo de teste |
| 11 | Testes | 43 testes; fluxos principais validados num dispositivo |
| 12 | Release | ícone e assinatura feitos; faltam screenshots |

Milestones 1 a 3 do plano (secção 22) estão cobertos.

## Correr

```bash
flutter pub get
flutter run
```

Depois de instalar, carregue no botão Home do Android e escolha o Lume, ou use o
aviso que aparece no topo do próprio launcher.

Verificações:

```bash
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

## Arquitetura

```text
Flutter (UI, estado, pesquisa, favoritos, definições)
    │  MethodChannel  com.lume.launcher/apps
    │  EventChannel   com.lume.launcher/events
    ▼
Kotlin (PackageManager, Intents, papel de Home)
    ▼
Android APIs
```

O Android é a fonte de verdade dos aplicativos instalados; o armazenamento
local guarda só preferências (favoritos, apps ocultas, definições).

### Flutter — `lib/`

```text
core/
  constants/   canais, chaves de preferências, métricas, durações
  theme/       AppTheme + LauncherPalette (ThemeExtension)
  utils/       normalização de texto, transições de rota
  providers/   providers de infraestrutura (prefs, serviços, repositórios)
data/
  models/      InstalledApp, LauncherSettings, eventos de plataforma
  services/    PlatformLauncherService (único ponto com MethodChannel),
               PreferencesService
  repositories/ AppRepository, FavoritesRepository, SettingsRepository
features/
  launcher/    Home, relógio, data, banner de launcher padrão
  apps/        lista completa, item de app, ícones, índice A-Z, menu contextual
  search/      ecrã e ranking de pesquisa
  favorites/   secção na Home e ecrã de gestão/reordenação
  settings/    Aparência, Gestos, Pesquisa, Aplicações, Sobre
  gestures/    mapeamento gesto → ação e ações de sistema
```

Estado com Riverpod 3 (`Notifier` / `AsyncNotifier`, sem geração de código).

### Android — `android/app/src/main/kotlin/com/lume/launcher/`

| Ficheiro | Responsabilidade |
|---|---|
| `MainActivity.kt` | Home Activity; liga os canais; fundo transparente sobre o wallpaper |
| `AppManager.kt` | MethodChannel + EventChannel; abrir apps, info, desinstalar |
| `PackageManagerService.kt` | listar apps, ícones em PNG com LruCache |
| `LauncherRoleManager.kt` | saber e pedir o papel de Home (RoleManager / Settings) |
| `GestureService.kt` | notificações, acessibilidade, definições do sistema |
| `LumeAccessibilityService.kt` | serviço opcional para ações globais |

## Decisões que se afastam do plano

**Ícones fora do `InstalledApp`.** O modelo da secção 9 do plano tem um campo
`icon`. Codificar ~150 ícones em PNG durante o arranque custa vários segundos,
o que contraria a FASE 10. Os ícones são pedidos um a um
(`appIconProvider`), com cache em Kotlin (`LruCache`) e no lado Dart.

**`isFavorite` também fora do modelo.** É uma preferência local, não um facto
do Android; vive no `FavoritesRepository` e é combinada na camada de providers.

**minSdk 24 (Android 7.0)** em vez de um valor mais baixo: é o mínimo suportado
pelo Flutter 3.44 no canal estável.

**Serviço de acessibilidade opcional.** A partir do Android 12 o sistema bloqueia
a reflexão sobre o `StatusBarManager`, por isso abrir as notificações, as
recentes ou bloquear o ecrã precisa de um `AccessibilityService`. Está desligado
por omissão, não lê conteúdo de ecrã (`canRetrieveWindowContent="false"`) e só
executa as três ações globais.

## Gestos

| Gesto | Ação de origem | Configurável |
|---|---|---|
| Deslizar para cima | Pesquisa | sim |
| Deslizar para baixo | Notificações | sim |
| Deslizar para a esquerda | Lista de aplicações | sim |
| Deslizar para a direita | Nada | sim |
| Toque duplo | Nada | sim |
| Manter premido (área livre) | Menu rápido | não |
| Manter premido (um app) | Menu contextual | não |

## Privacidade

Sem servidor, sem contas, sem pedidos de rede — a app não declara
`android.permission.INTERNET`. As preferências ficam no armazenamento local e
desaparecem com a desinstalação.

Permissões declaradas: `EXPAND_STATUS_BAR` e `REQUEST_DELETE_PACKAGES`, ambas
normais. A lista de apps usa a `<queries>` por `MAIN`/`LAUNCHER`, não
`QUERY_ALL_PACKAGES`.

## Ícone

Os ficheiros de origem estão em `assets/icon/`. O `icon_foreground_original.png`
vem do editor com fundo branco e sombra; `tool/prepare_icons.py` separa o
logótipo, remove a sombra e redimensiona-o para a keyline de 66dp do adaptive
icon, para nenhuma máscara de fabricante lhe cortar os cantos.

```bash
python tool/prepare_icons.py
dart run flutter_launcher_icons
```

## Assinatura

O release é assinado com uma keystore própria lida de `android/key.properties`
(fora do Git). Sem esse ficheiro, o build cai na chave de debug e avisa.

Verificar um APK:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Testes em dispositivo

`tool/device_shot.sh` e `tool/device_input.sh` só capturam o ecrã ou enviam
gestos quando o Lume está mesmo em primeiro plano e o ecrã está aceso. O
telemóvel de testes é o telemóvel real de alguém: uma captura às cegas apanha
o que estiver aberto.

```bash
tool/device_shot.sh build/device/home.png
tool/device_input.sh swipe 700 1750 150 1750 250
```

Validado num Samsung Galaxy A16 5G com Android 16: arranque a frio em 489 ms,
102 aplicações detetadas, abrir aplicações, índice alfabético, pesquisa,
favoritos, menu de contexto e os gestos de deslizar.

## Por fazer

- Screenshots para a página de release (FASE 12)
- Listas muito grandes e dispositivos mais antigos ou lentos
- Testes noutros fabricantes e tamanhos de ecrã (FASE 11)
