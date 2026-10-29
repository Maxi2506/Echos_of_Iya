"""Genera las escenas de los enemigos (scenes/enemies/*.tscn) a partir de sus hojas de sprites.

Uso (desde la raíz del proyecto):
    python3 tools/build_enemies.py

Para ajustar un enemigo (velocidad, vida, tamaño...) se cambia su entrada en ENEMIES
y se vuelve a correr el script.
"""

KILLZONE = ('uid://5gxckvplnwm2', 'res://scenes/killzone.tscn')
ENEMY_SCRIPT = ('uid://bjp1rnchkurdu', 'res://scripts/enemies/enemy.gd')
FROG_SCRIPT = ('uid://dhg2jytm6ius3', 'res://scripts/enemies/frog.gd')
SFX = {
    'hit': ('uid://g3hdfbjj52lo', 'res://assets/sfx/enemy_hit.wav'),
    'death': ('uid://iawqd15qku2d', 'res://assets/sfx/enemy_death.wav'),
    'slash': ('uid://iufy2hgq34gb', 'res://assets/sfx/sword_slash.wav'),
}

KNIGHT_DIR = 'res://assets/img/enemigos/yokai_knight/'
KITSUNE_DIR = 'res://assets/img/enemigos/yokai1/'
CRITTERS_DIR = 'res://assets/img/escenario/EnderDream3/'

ENEMIES = {
    'knight': {
        'uid': 'uid://bwnsf87h20ooj',
        'script': ENEMY_SCRIPT,
        'frame': (120, 80),
        # posición del dibujo respecto de los pies y escala (la que ya tenía en el juego)
        'sprite_pos': (0, -38.66), 'scale': (0.79, 0.96),
        'animations': {
            # nombre: (uid, archivo, cuadros, velocidad, loop, cuadros a usar)
            'idle': ('uid://cnnwi87r5dnis', KNIGHT_DIR + '_Idle.png', 10, 8, True, None),
            'run': ('uid://bn1ljab8t7apn', KNIGHT_DIR + '_Run.png', 10, 10, True, None),
            'attack': ('uid://6ty62bubokg6', KNIGHT_DIR + '_Attack.png', 4, 8, False, None),
            'hit': ('uid://ipnep5dx1h8y', KNIGHT_DIR + '_Hit.png', 1, 5, False, None),
            'death': ('uid://bgdgdrb33tgh6', KNIGHT_DIR + '_Death.png', 10, 12, False, None),
        },
        'body': (16, 36), 'contact': (14, 32),
        'attack_area': {'size': (40, 30), 'x': 24, 'y': -16},
        'attack_sound_pitch': 0.8,
        'props': {
            'max_health': 2, 'patrol_speed': 40.0, 'chase_speed': 75.0, 'detect_range': 130.0,
            'attack_range': 34.0, 'attack_active_frames': 'PackedInt32Array(1, 2)', 'attack_cooldown': 1.2,
            'faces_right': True, 'sprite_offset_x': 4.0, 'body_half_width': 8.0,
        },
    },
    'kitsune': {
        'uid': 'uid://x006kh6ex0x4',
        'script': ENEMY_SCRIPT,
        'frame': (148, 96),
        'sprite_pos': (0, -25.8), 'scale': (0.6, 0.6),
        'animations': {
            'idle': ('uid://ce5jl2trd568c', KITSUNE_DIR + 'IDLE.png', 6, 8, True, None),
            'run': ('uid://d2atrrrrnbo3e', KITSUNE_DIR + 'RUN.png', 8, 12, True, None),
            'attack': ('uid://bj7uae5npuoxw', KITSUNE_DIR + 'ATTACK 1.png', 5, 10, False, None),
        },
        'body': (16, 34), 'contact': (14, 30),
        'attack_area': {'size': (40, 26), 'x': 22, 'y': -14},
        'attack_sound_pitch': 1.25,
        'props': {
            'max_health': 2, 'patrol_speed': 55.0, 'chase_speed': 115.0, 'detect_range': 150.0,
            'attack_range': 40.0, 'attack_active_frames': 'PackedInt32Array(2, 3)', 'attack_cooldown': 0.9,
            'faces_right': True, 'sprite_offset_x': 13.0, 'body_half_width': 8.0,
            'death_color': 'Color(0.35, 0.7, 1, 1)',
        },
    },
    'snake': {
        'uid': 'uid://bteiief87kaii',
        'script': ENEMY_SCRIPT,
        'frame': (23, 16),
        'sprite_pos': (0, -8), 'scale': (1, 1),
        'animations': {
            'idle': ('uid://dxevobu7n34xh', CRITTERS_DIR + 'Snake - 6F.png', 6, 6, True, None),
            'run': ('uid://dxevobu7n34xh', CRITTERS_DIR + 'Snake - 6F.png', 6, 8, True, None),
        },
        'body': (18, 10), 'contact': (16, 9),
        'props': {
            'max_health': 1, 'patrol_speed': 22.0, 'can_chase': False,
            'faces_right': True, 'body_half_width': 9.0,
            'death_color': 'Color(0.6, 0.75, 0.25, 1)',
        },
    },
    'frog': {
        'uid': 'uid://cv6jfut6csd2',
        'script': FROG_SCRIPT,
        'frame': (27, 20),
        'sprite_pos': (0, -9), 'scale': (1, 1),
        'animations': {
            'idle': ('uid://dw1quw8g7k5um', CRITTERS_DIR + 'Frog - 14F.png', 14, 8, True, [0, 1, 2, 3, 4, 1]),
            'jump': ('uid://dw1quw8g7k5um', CRITTERS_DIR + 'Frog - 14F.png', 14, 14, False, [5, 6, 7, 8, 9, 10, 11, 12, 13]),
            'run': ('uid://dw1quw8g7k5um', CRITTERS_DIR + 'Frog - 14F.png', 14, 8, True, [0]),
        },
        'body': (18, 14), 'contact': (16, 12),
        'props': {
            'max_health': 1, 'detect_range': 110.0, 'sneak_detect_range': 30.0,
            'faces_right': False, 'body_half_width': 9.0,
            'death_color': 'Color(0.7, 0.7, 0.25, 1)',
        },
    },
}


