"""Completa los uid que faltan en los [ext_resource] de las escenas y recursos.

Godot, al guardar escenas desde un script en modo headless, a veces escribe las
referencias solo con la ruta. Funcionan igual, pero el editor prefiere tener el uid.
Este script lo busca en el .import, el .uid o el encabezado del archivo referenciado.

Uso: python3 tools/fix_uids.py scenes/level_1.tscn [más archivos...]
"""
import os
import re
import sys


def uid_of(res_path):
    path = res_path.replace('res://', '', 1)
    for candidate in (path + '.import', path + '.uid'):
        if os.path.exists(candidate):
            m = re.search(r'uid="?(uid://[a-z0-9]+)', open(candidate, encoding='utf-8').read())
            if m:
                return m.group(1)
    if os.path.exists(path) and path.endswith(('.tscn', '.tres')):
        m = re.search(r'^\[gd_(?:scene|resource)[^\]]*uid="(uid://[a-z0-9]+)"', open(path, encoding='utf-8').read(), re.M)
        if m:
            return m.group(1)
    return None


# uid propio de los archivos que genera tools/level_builder.gd (Godot no lo escribe al guardarlos)
HEADER_UIDS = {
    'scenes/levels/level_1.tscn': 'uid://b7o8ady7oujre',
    'scenes/levels/level_2.tscn': 'uid://fy2gme8buhia',
    'tilesets/world.tres': 'uid://cchqwafeustqe',
}


def fix(file):
    text = open(file, encoding='utf-8').read()
    count = 0
    uid = HEADER_UIDS.get(file)
    if uid and not re.match(r'^\[gd_\w+[^\]]*uid=', text):
        text = re.sub(r'^(\[gd_\w+[^\]]*)\]', r'\1 uid="%s"]' % uid, text, count=1)

    def repl(m):
        nonlocal count
        uid = uid_of(m.group(2))
        if not uid:
            return m.group(0)
        count += 1
        return f'[ext_resource type="{m.group(1)}" uid="{uid}" path="{m.group(2)}"'

    text = re.sub(r'^\[ext_resource type="(\w+)" path="([^"]+)"', repl, text, flags=re.M)
    open(file, 'w', encoding='utf-8').write(text)
    print(f'{file}: {count} uid agregados')


if __name__ == '__main__':
    for f in sys.argv[1:]:
        fix(f)
