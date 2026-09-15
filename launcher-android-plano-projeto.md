# Plano de Projeto — Launcher Android Minimalista

## 1. Visão do projeto

Criar um **launcher Android minimalista**, inspirado no conceito de launchers como o Niagara Launcher, mas com foco em:

- uso gratuito;
- experiência simples e rápida;
- interface minimalista;
- acesso eficiente aos aplicativos;
- privacidade e processamento local;
- possibilidade de evolução para um projeto open source.

> **Nota:** a inspiração deve estar no conceito e na experiência, sem copiar identidade visual, código, assets ou elementos proprietários de outros launchers.

---

# 2. Conceito da aplicação

A proposta é substituir a tela inicial tradicional do Android por uma interface mais limpa.

Em vez de:

> várias páginas + muitos ícones + pastas + widgets

o launcher terá:

> relógio + favoritos + lista de aplicativos + pesquisa + gestos.

Exemplo conceitual:

```text
┌─────────────────────────────┐
│                             │
│          22:34              │
│     Segunda, 15 Setembro    │
│                             │
│  WhatsApp                   │
│  YouTube                    │
│  Spotify                    │
│  Chrome                     │
│  Telegram                   │
│                             │
│                    A        │
│                    B        │
│                    C        │
│                    D        │
│                    E        │
│                    F        │
│                    ...      │
│                             │
│          ↑ Pesquisar        │
└─────────────────────────────┘
```

---

# 3. Funcionamento geral

O aplicativo funcionará como uma aplicação **Home/Launcher do Android**.

Fluxo:

```text
Android OS
    │
    │ Aplicativos instalados
    ▼
Seu Launcher
    │
    ├── Home Screen
    ├── App Manager
    ├── Search
    ├── Favorites
    ├── Gestures
    └── Settings
             │
             ▼
      Interface minimalista
```

Quando o utilizador selecionar o aplicativo como launcher padrão, o Android passará a abrir o seu launcher ao pressionar o botão Home.

---

# 4. Objetivos do MVP

O primeiro objetivo não é reproduzir todas as funcionalidades de launchers existentes.

O MVP deve provar que a ideia funciona.

## Funcionalidades do MVP

- [ ] Ser reconhecido pelo Android como Home Launcher
- [ ] Detectar aplicativos instalados
- [ ] Mostrar aplicativos
- [ ] Abrir aplicativos
- [ ] Lista alfabética
- [ ] Pesquisa
- [ ] Favoritos
- [ ] Swipe Up para pesquisa
- [ ] Dark Mode
- [ ] Light Mode
- [ ] Configurações básicas

## Fora do MVP

Inicialmente evitar:

- widgets avançados;
- animações complexas;
- sincronização na nuvem;
- contas de utilizador;
- backend;
- sistema social;
- personalização excessiva;
- funcionalidades que não sejam essenciais para validar o conceito.

---

# 5. Arquitetura geral

A aplicação será dividida em duas partes principais:

```text
Flutter
    │
    │ Interface e lógica da aplicação
    │
    ▼
MethodChannel / Plugin
    │
    ▼
Kotlin / Android
    │
    ▼
Android APIs
```

## Flutter será responsável por

- interface;
- navegação;
- estado;
- pesquisa;
- favoritos;
- configurações;
- temas;
- apresentação dos aplicativos;
- interação com o utilizador.

## Kotlin será responsável por

- integração com Android;
- descoberta de aplicativos instalados;
- obtenção de informações dos aplicativos;
- abertura de aplicativos;
- integração com funcionalidades específicas do sistema;
- funcionalidades que não estejam disponíveis diretamente no Flutter.

---

# 6. Estrutura de pastas

Estrutura inicial sugerida:

