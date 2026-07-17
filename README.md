# Spoons Hammerspoon

Collection de [Spoons](https://www.hammerspoon.org/Spoons/) développés pour un usage
perso (clavier AZERTY belge, éclairage domotique). Chaque dossier `*.spoon` est un Spoon
autonome contenant un `init.lua`.

## Spoons

| Spoon | Rôle |
|-------|------|
| **SwapKeys** | Remappe des touches via `hs.eventtap` : `<`/`>` et `@`/`#`. Bascule on/off. |
| **NumpadDot** | Force la touche `.` du pavé numérique à taper un point (AZERTY tape une virgule). Pratique pour les IP. |
| **WindowStep** | Déplace / redimensionne la fenêtre active « par pas » au clavier (répétition si la touche est maintenue). |
| **WLED** | Découvre (mDNS `_wled._tcp`) et pilote des modules WLED depuis un menubar + chooser. |
| **LedControl** | Client du service LedControl (FastAPI) : menubar, scènes, raccourcis ; peut lancer/superviser le service lui-même. |

Le docstring en tête de chaque `init.lua` documente la configuration et les hotkeys.

## Installation

Copier le(s) Spoon(s) voulu(s) dans `~/.hammerspoon/Spoons/`, puis les charger depuis
`~/.hammerspoon/init.lua` :

```lua
cp -r SwapKeys.spoon ~/.hammerspoon/Spoons/
```

```lua
hs.loadSpoon("SwapKeys")
spoon.SwapKeys:start()
```

Voir l'en-tête de chaque Spoon pour les options de configuration et `bindHotkeys`.

## Licence

MIT.
