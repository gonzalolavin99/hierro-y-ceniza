"""Genera la música del juego por síntesis (100 % original, sin licencias).
Ejecutar: python tools/gen_music.py  ->  game/assets/audio/music/varga_duel_1.wav, varga_duel_2.wav,
prologue_hall.wav (el salón del Regente) y prologue_sting.wav (la nota final que no cuadra)

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


# --- Prólogo, versión 2: el salón del Regente (cálido, esperanzado) y la nota final que no cuadra ---------
# Re mayor, 70 ppm, 16 compases. Cuerdas suaves de fondo, laúd en arpegios y una flauta sencilla en la
# segunda mitad. Nada de tensión: el jugador tiene que creer al Regente. Bucle exacto.
HALL_BPM = 70.0
HALL_BEAT = 60.0 / HALL_BPM
HALL_BARS = 16
HALL_LENGTH = int(SR * HALL_BEAT * 4 * HALL_BARS)
D3 = 146.83
# Acordes (semitonos desde re3): I vi IV V I iii IV V | vi IV I V IV I V I
HALL_CHORDS = [[0, 4, 7], [-3, 0, 4], [-7, -3, 0], [-5, -1, 2], [0, 4, 7], [-6, -3, 1], [-7, -3, 0], [-5, -1, 2],
               [-3, 0, 4], [-7, -3, 0], [0, 4, 7], [-5, -1, 2], [-7, -3, 0], [0, 4, 7], [-5, -1, 2], [0, 4, 7]]
# Melodía (semitonos desde re4, pulso, compás) para la segunda mitad.
HALL_MELODY = [(4, 0, 8), (2, 2, 8), (0, 0, 9), (-1, 2, 9), (2, 0, 10), (4, 1, 10), (7, 2, 10),
               (5, 0, 11), (4, 2, 11), (2, 0, 12), (0, 2, 12), (4, 0, 13), (2, 2, 13), (-1, 0, 14), (0, 0, 15)]


def semi(base, n):
    return base * 2 ** (n / 12.0)


def place_in(track, sound, at_seconds, length, gain=1.0):
    start = int(at_seconds * SR) % length
    end = start + len(sound)
    if end <= length:
        track[start:end] += sound * gain
    else:
        first = length - start
        track[start:] += sound[:first] * gain
        track[:end - length] += sound[first:] * gain


def soft_pad(freqs, seconds):
    t = t_axis(seconds)
    env = np.minimum(1.0, t / 0.9) * np.minimum(1.0, (seconds - t) / 0.9)
    x = np.zeros(len(t))
    for f in freqs:
        for detune in (0.997, 1.003):
            x += np.sin(2 * np.pi * f * detune * t + rng.uniform(0, 6)) * 0.5
            x += np.sin(2 * np.pi * f * 2 * detune * t) * 0.12
    return lowpass(x * env, 1800.0) / max(len(freqs), 1)


def flute(freq, seconds):
    t = t_axis(seconds)
    vib = 1.0 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.minimum(1.0, t / 0.4)
    phase = 2 * np.pi * np.cumsum(freq * vib) / SR
    env = np.minimum(1.0, t / 0.12) * np.exp(-np.maximum(t - seconds * 0.6, 0) / 0.25)
    breath = lowpass(rng.standard_normal(len(t)), 3000.0) * 0.03
    return (np.sin(phase) + 0.18 * np.sin(2 * phase) + breath) * env


def build_hall():
    mix = np.zeros(HALL_LENGTH)
    bar_s = HALL_BEAT * 4
    for bar, chord in enumerate(HALL_CHORDS):
        at = bar * bar_s
        place_in(mix, soft_pad([semi(D3, n) for n in chord] + [semi(D3, chord[0] - 12)], bar_s + 0.9), at, HALL_LENGTH, 0.55)
        # Laúd: arpegio en corcheas (raíz, tercera, quinta, octava…).
        notes = [chord[0], chord[1], chord[2], chord[0] + 12, chord[2], chord[1], chord[2], chord[0] + 12]
        for k, n in enumerate(notes):
            place_in(mix, pluck(semi(D3, n), 1.4, 0.995), at + k * HALL_BEAT * 0.5, HALL_LENGTH, 0.32)
    for n, beat, bar in HALL_MELODY:
        place_in(mix, flute(semi(D3 * 2, n), HALL_BEAT * 1.8), (bar * 4 + beat) * HALL_BEAT, HALL_LENGTH, 0.22)
    echo = np.zeros(HALL_LENGTH)
    d = int(SR * 0.31)
    echo[d:] = mix[:-d] * 0.25
    mix = mix + echo
    return mix / np.max(np.abs(mix)) * 0.7


def build_sting(seconds=7.0):
    """La nota que no cuadra: re grave y mi bemol juntos, cuerdas con trémolo, que crecen y se apagan."""
    t = t_axis(seconds)
    env = np.minimum(1.0, t / 2.5) * np.exp(-np.maximum(t - 3.5, 0) / 1.2)
    trem = 0.8 + 0.2 * np.sin(2 * np.pi * 6.0 * t)
    x = np.zeros(len(t))
    for f, a in [(73.42, 1.0), (77.78, 0.8), (36.71, 0.6), (155.56, 0.25)]:
        for h, ha in [(1, 1.0), (2, 0.35), (3, 0.15)]:
            x += a * ha * np.sin(2 * np.pi * f * h * t + rng.uniform(0, 6))
    x = lowpass(x * env * trem, 900.0)
    return x / np.max(np.abs(x)) * 0.6


def main():
    os.makedirs(OUT, exist_ok=True)
    for phase in (1, 2):
        data = build(phase)
        path = os.path.join(OUT, "varga_duel_%d.wav" % phase)
        wavfile.write(path, SR, (data * 32767).astype(np.int16))
        print("  %s  %.1f s" % (os.path.basename(path), LENGTH / SR))
    for name, data in (("prologue_hall", build_hall()), ("prologue_sting", build_sting())):
        path = os.path.join(OUT, name + ".wav")
        wavfile.write(path, SR, (data * 32767).astype(np.int16))
        print("  %s  %.1f s" % (os.path.basename(path), len(data) / SR))


if __name__ == "__main__":
    main()
