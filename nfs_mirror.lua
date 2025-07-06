require("orbis")

local settings = ac.storage {
    orbis = true,
    lights = true,
    ArrowEnabled = false,
    ArrowFade = true,
    NOAI = false,
    CenterApp = true
}

local mirror = {
    texture = "./assets/mirror.dds",
    lights = "./assets/lights.png",
    lights_orange = "./assets/lights_orange.png",
    size = vec2(520, 320)
}

local arrow = {
    texture = "./assets/arrow.png",
    size = vec2(80, 80)
}

local track = ac.getTrackID()
local sim = ac.getSim()
local orbisstate = false
local online = sim.isOnlineRace
local appWindow = ac.accessAppWindow('IMGUI_LUA_NFS mirror_main')

local function CenterApp()
    if not appWindow:valid() then return end

    local windowWidth = ac.getSim().windowWidth
    local center = (windowWidth - appWindow:size().x) / 2

    if appWindow:position().x ~= center and not ui.isMouseDragging(ui.MouseButton.Left, 0) then
        appWindow:move(vec2(center, appWindow:position().y))
    end
end

local function orbislogic()
    local orbis = OrbisList()
    local cpos = ac.getCar(sim.focusedCar).position
    local dist = 500

    if string.match(track, "shuto_revival_project") then
        for i = 1, #orbis do
            if dist > math.sqrt((cpos.x - orbis[i].x) ^ 2 + (cpos.z - orbis[i].z) ^ 2) then
                dist = math.sqrt((cpos.x - orbis[i].x) ^ 2 + (cpos.z - orbis[i].z) ^ 2)
            end
        end
    end

    if dist <= 400 then
        orbisstate = true
    else
        orbisstate = false
    end
end

function script.windowMain()
    ui.beginTonemapping()
    ui.drawVirtualMirror(vec2(14, 24), vec2(486, 155))
    ui.endTonemapping(1, 1.8 - (sim.lightSuggestion * 0.8), true)

    ui.setCursor(vec2(-10, -60))
    ui.image(mirror.texture, mirror.size, rgbm(1, 1, 1, 0.95))

    local arcCenter = vec2(250, 185)
    ui.pathArcTo(arcCenter, 19, 3.25, 6.18, 35)
    ui.pathFillConvex(rgbm(0.26, 0.29, 0.12, 0.8))

    ui.pathArcTo(arcCenter, 29, 3.2, 6.21, 35)
    ui.pathStroke(rgbm(0.36, 0.4, 0.22, 0.6), false, 4)

    ui.pathArcTo(arcCenter, 19, 3.25, 6.18, 35)
    ui.pathStroke(rgbm(0.50, 0.60, 0.19, 0.9), false, 4)

    local nearest = ac.getCar.ordered(1)
    if nearest == nil then return end
    if not online then return end

    local AI = nearest.isHidingLabels
    local inRange = nearest.distanceToCamera < 30
    local isorb = settings.orbis and orbisstate

    if settings.orbis and orbisstate then
        ui.setCursor(vec2(-10, -60))
        ui.image(mirror.lights_orange, mirror.size, rgbm(1, 1, 1, 1))
    end

    if inRange and not isorb and settings.lights then
        if not AI or (AI and not settings.NOAI) then
            ui.setCursor(vec2(-10, -60))
            ui.image(mirror.lights, mirror.size)
        end
    end

    if inRange and not isorb and settings.ArrowEnabled then
        if not AI or (AI and not settings.NOAI) then
            local look_vec3 = ac.getCar.ordered(0).look
            local diff_vec3 = nearest.position - ac.getCar.ordered(0).position

            local look_vec2 = vec2(look_vec3.x, look_vec3.z)
            local diff_vec2 = vec2(diff_vec3.x, diff_vec3.z)
            local angle = math.deg(look_vec2:angle(diff_vec2))
            local cross = look_vec2.x * diff_vec2.y - look_vec2.y * diff_vec2.x

            if cross >= 0 then angle = -angle end
            angle = angle + 90

            local opacity = settings.ArrowFade and math.clamp(math.lerp(1, 0, (nearest.distanceToCamera - 15) / 15), 0, 1) or 1

            ui.beginRotation()
            ui.setCursor(vec2(210, 143))
            ui.image(arrow.texture, arrow.size, rgbm(1, 1, 1, opacity))
            ui.endRotation(angle, vec2(0, 0))
        end
    end
end

function script.settings()
    local accentColor = rgbm(0.8, 0.06, 0.1, 1)
    local whitespace = 35
    local settingsString = "Disable indicator"

    if ac.getPatchVersionCode() >= 3425 then
        accentColor = ac.getUI().accentColor
    end

    ui.configureStyle(accentColor, false, true, 0.9)

    ui.setCursor(vec2(10, 35))
    if ui.checkbox("Center app", settings.CenterApp) then
        settings.CenterApp = not settings.CenterApp
    end

    if not online then
        ui.setCursor(vec2(10, 60))
        ui.text("Advanced options don't work in single player.")
        ui.drawSimpleLine(vec2(0, 64), vec2(300, 64), rgbm(0.4, 0.4, 0.4, 0.8))
        return
    end

    ui.drawSimpleLine(vec2(0, 23), vec2(300, 23), accentColor)

    if string.match(track, "shuto_revival_project") then
        whitespace = 0

        ui.setCursor(vec2(10, 70 - whitespace))
        if ui.checkbox("Enable orbis detection", settings.orbis) then
            settings.orbis = not settings.orbis
        end

        ui.drawSimpleLine(vec2(0, 64), vec2(300, 64), rgbm(0.4, 0.4, 0.4, 0.8))
    end

    ui.setCursor(vec2(10, 124 - whitespace))
    if ui.checkbox("Light indicator", settings.lights) then
        settings.lights = not settings.lights
    end

    ui.setCursor(vec2(10, 151 - whitespace))
    if ui.checkbox("Enable proximity arrow (buggy)", settings.ArrowEnabled) then
        settings.ArrowEnabled = not settings.ArrowEnabled
    end

    ui.setCursor(vec2(35, 180 - whitespace))
    if settings.ArrowEnabled and ui.checkbox("Enable arrow fading", settings.ArrowFade) then
        settings.ArrowFade = not settings.ArrowFade
    end

    if settings.ArrowEnabled and settings.lights then
        settingsString = "Disable indicators"
    end

    ui.setCursor(vec2(10, 97 - whitespace))
    if ui.checkbox(settingsString .. " with non players", settings.NOAI) then
        settings.NOAI = not settings.NOAI
    end
end

function script.update(dt)
    orbislogic()
    if settings.CenterApp then CenterApp() end
end
