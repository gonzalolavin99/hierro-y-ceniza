"""Run the art room without installing the game's separately licensed Mixamo files.

python tools/volsungos/preview.py --godot /path/to/godot [--test] [--capture /path/to/frame.png]
Only our assets/scripts are copied into a disposable project. The original game is not modified.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--test", action="store_true")
    parser.add_argument("--capture", type=Path)
    parser.add_argument("--without-media", action="store_true", help="Test the public checkout without local renders/video")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    # Windows graphics drivers may briefly retain shader-cache files after process exit.
    with tempfile.TemporaryDirectory(prefix="hierro-volsungos-", ignore_cleanup_errors=True) as directory:
        target = Path(directory)
        for folder in ["scenes/volsungos", "assets/volsungos"]:
            excluded = ["*.import"]
            if args.without_media and folder.startswith("assets"):
                excluded += ["*.jpg", "*.ogv", "*.uid", "manifest.json"]
            shutil.copytree(repo / "game" / folder, target / folder,
                            ignore=shutil.ignore_patterns(*excluded))
        (target / "tests").mkdir()
        shutil.copy2(repo / "game/tests/volsungos_test.gd", target / "tests/volsungos_test.gd")
        (target / "project.godot").write_text('''config_version=5
[application]
config/name="Volsungos Art Review"
run/main_scene="res://scenes/volsungos/visual_review.tscn"
[display]
window/size/viewport_width=1600
window/size/viewport_height=1000
window/size/window_width_override=1280
window/size/window_height_override=800
window/stretch/mode="canvas_items"
[rendering]
renderer/rendering_method="gl_compatibility"
''', encoding="utf-8")
        env = os.environ.copy()
        # Keep Godot's disposable editor/user data inside the disposable project too.
        env["APPDATA"] = str(target / "appdata")
        env["XDG_DATA_HOME"] = str(target / "appdata")
        env["XDG_CONFIG_HOME"] = str(target / "config")
        (target / "appdata").mkdir()
        engine = str(Path(args.godot).resolve())
        base = [engine, "--path", str(target)]
        result = subprocess.run(base + ["--headless", "--editor", "--import", "--quit"],
                                env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
        if result.returncode or "SCRIPT ERROR" in result.stdout + result.stderr:
            print(result.stdout + result.stderr)
            raise SystemExit(result.returncode or 1)
        command = base
        if args.test:
            command += ["--headless", "--script", "res://tests/volsungos_test.gd"]
        elif args.capture:
            capture = args.capture.resolve().as_posix()
            (target / "capture.gd").write_text('''extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene = load("res://scenes/volsungos/visual_review.tscn").instantiate()
    root.add_child(scene)
    await create_timer(1.0).timeout
    await RenderingServer.frame_post_draw
    var result = root.get_texture().get_image().save_png(%r)
    quit(result)
''' % capture, encoding="utf-8")
            command += ["--script", "res://capture.gd"]
        result = subprocess.run(command, env=env, capture_output=args.test or bool(args.capture),
                                text=True, encoding="utf-8", errors="replace",
                                timeout=90 if args.test or args.capture else None)
        if args.test or args.capture:
            print(result.stdout + result.stderr)
            if "SCRIPT ERROR" in result.stdout + result.stderr or "ERROR:" in result.stdout + result.stderr:
                raise SystemExit(1)
        code = result.returncode
    raise SystemExit(code)


if __name__ == "__main__":
    main()
