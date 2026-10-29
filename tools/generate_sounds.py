"""Genera los efectos de sonido del juego con síntesis simple (estilo retro).
Son sonidos propios, sin problemas de licencia.

Uso (desde la raíz del proyecto):
    python3 tools/generate_sounds.py
"""
import math
import os
import random
import struct
import wave

RATE = 44100
OUT = 'assets/sfx'


def save(name, samples):
    peak = max(abs(s) for s in samples) or 1
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(s / peak * 0.85 * 32767)) for s in samples))


def sword_slash():
    """Ruido filtrado que baja de agudo a grave: un 'fshh'."""
    random.seed(7)
    n = int(RATE * 0.22)
    out, lp, prev = [], 0.0, 0.0
    for i in range(n):
        t = i / n
        cutoff = 0.55 * (1 - t) ** 1.5 + 0.03
        lp += cutoff * (random.uniform(-1, 1) - lp)
        hp = lp - prev
        prev = lp
        env = min(1, t / 0.08) * (1 - t) ** 2
        out.append((hp * 0.8 + lp * 0.4) * env)
    save('sword_slash.wav', out)


def enemy_death():
    """Onda cuadrada que baja de tono, más ruido."""
    random.seed(8)
    n = int(RATE * 0.45)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        phase += (420 * (1 - t) ** 2 + 55) / RATE
        square = 1.0 if (phase % 1) < 0.5 else -1.0
        noise = random.uniform(-1, 1) * (1 - t) ** 3
        env = min(1, t / 0.01) * (1 - t) ** 1.5
        out.append((square * 0.6 + noise * 0.5) * env)
    save('enemy_death.wav', out)


def campfire_ignite():
    """'Fuump' de llama que se enciende, con chasquidos de brasas."""
    random.seed(9)
    n = int(RATE * 0.9)
    out, lp = [], 0.0
    for i in range(n):
        t = i / n
        cutoff = 0.02 + 0.25 * min(1, t / 0.15) * (1 - t)
        lp += cutoff * (random.uniform(-1, 1) - lp)
        env = min(1, t / 0.12) * (1 - t) ** 1.2
        crackle = (random.uniform(-1, 1) if random.random() < 0.002 * (1 - t) else 0.0)
        out.append(lp * env * 1.5 + crackle * 0.8)
    save('campfire_ignite.wav', out)


def player_hurt():
    """Golpe corto: ruido grave con un tono que cae rápido."""
    random.seed(10)
    n = int(RATE * 0.25)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        phase += (300 * (1 - t) + 80) / RATE
        tone = math.sin(phase * 2 * math.pi)
        noise = random.uniform(-1, 1)
        env = min(1, t / 0.005) * (1 - t) ** 2.5
        out.append((tone * 0.7 + noise * 0.4) * env)
    save('player_hurt.wav', out)


def enemy_hit():
    """Golpe seco de la espada contra un enemigo."""
    random.seed(11)
    n = int(RATE * 0.12)
    out, lp = [], 0.0
    for i in range(n):
        t = i / n
        lp += 0.35 * (random.uniform(-1, 1) - lp)
        tone = math.sin(2 * math.pi * (180 - 100 * t) * i / RATE)
        env = min(1, t / 0.01) * (1 - t) ** 3
        out.append((lp * 0.9 + tone * 0.6) * env)
    save('enemy_hit.wav', out)


def _tone_sequence(name, notes, seed, note_len=0.16, tail=0.6):
    """Secuencia de notas tipo campanita (seno con armónico y caída suave)."""
    random.seed(seed)
    total = int(RATE * (note_len * len(notes) + tail))
    out = [0.0] * total
    for k, freq in enumerate(notes):
        start = int(RATE * note_len * k)
        length = int(RATE * (note_len + tail))
        for i in range(length):
            if start + i >= total:
                break
            t = i / RATE
            env = min(1, t / 0.005) * math.exp(-t * 5)
            out[start + i] += (math.sin(2 * math.pi * freq * t) * 0.6 + math.sin(4 * math.pi * freq * t) * 0.2) * env
    save(name, out)


def secret_found():
    """Arpegio ascendente corto: descubriste algo."""
    _tone_sequence('secret_found.wav', [523, 659, 784, 1047], 12, note_len=0.09, tail=0.5)


def level_complete():
    """Fanfarria breve al completar un nivel."""
    _tone_sequence('level_complete.wav', [392, 523, 659, 784, 659, 1047], 13, note_len=0.15, tail=0.9)


def block_clang():
    """Choque metálico de la espada al bloquear: tonos agudos inarmónicos con caída rápida."""
    random.seed(14)
    n = int(RATE * 0.35)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-t * 14)
        tone = (math.sin(2 * math.pi * 1210 * t) * 0.5 + math.sin(2 * math.pi * 1870 * t) * 0.35
                + math.sin(2 * math.pi * 2960 * t) * 0.2)
        click = random.uniform(-1, 1) * math.exp(-t * 120)
        out.append(tone * env + click * 0.6)
    save('block_clang.wav', out)


def heal():
    """Curación: dos notas suaves que suben."""
    _tone_sequence('heal.wav', [660, 880, 1320], 15, note_len=0.07, tail=0.35)


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    sword_slash()
    enemy_death()
    campfire_ignite()
    player_hurt()
    enemy_hit()
    secret_found()
    level_complete()
    block_clang()
    heal()
    print('Sonidos generados.')
