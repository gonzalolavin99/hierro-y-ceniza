"""Genera game/scenes/levels/test_level.tscn (circuito de pruebas de movimiento).
Ejecutar: python tools/gen_test_level.py"""
import math, os

nodes = []
def tf(x, y, z, rot_x_deg=0.0):
    c, s = math.cos(math.radians(rot_x_deg)), math.sin(math.radians(rot_x_deg))
    # Filas de la base (rotación alrededor de X), luego origen
    vals = [1, 0, 0, 0, c, -s, 0, s, c, x, y, z]
    return "Transform3D(" + ", ".join(f"{v:.6g}" for v in vals) + ")"

def box(name, size, pos, mat="stone", rot=0.0, collision=True, parent="Geometry"):
    nodes.append(f'[node name="{name}" type="CSGBox3D" parent="{parent}"]\n'
                 f'transform = {tf(*pos, rot)}\n'
                 + ("use_collision = true\n" if collision else "")
                 + f'size = Vector3({size[0]}, {size[1]}, {size[2]})\n'
                 f'material = SubResource("{mat}")\n')

def label(name, text, pos, size=48):
    nodes.append(f'[node name="{name}" type="Label3D" parent="Labels"]\n'
                 f'transform = {tf(*pos)}\nbillboard = 1\ntext = "{text}"\n'
                 f'font_size = {size}\noutline_size = 12\n')

def ramp(name, x, z_start, angle, height, width, mat):
    """Rampa que sube hacia -Z desde (x, 0, z_start) hasta `height`. Devuelve z final."""
    a = math.radians(angle)
    length = height / math.sin(a)
    horiz = length * math.cos(a)
    t = 0.4
    mid_y, mid_z = height / 2, z_start - horiz / 2
    cy = mid_y - math.cos(a) * t / 2
    cz = mid_z - math.sin(a) * t / 2
    box(name, (width, t, round(length, 4)), (x, cy, cz), mat, angle)
    return z_start - horiz

# 1. Bloques bajos para subirse saltando
box("Block05", (2, 0.5, 2), (-3, 0.25, -5))
box("Block12", (2, 1.2, 2), (-6, 0.6, -5))
label("LblBlocks", "Bloques 0,5 m y 1,2 m", (-4.5, 2.2, -5))

# 2. Rampa suave 20° + plataforma
H = 2.6
z_end = ramp("RampGentle", -12, -2, 20, H, 4, "wood")
box("RampGentleTop", (4, H, 6), (-12, H / 2, z_end - 3))
label("LblRampGentle", "Rampa 20°", (-12, 2.2, -3))

# 3. Rampa empinada 50° (no se puede subir caminando)
z_end = ramp("RampSteep", -18, -2, 50, 3.0, 4, "wood")
box("RampSteepTop", (4, 3.0, 4), (-18, 1.5, z_end - 2))
label("LblRampSteep", "Rampa 50° (resbala)", (-18, 2.6, -1.5))

# 4. Escaleras (visual) + rampa invisible de colisión
steps, rise, run = 10, 0.25, 0.4
for i in range(steps):
    h = (i + 1) * rise
    box(f"Step{i+1}", (3, h, run), (8, h / 2, -3 - run * i - run / 2), "stone", 0, collision=False)
stair_h, stair_len = steps * rise, steps * run
box("StairTop", (3, stair_h, 4), (8, stair_h / 2, -3 - stair_len - 2))
label("LblStairs", "Escaleras", (8, 1.8, -2.5))

# 5. Circuito de saltos a 2,5 m de altura (huecos de 2 / 2,5 / 3 / 4 m)
z = -3 - stair_len - 4  # borde final de StairTop
for i, (gap, depth) in enumerate([(2.0, 3), (2.5, 3), (3.0, 4), (5.5, 4)]):
    start = z - gap
    box(f"JumpPlat{i+1}", (3, stair_h, depth), (8, stair_h / 2, start - depth / 2))
    label(f"LblGap{i+1}", f"{gap:g} m" + (" (corriendo)" if gap >= 4 else ""), (8, stair_h + 1.2, z - gap / 2))
    z = start - depth

# 6. Túnel para probar la cámara
box("TunnelL", (1, 3, 6), (-1.75, 1.5, -11))
box("TunnelR", (1, 3, 6), (1.75, 1.5, -11))
box("TunnelRoof", (4.5, 0.5, 6), (0, 3.25, -11), "dark")
label("LblTunnel", "Túnel (cámara)", (0, 4.2, -7.8))

# 7. Muro alto
box("Wall", (12, 6, 1), (0, 3, -22), "dark")