```text
lib/
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── extensions/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│
├── features/
│   │
│   ├── launcher/
│   │   ├── presentation/
│   │   ├── widgets/
│   │   └── controller/
│   │
│   ├── apps/
│   │   ├── presentation/
│   │   ├── controller/
│   │   └── widgets/
│   │
│   ├── search/
│   │   ├── presentation/
│   │   └── controller/
│   │
│   ├── favorites/
│   │   ├── presentation/
│   │   └── controller/
│   │
│   ├── settings/
│   │   ├── presentation/
│   │   └── controller/
│   │
│   └── gestures/
│       ├── controller/
│       └── services/
│
└── main.dart
```

---

# 7. Camada Android/Kotlin

Estrutura sugerida:

```text
android/
└── app/
    └── src/
        └── main/
            └── kotlin/
                └── com/seu/launcher/
                    │
                    ├── LauncherActivity.kt
                    ├── AppManager.kt
                    ├── PackageManagerService.kt
                    ├── LauncherRoleManager.kt
                    └── GestureService.kt
```

Os nomes podem ser ajustados conforme a arquitetura final.

---

# 8. Android como fonte dos aplicativos

O Android deve ser considerado a fonte principal de verdade para os aplicativos instalados.

Fluxo:

```text
Android PackageManager
        │
        ▼
Aplicativos instalados
        │
        ▼
Kotlin
        │
        ▼
MethodChannel
        │
        ▼
Flutter
        │
        ▼
AppRepository
        │
        ▼
Interface
```

Exemplo de dados:

```text
WhatsApp
package: com.whatsapp

Spotify
package: com.spotify.music

Chrome
package: com.android.chrome
```

---

# 9. Modelo de dados

Modelo inicial:

```dart
class InstalledApp {
  final String name;
  final String packageName;
  final Uint8List? icon;
  final bool isFavorite;

  InstalledApp({
    required this.name,
    required this.packageName,
    this.icon,
    this.isFavorite = false,
  });
}
```

Modelo futuro:

```text
InstalledApp
│
├── id
├── name
├── packageName
├── icon
├── isFavorite
├── isHidden
├── category
├── usageCount
└── lastOpened
```

Não é necessário implementar todos esses campos no início.

---

# 10. Persistência de dados

Os aplicativos instalados não precisam ser armazenados integralmente no banco.

O Android é a fonte dos aplicativos.

O armazenamento local será usado principalmente para preferências:

```text
Local Storage
│
├── favorites
├── hidden_apps
├── app_order
├── settings
├── theme
├── gestures
└── appearance
```

Exemplo:

```text
favorites

com.whatsapp
com.spotify.music
com.google.android.youtube
```

Fluxo:

```text
Android PackageManager
        │
        ▼
Apps instalados
        │
        ▼
Repository
        │
        ▼
Preferências locais
        │
        ▼
Aplicar favoritos/configurações
        │
        ▼
UI
```

---

# 11. Sistema de pesquisa

A pesquisa será uma das funcionalidades principais.

Fluxo:

```text
Swipe Up
    │
    ▼
Search Screen
    │
    ▼
Utilizador escreve
    │
    ▼
Filtrar aplicações
    │
    ▼
Resultados
    │
    ▼
Abrir aplicação
```

Pesquisa inicial:

```dart
apps.where(
  (app) => app.name
      .toLowerCase()
      .contains(query.toLowerCase()),
);
```

No futuro:

```text
Search
│
├── Nome
├── Package name
├── Favoritos
├── Apps recentes
└── Ranking de uso
```

---

# 12. Favoritos

O utilizador poderá marcar aplicativos como favoritos.

Exemplo:

```text
Favorites
────────────────

WhatsApp
Spotify
Chrome
YouTube
Telegram
```

Fluxo:

```text
Long Press
    │
    ▼
Menu contextual
    │
    ├── Add to Favorites
    └── Remove from Favorites
```

Os favoritos devem ser armazenados localmente usando o package name do aplicativo.

---

# 13. Gestos

Gestos sugeridos:

| Gesto | Ação |
|---|---|
| Swipe Up | Pesquisa |
| Swipe Down | Notificações / ação configurável |
| Swipe Left | Lista de aplicativos |
| Swipe Right | Favoritos |
| Long Press | Menu contextual |
| Double Tap | Ação configurável |

