<p align="center">
  <img src="logo.png" width="160" alt="Space Explorer logo">
</p>

# Space Explorer

**Plan your expedition. Pilot your ship. Explore another world.**

A 3D space exploration game built with **Godot 4.7**, developed in the **NASA-SpaceApps-2026** repository. Prepare a mission inside your spacecraft, navigate an asteroid field, and land on one of **14 destinations** to explore on foot. Bring your equipment, keep an eye on the ship's resources, and decide whether Rocky joins the expedition.

![Space Explorer main menu](docs/images/main-menu.png)

[Gameplay](#the-expedition-loop) · [Worlds and weather](#worlds-and-weather) · [Controls](#controls) · [Run the project](#run-the-project) · [Credits](#credits)

## The expedition loop

1. **Prepare in the cabin.** Look directly at the mission desk to reveal the contextual interaction options.
2. **Plan with E.** Choose a destination and objective, select equipment, check weight, load fuel, repair the ship, and choose whether to bring Rocky.
3. **Create an expedition.** The trip is registered in the mission panel and selected equipment appears in the backpack.
4. **Pilot with Q.** Leave the interior view and control the spacecraft through the surrounding asteroid field.
5. **Land and explore.** Enter a planet's approach zone to trigger the loading transition. The ship appears landed, with the astronaut outside.
6. **Return to space.** Walk close to the landed ship and press Q to take off.

<p>
  <img src="docs/images/spaceflight.png" width="49%" alt="Spaceflight with engine effects, asteroid field and ship resource HUD">
  <img src="docs/images/cockpit.png" width="49%" alt="The spacecraft cockpit and mission desk">
</p>

## Plan before you launch

The fullscreen mission planner brings the destination, equipment and ship resources together. Its orbital map renders the actual planets and ship position; drag to pan and use the mouse wheel to zoom.

- Select an expedition objective and destination.
- Check the world's weather and surface gravity before leaving.
- Transfer fuel from the onboard reserve into the tank.
- Repair hull damage and check the total weight limit.
- Pack a camera, radar, repair kit, oxygen, supplies, mineral scanner, drill or signal beacon.
- Include Rocky and adjust the companion's following distance.

![Mission planner showing the orbital map, equipment, weather, gravity and ship resources](docs/images/mission-planner.png)

During flight, the HUD tracks **fuel, hull health and total weight**. Asteroid collisions can damage the ship. The resource panel and mission panel can be collapsed to clear the view.

On foot, the astronaut has a separate **health bar**. Surface exposure drains **0.25 HP per second**, while resting inside the cabin restores **2 HP per second**. Reaching zero triggers an emergency evacuation to space and stabilizes health at 25%. Pausing or loading a destination stops health changes.

## Life aboard the spacecraft

The cabin includes workstations, a cockpit, storage, a lounge and sleeping quarters. A wide window with diagonal corners looks directly into the space scene. Metal, glass and fabric finishes, instrument lighting, helmet lights and floating cabin particles give the interior its character.

<p>
  <img src="docs/images/ship-window.png" width="49%" alt="Wide spacecraft window between the two workstations, overlooking planets and asteroids">
  <img src="docs/images/workstation.png" width="49%" alt="A furnished workstation with an illuminated desk lamp and retro computer">
</p>

### Equipment and backpack

The backpack has **12 slots** with drag-and-drop movement, stacking and swapping. Expedition equipment contributes to the carried weight. Press I while on foot to open it; the game pauses and releases the mouse cursor while you organize items.

![Backpack containing the equipment selected for an expedition](docs/images/backpack.png)

### Meet Rocky

Rocky follows the astronaut at a configurable distance, navigating around furniture and following the route the player takes. Use the planner to bring the companion to a planet or leave Rocky aboard the ship.

![Rocky accompanying the astronaut inside the spacecraft](docs/images/rocky.png)

## Worlds and weather

The game combines a fictional planetary system with distinct explorable surfaces. Each landing zone has terrain, rocks, lighting and gravity, while atmospheric worlds add local weather effects. Weather emitters follow the player and stop when the surface is inactive.

The earlier destinations remain available: **Mercury, Phoenix, Asteria, Nereida, Vulcan, Imaginary, Cubic and Mars**. The six additional worlds below each have their own orbital appearance and surface climate.

### Pelagia — Rain

Overcast skies, falling rain and wet terrain with softened reflections.

<p>
  <img src="docs/images/pelagia-orbit.png" width="49%" alt="Pelagia viewed from orbit with blue-green terrain and cloud cover">
  <img src="docs/images/pelagia-surface.png" width="49%" alt="Rain falling over Pelagia's wet landing zone">
</p>

### Viridia — Radioactive storm

Green atmospheric haze, luminous charged dust and distant electrical discharges.

<p>
  <img src="docs/images/viridia-orbit.png" width="49%" alt="Viridia's green atmosphere viewed from orbit">
  <img src="docs/images/viridia-surface.png" width="49%" alt="Viridia's radioactive storm with green fog and glowing particles">
</p>

### Borealis — Blizzard

Wind-driven snow, pale frozen terrain and cold fog that reduces visibility.

<p>
  <img src="docs/images/borealis-orbit.png" width="49%" alt="The frozen world Borealis seen from orbit">
  <img src="docs/images/borealis-surface.png" width="49%" alt="Snow and fog around the landed ship on Borealis">
</p>

### Sirocco — Sandstorm

Warm desert colors, dune-like relief and windblown sand beneath a dusty sky.

<p>
  <img src="docs/images/sirocco-orbit.png" width="49%" alt="Sirocco's desert-colored surface and atmosphere from orbit">
  <img src="docs/images/sirocco-surface.png" width="49%" alt="A sandstorm crossing Sirocco's landing zone">
</p>

### Cinder — Ash and embers

Dark volcanic ground, drifting ash, glowing embers and surface vents.

<p>
  <img src="docs/images/cinder-orbit.png" width="49%" alt="The dark volcanic planet Cinder viewed from space">
  <img src="docs/images/cinder-surface.png" width="49%" alt="Cinder's ash-covered surface with the astronaut and landed spacecraft">
</p>

### Ionis — Ion storm

Violet haze, luminous airborne particles and intermittent atmospheric lightning.

<p>
  <img src="docs/images/ionis-orbit.png" width="49%" alt="Ionis viewed from orbit with violet terrain and cloud patterns">
  <img src="docs/images/ionis-surface.png" width="49%" alt="Ionis's purple storm atmosphere over rugged terrain">
</p>

## Controls

### On foot

- **W / A / S / D:** move.
- **Shift:** run.
- **Space:** jump.
- **Hold right mouse button + move mouse:** rotate the camera.
- **Q while looking at the mission desk:** pilot the ship.
- **E while looking at the mission desk:** open the mission planner.
- **I:** open or close the backpack.
- **F:** toggle the two helmet lights.
- **Q near the landed ship:** take off from a planet.
- **P:** pause or resume.

### Piloting

- **W / S:** forward or reverse thrust.
- **A / D:** turn.
- **Space / Ctrl:** ascend or descend.
- **Shift:** activate boost.
- **Hold right mouse button + move mouse:** rotate the camera.
- **Q:** return to the spacecraft interior.
- **P:** pause or resume.

Backpack and helmet-light actions are disabled while piloting. Planning, backpack and pause menus block gameplay controls while open.

## Settings and pause

The options menu includes graphics presets, display mode, window resolution, VSync, frame-rate limit, render scale, antialiasing, shadows and post-processing settings. Audio levels, camera sensitivity and vertical inversion can also be adjusted. Use **Apply and save** to keep changes between sessions.

Press P during gameplay to resume, open settings or quit.

<p>
  <img src="docs/images/graphics-options.png" width="49%" alt="Advanced graphics options including render scale and antialiasing">
  <img src="docs/images/pause-menu.png" width="49%" alt="Pause menu with Resume, Settings and Quit game options">
</p>

## Run the project

The project uses **Godot 4.7**, **GDScript**, the **Forward+ renderer** and **Jolt Physics**. The current Windows renderer configuration uses Direct3D 12.

1. Download or clone the repository with its assets.
2. Import the root `project.godot` file in Godot 4.7.
3. Wait for the initial asset import to finish.
4. Press **F5** to start from the main menu, then select **Play**.

If the Godot executable is available as `godot` on your command line:

```sh
godot --path . --editor
```

To start the game directly:

```sh
godot --path .
```

### Project layout

- `Proyecto/Escenas/` — main menu, gameplay, UI, interior and planet scenes.
- `Proyecto/Codigos/` — astronaut, ship, expeditions, backpack, missions and settings logic.
- `Proyecto/Codigos/Planetas/` — planetary profiles and weather effects.
- `Proyecto/Modelos/` — spacecraft, characters, furniture, planets and collision resources.
- `Proyecto/Materiales/` and `Proyecto/Efectos/` — materials, shaders and visual effects.
- `Proyecto/Texturas/` and `Proyecto/Sonidos/` — artwork, textures and audio.
- `docs/images/` — screenshots used in this README, excluded from Godot's asset import.

## Credits

The screenshots in this README come from the game running in Godot. Menu, interface and item artwork include **AI-generated images**, also acknowledged in the in-game credits.

The asteroid field includes an optimized version of **1999 RQ36 asteroid**, credited to **NASA / Christopher R. Meaney**. Its source, optimization notes and attribution are documented in [NASA resource notes](Proyecto/Modelos/NASA/FUENTE.md).

Additional third-party models retain their individual licenses, including CC BY and CC BY-NC assets. See [model credits and licenses](Proyecto/Modelos/RECURSOS_INCORPORADOS.md) for the recorded authors and sources.

This is a fictional exploration game; the planetary arrangement and weather are designed for gameplay. Use of NASA resources does not imply NASA endorsement or sponsorship.
