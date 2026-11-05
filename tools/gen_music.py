"""Genera la música del duelo con la Capitana Varga por síntesis (100 % original, sin licencias).
Ejecutar: python tools/gen_music.py  ->  game/assets/audio/music/varga_duel_1.wav y varga_duel_2.wav

Mezcla de Europa y Japón (D3): tambores graves tipo taiko, un bordón grave de fondo y una melodía de
cuerda pulsada en modo frigio (re, mi bemol, fa, sol, la, si bemol, do), tensa y oscura.
- Fase 1: 96 pulsos por minuto, tambor cada pulso, melodía espaciada.
- Fase 2: la misma pieza, con el doble de tambores, redobles y la melodía una octava más arriba y más densa.
Las dos duran lo mismo y empiezan en el mismo compás: el juego pasa de una a otra sin cortar el ritmo.
Cada archivo es un bucle exacto (16 compases).
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 22050
BPM = 96.0
BEAT = 60.0 / BPM
BARS = 16
LENGTH = int(SR * BEAT * 4 * BARS)
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio", "music")
rng = np.random.default_rng(11)

# Modo frigio sobre re (D): semitonos desde re.
PHRYGIAN = [0, 1, 3, 5, 7, 8, 10]
D2 = 73.42


def note_freq(degree, octave=0):
    """Grado de la escala (puede ser negativo o > 6) a hercios, desde re2."""
    o, d = divmod(degree, 7)
    return D2 * 2 ** (octave + o + PHRYGIAN[d] / 12.0)


def t_axis(seconds):
    return np.arange(int(SR * seconds)) / SR


def lowpass(x, f):
    return signal.sosfilt(signal.butter(4, f, btype="low", fs=SR, output="sos"), x)


def place(track, sound, at_seconds, gain=1.0):
    start = int(at_seconds * SR) % LENGTH
    end = start + len(sound)
    if end <= LENGTH:
        track[start:end] += sound * gain
    else:  # Da la vuelta al final (bucle exacto).
        first = LENGTH - start
        track[start:] += sound[:first] * gain
        track[:end - LENGTH] += sound[first:] * gain


def taiko(big=True):
    t = t_axis(1.2 if big else 0.5)
    f0, f1 = (95.0, 48.0) if big else (190.0, 110.0)
    freq = f1 + (f0 - f1) * np.exp(-t / 0.05)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    body = np.sin(phase) * np.exp(-t / (0.38 if big else 0.12))
    skin = lowpass(rng.standard_normal(len(t)), 900.0 if big else 2500.0) * np.exp(-t / 0.03) * 0.5
    return (body + skin) * (1.0 if big else 0.45)


def rim():
    t = t_axis(0.12)
    return lowpass(rng.standard_normal(len(t)), 5000.0) * np.exp(-t / 0.015) * 0.25


def pluck(freq, seconds=1.6, brightness=0.996):
    """Cuerda pulsada (Karplus-Strong): suena a laúd / koto."""
    n = int(SR * seconds)
    period = max(int(SR / freq), 2)
    buf = rng.uniform(-1, 1, period)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % period]
        buf[i % period] = brightness * 0.5 * (buf[i % period] + buf[(i + 1) % period])
    return out * np.exp(-np.arange(n) / (SR * seconds * 0.5)) * 0.5


def drone():
    t = np.arange(LENGTH) / SR
    slow = 0.75 + 0.25 * np.sin(2 * np.pi * t / (BEAT * 16))
    tone = np.zeros(LENGTH)
    for f, a in [(D2 / 2, 0.5), (D2, 0.35), (D2 * 1.5, 0.18), (D2 * 2, 0.08)]:
        tone += a * np.sin(2 * np.pi * f * t + rng.uniform(0, 6))
    return lowpass(tone, 400.0) * slow * 0.35


# Melodía de 8 compases (grado de escala, pulso en el compás, compás); se repite dos veces.
MELODY = [
    (4, 0, 0), (5, 1.5, 0), (4, 2.5, 0), (1, 3, 0),
    (0, 0, 1), (1, 2, 1),
    (4, 0, 2), (6, 1, 2), (7, 1.5, 2), (6, 2.5, 2), (4, 3, 2),
    (5, 0, 3), (4, 2, 3), (1, 3.5, 3),
    (0, 0, 4), (2, 1, 4), (4, 1.5, 4), (5, 2.5, 4),
    (4, 0, 5), (1, 1, 5), (0, 2, 5),
    (-1, 0, 6), (0, 1.5, 6), (1, 2.5, 6), (3, 3, 6),
    (1, 0, 7), (0, 2, 7),
]


def build(phase):
    mix = drone()
    drums = np.zeros(LENGTH)
    for bar in range(BARS):
        for beat in range(4):
            at = (bar * 4 + beat) * BEAT
            if beat in (0, 2) or phase == 2:
                place(drums, taiko(True), at, 1.0 if beat == 0 else 0.7)
            if phase == 1 and beat == 3 and bar % 2 == 1:
                place(drums, taiko(False), at + BEAT * 0.5, 0.8)
            if phase == 2:
                place(drums, taiko(False), at + BEAT * 0.5, 0.7)
                place(drums, rim(), at + BEAT * 0.75, 1.0)
        if phase == 2 and bar % 4 == 3:  # Redoble al final de cada frase.
            for k in range(8):
                place(drums, taiko(False), (bar * 4 + 3) * BEAT + k * BEAT / 8, 0.4 + k * 0.06)
    melody = np.zeros(LENGTH)
    octave = 2 if phase == 1 else 3
    for rep in range(2):
        for degree, beat, bar in MELODY:
            at = ((rep * 8 + bar) * 4 + beat) * BEAT
            place(melody, pluck(note_freq(degree, octave)), at, 0.9)
            if phase == 2:  # Eco a la octava baja, medio pulso después: más denso.
                place(melody, pluck(note_freq(degree, octave - 1), 1.0), at + BEAT * 0.5, 0.45)
    mix = mix + drums * 0.8 + melody * 0.55
    # Un poco de sala (eco corto) para que no suene seco.
    echo = np.zeros(LENGTH)
    delay = int(SR * 0.19)
    echo[delay:] = mix[:-delay] * 0.22
    mix = mix + echo
    return mix / np.max(np.abs(mix)) * 0.85


def main():
    os.makedirs(OUT, exist_ok=True)
    for phase in (1, 2):
        data = build(phase)
        path = os.path.join(OUT, "varga_duel_%d.wav" % phase)
        wavfile.write(path, SR, (data * 32767).astype(np.int16))
        print("  %s  %.1f s" % (os.path.basename(path), LENGTH / SR))


if __name__ == "__main__":
    main()
