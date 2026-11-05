"""Genera los chillidos de Frank (el tití) por síntesis: 100 % originales, sin voces ni grabaciones ajenas.
Ejecutar desde G:\\Game:  python tools/gen_frank.py   (o --all para rehacerlos todos)

Lee tools/voice_lines.json (lo genera game/tests/export_voice_script.gd) y escribe
game/assets/audio/voice/frank/<id>.wav. Cada línea trae `chirp` (el tipo de chillido) y `chars`
(largo del subtítulo): las frases largas chillan más rato, para que el subtítulo y el sonido vayan juntos.

Tipos (inspirados en los monitos pequeños de verdad: silbidos largos, trinos y gorjeos):
  call       silbidos largos y subidos, para pedir ayuda
  chatter    parloteo: muchos gorjeos cortos que suben y bajan, como si hablara
  happy      trino que sube, contento
  sad        silbidos suaves que bajan despacio
  indignant  parloteo con golpes de queja, más fuerte
  squeak     un chillidito corto
  twitter    gorjeo bajito, hablando solo
  alarm      chillido agudo y áspero, susto
"""
import json
import os
import sys

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "game", "assets", "audio", "voice", "frank")
LINES = os.path.join(ROOT, "tools", "voice_lines.json")


def tone(f_curve, amp_curve, rng, breath=0.08, harmonics=(1.0, 0.35, 0.12)):
    """Silbido con armónicos que sigue una curva de frecuencia (Hz por muestra) y de volumen."""
    vibrato = 1.0 + 0.012 * np.sin(2 * np.pi * rng.uniform(18, 26) * np.arange(len(f_curve)) / SR)
    phase = 2 * np.pi * np.cumsum(f_curve * vibrato) / SR
    x = sum(a * np.sin((k + 1) * phase) for k, a in enumerate(harmonics))
    noise = rng.standard_normal(len(x))
    noise = signal.sosfilt(signal.butter(2, [2500, 9000], btype="band", fs=SR, output="sos"), noise)
    return (x + breath * noise) * amp_curve


def envelope(n, attack=0.008, release=0.03):
    a, r = max(int(attack * SR), 1), max(int(release * SR), 1)
    env = np.ones(n)
    env[:a] = np.linspace(0, 1, a)
    env[-r:] *= np.linspace(1, 0, r)
    return env


def sweep(f0, f1, seconds, rng, curve=1.0, gain=1.0, breath=0.08):
    n = max(int(seconds * SR), 32)
    t = np.linspace(0, 1, n) ** curve
    f = f0 + (f1 - f0) * t
    return tone(f, envelope(n) * gain, rng, breath)


def chirp_up_down(f_low, f_high, seconds, rng, gain=1.0):
    n = max(int(seconds * SR), 32)
    t = np.linspace(0, 1, n)
    f = f_low + (f_high - f_low) * np.sin(np.pi * t) ** 0.8
    return tone(f, envelope(n) * gain, rng)


def place(parts):
    """Junta (inicio en s, sonido) en una sola pista."""
    end = max(int(at * SR) + len(s) for at, s in parts)
    out = np.zeros(end + int(0.05 * SR))
    for at, s in parts:
        i = int(at * SR)
        out[i:i + len(s)] += s
    return out


def chatter(seconds, rng, loud=1.0, base=2600.0):
    parts, at = [], 0.0
    while at < seconds:
        length = rng.uniform(0.045, 0.11)
        lo = base * rng.uniform(0.8, 1.15)
        hi = lo * rng.uniform(1.2, 1.7)
        s = chirp_up_down(lo, hi, length, rng, gain=loud * rng.uniform(0.6, 1.0)) if rng.random() < 0.6 \
            else sweep(hi, lo, length, rng, gain=loud * rng.uniform(0.5, 0.9))
        parts.append((at, s))
        at += length + rng.uniform(0.015, 0.06)
        if rng.random() < 0.12:  # Pausita, como entre palabras.
            at += rng.uniform(0.08, 0.16)
    return place(parts)


