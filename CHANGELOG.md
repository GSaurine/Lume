# Registo de alterações

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
