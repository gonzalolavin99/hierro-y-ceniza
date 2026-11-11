"""Genera los sonidos de ambiente del Paso de Hierro por síntesis (100 % originales, sin licencias).
Ejecutar: python tools/gen_ambient.py  ->  game/assets/audio/ambient/*.wav

- wind_loop.wav: viento en bucle (sin corte al repetirse), con ráfagas suaves.
- river_loop.wav: rumor de agua corriendo, en bucle.
- bird_1..6.wav: cantos cortos de pájaros lejanos (solo se oyen; no son animales del juego).
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio", "ambient")
rng = np.random.default_rng(11)


def lowpass(x, f, order=4):
    return signal.sosfilt(signal.butter(order, f, btype="low", fs=SR, output="sos"), x)


def band(x, lo, hi, order=4):
    return signal.sosfilt(signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos"), x)


def smooth_noise(seconds, rate_hz):
    """Curva aleatoria lenta entre 0 y 1 (para modular el viento o el agua)."""
    n = int(seconds * rate_hz) + 4
    points = rng.random(n)
    x = np.linspace(0, n - 3, int(SR * seconds))
    return np.interp(x, np.arange(n), points)


def make_loop(x, fade_seconds=2.0):
    """Funde el final con el principio para que al repetirse no se note el corte."""
    n = int(SR * fade_seconds)
    head = x[:n].copy()
    tail = x[-n:].copy()
    ramp = np.linspace(0.0, 1.0, n)
    x = x[:-n].copy()
    x[:n] = tail * (1.0 - ramp) + head * ramp
    return x


def save(name, x, peak_db=-3.0):
    os.makedirs(OUT, exist_ok=True)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * (10 ** (peak_db / 20.0))
    wavfile.write(os.path.join(OUT, name), SR, (x * 32767).astype(np.int16))
    print(f"  {name:18s} {len(x) / SR:5.1f} s")


def wind(seconds=24.0):
    noise = rng.standard_normal(int(SR * seconds))
    low = lowpass(noise, 380)
    mid = band(noise, 300, 1400)
    gust = smooth_noise(seconds, 0.25) ** 2  # Ráfagas lentas.
    whistle = smooth_noise(seconds, 0.12)
    x = low * (0.45 + 0.55 * gust) + mid * 0.35 * gust * whistle
    return make_loop(x)


def river(seconds=20.0):
    noise = rng.standard_normal(int(SR * seconds))
    body = band(noise, 250, 2600)
    bubbles = band(noise, 1800, 5000) * (smooth_noise(seconds, 6.0) ** 3)
    x = body * (0.8 + 0.2 * smooth_noise(seconds, 0.5)) + bubbles * 0.5
    return make_loop(lowpass(x, 4500))


def bird(variant):
    """Un canto corto: 2–5 notas que suben o bajan, con un poco de eco de lejos."""
    r = np.random.default_rng(100 + variant)
    notes = r.integers(2, 6)
    parts = []
    base = r.uniform(2400, 4200)
    for i in range(notes):
        length = r.uniform(0.06, 0.16)
        t = np.arange(int(SR * length)) / SR
        f0 = base * r.uniform(0.85, 1.2)
        f1 = f0 * r.uniform(0.7, 1.4)
        freq = np.linspace(f0, f1, len(t)) + 120 * np.sin(2 * np.pi * r.uniform(20, 45) * t)
        phase = 2 * np.pi * np.cumsum(freq) / SR
        env = np.sin(np.pi * np.linspace(0, 1, len(t))) ** 1.5
        tone = (np.sin(phase) + 0.25 * np.sin(2 * phase)) * env
        parts.append(tone)
        parts.append(np.zeros(int(SR * r.uniform(0.04, 0.12))))
    x = np.concatenate(parts + [np.zeros(int(SR * 0.6))])
    # Lejos: menos agudos y un eco corto.
    x = lowpass(x, 5200)
    delay = int(SR * 0.11)
    echo = np.zeros_like(x)
    echo[delay:] = x[:-delay] * 0.25
    return x + echo


if __name__ == "__main__":
    print("Ambiente del Paso de Hierro:")
    save("wind_loop.wav", wind())
    save("river_loop.wav", river())
    for v in range(1, 7):
        save(f"bird_{v}.wav", bird(v), peak_db=-6.0)
