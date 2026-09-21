# Backyard Mayhem

Comedy roguelike shooter with tower-defence elements, built in **Godot 4.7.2** with GDScript.

## Test

```bash
$GODOT_BIN --headless --path . --script res://tests/run_all.gd
```

## Art pipeline

Original uploaded sprite sheets are preserved under `assets/source/`. Runtime-ready transparent/cropped frames are generated into the derived `assets/*` folders; source art is never destructively edited.
