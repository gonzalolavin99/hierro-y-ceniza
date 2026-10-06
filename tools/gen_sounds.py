"""Genera los efectos de sonido del combate por síntesis (100% originales, sin licencias).
Ejecutar: python tools/gen_sounds.py  ->  game/assets/audio/sfx/*.wav

Cada sonido tiene varias variantes para que no suene repetitivo.
"""
import os
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio", "sfx")
rng = np.random.default_rng(7)


def t_axis(seconds):
    return np.arange(int(SR * seconds)) / SR


def env_exp(t, decay):
    return np.exp(-t / max(decay, 1e-4))


def band(noise, lo, hi, order=4):
    sos = signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, noise)


def highpass(x, f, order=4):
    return signal.sosfilt(signal.butter(order, f, btype="high", fs=SR, output="sos"), x)


def lowpass(x, f, order=4):
    return signal.sosfilt(signal.butter(order, f, btype="low", fs=SR, output="sos"), x)


def pad(x, n):
    return np.pad(x, (0, max(0, n - len(x))))[:n]


def ring(t, f0, ratios, amps, decays, detune=1.0035):
    """Parciales inarmónicos (como una barra de metal) con batido para que 'brille'."""
    out = np.zeros_like(t)
    for r, a, d in zip(ratios, amps, decays):
        f = f0 * r
        phase = rng.uniform(0, 2 * np.pi)
        out += a * env_exp(t, d) * (np.sin(2 * np.pi * f * t + phase) + 0.6 * np.sin(2 * np.pi * f * detune * t))
    return out


def thump(t, f_start, f_end, decay, amp):
    f = f_end + (f_start - f_end) * np.exp(-t / 0.03)
    phase = 2 * np.pi * np.cumsum(f) / SR
    return amp * np.sin(phase) * env_exp(t, decay)


def noise_burst(t, lo, hi, decay, amp):
    return amp * band(rng.standard_normal(len(t)), lo, hi) * env_exp(t, decay)


def reverb(x, seconds=0.7, mix=0.18):
    """Reverberación simple: convolución con ruido que decae (sala de piedra)."""
    ti = t_axis(seconds)
    ir = rng.standard_normal(len(ti)) * env_exp(ti, seconds / 5)
    ir = lowpass(ir, 6000)
    ir /= np.max(np.abs(ir))
    wet = pad(signal.fftconvolve(x, ir), len(x) + len(ti))
    dry = np.pad(x, (0, len(ti)))
    wet /= np.max(np.abs(wet)) + 1e-9
    return dry * (1 - mix) + wet * mix * np.max(np.abs(dry))


def fade_out(x, seconds=0.05):
    n = min(len(x), int(SR * seconds))
    x[-n:] *= np.linspace(1, 0, n)
    return x


def save(name, x, peak_db=-1.0):
    x = fade_out(x.astype(np.float64))
    x = x / (np.max(np.abs(x)) + 1e-9) * (10 ** (peak_db / 20))
    os.makedirs(OUT, exist_ok=True)
    wavfile.write(os.path.join(OUT, name + ".wav"), SR, (x * 32767).astype(np.int16))
    print("  ", name)


# ---------------------------------------------------------------------------------

def scrape(t, length, freqs, amp, slide=0.08):
    """Chirrido de filo contra filo: ruido con 'tirones' (fricción) pasado por resonancias metálicas."""
    n = rng.standard_normal(len(t))
    # Fricción a tirones (stick-slip): pulsos irregulares a ~60 Hz
    jitter = np.abs(lowpass(rng.standard_normal(len(t)), 90)) * 6
    envelope = np.clip(t / 0.004, 0, 1) * np.exp(-((t / length) ** 2) * 3)
    x = band(n, 700, 5000) * (0.4 + jitter) * envelope
    out = np.zeros_like(t)
    for i, f in enumerate(freqs):
        # Las resonancias bajan un poco de tono mientras el filo se desliza
        for seg_start in range(0, len(t), 2048):
            seg = slice(seg_start, min(seg_start + 2048, len(t)))
            fc = f * (1 - slide * min(1.0, seg_start / SR / length))
            b, a = signal.iirpeak(fc, 18, fs=SR)
            out[seg] += signal.lfilter(b, a, x[seg]) / (i + 1)
    return amp * out


