-- SCRIPT DE OPTIMIZACIÓN EXTREMA: NO ANIMACIONES, NO TEXTURAS, NO PARTÍCULAS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting") -- Para controlar el cielo

-- MEJORA: Color gris/blanco plano para forzar en absolutamente todo el juego
local COLOR_FIJO = Color3.fromRGB(180, 180, 180)

-- 1. FUNCIÓN PARA LIMPIAR TODO OBJETO (MAPA, JUGADORES, NPC)
local function limpiarObjeto(v)
    -- Eliminar efectos visuales y partículas
    if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Fire") or v:IsA("Trail") then
        v:Destroy()
    -- Eliminar texturas, ropa y calcomanías
    elseif v:IsA("Texture") or v:IsA("Decal") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
        v:Destroy()
    -- Eliminar animaciones incrustadas
    elseif v:IsA("Animation") or v:IsA("AnimationController") then
        v:Destroy()
    -- Convertir bloques y terrenos pesados en materiales lisos y planos
    elseif v:IsA("BasePart") and not v:IsA("MeshPart") then
        v.Material = Enum.Material.SmoothPlastic
        v.Reflectance = 0
        v.Color = COLOR_FIJO -- MEJORA: Forzar color gris plano en bloques comunes
        v.CastShadow = false -- MEJORA: Quita sombras para dar más FPS
    elseif v:IsA("MeshPart") then
        v.TextureID = "" -- Quita la textura digital del modelo 3D
        v.Material = Enum.Material.SmoothPlastic
        v.Color = COLOR_FIJO -- MEJORA: Forzar color gris plano en modelos 3D
        v.CastShadow = false -- MEJORA: Quita sombras en modelos 3D
    -- Eliminar iluminación avanzada del juego (Sombras, desenfoque)
    elseif v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
        v:Destroy()
    
    -- ==========================================
    -- LO NUEVO QUE ME PEDISTE (AÑADIDO SIN BORRAR NADA):
    -- ==========================================
    -- CONVERTIR MOLDES COMPLEJOS EN BLOQUES SIMPLES (Destruye formas custom de sombreros, accesorios o cuerpos)
    elseif v:IsA("SpecialMesh") or v:IsA("BlockMesh") or v:IsA("CharacterMesh") then
        v:Destroy() 
    end
end

-- 2. DETENER ANIMACIONES EN TIEMPO REAL (JUGADORES Y NPC)
local function detenerAnimaciones(personaje)
    if not personaje then return end
    -- Destruye el script que genera el movimiento por defecto
    local animateScript = personaje:FindFirstChild("Animate")
    if animateScript then animateScript:Destroy() end
    
    -- Bucle para congelar cualquier intento de animación
    local humanoid = personaje:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0) -- Detiene en seco la animación
            end
        end
    end
end

-- ==========================================
-- LO NUEVO QUE ME PEDISTE (AÑADIDO SIN BORRAR NADA):
-- ==========================================
-- ASEGURAR QUE TU PROPIO PERSONAJE PIERDA ANIMACIONES AL REVIVIR O CAMBIAR DE ZONA
local function monitorearMiPersonaje(char)
    if not char then return end
    detenerAnimaciones(char)
    for _, v in pairs(char:GetDescendants()) do
        pcall(limpiarObjeto, v)
    end
    -- Si tu personaje se equipa armas, herramientas o accesorios nuevos, los vuelve bloques grises
    char.DescendantAdded:Connect(function(v)
        pcall(limpiarObjeto, v)
    end)
end

-- Ejecución inmediata y continua para tu propio avatar
if LocalPlayer.Character then monitorearMiPersonaje(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(monitorearMiPersonaje)
-- ==========================================

-- 3. EJECUCIÓN INICIAL (Limpia todo lo que ya cargó en el mapa)
for _, v in pairs(game:GetDescendants()) do
    pcall(limpiarObjeto, v)
end

-- 4. BUCLE EN SEGUNDO PLANO (Para nuevos elementos, ataques, NPC que reaparecen o jugadores que entran)
game:GetDescendantsInstanceAddedSignal():Connect(function(v)
    pcall(limpiarObjeto, v)
end)

-- ==========================================
-- NUEVA FUNCIÓN: ELIMINAR EL CIELO Y HACERLO NEGRO ABSOLUTO
-- ==========================================
local function oscurecerCielo()
    Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
    Lighting.GlobalShadows = false
    Lighting.ClockTime = 0 -- Forzar medianoche para fondo oscuro
    
    -- Borra elementos del cielo
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
            v:Destroy()
        end
    end
end
pcall(oscurecerCielo)
Lighting.ChildAdded:Connect(function(v)
    if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
        pcall(function() v:Destroy() end)
    end
end)
-- ==========================================

RunService.Heartbeat:Connect(function()
    -- CORREGIDO: Detiene animaciones de todos los jugadores y les quita el color Blender
    for _, jugador in pairs(Players:GetPlayers()) do
        if jugador.Character then
            pcall(detenerAnimaciones, jugador.Character)
            -- Bucle agresivo anti-Blender para jugadores
            for _, m in pairs(jugador.Character:GetDescendants()) do
                if m:IsA("MeshPart") then
                    m.TextureID = ""
                    m.Color = COLOR_FIJO
                end
            end
        end
    end
    -- CORREGIDO: Detiene animaciones de los NPC y les quita el color Blender
    for _, modelo in pairs(workspace:GetDescendants()) do
        if modelo:IsA("Model") and modelo:FindFirstChildOfClass("Humanoid") then
            pcall(detenerAnimaciones, modelo)
            -- Bucle agresivo anti-Blender para NPCs/Unidades
            for _, m in pairs(modelo:GetDescendants()) do
                if m:IsA("MeshPart") then
                    m.TextureID = ""
                    m.Color = COLOR_FIJO
                end
            end
        end
    end
    -- Mantener el cielo negro si el juego intenta resetear la hora
    Lighting.ClockTime = 0
end)

-- Reducir la calidad de renderizado de texturas al mínimo absoluto en el motor
pcall(function()
    settings():GetService("RenderSettings").TextureQualityOverride = 0
end)

print("--- TODO HA SIDO REMOVEDO EN ABSOLUTO ---")
