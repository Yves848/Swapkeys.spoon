--- === Yabai ===
---
--- Pilote le gestionnaire de fenêtres **yabai** depuis Hammerspoon : focus / échange
--- de fenêtres, déplacement dans l'arbre (warp), navigation entre Spaces (bureaux
--- virtuels) — index, relatif, création/destruction — envoi d'une fenêtre vers un
--- Space, gestion multi-écrans (déplacer un Space sur un autre écran, focus écran,
--- envoi de fenêtre vers un écran), cycle de layout (bsp ↔ stack ↔ float) et quelques
--- actions d'agencement (float, zoom, rotation, équilibrage).
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
---   local wm    = { "ctrl", "alt" }           -- focus / échange / warp
---   local space = { "ctrl", "alt", "cmd" }    -- Spaces / écrans / layout
---   local send  = { "ctrl", "alt", "cmd", "shift" }
---   spoon.Yabai:bindHotkeys({
---     -- Fenêtres
---     focus_west  = { wm, "left" },  focus_east = { wm, "right" },
---     focus_south = { wm, "down" },  focus_north = { wm, "up" },
---     swap_west   = { { "ctrl", "alt", "shift" }, "left" },  -- etc.
---     warp_west   = { { "ctrl", "shift" }, "left" },         -- déplacer dans l'arbre
---     toggle_zoom = { wm, "return" }, toggle_float = { space, "f" },
---     layout_cycle = { space, "space" },       -- bsp ↔ stack ↔ float
---     rotate = { space, "r" }, balance = { space, "e" },
---     -- Spaces (bureaux virtuels)
---     space_1 = { space, "1" }, space_2 = { space, "2" },    -- focus Space N
---     send_1  = { send, "1" },                               -- envoyer la fenêtre au Space N
---     space_prev = { space, "," }, space_next = { space, ";" },
---     send_prev  = { send,  "," }, send_next  = { send,  ";" },
---     space_create = { space, "n" }, space_destroy = { space, "w" },
---     -- Écrans (multi-moniteurs) — « = » = l'autre écran, le modif dit quoi déplacer
---     display_next       = { space, "=" },                        -- focus écran
---     send_display_next  = { send,  "=" },                        -- y envoyer la fenêtre
---     space_display_next = { { "ctrl", "alt", "shift" }, "=" },   -- y déplacer le Space
---   })
---
--- Choix des touches : les actions par symbole doivent utiliser des touches PRÉSENTES
--- dans le keymap actif (cf. hs.keycodes.map / hs.keycodes.currentLayout()). Sur AZERTY
--- belge, « , ; = » sont natives alors que « [ ] . » ne le sont pas (HS retombe sur des
--- keycodes US → touches mortes). Adaptez le mapping à votre disposition clavier.

local obj = {}
obj.__index = obj

obj.name = "Yabai"
obj.version = "1.1"
obj.author = "ledcontrol"
obj.license = "MIT"

-- Chemin du binaire yabai (Homebrew Apple Silicon par défaut).
obj.yabai = "/opt/homebrew/bin/yabai"

--- Lance `yabai -m <args…>` sans bloquer. `andThen` (optionnel) est appelé une fois
--- la commande terminée — sert à enchaîner deux commandes (ex. envoyer une fenêtre
--- vers un Space puis suivre ce Space).
-- Messages d'erreur yabai *bénins* à ne pas afficher : impasses de navigation quand il
-- n'y a pas de fenêtre/écran voisin dans la direction demandée (« could not locate a
-- {eastward,…} managed window », « … display »). Ce sont des non-événements, pas des
-- erreurs — les remonter en alerte est du bruit.
local function isBenignError(msg)
  return msg:match("could not locate") ~= nil
end

function obj:_run(args, andThen)
  local task = hs.task.new(self.yabai, function(code, _out, err)
    -- yabai renvoie un code ≠ 0 + un message sur stderr en cas d'échec (fenêtre
    -- introuvable, Space inexistant, écran unique, SA non chargée…). On l'affiche
    -- discrètement, sauf pour les impasses de navigation (voir isBenignError).
    if code ~= 0 and err and #err > 0 then
      local msg = err:gsub("%s+$", "")
      if not isBenignError(msg) then hs.alert.show("yabai : " .. msg) end
    end
    if andThen then andThen() end
  end, args)
  task:start()
end

--- Lance une requête `yabai -m query …` et passe le JSON décodé à `cb`. Sur échec
--- (code ≠ 0 ou JSON invalide), `cb` n'est pas appelé (erreur affichée en alerte).
function obj:_query(args, cb)
  local task = hs.task.new(self.yabai, function(code, out, err)
    if code ~= 0 then
      if err and #err > 0 then
        local msg = err:gsub("%s+$", "")
        if not isBenignError(msg) then hs.alert.show("yabai : " .. msg) end
      end
      return
    end
    local ok, data = pcall(hs.json.decode, out)
    if ok and data then cb(data) end
  end, args)
  task:start()
end

--- Envoie la fenêtre focalisée vers le Space `sel` (index numérique ou "next"/"prev"),
--- puis suit ce Space. Deux commandes enchaînées : `window --space` puis `space --focus`
--- (les combiner en un seul appel échoue silencieusement). Comme le focus n'a pas encore
--- bougé quand on enchaîne, "next"/"prev" restent valides pour le `--focus`.
function obj:_sendToSpace(sel)
  local s = tostring(sel)
  self:_run({ "-m", "window", "--space", s }, function()
    self:_run({ "-m", "space", "--focus", s })
  end)
end

--- Envoie la fenêtre focalisée vers l'écran `dir` ("next"/"prev"), puis suit cet écran.
function obj:_sendToDisplay(dir)
  self:_run({ "-m", "window", "--display", dir }, function()
    self:_run({ "-m", "display", "--focus", dir })
  end)
