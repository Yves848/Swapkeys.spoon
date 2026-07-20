--- === CheatSheet ===
---
--- Affiche une fenêtre popup **flottante** (via `hs.webview`) listant tous les raccourcis
--- clavier et leur description, façon « which-key ». Un même raccourci l'affiche et le
--- masque ; `Échap` ferme aussi. La fenêtre est *non-activante* : elle apparaît sans voler
--- le focus à l'application courante.
---
--- Les données affichées sont entièrement configurables via `obj.sections` (voir la forme
--- ci-dessous) : on les définit dans `~/.hammerspoon/init.lua`, juste à côté des `bindHotkeys`,
--- pour garder une source unique. Un jeu par défaut (la config de l'auteur) est fourni afin
--- que le Spoon fonctionne dès son chargement.
---
--- Usage dans ~/.hammerspoon/init.lua :
---   hs.loadSpoon("CheatSheet")
---   -- Optionnel : remplacer/compléter la liste (sinon le défaut est utilisé)
---   -- spoon.CheatSheet.sections = {
---   --   { title = "Fenêtres", accent = "#4b9fff", items = {
---   --       { "⌃⌥ ← → ↑ ↓", "Déplacer le focus vers la voisine" },
---   --       { "⌃⌥⌘ F",      "(Dé)flotter la fenêtre" },
---   --   } },
---   -- }
---   spoon.CheatSheet:bindHotkeys({ toggle = { { "ctrl", "alt" }, "h" } })
---
--- Chaque item est { keys, description }. Dans `keys`, les jetons séparés par des espaces
--- sont rendus en touches (`<kbd>`) ; les séparateurs « / · … + » restent en texte discret.
--- Groupez les modificateurs (« ⌃⌥⌘ ») et espacez ce qui doit devenir des touches distinctes
--- (« ← → ↑ ↓ »).

local obj = {}
obj.__index = obj

obj.name = "CheatSheet"
obj.version = "1.0"
obj.author = "ledcontrol"
obj.license = "MIT"

-- Titre affiché en haut de la fenêtre.
obj.title = "Raccourcis Hammerspoon"
-- Sous-titre (rappel du modèle courant). Mettre "" pour le masquer.
obj.subtitle = "Mode manuel (float) — rangez avec ⌘⌥ · pavage d'un Space via ⌃⌥⌘ espace"

-- Dimensions de la fenêtre (px). Ajustées au contenu ; le corps défile si besoin.
obj.width = 980
obj.height = 660

-- Jeu de raccourcis par défaut (config de l'auteur). Surchargeable depuis init.lua.
obj.sections = {
  { title = "Fenêtres — tiling (yabai)", accent = "#4b9fff", items = {
    { "⌃⌥ ← → ↑ ↓",  "Déplacer le focus vers la fenêtre voisine" },
    { "⌃⌥⇧ ← → ↑ ↓", "Échanger la fenêtre avec sa voisine" },
    { "⌃⌥⌘ ← → ↑ ↓", "Warp — ré-insérer la fenêtre dans l'arbre" },
    { "⌃⌥ ↩",        "Plein cadre (zoom-fullscreen)" },
    { "⌃⌥⌘ F",       "(Dé)flotter la fenêtre + centrer" },
    { "⌃⌥⌘ Espace",  "Cycle layout : bsp → stack → float" },
    { "⌃⌥⌘ R",       "Pivoter l'agencement de 90°" },
    { "⌃⌥⌘ E",       "Rééquilibrer les tailles" },
  } },
  { title = "Bureaux virtuels (Spaces)", accent = "#42c58a", items = {
    { "⌃⌥⌘ 1…9",   "Aller au Space N" },
    { "⌃⌥⌘⇧ 1…9",  "Envoyer la fenêtre au Space N (+ suivre)" },
    { "⌃⌥⌘ , / ;",  "Space précédent / suivant" },
    { "⌃⌥⌘⇧ , / ;", "Envoyer la fenêtre au Space préc. / suiv." },
    { "⌃⌥⌘ N",      "Créer un Space (+ le focaliser)" },
    { "⌃⌥⌘ W",      "Détruire le Space courant" },
  } },
  { title = "Écrans — « = » = l'autre écran", accent = "#a486ff", items = {
    { "⌃⌥⌘ =",  "Focaliser l'autre écran" },
    { "⌃⌥⌘⇧ =", "Envoyer la fenêtre à l'autre écran (+ suivre)" },
    { "⌃⌥⇧ =",  "Déplacer le Space entier vers l'autre écran" },
  } },
  { title = "Placement — Magnet / Rectangle", accent = "#3fb6c9", items = {
    { "⌘⌥ ← → ↑ ↓", "Moitié gauche / droite / haut / bas" },
    { "⌘⌥ U I J K",  "Quarts : haut-g / haut-d / bas-g / bas-d" },
    { "⌘⌥ D F G",    "Tiers : gauche / centre / droite" },
    { "⌘⌥ E / T",    "Deux-tiers : gauche / droite" },
    { "⌘⌥ ↩",        "Plein écran (zone utile)" },
    { "⌘⌥ C",        "Centrer (60 %)" },
  } },
  { title = "Fenêtre au pixel (flottantes)", accent = "#e0a13a", items = {
    { "⇧⌥ ← → ↑ ↓", "Déplacer par pas (50 px)" },
    { "⌘⌃ ← →",     "Redimensionner — largeur" },
    { "⌘⌃ ↑ ↓",     "Redimensionner — hauteur" },
  } },
  { title = "Éclairage & domotique", accent = "#f0803a", items = {
    { "⌃⌥ L", "LedControl — ouvrir la fenêtre" },
    { "⌃⌥ 1", "LedControl — scène « travail »" },
    { "⌃⌥ 2", "LedControl — scène « détente »" },
    { "⌃⌥ 0", "LedControl — tout éteindre" },
    { "⌃⌥ W", "WLED — palette (chooser)" },
    { "⌃⌥ A", "Aquarium — palette (on / off / état)" },
  } },
  { title = "Son", accent = "#e35aa8", items = {
    { "⌃⌥ B", "SoundControl — popup profils (puis 1…9, Échap)" },
  } },
  { title = "Système & divers", accent = "#8b97a8", items = {
    { "⌃⌥ N",  "Synology — monter les partages SMB" },
    { "⌃⌥ P",  "Pavé num. « . » ⇄ « , » (bascule)" },
    { "⌘⌥⌃ R", "Recharger la config Hammerspoon" },
    { "⌃⌥ H",  "Afficher / masquer cette aide" },
    { "menubar 🔁 / ❌", "SwapKeys : < / > ⇄ @ / # (clic sur l'icône)" },
  } },
}

-- Séparateurs rendus en texte discret plutôt qu'en touche.
local SEPARATORS = { ["/"] = true, ["·"] = true, ["…"] = true, ["+"] = true }

-- Échappe le texte destiné au HTML (descriptions, libellés de touches).
local function esc(s)
  return (tostring(s):gsub("[&<>]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }))
end

-- Transforme "⌃⌥⌘ , / ;" en une suite de <kbd> + séparateurs.
local function renderKeys(keys)
  local parts = {}
  for tok in keys:gmatch("%S+") do
    if SEPARATORS[tok] then
      parts[#parts + 1] = '<span class="sep">' .. esc(tok) .. "</span>"
    else
      parts[#parts + 1] = "<kbd>" .. esc(tok) .. "</kbd>"
    end
  end
  return table.concat(parts, " ")
end

--- Construit le document HTML complet (thème sombre translucide) à partir de `obj.sections`.
function obj:_html()
  local cards = {}
  for _, sec in ipairs(self.sections or {}) do
    local rows = {}
    for _, it in ipairs(sec.items or {}) do
      rows[#rows + 1] = string.format(
        '<tr><td class="k">%s</td><td class="d">%s</td></tr>',
        renderKeys(it[1]), esc(it[2]))
    end
    local accent = sec.accent or "#4b9fff"
    cards[#cards + 1] = string.format(
      '<section class="card"><h2 style="color:%s;border-color:%s">%s</h2>'
        .. '<table>%s</table></section>',
      accent, accent, esc(sec.title), table.concat(rows))
  end

  return [[<!doctype html><html lang="fr"><head><meta charset="utf-8"><style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body { background: transparent; overflow: hidden; }
    body {
      font-family: -apple-system, "Helvetica Neue", Arial, sans-serif;
      color: #e6e9ef; padding: 14px; -webkit-user-select: none; user-select: none;
    }
    .panel {
      background: rgba(24, 27, 34, 0.97); border: 1px solid rgba(255,255,255,0.08);
      border-radius: 16px; padding: 16px 18px 14px;
      box-shadow: 0 18px 60px rgba(0,0,0,0.55);
    }
    header { display: flex; align-items: baseline; justify-content: space-between;
      margin-bottom: 12px; padding-bottom: 8px; border-bottom: 1px solid rgba(255,255,255,0.08); }
    header h1 { font-size: 16px; font-weight: 600; letter-spacing: .2px; }
    header .hint { font-size: 11px; color: #8b93a3; }
    header .hint kbd { font-size: 10px; }
    .sub { font-size: 11px; color: #8b93a3; margin: -6px 0 11px; }
    .grid { column-count: 3; column-gap: 16px; }
    @media (max-width: 720px) { .grid { column-count: 2; } }
    .card { break-inside: avoid; margin-bottom: 13px; }
    .card h2 { font-size: 11px; font-weight: 700; text-transform: uppercase;
      letter-spacing: .4px; padding-bottom: 3px; margin-bottom: 3px;
      border-bottom: 1px solid; }
    table { width: 100%; border-collapse: collapse; }
    td { padding: 2.5px 0; vertical-align: middle; font-size: 12px; }
    td.k { text-align: right; white-space: nowrap; width: 1%; padding-right: 10px; }
    td.d { color: #c3c9d4; }
    kbd { display: inline-block; font-family: inherit; font-size: 11px; font-weight: 600;
      min-width: 15px; text-align: center; padding: 1px 5px; margin: 1px;
      color: #eef1f6; background: #2b3140;
      border: 1px solid #3d4557; border-bottom-width: 2px; border-radius: 5px; }
    .sep { color: #6b7385; padding: 0 1px; }
  </style></head><body><div class="panel">
    <header><h1>]] .. esc(self.title) .. [[</h1>
    <span class="hint"><kbd>Échap</kbd> ou <kbd>⌃⌥H</kbd> pour fermer</span></header>]]
    .. ((self.subtitle and self.subtitle ~= "") and ('<div class="sub">' .. esc(self.subtitle) .. "</div>") or "")
    .. [[<div class="grid">]] .. table.concat(cards) .. [[</div>
  </div></body></html>]]
end

-- Crée (une seule fois) le modal qui capte Échap quand la fenêtre est visible.
function obj:_ensureModal()
  if self._modal then return end
  self._modal = hs.hotkey.modal.new()
  self._modal:bind({}, "escape", function() self:hide() end)
end

-- Marge transparente (px) autour du panneau, de chaque côté — laisse respirer l'ombre CSS
-- et sert au calcul de la hauteur finale. Doit valoir le `padding` du <body>.
local BODY_MARGIN = 14

-- Ajuste la hauteur de la fenêtre à celle réelle du panneau (+ marges) et la re-centre
-- verticalement sur l'écran `scr`. Appelé une fois le chargement terminé.
function obj:_fitHeight(scr, w)
  if not self._webview then return end
  self._webview:evaluateJavaScript(
    "Math.ceil(document.querySelector('.panel').getBoundingClientRect().height)",
    function(res)
      local ch = tonumber(res)
      if not ch or not self._webview then return end
      local nh = ch + 2 * BODY_MARGIN
      self._webview:frame({
        x = scr.x + (scr.w - w) / 2,
        y = scr.y + (scr.h - nh) / 2,
        w = w, h = nh,
      })
    end)
end

--- Affiche la fenêtre (recrée le webview à chaque fois → contenu toujours à jour).
--- La hauteur est ajustée au contenu réel une fois le HTML chargé (navigationCallback →
--- evaluateJavaScript) : pas d'espace vide, centrage vertical exact.
function obj:show()
  self:_ensureModal()
  if self._webview then self:hide() end
  local scr = (hs.screen.mainScreen() or hs.screen.primaryScreen()):frame()
  local w, h = self.width, self.height
  local rect = {
    x = scr.x + (scr.w - w) / 2,
    y = scr.y + (scr.h - h) / 2,
    w = w, h = h,
  }
  local masks = hs.webview.windowMasks
  self._webview = hs.webview.new(rect)
    :windowStyle(masks.borderless | masks.nonactivating)
    :level(hs.drawing.windowLevels.modalPanel)
    :shadow(false) -- pas d'ombre native (rectangulaire) → ombre gérée en CSS sur le panneau
    :transparent(true)
    :allowTextEntry(false)
    :navigationCallback(function(action)
      -- Le contenu est mis en page → on peut mesurer et ajuster la hauteur.
      if action == "didFinishNavigation" then self:_fitHeight(scr, w) end
    end)
    :html(self:_html())
  self._webview:show()
  self._modal:enter() -- capte Échap globalement tant que la fenêtre est visible
  self._visible = true
  return self
end

--- Masque et détruit la fenêtre.
function obj:hide()
  if self._webview then
    self._webview:delete()
    self._webview = nil
  end
  if self._modal then self._modal:exit() end
  self._visible = false
  return self
end

--- Bascule affichage/masquage.
function obj:toggle()
  if self._visible then self:hide() else self:show() end
  return self
end

--- bindHotkeys : action reconnue `toggle` (afficher/masquer la fenêtre d'aide).
function obj:bindHotkeys(mapping)
  self:_ensureModal()

  local spec = mapping and mapping.toggle
  if spec then
    hs.hotkey.bind(spec[1], spec[2], function() self:toggle() end)
  end
  return self
end

return obj