## Implementação por etapas

Primeiro:

```text
Swipe Up
    ↓
Search
```

Depois:

```text
Long Press
    ↓
Menu / Customize
```

Só posteriormente adicionar os restantes gestos.

---

# 14. Interface inicial

A Home Screen deve conter inicialmente:

```text
Home
│
├── Clock
├── Date
├── Favorites
├── App List
└── Gesture Area
```

A interface deve priorizar:

- legibilidade;
- velocidade;
- poucos elementos;
- pouca distração;
- animações discretas;
- acessibilidade;
- boa utilização com uma mão.

---

# 15. Personalização

Após o MVP, adicionar:

```text
Appearance

○ Light
○ Dark
○ System

Font size
─────────────○────

App spacing
──────○──────────

Show clock       ON
Show date        ON
Show icons       OFF
Animations       ON
```

Possíveis funcionalidades futuras:

- wallpaper;
- cor de destaque;
- fonte;
- espaçamento;
- transparência;
- blur;
- tamanho da lista;
- posição dos favoritos;
- estilo dos indicadores.

---

# 16. Configurações

Estrutura sugerida:

```text
Settings
│
├── Appearance
├── Favorites
├── Gestures
├── Search
├── Apps
└── About
```

Exemplo:

```text
Appearance
├── Theme
├── Font Size
├── App Spacing
├── Show Icons
└── Animations

Gestures
├── Swipe Up
├── Swipe Down
├── Swipe Left
├── Swipe Right
└── Double Tap
```

---

# 17. Privacidade e funcionamento local

Uma característica importante do projeto pode ser manter o máximo possível de dados localmente.

Arquitetura inicial:

```text
Android
   │
   ├── Apps
   ├── Favorites
   ├── Preferences
   └── Settings
          │
          ▼
       Local
```

Não existe necessidade inicial de:

- backend;
- autenticação;
- contas;
- banco de dados remoto;
- sincronização cloud.

Isso reduz a complexidade e facilita manter o launcher gratuito.

---

# 18. Tecnologias

## Frontend

- Flutter
- Dart
- Material 3 como base, com UI própria

## Android

- Kotlin
- Android SDK
- PackageManager
- Intent
- APIs relacionadas ao papel de Home/Launcher
- MethodChannel ou plugin Flutter próprio

## Gerenciamento de estado

Sugestão:

- Riverpod

## Persistência

Possibilidades:

- SharedPreferences para configurações simples;
- Hive ou Isar para dados locais mais estruturados.

A escolha definitiva pode ser feita durante a implementação.

## Design

- Figma

## Versionamento

- Git
- GitHub

---

# 19. Roadmap de desenvolvimento

## FASE 0 — Planejamento

Antes do código:

- [ ] Definir nome
- [ ] Definir identidade visual
- [ ] Definir objetivo
- [ ] Definir público
- [ ] Definir funcionalidades
- [ ] Definir MVP
- [ ] Definir arquitetura
- [ ] Definir tecnologias

---

# FASE 1 — Projeto Flutter

Objetivo:

Criar a base do projeto.

Tasks:

- [ ] Criar projeto Flutter
- [ ] Configurar Git
- [ ] Criar repositório GitHub
- [ ] Configurar estrutura de pastas
- [ ] Configurar lint
- [ ] Configurar Riverpod
- [ ] Configurar tema
- [ ] Criar ambiente de desenvolvimento

---

# FASE 2 — Android Launcher

Objetivo:

Fazer o Android reconhecer o aplicativo como Home Launcher.

Tasks:

- [ ] Configurar AndroidManifest
- [ ] Configurar Intent Filter de Home
- [ ] Testar reconhecimento como launcher
- [ ] Criar fluxo de seleção como launcher padrão
- [ ] Testar botão Home
- [ ] Testar inicialização após reboot

Resultado esperado:

```text
Pressionar Home
       ↓
Seu Launcher
```

---

# FASE 3 — Descoberta de aplicativos