end

--- Fait passer le Space courant au layout suivant dans le cycle bsp → stack → float → bsp.
--- Interroge d'abord le type courant (le layout n'est pas déductible sans requête).
function obj:_cycleLayout()
  self:_query({ "-m", "query", "--spaces", "--space" }, function(data)
    local order = { bsp = "stack", stack = "float", float = "bsp" }
    local nextLayout = order[data.type] or "bsp"
    self:_run({ "-m", "space", "--layout", nextLayout })
    hs.alert.show("Layout : " .. nextLayout)
  end)
end

--- Bascule le Space courant entre pavage automatique (bsp) et manuel/flottant (float).
--- Contrairement à _cycleLayout, ne passe pas par "stack" : un simple interrupteur à
--- deux états, avec confirmation.
function obj:_toggleTiling()
  self:_query({ "-m", "query", "--spaces", "--space" }, function(data)
    local toBsp = (data.type ~= "bsp") -- depuis float ou stack → bsp ; depuis bsp → float
    local target = toBsp and "bsp" or "float"
    self:_run({ "-m", "space", "--layout", target })
    hs.alert.show(toBsp and "Pavage automatique (bsp)" or "Manuel — flottant (float)")
  end)
end

--- Crée un Space sur l'écran actif puis le focalise (le nouveau Space est ajouté en fin
--- de liste → on focalise "last").
function obj:_createSpace()
  self:_run({ "-m", "space", "--create" }, function()
    self:_run({ "-m", "space", "--focus", "last" })
  end)
end

--- Déplace le Space courant vers l'écran `dir` ("next"/"prev") puis suit cet écran.
function obj:_moveSpaceToDisplay(dir)
  self:_run({ "-m", "space", "--display", dir }, function()
    self:_run({ "-m", "display", "--focus", dir })
  end)
end

--- bindHotkeys : voir le docstring d'en-tête pour la liste des actions.
--- Actions reconnues :
---   Fenêtres :
---     focus_{west,south,north,east}   — déplacer le focus vers la fenêtre voisine
---     swap_{west,south,north,east}    — échanger la fenêtre avec sa voisine
---     warp_{west,south,north,east}    — déplacer la fenêtre dans l'arbre (ré-insertion)
---     toggle_float                    — (dé)flotter la fenêtre (géré ↔ flottant)
---     toggle_zoom                     — plein cadre du parent (zoom-fullscreen)
---     layout_cycle                    — bsp → stack → float → bsp
---     layout_toggle                   — bascule pavage auto (bsp) ↔ manuel (float)
---     rotate                          — pivoter l'agencement de 90°
---     balance                         — rééquilibrer les tailles
---   Spaces :
---     space_1 … space_9               — focaliser le Space N
---     send_1 … send_9                 — envoyer la fenêtre au Space N (et suivre)
---     space_next / space_prev         — focaliser le Space suivant / précédent
---     send_next / send_prev           — envoyer la fenêtre au Space suivant / précédent (et suivre)
---     space_create / space_destroy    — créer (et focaliser) / détruire le Space courant
---   Écrans :
---     display_next / display_prev     — focaliser l'écran suivant / précédent
---     send_display_next / send_display_prev — envoyer la fenêtre vers l'écran voisin (et suivre)
---     space_display_next / space_display_prev — déplacer le Space courant vers l'écran voisin (et suivre)
function obj:bindHotkeys(mapping)
  local dirs = { west = "west", south = "south", north = "north", east = "east" }

  local actions = {
    -- Simple bascule flottant/géré. (Pas de `--grid` : il échoue sur une fenêtre gérée
    -- — « cannot apply grid layout to a managed window ». Pour centrer/placer une fois
    -- flottante, utiliser WindowSnap : ⌘⌥C, ⌘⌥ flèches, etc.)
    toggle_float = function() self:_run({ "-m", "window", "--toggle", "float" }) end,
    toggle_zoom   = function() self:_run({ "-m", "window", "--toggle", "zoom-fullscreen" }) end,
    layout_cycle  = function() self:_cycleLayout() end,
    layout_toggle = function() self:_toggleTiling() end,
    rotate       = function() self:_run({ "-m", "space", "--rotate", "90" }) end,
    balance      = function() self:_run({ "-m", "space", "--balance" }) end,
    -- Spaces relatifs et gestion dynamique.
    space_next    = function() self:_run({ "-m", "space", "--focus", "next" }) end,
    space_prev    = function() self:_run({ "-m", "space", "--focus", "prev" }) end,
    send_next     = function() self:_sendToSpace("next") end,
    send_prev     = function() self:_sendToSpace("prev") end,
    space_create  = function() self:_createSpace() end,
    space_destroy = function() self:_run({ "-m", "space", "--destroy" }) end,
    -- Écrans.
    display_next  = function() self:_run({ "-m", "display", "--focus", "next" }) end,
    display_prev  = function() self:_run({ "-m", "display", "--focus", "prev" }) end,
    send_display_next = function() self:_sendToDisplay("next") end,
    send_display_prev = function() self:_sendToDisplay("prev") end,
    space_display_next = function() self:_moveSpaceToDisplay("next") end,
    space_display_prev = function() self:_moveSpaceToDisplay("prev") end,
  }

  -- focus_* / swap_* / warp_* pour les quatre directions.
  for name, dir in pairs(dirs) do
    actions["focus_" .. name] = function() self:_run({ "-m", "window", "--focus", dir }) end
    actions["swap_" .. name]  = function() self:_run({ "-m", "window", "--swap", dir }) end
    actions["warp_" .. name]  = function() self:_run({ "-m", "window", "--warp", dir }) end
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