def deflect(variant):
    """Desvío: choque de espada contra espada que 'rechina' y resuena. El sonido 'premio'."""
    t = t_axis(1.2)
    f0 = 880 * (1 + 0.05 * (variant - 2))
    x = noise_burst(t, 1500, 5000, 0.008, 0.9)                               # contacto
    x += scrape(t, 0.16 + 0.03 * variant, [f0 * 1.31, f0 * 2.47, f0 * 3.6], 2.2)  # chirrido metálico
    # Timbre de hoja (proporciones de una barra de acero), sin agudos chillones
    x += 0.5 * ring(t, f0, [1.0, 2.756, 5.404], [1, 0.45, 0.15], [0.55, 0.3, 0.12], 1.004)
    x += 0.35 * ring(t, 340 + 15 * variant, [1.0, 1.52], [1, 0.5], [0.2, 0.12])     # cuerpo
    x += thump(t, 150, 65, 0.07, 1.0)
    x = lowpass(x, 6500)
    return reverb(x, 0.8, 0.2)


def block(variant):
    """Bloqueo: choque más sordo y corto que el desvío (para que el desvío destaque)."""
    t = t_axis(0.6)
    x = noise_burst(t, 600, 3500, 0.03, 1.0)
    x += scrape(t, 0.07, [560 + 30 * variant, 1300], 0.9, 0.04)
    x += 0.4 * ring(t, 520 + 30 * variant, [1.0, 2.756], [1, 0.3], [0.14, 0.07])
    x += thump(t, 140, 60, 0.08, 1.1)
    x = lowpass(x, 5000)
    return reverb(x, 0.5, 0.12)


def hit(variant):
    """Golpe que conecta: impacto grave + corte."""
    t = t_axis(0.5)
    x = thump(t, 120 + 10 * variant, 50, 0.09, 1.2)
    x += noise_burst(t, 250, 1800, 0.07, 0.9)
    x += noise_burst(t, 3500, 9000, 0.025, 0.35)                          # filo
    return reverb(x, 0.4, 0.1)


def swing(variant):
    """Tajo al aire (whoosh): ruido con filtro que barre de grave a agudo y vuelve."""
    dur = 0.32 + 0.03 * variant
    t = t_axis(dur)
    n = rng.standard_normal(len(t))
    # Filtro de un polo con frecuencia de corte variable
    cutoff = 500 + 3200 * np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 2
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(n)
    for i in range(1, len(n)):
        y[i] = (1 - a[i]) * n[i] + a[i] * y[i - 1]
    y = highpass(y, 200)
    envelope = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 3
    return y * envelope


def posture_break(variant):
    """Postura rota: crujido + resonancia grave, como un gong de metal golpeado."""
    t = t_axis(1.6)
    x = noise_burst(t, 1500, 9000, 0.02, 1.2)
    x += 0.6 * ring(t, 190, [1.0, 1.47, 2.09, 2.56, 3.9], [1, 0.8, 0.6, 0.4, 0.25], [1.1, 0.8, 0.6, 0.4, 0.2], 1.006)
    x += thump(t, 110, 40, 0.15, 1.3)
    return reverb(x, 1.0, 0.25)


def deathblow(variant):
    """Golpe mortal: impacto profundo + corte + eco largo."""
    t = t_axis(1.5)
    x = thump(t, 90, 35, 0.22, 1.6)
    x += noise_burst(t, 200, 1500, 0.12, 1.0)
    x += noise_burst(t, 3000, 10000, 0.05, 0.5)
    x += 0.25 * ring(t, 300, [1.0, 1.52, 2.4], [1, 0.6, 0.3], [0.9, 0.5, 0.3])
    return reverb(x, 1.2, 0.28)


def glint(variant):
    """Destello del filo enemigo: 'ting' agudo y breve. Avisa sin tapar el combate."""
    t = t_axis(0.45)
    x = ring(t, 2300 + 120 * variant, [1.0, 1.53], [1, 0.3], [0.1, 0.05])
    attack = np.clip(t / 0.004, 0, 1)
    return reverb(x * attack, 0.4, 0.15)


SOUNDS = {
    "deflect": (deflect, 3),
    "block": (block, 3),
    "hit": (hit, 3),
    "swing": (swing, 4),
    "posture_break": (posture_break, 1),
    "deathblow": (deathblow, 2),
    "glint": (glint, 2),
}

if __name__ == "__main__":
    print("Generando sonidos en", os.path.abspath(OUT))
    for name, (fn, count) in SOUNDS.items():
        for v in range(1, count + 1):
            save(f"{name}_{v}", fn(v), -1.0 if name != "glint" else -6.0)
