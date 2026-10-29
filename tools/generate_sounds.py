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


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    sword_slash()
    enemy_death()
    campfire_ignite()
    player_hurt()
    print('Sonidos generados.')