Objetivo:

Detectar aplicativos instalados.

Tasks:

- [ ] Criar PackageManagerService
- [ ] Obter aplicativos instalados
- [ ] Obter nome
- [ ] Obter package name
- [ ] Obter ícone
- [ ] Criar InstalledApp
- [ ] Criar AppRepository
- [ ] Criar MethodChannel
- [ ] Enviar dados Kotlin → Flutter
- [ ] Mostrar aplicativos na interface

---

# FASE 4 — Abrir aplicativos

Objetivo:

Permitir que o utilizador abra aplicativos.

Fluxo:

```text
Tap
 │
 ▼
Flutter
 │
 ▼
MethodChannel
 │
 ▼
Kotlin
 │
 ▼
Android Intent
 │
 ▼
Aplicativo
```

Tasks:

- [ ] Criar método launchApp
- [ ] Receber package name
- [ ] Criar Intent
- [ ] Abrir aplicação
- [ ] Tratar erros
- [ ] Testar diferentes tipos de aplicações

---

# FASE 5 — Home Screen

Objetivo:

Criar a primeira interface utilizável.

Tasks:

- [ ] Criar HomeScreen
- [ ] Criar ClockWidget
- [ ] Criar DateWidget
- [ ] Criar FavoritesSection
- [ ] Criar AppList
- [ ] Criar AppItem
- [ ] Criar indicador alfabético
- [ ] Definir espaçamento
- [ ] Criar animações mínimas

---

# FASE 6 — Pesquisa

Tasks:

- [ ] Criar SearchController
- [ ] Criar SearchScreen
- [ ] Criar SearchInput
- [ ] Filtrar aplicativos
- [ ] Mostrar resultados
- [ ] Abrir aplicação a partir dos resultados
- [ ] Implementar Swipe Up
- [ ] Adicionar animação de entrada/saída

---

# FASE 7 — Favoritos

Tasks:

- [ ] Criar FavoritesRepository
- [ ] Criar armazenamento local
- [ ] Adicionar favorito
- [ ] Remover favorito
- [ ] Mostrar favoritos na Home
- [ ] Reordenar favoritos
- [ ] Implementar Long Press

---

# FASE 8 — Settings

Tasks:

- [ ] Criar SettingsScreen
- [ ] Criar Appearance
- [ ] Criar Gestures
- [ ] Criar Search Settings
- [ ] Criar App Settings
- [ ] Criar About

---

# FASE 9 — Temas

Tasks:

- [ ] Light Mode
- [ ] Dark Mode
- [ ] System Mode
- [ ] Configuração de tamanho da fonte
- [ ] Configuração de espaçamento
- [ ] Mostrar/ocultar ícones
- [ ] Configuração de animações

---

# FASE 10 — Performance

O launcher deve ser rápido porque é uma aplicação que o utilizador acessa constantemente.

Tasks:

- [ ] Evitar rebuilds desnecessários
- [ ] Otimizar carregamento de ícones
- [ ] Cache de dados quando apropriado
- [ ] Testar listas grandes
- [ ] Testar dispositivos mais antigos
- [ ] Medir tempo de inicialização
- [ ] Reduzir consumo de memória

---

# FASE 11 — Testes

## Testes funcionais

- [ ] Launcher inicia
- [ ] Home funciona
- [ ] Aplicativos aparecem
- [ ] Aplicativos abrem
- [ ] Pesquisa funciona
- [ ] Favoritos funcionam
- [ ] Gestos funcionam
- [ ] Settings funcionam
- [ ] Tema funciona

## Testes Android

- [ ] Android versão mínima definida
- [ ] Android versão atual
- [ ] Diferentes fabricantes
- [ ] Diferentes tamanhos de tela
- [ ] Orientação da tela
- [ ] Reboot
- [ ] Aplicativos instalados/desinstalados

---

# FASE 12 — Release

Antes da primeira versão pública:

