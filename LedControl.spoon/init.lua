--- === LedControl ===
---
--- Client Hammerspoon du service LedControl (FastAPI).
--- Ajoute un menu dans la barre des menus, des raccourcis clavier, et l'accès aux scènes.
---
--- Installation :
---   cp -r hammerspoon/LedControl.spoon ~/.hammerspoon/Spoons/
--- Dans ~/.hammerspoon/init.lua :
---   local led = hs.loadSpoon("LedControl")
---   led.projectPath = os.getenv("HOME") .. "/git/ledcontrol"  -- lance/supervise le service
---   led.baseUrl = "http://127.0.0.1:8787"                     -- optionnel (défaut)
---   led:bindHotkeys({
---     all_on   = {{"cmd", "alt", "ctrl"}, "L"},
---     all_off  = {{"cmd", "alt", "ctrl"}, "K"},
---     travail  = {{"cmd", "alt", "ctrl"}, "1"},
---     detente  = {{"cmd", "alt", "ctrl"}, "2"},
---   })
---   led:start()
---
--- Si `projectPath` est défini, Hammerspoon démarre le service FastAPI lui-même : le
--- process enfant hérite de l'autorisation « Réseau local » de Hammerspoon (indispensable
--- sur macOS pour joindre les WLED/prises). Sinon, lancez le service via ./macos/start.sh.

local obj = {}
obj.__index = obj

obj.name = "LedControl"
obj.version = "0.1.0"
obj.author = "ledcontrol"
obj.license = "MIT"

obj.baseUrl = "http://127.0.0.1:8787"
obj.menuIcon = "🎛️"

-- Si défini, le Spoon lance et surveille le service FastAPI lui-même (via hs.task).
-- Un process lancé par Hammerspoon hérite de son autorisation « Réseau local » macOS,
-- ce qui permet au service de joindre les WLED/prises (impossible depuis un terminal).
obj.projectPath = nil

-- Icône dans la barre de menus. Mettre à false si la barre est pleine (encoche) :
-- utilisez alors le chooser au clavier (bindHotkeys{ chooser = ... }).
obj.showMenubar = true

obj.menubar = nil
obj.serverTask = nil
obj._stopping = false

-- --- HTTP helpers ---------------------------------------------------------

function obj:_get(path, cb)
  hs.http.asyncGet(self.baseUrl .. path, nil, function(status, body)
    if status ~= 200 then
      hs.printf("[LedControl] GET %s -> %s", path, tostring(status))
      cb(nil)
      return
    end
    local ok, data = pcall(hs.json.decode, body)
    cb(ok and data or nil)
  end)
end

function obj:_post(path, cb)
  hs.http.asyncPost(self.baseUrl .. path, "", { ["Content-Type"] = "application/json" },
    function(status, body)
      if status ~= 200 then
        hs.alert.show("LedControl : échec (" .. tostring(status) .. ")")
      end
      if cb then cb(status == 200) end
    end)
end

-- --- Actions --------------------------------------------------------------

function obj:allOn() self:_post("/api/all/on", function() self:refresh() end) end
function obj:allOff() self:_post("/api/all/off", function() self:refresh() end) end
function obj:toggleDevice(id) self:_post("/api/devices/" .. id .. "/toggle", function() self:refresh() end) end
function obj:applyScene(name)
  self:_post("/api/scenes/" .. hs.http.encodeForQuery(name), function()
    hs.alert.show("Scène : " .. name)
    self:refresh()
  end)
end

-- --- Chooser (palette au clavier, indépendante de la barre de menus) --------

