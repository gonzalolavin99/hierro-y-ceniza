"""Genera las voces del juego en local con Kokoro (gratis, sin internet, licencia Apache 2.0).

Ejecutar desde G:\\Game con el Python del entorno de voz:
    G:\\Herramientas\\tts\\venv\\Scripts\\python tools/gen_voices.py          (solo las que faltan)
    G:\\Herramientas\\tts\\venv\\Scripts\\python tools/gen_voices.py --all    (rehace todas)

Lee tools/voice_lines.json (lo genera game/tests/export_voice_script.gd a partir de voice_lines.gd)
y escribe game/assets/audio/voice/<personaje>/<id>.wav, que el autoload Voice reproduce.
"""
import json
import os
import sys

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
MODELS = r"G:\Herramientas\tts\models"
OUT = os.path.join(ROOT, "game", "assets", "audio", "voice")
LINES = os.path.join(ROOT, "tools", "voice_lines.json")

# Voz de Kokoro y tratamiento por personaje (voces elegidas por tono medido: graves y masculinas).
#   speed: velocidad del habla · pitch: <1 más grave (y algo más lento) · grit: aspereza (0 = limpia)
#   reverb: eco de sala (0 = seco)
SPEAKERS = {
    "kael": {"voice": "bm_daniel", "lang": "en-gb", "speed": 1.0, "pitch": 0.97, "grit": 0.0, "reverb": 0.0},
    "soldier": {"voice": "am_onyx", "lang": "en-us", "speed": 1.0, "pitch": 1.0, "grit": 0.35, "reverb": 0.0},
    "kael_scene": {"voice": "bm_daniel", "lang": "en-gb", "speed": 0.95, "pitch": 0.97, "grit": 0.0, "reverb": 0.12},
    "varga": {"voice": "bf_isabella", "lang": "en-gb", "speed": 1.0, "pitch": 0.95, "grit": 0.12, "reverb": 0.0},
    "regent": {"voice": "bm_george", "lang": "en-gb", "speed": 0.9, "pitch": 0.95, "grit": 0.0, "reverb": 0.3},
    "narrator": {"voice": "bm_lewis", "lang": "en-gb", "speed": 0.82, "pitch": 0.93, "grit": 0.1, "reverb": 0.22},
}
# Duración máxima de los esfuerzos (gritos y quejidos), en segundos; los de muerte duran algo más.
EFFORT_MAX = 1.1
EFFORT_LONG_MAX = 2.2
LONG_EVENTS = {"death", "broken", "deathblow"}


def trim_silence(x, sr, threshold=0.012):
    loud = np.where(np.abs(x) > threshold)[0]
    if len(loud) == 0:
        return x
    start = max(loud[0] - int(0.02 * sr), 0)
    end = min(loud[-1] + int(0.08 * sr), len(x))
    return x[start:end]


def change_pitch(x, factor):
    """Remuestreo simple: factor < 1 baja el tono (y alarga un poco la voz, como alguien mayor)."""
    if abs(factor - 1.0) < 1e-3:
        return x
    n = int(len(x) / factor)
    return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)


def add_grit(x, amount):
    if amount <= 0:
        return x
    drive = 1.0 + amount * 6.0
    return (1 - amount) * x + amount * np.tanh(x * drive) / np.tanh(drive)


def add_reverb(x, sr, mix, seconds=0.6):
    if mix <= 0:
        return x
    rng = np.random.default_rng(3)
    t = np.arange(int(seconds * sr)) / sr
    ir = rng.standard_normal(len(t)) * np.exp(-t / (seconds / 4))
    ir /= np.sqrt(np.sum(ir ** 2))
    wet = np.convolve(x, ir)[: len(x) + len(t) // 2]
    dry = np.pad(x, (0, len(wet) - len(x)))
    return (1 - mix) * dry + mix * wet


def fade(x, sr, fade_in=0.01, fade_out=0.06):
    a, b = int(fade_in * sr), int(fade_out * sr)
    x = x.copy()
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b and len(x) > b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def normalize(x, peak_db):
    peak = np.max(np.abs(x))
    return x if peak < 1e-6 else x * (10 ** (peak_db / 20) / peak)


# Nombres de letras en fonemas: si aparecen, la voz va a deletrear ("Hh!" -> "eich-eich") en vez de
# hacer el sonido. Se detiene la generación para cambiar la interjección en voice_lines.gd.
SPELLED_LETTERS = ["eɪtʃ", "ˌɛm", "ˌɛn", "ˌɛf", "ˌɛs", "ˌiː", "dʒˌiː"]


def check_pronunciation(kokoro, speaker, line):
    phonemes = kokoro.tokenizer.phonemize(line["text"], SPEAKERS[speaker]["lang"])
    spelled = [p for p in SPELLED_LETTERS if p in phonemes]
    if spelled:
        raise SystemExit(f"ERROR {line['id']}: «{line['text']}» se leería deletreado ({phonemes}). "
                         "Cambiar la interjección en game/scripts/systems/voice_lines.gd.")


def render(kokoro, speaker, line):
    cfg = SPEAKERS[speaker]
    text = line["text"]
    effort = not line["phrase"]
    # Los esfuerzos se dicen algo más rápido y con más energía.
    speed = cfg["speed"] * (1.1 if effort else 1.0)
    samples, sr = kokoro.create(text, voice=cfg["voice"], speed=speed, lang=cfg["lang"])
    x = trim_silence(np.asarray(samples, dtype=np.float64), sr)
    x = change_pitch(x, cfg["pitch"])
    x = add_grit(x, cfg["grit"])
    if effort:
        limit = EFFORT_LONG_MAX if line["event"] in LONG_EVENTS else EFFORT_MAX
        x = x[: int(limit * sr)]
    x = add_reverb(x, sr, cfg["reverb"])
    x = fade(x, sr, fade_out=0.12 if effort else 0.06)
    return normalize(x, -3.0 if effort else -2.0), sr


def main():
    redo = "--all" in sys.argv
    with open(LINES, encoding="utf-8") as f:
        data = json.load(f)
    kokoro = Kokoro(os.path.join(MODELS, "kokoro-v1.0.onnx"), os.path.join(MODELS, "voices-v1.0.bin"))
    made, skipped = 0, 0
    for speaker, lines in data.items():
        folder = os.path.join(OUT, speaker)
        os.makedirs(folder, exist_ok=True)
        for line in lines:
            path = os.path.join(folder, line["id"] + ".wav")
            if os.path.exists(path) and not redo:
                skipped += 1
                continue
            if not line["phrase"]:
                check_pronunciation(kokoro, speaker, line)
            x, sr = render(kokoro, speaker, line)
            if len(x) < int(0.08 * sr):
                print(f"  AVISO {line['id']}: salió casi vacío ({len(x) / sr:.2f} s); revisar el texto «{line['text']}»")
            sf.write(path, x.astype(np.float32), sr, subtype="PCM_16")
            made += 1
            print(f"  {line['id']:<20} {len(x) / sr:4.2f} s  «{line['text']}»")
    print(f"Hechas {made}, ya existían {skipped}.")


if __name__ == "__main__":
    main()
