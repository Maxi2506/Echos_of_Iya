# Echoes of Iya

Plataformero 2D en pixel art hecho con **Godot 4.4**, ambientado en el Valle de Iya (Japón).
Dos niveles: **El Valle** (bosque, castillo y puente, termina en un torii) y **Las Ruinas**
(cuevas oscuras bajo el castillo, termina en el Cristal del Eco).

## Cómo jugar

| Acción | Teclado | Joystick |
|---|---|---|
| Moverse | ← → | Cruceta / stick |
| Saltar (mantener = más alto) | Espacio | A |
| Atacar (también en el aire) | X | X |
| Caminar en sigilo | Shift | LB |
| Pausa | Esc / P | Start |
| Mapa | M | Select |

- **3 corazones.** Los enemigos quitan uno por golpe; los pozos matan de una.
- **Fogatas:** al pasar se encienden, curan y guardan. Al morir volvés a la última.
  Lo que hiciste antes de la fogata queda hecho; lo de después (enemigos, cristales) vuelve.
- **Sigilo:** caminando con Shift los enemigos solo te ven de muy cerca. Si te ven, muestran "!".
- **Cristales** = puntos. **Secretos:** paredes que parecen sólidas pero se pueden atravesar.
- Opciones: volumen, dificultad (velocidad de los enemigos) e idioma (español / inglés).

## Estructura

```
scenes/levels/     level_1.tscn y level_2.tscn (generados, ver abajo)
scenes/enemies/    caballero, kitsune, serpiente y rana (generados)
scenes/level/      meta, plataforma móvil, fin de nivel, mapa
scenes/            jugador, menús, HUD, pausa, muerte, fogata, cristal...
scripts/           código (cada archivo tiene comentarios al principio)
scripts/enemies/   enemy.gd: comportamiento común de todos los enemigos
tilesets/          world.tres: el TileSet compartido por los dos niveles
assets/            solo lo que el juego usa
_archivo/          assets sin usar (Godot los ignora; mover a assets/ para usarlos)
tools/             generadores (Godot también ignora esta carpeta)
```

Autoloads: `Settings` (opciones e idioma), `SaveGame` (partida y estadísticas),
`Music` y `DebugTools` (solo en pruebas).

## Modificar los niveles

Los mapas están dibujados en texto en `tools/levels/` (`level2.txt` es el nivel 2 entero;
`level1_ext.txt` es la zona final del nivel 1). Cada carácter es una celda de 16×16:

```
.  vacío        #  roca del bosque    B  piedra del castillo    =  puente de madera
F / f  pared falsa (castillo / roca): zona secreta; la sala de atrás se tapa sola
P  jugador      c  cristal            H  fogata                 G  meta
K  caballero    X  kitsune            s  serpiente              r  rana
M  plataforma móvil horizontal        V  plataforma móvil vertical
l  velas        L  farol colgante
```

Las fichas que se paran en el piso (P, H, G, enemigos, velas) van en la celda de arriba del piso.
El salto alcanza unas 3 celdas hacia arriba y 5 de ancho.

Después de editar, regenerar (desde la raíz del proyecto):

```bash
godot --headless --path . --script tools/level_builder.gd
python3 tools/fix_uids.py scenes/levels/level_1.tscn scenes/levels/level_2.tscn
```

Las zonas 1 a 4 del nivel 1 son el mapa original hecho a mano; sus enemigos y cristales
están en la lista `classic` dentro de `tools/level_builder.gd`.

## Otros generadores (en `tools/`)

- `build_enemies.py`: escenas de enemigos (vida, velocidad, tamaño, ataques).
- `generate_sprites.py`: fogata apagada, muerte del héroe, corazones y torii.
- `generate_sounds.py`: efectos de sonido (síntesis propia, sin licencias de terceros).

## Herramientas de prueba

Solo funcionan al ejecutar desde Godot (no en el juego exportado):
**F1** modo dios (volar, atravesar paredes, invencible), **F2** ir a la siguiente fogata,
**F3** alejar la cámara. Para quitarlas: borrar `scripts/debug_tools.gd` y su línea en
`[autoload]` de `project.godot`.

## Créditos y licencias

- Escenarios: packs de **Szadi art** (dominio público). Enemigos, cristales y demás: packs gratuitos
  de terceros; revisar la licencia de cada uno antes de publicar.
- Sonidos, sprites de la fogata apagada, muerte del héroe, corazones y torii: generados para este proyecto.
- **Música:** "Near Light" de Ólafur Arnalds, con derechos de autor. Sirve para uso académico;
  **reemplazarla antes de publicar el juego.**
