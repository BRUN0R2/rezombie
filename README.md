# ReZombie

ReZombie is a modern Zombie Mod base for Counter-Strike 1.6.

The project targets AMX Mod X 1.10 with ReHLDS, ReGameDLL and ReAPI.

## Build

Run:

```bat
build.bat
```

The build package is generated in `build/cstrike`.

## Local Server

`start.bat` expects a local server folder beside `Mods`:

```text
CS 1.6/
  Compiler/
  Mods/rezombie/
  REHLDS-Rezombie/
```

Set the RCON password through the environment before starting:

```bat
set REZOMBIE_RCON_PASSWORD=your-local-password
start.bat
```
