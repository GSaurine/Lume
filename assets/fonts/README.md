# Fontes

Embutidas no APK porque o Lume não declara permissão de Internet e não pode ir
buscá-las à rede. Custam cerca de 1,4 MB no total, uma vez só — não por
arquitetura.

| Ficheiro | Família | Licença | Espessuras |
|---|---|---|---|
| `Inter.ttf` | Inter | SIL Open Font License 1.1 | 100–900 |
| `Outfit.ttf` | Outfit | SIL Open Font License 1.1 | 100–900 |
| `Lora.ttf` | Lora | SIL Open Font License 1.1 | 400–700 |
| `JetBrainsMono.ttf` | JetBrains Mono | SIL Open Font License 1.1 | 100–800 |

São todas **fontes variáveis**: um único ficheiro cobre todas as espessuras. O
`fontWeight` sozinho não as altera — é preciso passar `fontVariations` com o
eixo `wght`, e é o que `LauncherFont.apply` faz, respeitando o intervalo de
cada família.

As licenças OFL estão nos ficheiros `OFL-*.txt` e têm de acompanhar qualquer
distribuição do APK.

Origem: <https://github.com/google/fonts>