function obj:showChooser()
  -- Récupère appareils + scènes puis affiche une palette de sélection.
  self:_get("/api/devices", function(devices)
    self:_get("/api/scenes", function(scenes)
      local choices = {}
      for _, name in ipairs(scenes or {}) do
        choices[#choices + 1] = {
          text = "🎬 Scène : " .. name,
          subText = "Appliquer la scène",
          act = { kind = "scene", name = name },
        }
      end
      choices[#choices + 1] = { text = "🔆 Tout allumer", act = { kind = "all", on = true } }
      choices[#choices + 1] = { text = "🌙 Tout éteindre", act = { kind = "all", on = false } }
      for _, dev in ipairs(devices or {}) do
        local st = dev.state or {}
        local mark = st.reachable == false and "⚠︎ " or (st.on and "🟢 " or "⚪ ")
        choices[#choices + 1] = {
          text = mark .. dev.name,
          subText = dev.type .. " — basculer on/off",
          act = { kind = "toggle", id = dev.id },
        }
      end

      local chooser = hs.chooser.new(function(sel)
        if not sel then return end
        local a = sel.act
        if a.kind == "scene" then
          self:applyScene(a.name)
        elseif a.kind == "all" then
          self:_post("/api/all/" .. (a.on and "on" or "off"))
        elseif a.kind == "toggle" then
          self:toggleDevice(a.id)
        end
      end)
      chooser:placeholderText("LedControl — scène, tout ON/OFF, ou appareil…")
      chooser:choices(choices)
      chooser:show()
    end)
  end)
end

-- --- Menu ------------------------------------------------------------------

function obj:_buildMenu(devices, scenes)
  local menu = {}

  table.insert(menu, { title = "Tout allumer", fn = function() self:allOn() end })
  table.insert(menu, { title = "Tout éteindre", fn = function() self:allOff() end })
  table.insert(menu, { title = "-" })

  if scenes and #scenes > 0 then
    table.insert(menu, { title = "Scènes", disabled = true })
    for _, name in ipairs(scenes) do
      table.insert(menu, { title = "  " .. name, fn = function() self:applyScene(name) end })
    end
    table.insert(menu, { title = "-" })
  end

  table.insert(menu, { title = "Appareils", disabled = true })
  if devices then
    for _, dev in ipairs(devices) do
      local st = dev.state or {}
      local mark = st.reachable == false and "⚠ " or (st.on and "🟢 " or "⚪ ")
      table.insert(menu, {
        title = "  " .. mark .. dev.name,
        fn = function() self:toggleDevice(dev.id) end,
      })
    end
  end

  table.insert(menu, { title = "-" })
  table.insert(menu, { title = "Rafraîchir", fn = function() self:refresh() end })
  return menu
end

function obj:refresh()
  if not self.menubar then return end
  self:_get("/api/devices", function(devices)
    self:_get("/api/scenes", function(scenes)
      self.menubar:setMenu(self:_buildMenu(devices or {}, scenes or {}))
    end)
  end)
end

-- --- Lifecycle -------------------------------------------------------------

function obj:bindHotkeys(mapping)
  local actions = {
    all_on = function() self:allOn() end,
    all_off = function() self:allOff() end,
    chooser = function() self:showChooser() end,
  }
  for action, spec in pairs(mapping) do
    local fn = actions[action] or function() self:applyScene(action) end
    hs.hotkey.bind(spec[1], spec[2], fn)
  end
  return self
end

-- --- Service (lancé/supervisé par Hammerspoon) ----------------------------

function obj:startService()
  if not self.projectPath then return end
  if self.serverTask and self.serverTask:isRunning() then return end

  local py = self.projectPath .. "/.venv/bin/python3"
  local serve = self.projectPath .. "/macos/serve.py"
  if not hs.fs.attributes(py) or not hs.fs.attributes(serve) then
    hs.printf("[LedControl] Python venv ou serve.py introuvable sous %s", self.projectPath)
    return
  end

  self.serverTask = hs.task.new(py, function(code, _, _)
    hs.printf("[LedControl] service terminé (code %s)", tostring(code))
    self.serverTask = nil
    -- Redémarrage auto (sauf arrêt volontaire), après un court délai.
    if not self._stopping then
      hs.timer.doAfter(3, function() self:startService() end)
    end
  end, { serve })

  self.serverTask:start()
  hs.printf("[LedControl] service démarré : %s", serve)
end

function obj:stopService()
  self._stopping = true
  if self.serverTask then
    self.serverTask:terminate()
    self.serverTask = nil
  end
end

-- --- Lifecycle -------------------------------------------------------------

function obj:start()
  self._stopping = false
  self:startService()
  if self.showMenubar and not self.menubar then
    self.menubar = hs.menubar.new()
    self.menubar:setTitle(self.menuIcon)
    -- Laisse le service démarrer avant le premier rafraîchissement du menu.
    hs.timer.doAfter(self.projectPath and 2.5 or 0, function() self:refresh() end)
  end
  return self
end

function obj:stop()
  self:stopService()
  if self.menubar then
    self.menubar:delete()
    self.menubar = nil
  end
  return self
end

return obj