# Escena completa
header = '''[gd_scene format=3]

[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="1_player"]
[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="2_hud"]
[ext_resource type="Script" path="res://tests/posture_plate.gd" id="3_plate"]

[sub_resource type="ProceduralSkyMaterial" id="sky_material"]
sky_top_color = Color(0.32, 0.37, 0.44, 1)
sky_horizon_color = Color(0.66, 0.62, 0.56, 1)
ground_bottom_color = Color(0.16, 0.15, 0.14, 1)
ground_horizon_color = Color(0.66, 0.62, 0.56, 1)

[sub_resource type="Sky" id="sky"]
sky_material = SubResource("sky_material")

[sub_resource type="Environment" id="environment"]
background_mode = 2
sky = SubResource("sky")
ambient_light_source = 3
tonemap_mode = 2
fog_enabled = true
fog_light_color = Color(0.6, 0.58, 0.54, 1)
fog_density = 0.012

[sub_resource type="StandardMaterial3D" id="ground_material"]
albedo_color = Color(0.33, 0.31, 0.27, 1)

[sub_resource type="PlaneMesh" id="ground_mesh"]
material = SubResource("ground_material")
size = Vector2(120, 120)

[sub_resource type="BoxShape3D" id="ground_shape"]
size = Vector3(120, 1, 120)

[sub_resource type="StandardMaterial3D" id="stone"]
albedo_color = Color(0.52, 0.5, 0.47, 1)

[sub_resource type="StandardMaterial3D" id="wood"]
albedo_color = Color(0.45, 0.33, 0.22, 1)

[sub_resource type="StandardMaterial3D" id="dark"]
albedo_color = Color(0.25, 0.24, 0.23, 1)

[sub_resource type="StandardMaterial3D" id="plate_material"]
albedo_color = Color(0.75, 0.15, 0.1, 1)

[sub_resource type="BoxShape3D" id="plate_shape"]
size = Vector3(2.5, 1, 2.5)

'''
stair_angle = math.degrees(math.atan2(stair_h, stair_len))
stair_ramp_len = math.hypot(stair_h, stair_len)
header += f'''[sub_resource type="BoxShape3D" id="stair_ramp_shape"]
size = Vector3(3, 0.2, {stair_ramp_len + 0.3:.4f})

'''
a = math.radians(stair_angle)
sr_y = stair_h / 2 - math.cos(a) * 0.1
sr_z = -3 - stair_len / 2 - math.sin(a) * 0.1

body = f'''[node name="TestLevel" type="Node3D"]

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("environment")

[node name="Sun" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866025, 0.25, -0.433013, 0, 0.866025, 0.5, 0.5, -0.433013, 0.75, 0, 10, 0)
light_color = Color(1, 0.93, 0.82, 1)
shadow_enabled = true

[node name="Ground" type="StaticBody3D" parent="."]

[node name="Mesh" type="MeshInstance3D" parent="Ground"]
mesh = SubResource("ground_mesh")

[node name="Collision" type="CollisionShape3D" parent="Ground"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, 0)
shape = SubResource("ground_shape")

[node name="Geometry" type="Node3D" parent="."]

[node name="StairRamp" type="StaticBody3D" parent="."]

[node name="Collision" type="CollisionShape3D" parent="StairRamp"]
transform = {tf(8, sr_y, sr_z, stair_angle)}
shape = SubResource("stair_ramp_shape")

[node name="PosturePlate" type="Area3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 5, 0, 3)
collision_mask = 2
script = ExtResource("3_plate")

[node name="Collision" type="CollisionShape3D" parent="PosturePlate"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
shape = SubResource("plate_shape")

[node name="Visual" type="CSGBox3D" parent="PosturePlate"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.03, 0)
size = Vector3(2.5, 0.06, 2.5)
material = SubResource("plate_material")

[node name="Labels" type="Node3D" parent="."]

[node name="Title" type="Label3D" parent="Labels"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.2, -21.4)
text = "HIERRO Y CENIZA
Hito 1 · Movimiento"
font_size = 110
outline_size = 18

[node name="Player" parent="." instance=ExtResource("1_player")]

[node name="HUD" parent="." instance=ExtResource("2_hud")]

'''
label("LblPlate", "Placa de postura (quédate encima)", (5, 1.6, 3))

out = os.path.join(os.path.dirname(__file__), "..", "game", "scenes", "levels", "test_level.tscn")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    f.write(header + body + "\n".join(nodes))
print("Escrito", os.path.abspath(out), "-", len(nodes), "nodos generados")
