"""Rebuild provenance hashes after intentionally changing a bundled Volsungos asset."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "game/assets/volsungos"
SOURCES = {
    "hall.jpg": "dossier-productor-e01-v01/revision/F01_BARNSTOKKR_V03.jpg",
    "sigurd.jpg": "vistas-aprobados-v09/SIGURD-APROBADO-preview.jpg",
    "siggeir.jpg": "vistas-aprobados-v09/SIGGEIR-APROBADO-preview.jpg",
    "signy.jpg": "vistas-aprobados-v09/SIGNY-APROBADO-preview.jpg",
    "forge.ogv": "video/V07_FORGE.mp4",
}


if __name__ == "__main__":
    manifest = {
        "project": "Los Volsungos",
        "source_root": "proyecto-volsungos",
        "integration": "dev/volsungos-3d",
        "source_type": "AI-generated 2D renders and prerendered video; no source meshes or rigs supplied",
        "authorization": "Project owner requested reuse in hierro-y-ceniza on 2026-11-15",
        "files": [],
    }
    for filename, source in SOURCES.items():
        content = (ASSETS / filename).read_bytes()
        manifest["files"].append({
            "file": filename, "source": source, "bytes": len(content),
            "sha256": hashlib.sha256(content).hexdigest(),
            "processing": "First 6 seconds, 960px wide, 24fps, Theora q6, silent" if filename.endswith("ogv") else "Unmodified existing JPEG preview",
        })
    (ASSETS / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Manifest: {len(SOURCES)} assets, {sum(f['bytes'] for f in manifest['files']):,} bytes")
