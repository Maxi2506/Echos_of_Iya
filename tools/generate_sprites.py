"""Genera los sprites que faltaban a partir de los existentes.

Uso (desde la raíz del proyecto):
    python3 tools/generate_sprites.py

Crea:
    assets/img/escenario/Elements/campfire_off.png    fogata apagada (32x16)
    assets/img/personaje/protagonista/hero_death.png  muerte del héroe (9 cuadros de 128x128)
    assets/img/ui/heart_full.png / heart_empty.png    corazones del HUD (9x8)
"""
import os
import random

from PIL import Image

random.seed(3)


def campfire_off():
    """Fogata apagada: la encendida sin llamas ni halo, con ceniza en el cuenco."""
    lit = Image.open('assets/img/escenario/Elements/anim_light2.png').convert('RGBA').crop((0, 0, 32, 16))
    flame = {(134, 34, 0), (240, 65, 0), (220, 218, 11)}
    bowl_top = min(y for y in range(16) for x in range(32) if lit.getpixel((x, y))[:3] == (24, 16, 11))
    ash = [(70, 64, 62, 255), (58, 52, 50, 255), (92, 40, 28, 255)]
    off = Image.new('RGBA', (32, 16))
    for y in range(16):
        for x in range(32):
            r, g, b, a = lit.getpixel((x, y))
            if a < 255:
                continue  # halo rojo semitransparente
            if (r, g, b) in flame:
                if y >= bowl_top - 1:
                    off.putpixel((x, y), random.choice(ash))
                continue
            off.putpixel((x, y), (r, g, b, a))
    off.save('assets/img/escenario/Elements/campfire_off.png')


def _tint(im, color, amount):
    out = im.copy()
    px = out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (int(r + (color[0] - r) * amount), int(g + (color[1] - g) * amount),
                            int(b + (color[2] - b) * amount), a)
    return out


def _shift(im, dx, dy):
    out = Image.new('RGBA', im.size)
    out.paste(im, (dx, dy))
    return out


def hero_death():
    """Muerte del héroe: destello, golpe, cae, queda tendido y se disuelve en 'ecos' celestes."""
    hero = Image.open('assets/img/personaje/protagonista/male_hero.png').convert('RGBA')
    cell = lambda c, r: hero.crop((c * 128, r * 128, c * 128 + 128, r * 128 + 128))
    idle, fall = cell(0, 1), cell(0, 5)
    feet_y = idle.getbbox()[3]  # fila de los pies, para apoyar al héroe tendido en el piso

    frames = [
        _tint(idle, (255, 255, 255), 0.85),                                  # destello
        _shift(_tint(fall, (255, 60, 60), 0.35), -4, -6),                    # golpe
        _shift(_tint(fall.rotate(-35, resample=Image.NEAREST, center=(64, feet_y)), (255, 60, 60), 0.2), -6, -2),
    ]
    lying = idle.rotate(-90, resample=Image.NEAREST, center=(64, feet_y))
    lying = _shift(lying, 0, feet_y - lying.getbbox()[3])
    frames.append(lying)

    opaque = [(x, y) for y in range(128) for x in range(128) if lying.getpixel((x, y))[3] > 0]
    random.shuffle(opaque)
    for step in range(1, 6):
        f = Image.new('RGBA', (128, 128))
        px = f.load()
        keep = int(len(opaque) * (1 - step / 5))
        for (x, y) in opaque[:keep]:
            px[x, y] = lying.getpixel((x, y))
        for (x, y) in opaque[keep:keep + 60]:
            nx, ny = x + random.randint(-2, 2), y - random.randint(2, 6) * step
            if 0 <= nx < 128 and 0 <= ny < 128:
                px[nx, ny] = (120, 230, 255, max(40, 255 - step * 40))
        frames.append(f)

    sheet = Image.new('RGBA', (128 * len(frames), 128))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * 128, 0))
    sheet.save('assets/img/personaje/protagonista/hero_death.png')


HEART = ["..XX.XX..", ".XOOXOOX.", "XOWOOOOOX", "XOOOOOOOX",
         ".XOOOOOX.", "..XOOOX..", "...XOX...", "....X...."]


def hearts():
    os.makedirs('assets/img/ui', exist_ok=True)
    for name, filled in (('heart_full', True), ('heart_empty', False)):
        im = Image.new('RGBA', (9, 8))
        for y, line in enumerate(HEART):
            for x, ch in enumerate(line):
                if ch == 'X':
                    im.putpixel((x, y), (20, 10, 16, 255))
                elif ch == 'W':
                    im.putpixel((x, y), (255, 220, 220, 255) if filled else (110, 90, 100, 255))
                elif ch == 'O':
                    im.putpixel((x, y), (220, 40, 60, 255) if filled else (60, 40, 50, 255))
        im.save(f'assets/img/ui/{name}.png')


if __name__ == '__main__':
    campfire_off()
    hero_death()
    hearts()
    print('Sprites generados.')
