"""Prepara as camadas do ícone a partir do ficheiro exportado do editor.

O original (`assets/icon/icon_foreground_original.png`) vem com fundo branco
opaco e uma sombra. Este script:

  1. separa o logótipo do fundo pela saturação (o logótipo é colorido, o fundo
     e a sombra são cinzentos);
  2. desfaz a composição sobre branco, para as bordas não ficarem lavadas;
  3. redimensiona e centra o logótipo, deixando margem para o `inset` de 16%
     que o flutter_launcher_icons aplica por cima;
  4. gera a camada monocromática dos ícones temáticos do Android 13+.

Usar:
    pip install pillow numpy
    python tool/prepare_icons.py
    dart run flutter_launcher_icons

Se reexportar o logótipo do editor com fundo transparente e sem sombra, este
passo deixa de ser necessário — basta gravar por cima de
`assets/icon/icon_foreground.png`.
"""

from __future__ import annotations

import pathlib

import numpy as np
from PIL import Image

ICON_DIR = pathlib.Path(__file__).resolve().parent.parent / 'assets' / 'icon'
SOURCE = ICON_DIR / 'icon_foreground_original.png'
FOREGROUND = ICON_DIR / 'icon_foreground.png'
MONOCHROME = ICON_DIR / 'icon_monochrome.png'

CANVAS = 1024

# O flutter_launcher_icons envolve o foreground num inset de 16% por lado,
# ou seja desenha-o a 68% do tamanho.
#
# A keyline do adaptive icon manda que a arte caiba num círculo de 66dp num
# canvas de 108dp. O "L" é alto e tem cantos quadrados: se só olhássemos à
# altura, a máscara circular de alguns fabricantes cortava-lhe os cantos. Por
# isso o valor abaixo foi calculado a partir do ponto do logótipo mais
# afastado do centro, não da sua altura.
TARGET = 755

# A saturação abaixo de LOW conta como fundo; acima de HIGH conta como
# logótipo. Entre as duas há uma rampa, que é o que suaviza as bordas.
SATURATION_LOW = 8.0
SATURATION_HIGH = 45.0


def extract_logo(path: pathlib.Path) -> Image.Image:
    """Devolve o logótipo recortado, com alpha e sem o fundo branco."""
    rgb = np.array(Image.open(path).convert('RGB')).astype(np.float64)

    saturation = rgb.max(axis=2) - rgb.min(axis=2)
    alpha = np.clip(
        (saturation - SATURATION_LOW) / (SATURATION_HIGH - SATURATION_LOW), 0.0, 1.0
    )

    # composto = original*a + 255*(1-a)  =>  original = (composto - 255*(1-a)) / a
    a3 = alpha[:, :, None]
    divisor = np.where(a3 > 0.05, a3, 1.0)
    straight = np.clip((rgb - 255.0 * (1.0 - a3)) / divisor, 0, 255)

    rgba = np.dstack([straight.astype(np.uint8), (alpha * 255).astype(np.uint8)])
    image = Image.fromarray(rgba, 'RGBA')
    return image.crop(image.getbbox())


def centre_on_canvas(logo: Image.Image, *, monochrome: bool) -> Image.Image:
    scale = TARGET / max(logo.size)
    resized = logo.resize(
        (round(logo.width * scale), round(logo.height * scale)), Image.LANCZOS
    )

    layer = resized
    if monochrome:
        layer = Image.new('RGBA', resized.size, (0, 0, 0, 255))

    canvas = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(
        layer,
        ((CANVAS - resized.width) // 2, (CANVAS - resized.height) // 2),
        resized,
    )
    return canvas


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f'Não encontrei {SOURCE}')

    logo = extract_logo(SOURCE)
    print(f'logótipo recortado: {logo.width}x{logo.height}')

    for path, monochrome in ((FOREGROUND, False), (MONOCHROME, True)):
        image = centre_on_canvas(logo, monochrome=monochrome)
        image.save(path)
        left, top, right, bottom = image.getbbox()
        print(f'{path.name}: bbox {left},{top} -> {right},{bottom}')


if __name__ == '__main__':
    main()
