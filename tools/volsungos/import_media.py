"""Prepare locally owned Volsungos sources for Godot; never uploads files or changes Git ignores."""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys

from asset_manifest import ASSETS, SOURCES


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path, help="Local proyecto-volsungos directory")
    parser.add_argument("--ffmpeg", required=True, type=Path)
    args = parser.parse_args()
    missing = [args.source / filename for filename in SOURCES.values() if not (args.source / filename).is_file()]
    if missing:
        parser.error("Missing source files: " + ", ".join(str(p) for p in missing))
    if not args.ffmpeg.is_file():
        parser.error("FFmpeg executable does not exist")
    ASSETS.mkdir(parents=True, exist_ok=True)
    for name, source in SOURCES.items():
        if name.endswith(".jpg"):
            shutil.copy2(args.source / source, ASSETS / name)
    subprocess.run([str(args.ffmpeg.resolve()), "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(args.source / SOURCES["forge.ogv"]), "-t", "6", "-an",
                    "-vf", "scale=960:-2,fps=24", "-c:v", "libtheora", "-q:v", "6",
                    str(ASSETS / "forge.ogv")], check=True)
    subprocess.run([sys.executable, str(Path(__file__).with_name("asset_manifest.py"))], check=True)
    print("Local media prepared. No files uploaded.")


if __name__ == "__main__":
    main()
