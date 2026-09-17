# Registo de alterações

## Por publicar

### Adicionado

- **Ícones no ecrã inicial.** Passam a ser o estado de origem, na forma de
  símbolos neutros — não logótipos de marcas. O Lume adivinha o de cada
  aplicação em duas camadas: uma tabela das aplicações que quase toda a gente
  tem (Spotify, YouTube, Instagram, LinkedIn, WhatsApp e mais uma centena), e
  palavras-chave no nome e no package para o resto.
- **Escolher o ícone de uma aplicação.** Manter premido → "Escolher ícone", e
  uma grelha de sessenta símbolos agrupados por tema. Resolve o que a tabela
  nunca poderia cobrir: há milhares de bancos, de lojas e de aplicações locais.
  A escolha ganha sempre ao palpite automático.
- **Três estilos de ícone** em Definições → Aparência: símbolos, ícones
  originais das aplicações, ou nenhum.
- **Cinco estilos de animação** — nenhuma, seca, discreta, suave e elástica.
  Cada um muda a duração *e* a curva do movimento, que é o que faz uma
  transição parecer seca ou macia.

### Corrigido

- Com o conteúdo ao centro, o ícone ficava encostado à margem esquerda
  enquanto o nome centrava. Passam a andar juntos.

## v0.1.2

### Adicionado

Personalização, a pedido do primeiro utilizador de fora. Cobre parte da lista
da secção 15 do plano.

- **Dar outro nome às aplicações.** Manter premido → "Dar outro nome". O nome
  fica ligado ao *package*, por isso sobrevive a atualizações da aplicação e a
  mudanças de idioma do telemóvel, e muda também a posição na lista, a letra do
  índice e a pesquisa. Definições → Aplicações mostra os nomes dados e permite
  repô-los.
- **Cor de destaque**, à escolha entre seis. Cada uma tem um tom para o tema
  claro e outro para o escuro, porque a mesma cor não tem contraste nos dois.
- **Alinhamento na Home**: relógio, data e favoritos à esquerda ou ao centro.
- **Mudar wallpaper** a partir de Definições → Aparência, abrindo o seletor do
  Android.

### Corrigido

- Com o conteúdo ao centro, o relógio e os favoritos não ficavam no mesmo eixo:
  os favoritos descontavam a largura da barra alfabética e o relógio não.

### Alterado

- **Os painéis passam a ser opacos por omissão.** O primeiro utilizador a
  experimentar o Lume queixou-se de o wallpaper por trás da pesquisa
  atrapalhar a leitura. A transparência passa a ser uma definição
  (Aparência → Painéis), regulável entre 70% e 100%.

## v0.1.1

Correções encontradas ao testar num dispositivo real (Samsung Galaxy A16 5G,
Android 16). Se instalou a v0.1.0, vale a pena atualizar: os gestos quase não
funcionavam.

### Corrigido

- **Gestos ignoravam a maior parte do ecrã.** Deslizar por cima do relógio, da
  data, da dica ou de um favorito não fazia nada — só funcionava em zonas
  vazias. No Flutter, qualquer `Text` responde ao hit test e um `InkWell` é
  opaco, por isso o gesto nunca chegava à camada que o trata.
- **Deslizes lentos não contavam.** Só a velocidade final era considerada, pelo
  que arrastar devagar e parar antes de levantar o dedo não disparava nada.
  Agora conta a velocidade **ou** a distância percorrida.
- **Texto ilegível sobre wallpaper claro.** O contraste era de 1,01:1 no índice
  alfabético e na dica dos favoritos, contra os 4,5:1 exigidos pela WCAG AA. O
  texto sobre o wallpaper passa a ter sombra e a paleta ganhou contraste.
- **Fantasmas da Home nos painéis.** O relógio e o banner liam-se através da
  lista de aplicações e da pesquisa. As rotas de ecrã inteiro passam a ser
  opacas; o wallpaper continua visível.

### Interno

- 43 testes, incluindo regressão para a deteção de deslizes e para o hit test
  dos itens sobre o wallpaper
- `tool/device_shot.sh` e `tool/device_input.sh`: capturas e gestos só são
  enviados com o Lume em primeiro plano e o ecrã aceso

## v0.1.0

Primeira versão pública. Cobre as FASES 1 a 9 do plano do projeto: papel de
Home Launcher, deteção e abertura de aplicações, Home com relógio, data,
favoritos e índice alfabético, pesquisa local com ordenação por relevância,
gestos configuráveis, definições e temas claro/escuro/sistema.
