# config/ — configs versionnées de l'environnement fenêtres / thème

Copies **versionnées** (miroir de sauvegarde) des fichiers de configuration qui vivent
dans `~/.config`. La référence reste la version *live* dans `~/.config` ; ce dossier en
est le miroir git, à re-synchroniser après édition — même logique que les Spoons vis-à-vis
de `~/.hammerspoon/Spoons/`.

## Contenu

- **`yabai/yabairc`** → `~/.config/yabai/yabairc`
  Gestionnaire de fenêtres yabai : mode manuel (`layout float`), règles float, effets
  visuels (opacité, ombres, animations), scripting addition. Piloté au clavier via
  Hammerspoon (`Yabai.spoon`), pas de skhd.
  Prérequis : `brew install asmvik/formulae/yabai` + SIP partiellement désactivé + règle
  sudoers `--load-sa`. Les animations nécessitent en plus l'autorisation « Enregistrement
  de l'écran » pour yabai.

- **`borders/bordersrc`** → `~/.config/borders/bordersrc`
  JankyBorders : anneau de focus autour de la fenêtre active.
  Prérequis : `brew install FelixKratz/formulae/borders`.

- **`sketchybar/`** → `~/.config/sketchybar/`
  Barre de menu personnalisée (Spaces, app courante, menus d'app, widgets batterie / cpu /
  wifi / volume, calendrier, média). Config en Lua.
  Prérequis : `brew install sketchybar`, **SbarLua** (module compilé dans
  `~/.local/share/sketchybar_lua/`, via `git clone https://github.com/FelixKratz/SbarLua && make install`),
  et les polices (SF Pro / SF Mono, sketchybar-app-font).
  Les artefacts compilés (`helpers/**/bin/`) sont exclus (voir `.gitignore`) et se
  régénèrent avec `make`.

## Redéployer sur une machine

```sh
rsync -a config/yabai/      ~/.config/yabai/
rsync -a config/borders/    ~/.config/borders/
rsync -a config/sketchybar/ ~/.config/sketchybar/

# recompiler les helpers sketchybar
(cd ~/.config/sketchybar/helpers && make)
(cd ~/.config/sketchybar/helpers/event_providers && make)

# (re)démarrer les services
brew services restart sketchybar
brew services restart felixkratz/formulae/borders
yabai --restart-service
```
