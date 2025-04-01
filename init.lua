--- === MonSpoon ===
---
--- Un exemple de squelette pour créer un spoon pour Hammerspoon.
---
local obj      = {}
obj.__index    = obj

-- Métadonnées
obj.name       = "SwapKeys"
obj.version    = "1.0"
obj.author     = "Yves Godart <yves.godart@gmail.com>"
obj.homepage   = "https://www.hammerspoon.org/Spoons/SwapKeys.html"
obj.license    = "MIT - https://opensource.org/licenses/MIT"

local logger   = hs.logger.new("SwapKeys", "debug")
local keyDown  = hs.eventtap.event.types.keyDown
-- Variables internes (à utiliser si besoin)
local internal = {
  remapEnabled = true,
  remapTap = nil,
  menuIcon = nil
}

--local eventtap = hs.eventtap
--local keydown  = hs.eventtap.event.types.keyDown

local function remapFunction(e)
  -- logger.i("remapFuntion")

  if not internal.remapEnabled then
    return false
  end

  local code = e:getKeyCode()
  local flags = e:getFlags()
  -- logger.i(code)
  if code == 10 then
    if flags.shift then
      hs.eventtap.keyStrokes(">")
    else
      hs.eventtap.keyStrokes("<")
    end
    return true
  elseif code == 50 then
    if flags.shift then
      hs.eventtap.keyStrokes("#")
    else
      hs.eventtap.keyStrokes("@")
    end
    return true
  end
  return false
end
--- MonSpoon:init()
--- Fonction d'initialisation du spoon.
function obj:init()
  hs.alert.show("SwapKeys initialisé!")
end

--- MonSpoon:start()
--- Démarre le spoon et lance ses fonctionnalités.
function obj:start()
  hs.alert.show("SwapKeys démarré!")
  internal.remapTap = hs.eventtap.new({ keyDown }, remapFunction)
  internal.remapTap:start()
end

--- SwapKeys:toggle()
--- Met en pause ou redémarre le swap des touches
function obj:toggle()
  internal.remapEnabled = not internal.remapEnabled
  if (not internal.remapEnabled) then
    hs.alert.show("SwapKeys en pause!")
  else
    hs.alert.show("SwapKeys en fonctionnement!")
  end
  -- Ajoutez ici le code pour arrêter votre spoon
end

function obj:isEnabled()
  return internal.remapEnabled
end

--- MonSpoon:stop()
--- Arrête le spoon et nettoie les ressources.
function obj:stop()
  hs.alert.show("SwapKeys en arrêté!")
  if internal.remapTap then
    internal.remapTap = nil
  end
end

return obj
