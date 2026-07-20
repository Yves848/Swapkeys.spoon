--- === Yabai ===
---
--- Pilote le gestionnaire de fenêtres **yabai** depuis Hammerspoon : focus / échange
--- de fenêtres, navigation entre Spaces (bureaux virtuels), envoi d'une fenêtre vers
--- un Space, et quelques actions d'agencement (float, zoom, rotation, équilibrage).
---
--- Pourquoi depuis Hammerspoon plutôt que skhd ? Source unique des raccourcis (toute la
--- config vit déjà en HS) et pas de second démon global qui entrerait en concurrence
--- avec l'`hs.eventtap` de SwapKeys. Les commandes sont lancées via `hs.task` (pas de
--- shell spawné à chaque appui → latence minimale).
---
--- Prérequis : yabai installé (fork asmvik pour macOS 26 Tahoe) et sa *scripting
--- addition* chargée (SIP partiellement désactivé) pour la gestion des Spaces.
---   brew install asmvik/formulae/yabai
---
--- Usage dans ~/.hammerspoon/init.lua :
---   hs.loadSpoon("Yabai")
---   -- spoon.Yabai.yabai = "/opt/homebrew/bin/yabai"  -- chemin du binaire (optionnel)
---   local wm    = { "ctrl", "alt" }           -- focus / échange
---   local space = { "ctrl", "alt", "cmd" }    -- Spaces
---   spoon.Yabai:bindHotkeys({
---     focus_west  = { wm, "left" },  focus_east = { wm, "right" },
---     focus_south = { wm, "down" },  focus_north = { wm, "up" },
---     swap_west   = { { "ctrl", "alt", "shift" }, "left" },  -- etc.
---     space_1 = { space, "1" }, space_2 = { space, "2" },    -- focus Space N
---     send_1  = { { "ctrl", "alt", "cmd", "shift" }, "1" },  -- envoyer la fenêtre au Space N
---     toggle_zoom = { wm, "return" },
---     toggle_float = { space, "f" },
---     rotate = { space, "r" }, balance = { space, "e" },
---   })

local obj = {}
obj.__index = obj

obj.name = "Yabai"
obj.version = "1.0"
obj.author = "ledcontrol"
obj.license = "MIT"

-- Chemin du binaire yabai (Homebrew Apple Silicon par défaut).
obj.yabai = "/opt/homebrew/bin/yabai"

--- Lance `yabai -m <args…>` sans bloquer. `andThen` (optionnel) est appelé une fois
--- la commande terminée — sert à enchaîner deux commandes (ex. envoyer une fenêtre
--- vers un Space puis suivre ce Space).
function obj:_run(args, andThen)
  local task = hs.task.new(self.yabai, function(code, _out, err)
    -- yabai renvoie un code ≠ 0 + un message sur stderr en cas d'échec (fenêtre
    -- introuvable, Space inexistant, SA non chargée…). On l'affiche discrètement.
    if code ~= 0 and err and #err > 0 then
      hs.alert.show("yabai : " .. err:gsub("%s+$", ""))
    end
    if andThen then andThen() end
  end, args)
  task:start()
end

--- Envoie la fenêtre focalisée vers le Space `n`, puis suit ce Space (deux commandes
--- enchaînées : `window --space n` échoue silencieusement si on tente `--focus` combiné).
function obj:_sendToSpace(n)
  local ns = tostring(n)
  self:_run({ "-m", "window", "--space", ns }, function()
    self:_run({ "-m", "space", "--focus", ns })
  end)
end

--- bindHotkeys : voir le docstring d'en-tête pour la liste des actions.
--- Actions reconnues :
---   focus_{west,south,north,east}   — déplacer le focus vers la fenêtre voisine
---   swap_{west,south,north,east}    — échanger la fenêtre avec sa voisine
---   space_1 … space_9               — focaliser le Space N
---   send_1 … send_9                 — envoyer la fenêtre au Space N (et suivre)
---   toggle_float                    — (dé)flotter la fenêtre et la centrer
---   toggle_zoom                     — plein cadre du parent (zoom-fullscreen)
---   rotate                          — pivoter l'agencement de 90°
---   balance                         — rééquilibrer les tailles
function obj:bindHotkeys(mapping)
  local dirs = { west = "west", south = "south", north = "north", east = "east" }

  local actions = {
    toggle_float = function() self:_run({ "-m", "window", "--toggle", "float", "--grid", "4:4:1:1:2:2" }) end,
    toggle_zoom  = function() self:_run({ "-m", "window", "--toggle", "zoom-fullscreen" }) end,
    rotate       = function() self:_run({ "-m", "space", "--rotate", "90" }) end,
    balance      = function() self:_run({ "-m", "space", "--balance" }) end,
  }

  -- focus_* / swap_* pour les quatre directions.
  for name, dir in pairs(dirs) do
    actions["focus_" .. name] = function() self:_run({ "-m", "window", "--focus", dir }) end
    actions["swap_" .. name]  = function() self:_run({ "-m", "window", "--swap", dir }) end
  end

  -- space_1..9 (focus) et send_1..9 (envoi de la fenêtre).
  for n = 1, 9 do
    local ns = tostring(n)
    actions["space_" .. ns] = function() self:_run({ "-m", "space", "--focus", ns }) end
    actions["send_" .. ns]  = function() self:_sendToSpace(n) end
  end

  for name, spec in pairs(mapping or {}) do
    local fn = actions[name]
    if fn then
      -- pressedfn + repeatfn = fn → l'action se répète si la touche est maintenue
      -- (utile pour le focus/déplacement en rafale).
      hs.hotkey.bind(spec[1], spec[2], fn, nil, fn)
    end
  end
  return self
end

return obj
