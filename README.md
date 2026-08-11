# Murder Mystery — LAN Game
Godot 4 / Android APK / Up to 5 players on same WiFi

## Roles
| Players | Murderer | Sheriff | Innocents |
|---------|----------|---------|-----------|
| 2       | 1        | 1       | 0         |
| 3-5     | 1        | 1       | rest      |

## Rules
- **Murderer** — stab innocents with knife (melee)
- **Sheriff** — shoot murderer (ranged). Shoots innocent → dies, drops gun
- **Innocent** — survive. Pick up dropped gun → becomes **Hero**
- **Hero** — can shoot. Shoots murderer → innocents win. Shoots innocent → dies

## Maps
- Mansion — corridor-room layout
- Workshop — shelves and machinery
- Rooftop — open with cover

## Build (GitHub Actions)
1. Push to `main` branch
2. Actions builds APK automatically
3. Download from Actions → Artifacts

## Local build
```bash
godot --headless --export-debug "Android" build/MurderMystery.apk
```

## Controls
| Control | Desktop | Mobile |
|---------|---------|--------|
| Move | WASD / Arrow | Left joystick |
| Look | Mouse | Right drag |
| Jump | Space | JUMP button |
| Action | F | ACTION button |

## Network
- Default port: **7777** (UDP)
- Host: tap "HOST GAME", share your IP
- Join: enter host IP, tap "JOIN GAME"
