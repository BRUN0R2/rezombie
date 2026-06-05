# REZOMBIE

## What is this?

ReZombie is a new Zombie Mod base for Counter-Strike 1.6 built from scratch with AMX Mod X, ReHLDS, ReGameDLL and ReAPI.

The project uses old Zombie Mod projects only as study references. The goal is not to port legacy code, but to build a cleaner, more modular and easier to maintain foundation for modern CS 1.6 zombie gameplay.

## Project goals

* Build a clean and modern Zombie Mod architecture from scratch.
* Keep plugins small, modular and easy to understand.
* Provide a strong public API for classes, subclasses, props, models, modes, rounds and players.
* Make it simple to create new zombie classes, human classes and game modes.
* Avoid hidden fallbacks, silent failures and temporary workarounds.
* Prefer explicit state, predictable runtime behavior and low boilerplate.

## Current status

The project already has the first functional base:

* Modular APIs.
* Typed handles for classes, subclasses, props, models and modes.
* Simple weapon API for class and subclass melee models.
* Player state, class changes and infection flow.
* Basic round core.
* First infection mode.
* First zombie subclass: `fleshpound`.
* Modular build package.
* Local runtime validation helpers.

This is still an early development project and the gameplay is evolving step by step.

## Requirements

Use the latest stable or development builds when possible:

* ReHLDS
* ReGameDLL
* Metamod-r or Metamod-P
* AMX Mod X 1.10
* ReAPI

## Tested environment

Current local validation environment:

* ReHLDS: `3.15.0.896-dev`
* ReGameDLL: `5.30.0.814-dev`
* Metamod-r: `1.3.0.149`
* AMX Mod X: `1.10.0.5476`
* ReAPI: `5.29.0.359-dev`

## Build

Run:

```bat
build.bat
```

The package is generated in:

```text
build/cstrike
```

The `build` folder is generated locally and is not versioned.

Plugin output is modular:

```text
addons/amxmodx/plugins/rezombie/api
addons/amxmodx/plugins/rezombie/classes
addons/amxmodx/plugins/rezombie/core
addons/amxmodx/plugins/rezombie/dev
addons/amxmodx/plugins/rezombie/gamemodes
addons/amxmodx/plugins/rezombie/hud
```

## Install

Copy the generated `build/cstrike` content into your server `cstrike` folder.

The generated plugin lists are:

```text
addons/amxmodx/configs/plugins-rezombie.ini
addons/amxmodx/configs/plugins-rezombie-dev.ini
```

`plugins-rezombie-dev.ini` is only for local validation and should not be loaded on production servers.

## How can I help?

Install it on a local test server, try real gameplay flows and report problems with clear reproduction steps.

Useful feedback:

* Runtime errors.
* Broken round flow.
* Class or model issues.
* API design suggestions.
* Clean and focused pull requests.

## Acknowledgments

Thanks to the projects that keep Counter-Strike 1.6 modding alive:

* ReHLDS
* ReGameDLL_CS
* Metamod-r
* AMX Mod X
* ReAPI

Thanks to people who contributed directly or indirectly:

* [fl0werD](https://github.com/fl0werD/)
* [PerfectScrash](https://github.com/PerfectScrash/)
* [wilianmaique](https://github.com/wilianmaique)

Thanks to the Zombie Plague and ReZombie communities for the years of ideas, experiments and references that helped shape this project.