def make(kind, seconds, rng):
    if kind == "call":
        parts, at = [], 0.0
        while at < seconds:
            length = rng.uniform(0.32, 0.5)
            f0 = rng.uniform(2300, 2700)
            parts.append((at, sweep(f0, f0 * rng.uniform(1.35, 1.55), length, rng, curve=0.6, breath=0.05)))
            at += length + rng.uniform(0.08, 0.16)
        return place(parts)
    if kind == "chatter":
        return chatter(seconds, rng)
    if kind == "happy":
        parts = [(0.0, chatter(min(seconds, 0.5), rng, base=2800.0))]
        trill, at, f = [], 0.0, 2600.0
        for _ in range(9):
            trill.append((at, chirp_up_down(f, f * 1.25, 0.05, rng, gain=0.9)))
            at += 0.045
            f *= 1.05
        parts.append((min(seconds, 0.5) + 0.05, place(trill)))
        if seconds > 1.3:
            parts.append((1.0, chatter(seconds - 1.0, rng, base=3000.0)))
        return place(parts)
    if kind == "sad":
        parts, at = [], 0.0
        while at < seconds:
            length = rng.uniform(0.45, 0.7)
            f0 = rng.uniform(2400, 2700)
            parts.append((at, sweep(f0, f0 * 0.72, length, rng, curve=1.4, gain=0.55, breath=0.12)))
            at += length + rng.uniform(0.15, 0.3)
        return place(parts)
    if kind == "indignant":
        parts, at = [], 0.0
        while at < seconds:
            if rng.random() < 0.3:
                s = sweep(3600, 2200, 0.16, rng, gain=1.0, breath=0.2)  # "¡Hmpf!"
                parts.append((at, s))
                at += 0.22
            else:
                s = chatter(rng.uniform(0.3, 0.5), rng, loud=0.95, base=3000.0)
                parts.append((at, s))
                at += len(s) / SR
        return place(parts)
    if kind == "squeak":
        f0 = rng.uniform(3000, 3600)
        first = sweep(f0, f0 * rng.uniform(1.25, 1.5), rng.uniform(0.09, 0.14), rng)
        second = sweep(f0 * 1.1, f0 * 0.9, 0.07, rng, gain=0.5)  # Coletilla más bajita.
        return place([(0.0, first), (len(first) / SR + 0.05, second)])
    if kind == "twitter":
        return chatter(seconds, rng, loud=0.5, base=2400.0)
    if kind == "alarm":
        parts = []
        for k in range(3):
            parts.append((k * 0.12, sweep(4200, 3300, 0.09, rng, gain=1.0, breath=0.45)))
        return place(parts)
    raise SystemExit("Tipo de chillido desconocido: %s" % kind)


def length_for(line):
    kind, chars = line["chirp"], line.get("chars", 0)
    if kind in ("squeak", "alarm"):
        return 0.0
    if chars <= 0:
        return {"happy": 0.9, "twitter": 0.9, "chatter": 0.8}.get(kind, 0.8)
    return float(np.clip(0.35 + chars * 0.045, 0.8, 3.2))


def finish(x):
    x = signal.sosfilt(signal.butter(2, 900, btype="high", fs=SR, output="sos"), x)
    # Un poco de cuerpo (que no suene a pájaro): eco cortísimo, como el pecho de un animalito.
    d = int(0.004 * SR)
    x = x + np.pad(x, (d, 0))[: len(x)] * 0.3
    return x / max(np.max(np.abs(x)), 1e-6) * 0.7


def main():
    redo = "--all" in sys.argv
    with open(LINES, encoding="utf-8") as f:
        data = json.load(f)
    os.makedirs(OUT, exist_ok=True)
    made = 0
    for i, line in enumerate(data.get("frank", [])):
        path = os.path.join(OUT, line["id"] + ".wav")
        if os.path.exists(path) and not redo:
            continue
        rng = np.random.default_rng(100 + i)
        x = finish(make(line["chirp"], length_for(line), rng))
        wavfile.write(path, SR, (x * 32767).astype(np.int16))
        made += 1
        print("  %-18s %4.2f s  (%s)" % (line["id"], len(x) / SR, line["chirp"]))
    print("Hechos %d." % made)


if __name__ == "__main__":
    main()
