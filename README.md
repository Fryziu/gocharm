# GoCharm for Luanti

[![Luanti](https://img.shields.io/badge/Luanti-5.10%2B%20%2F%205.17-blue.svg)](https://www.luanti.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Game: VoxeLibre](https://img.shields.io/badge/Game-VoxeLibre%20%7C%20Minetest%20Game-green.svg)](https://content.luanti.org/packages/Wuzzy/mineclone2/)

**GoCharm** is a modernized, immersive multi-home and teleportation mod for the **Luanti** engine (formerly Minetest). It introduces the **Traveler's Amulet**—a craftable, magical artifact with a graphical interface (GUI), rapid mouse-click controls, and a panic-button teleport system, fully integrated with **VoxeLibre** and **Minetest Game**.

Originally forked from [octacian/multihome](https://github.com/octacian/multihome), this project transforms a simple text-based chat command mod into a complete RPG-style navigation tool.

---

## ✨ Features

- **The Traveler's Amulet (`gocharm:amulet`)**: A physical, craftable item with custom inventory textures and 3D wield mesh support.
- **Panic Button (Quick Recall)**: Right-Click (**RMB**) instantly teleports you to your marked **MASTER** home (safehouse/base) without opening any menus or touching the chat console.
- **Intuitive GUI**: Left-Click (**LMB**) or **Shift + RMB** opens an interactive management window (Master-Detail layout).
- **MASTER Waypoint Priority**: Pin your primary base as `[MASTER]`—it automatically sorts to the top of your list and serves as your instant recall destination.
- **Alchemical Crafting**: A rich, mid-game recipe requiring diamond, copper, gold, redstone block, spider eye, cave mushroom, and a book.
- **Engine Modernization**: Fully optimized for Luanti 5.17+ using the modern `MetaDataRef` API (no deprecated attribute warnings).
- **Rock-Solid Formspec**: Robust string escaping ensuring menu stability regardless of coordinate syntax or font renderers.
- **Native Localization (i18n)**: Fully translated into **English** and **Polish** out of the box using Luanti's client-aware `.tr` engine.
- **Full Backward Compatibility & Seamless Migration**: Automatically detects and migrates existing teleport points from legacy `multihome` installations without data loss.

---

## 🎮 How It Works

### Controls (With Amulet in Hand)
| Action | Trigger | Description |
| :--- | :--- | :--- |
| **Open Menu** | **LMB** (Left Click) | Opens the Amulet GUI to manage or visit all waypoints. |
| **Instant Recall** | **RMB** (Right Click) | Immediately teleports you to your **MASTER** location. |
| **Alternative Menu**| **Shift + RMB** | Opens the Amulet GUI (useful if sneak-clicking). |

### Graphical Interface (GUI)
Opening the amulet displays all saved locations with real-time slot tracking (e.g. `Locations (2/3)`):
- **Teleport**: Jump to the selected location (double-clicking an entry also teleports immediately).
- **Update to My Pos**: Overwrite the coordinates of the selected waypoint with your current standing position.
- **Set as MASTER**: Mark the selected waypoint with the golden `[MASTER]` badge for single-click recall.
- **Delete**: Remove the selected waypoint from your amulet.
- **Save Location**: Type a name and record a brand-new waypoint (enforces server slot limits).

---

## 🔨 Crafting Recipes

### VoxeLibre (MineClone2)
Crafted in a standard 3x3 crafting table using materials collected from mines, caves, and mobs:

| Col 1 | Col 2 | Col 3 |
| :---: | :---: | :---: |
| **Book** (`mcl_books:book`) | **Copper Ingot** (`mcl_copper:copper_ingot`) | **Redstone Block** (`mesecons_torch:redstoneblock`) |
| **Gold Ingot** (`mcl_core:gold_ingot`) | **Diamond** (`mcl_core:diamond`) | **Gold Ingot** (`mcl_core:gold_ingot`) |
| **Spider Eye** (`mcl_mobitems:spider_eye`) | **Copper Ingot** (`mcl_copper:copper_ingot`) | **Cave Mushroom** (Brown or Red) |

*(Both `mcl_mushrooms:mushroom_brown` and `mcl_mushrooms:mushroom_red` are supported).*

### Minetest Game (Fallback)
- **Top Row**: Book (`default:book`), Copper Ingot (`default:copper_ingot`), Mese Block (`default:mese`)
- **Middle Row**: Gold Ingot (`default:gold_ingot`), Diamond (`default:diamond`), Gold Ingot (`default:gold_ingot`)
- **Bottom Row**: Obsidian Shard (`default:obsidian_shard`), Copper Ingot (`default:copper_ingot`), Brown Mushroom (`flowers:mushroom_brown`)

---

## 💬 Chat Commands

For players who haven't crafted the amulet yet or prefer console commands:

| Command | Description |
| :--- | :--- |
| `/gocharm set <name>` | Save or update a location at your current position. |
| `/gocharm del <name>` | Delete a location (`/gocharm delete` and `remove` also work). |
| `/gocharm go [name]` | Teleport to a named location (or to MASTER if name is omitted). |
| `/gocharm list` | List all your saved locations and coordinates. |
| `/h [name]` | Ultra-fast alias for instant teleportation. |

---

## ⚙️ Configuration (`minetest.conf`)

You can customize mod behavior via `minetest.conf` or the world configuration:

```ini
# Maximum number of locations per player (Default: 5)
gocharm.max = 3

# Default privileges for newly registered players
default_privs = interact, shout, gocharm