def fmt(v):
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, float):
        return repr(v)
    return str(v)


def build(name, cfg):
    ext, subs, nodes = [], [], []
    ext_ids = {}

    def ext_res(kind, uid, path):
        key = (kind, path)
        if key not in ext_ids:
            ext_ids[key] = f'{len(ext_ids) + 1}_{name[:4]}'
            ext.append(f'[ext_resource type="{kind}" uid="{uid}" path="{path}" id="{ext_ids[key]}"]')
        return ext_ids[key]

    script_id = ext_res('Script', *cfg['script'])
    killzone_id = ext_res('PackedScene', *KILLZONE)

    fw, fh = cfg['frame']
    anim_entries = []
    for anim, (uid, path, count, speed, loop, picks) in cfg['animations'].items():
        tex = ext_res('Texture2D', uid, path)
        frames = []
        for i in (picks if picks is not None else range(count)):
            sid = f'AtlasTexture_{anim}{i}'
            if not any(s.startswith(f'[sub_resource type="AtlasTexture" id="{sid}"]') for s in subs):
                subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("{tex}")\nregion = Rect2({i * fw}, 0, {fw}, {fh})')
            frames.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sid)
        anim_entries.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % (
            ', '.join(frames), fmt(loop), anim, float(speed)))
    subs.append('[sub_resource type="SpriteFrames" id="SpriteFrames_main"]\nanimations = [%s]' % ', '.join(anim_entries))

    bw, bh = cfg['body']
    cw, ch = cfg['contact']
    subs.append(f'[sub_resource type="RectangleShape2D" id="Shape_body"]\nsize = Vector2({bw}, {bh})')
    subs.append(f'[sub_resource type="RectangleShape2D" id="Shape_contact"]\nsize = Vector2({cw}, {ch})')

    props = '\n'.join(f'{k} = {fmt(v)}' for k, v in cfg['props'].items())
    sx, sy = cfg['sprite_pos']
    kx, ky = cfg['scale']
    nodes.append(f'[node name="{name}" type="CharacterBody2D"]\ncollision_layer = 4\nscript = ExtResource("{script_id}")\n{props}')
    nodes.append(f'[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]\nposition = Vector2({sx}, {sy})\n'
                 f'scale = Vector2({kx}, {ky})\nsprite_frames = SubResource("SpriteFrames_main")\nanimation = &"idle"\nautoplay = "idle"')
    nodes.append(f'[node name="CollisionShape2D" type="CollisionShape2D" parent="."]\nposition = Vector2(0, {-bh / 2})\nshape = SubResource("Shape_body")')
    nodes.append(f'[node name="killzone" parent="." instance=ExtResource("{killzone_id}")]')
    nodes.append(f'[node name="CollisionShape2D" type="CollisionShape2D" parent="killzone"]\nposition = Vector2(0, {-ch / 2})\nshape = SubResource("Shape_contact")')

    if 'attack_area' in cfg:
        aa = cfg['attack_area']
        subs.append(f'[sub_resource type="RectangleShape2D" id="Shape_attack"]\nsize = Vector2({aa["size"][0]}, {aa["size"][1]})')
        nodes.append(f'[node name="AttackArea" parent="." instance=ExtResource("{killzone_id}")]')
        nodes.append(f'[node name="CollisionShape2D" type="CollisionShape2D" parent="AttackArea"]\nposition = Vector2({aa["x"]}, {aa["y"]})\nshape = SubResource("Shape_attack")')
        slash = ext_res('AudioStream', *SFX['slash'])
        nodes.append(f'[node name="AttackSound" type="AudioStreamPlayer2D" parent="."]\nstream = ExtResource("{slash}")\n'
                     f'volume_db = -6.0\npitch_scale = {cfg["attack_sound_pitch"]}\nbus = &"SFX"')

    hit = ext_res('AudioStream', *SFX['hit'])
    death = ext_res('AudioStream', *SFX['death'])
    nodes.append(f'[node name="HitSound" type="AudioStreamPlayer2D" parent="."]\nstream = ExtResource("{hit}")\nbus = &"SFX"')
    nodes.append(f'[node name="DeathSound" type="AudioStreamPlayer2D" parent="."]\nstream = ExtResource("{death}")\nvolume_db = -6.0\nbus = &"SFX"')

    text = f'[gd_scene load_steps={len(ext) + len(subs) + 1} format=3 uid="{cfg["uid"]}"]\n\n'
    text += '\n'.join(ext) + '\n\n' + '\n\n'.join(subs) + '\n\n' + '\n\n'.join(nodes) + '\n'
    with open(f'scenes/enemies/{name}.tscn', 'w') as f:
        f.write(text)


if __name__ == '__main__':
    import os
    os.makedirs('scenes/enemies', exist_ok=True)
    for enemy_name, enemy_cfg in ENEMIES.items():
        build(enemy_name, enemy_cfg)
    print('Escenas de enemigos generadas:', ', '.join(ENEMIES))