- [ ] Definir versão
- [ ] Criar ícone
- [ ] Criar nome oficial
- [ ] Criar screenshots
- [ ] Criar descrição
- [ ] Criar política de privacidade, se necessária
- [ ] Gerar APK/AAB
- [ ] Testar build release
- [ ] Criar GitHub Release
- [ ] Definir estratégia de distribuição

---

# 20. Backlog inicial do GitHub

Sugestão de Issues:

```text
#1 Setup Flutter project
#2 Configure Git repository
#3 Configure Android launcher intent
#4 Test Home Launcher behavior
#5 Create PackageManagerService
#6 Detect installed applications
#7 Create InstalledApp model
#8 Create AppRepository
#9 Create MethodChannel
#10 Display installed applications
#11 Implement application launching
#12 Create HomeScreen
#13 Create ClockWidget
#14 Create DateWidget
#15 Create AppList
#16 Create FavoritesSection
#17 Implement Search
#18 Implement Swipe Up
#19 Implement Favorites
#20 Implement Long Press
#21 Create Settings
#22 Implement Dark Mode
#23 Implement Light Mode
#24 Implement System Theme
#25 Optimize icon loading
#26 Optimize application startup
#27 Add automated tests
#28 Test multiple Android devices
#29 Prepare release build
#30 Create first release
```

---

# 21. Ordem recomendada de implementação

Não desenvolver as funcionalidades aleatoriamente.

Seguir:

```text
1. Projeto
   ↓
2. Android Launcher
   ↓
3. Detectar aplicativos
   ↓
4. Mostrar aplicativos
   ↓
5. Abrir aplicativos
   ↓
6. Home Screen
   ↓
7. Pesquisa
   ↓
8. Favoritos
   ↓
9. Gestos
   ↓
10. Settings
   ↓
11. Personalização
   ↓
12. Performance
   ↓
13. Testes
   ↓
14. Release
```

O ponto importante é chegar rapidamente a:

```text
Android
   ↓
Seu Launcher
   ↓
Lista de Apps
   ↓
Abrir App
```

Esse será o primeiro grande marco técnico.

---

# 22. Marcos do projeto

## Milestone 1 — Launcher funcionando

Critério:

```text
O Android consegue usar o aplicativo como Home.
```

---

## Milestone 2 — Launcher funcional

Critério:

```text
Launcher
├── mostra apps
└── abre apps
```

---

## Milestone 3 — MVP

Critério:

```text
Launcher
├── Home
├── Apps
├── Search
├── Favorites
├── Gestures
└── Settings
```

---

## Milestone 4 — Beta

Adicionar:

- personalização;
- performance;
- testes;
- tratamento de erros;
- refinamento da UX.

---

## Milestone 5 — Release

Aplicação:

- estável;
- documentada;
- testada;
- distribuível;
- gratuita.

---

# 23. Princípios do projeto

Durante o desenvolvimento, seguir estes princípios:

### 1. Simplicidade

Não adicionar uma funcionalidade apenas porque é possível.

### 2. Performance

O launcher será utilizado muitas vezes por dia. Pequenos atrasos serão perceptíveis.

### 3. Privacidade

Sempre que possível, manter dados e preferências localmente.

### 4. Modularidade

Cada funcionalidade deve ter responsabilidade clara.

### 5. Evolução incremental

Primeiro fazer funcionar.

Depois melhorar.

### 6. UX antes de complexidade

Uma funcionalidade simples e excelente é melhor que uma funcionalidade complexa e difícil de usar.

---

# 24. Próxima etapa recomendada

Antes de começar a programar toda a aplicação, criar três documentos/artefatos:

```text
01-product-plan.md
02-technical-architecture.md
03-ui-ux-plan.md
```

Depois:

```text
Figma
   ↓
Protótipo
   ↓
Flutter
   ↓
Kotlin / Android
   ↓
MVP
```

A primeira implementação prática deve ser **fazer o Android reconhecer o aplicativo como launcher e conseguir listar/abrir os aplicativos instalados**.

Depois disso, a interface pode ser construída sobre uma base técnica já funcional.
