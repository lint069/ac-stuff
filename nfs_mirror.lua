require("orbis")

local settings = ac.storage {
    orbis = true,
    lights = true,
    ArrowEnabled = false,
    ArrowFade = true,
    NOAI = false
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

function script.windowMain()
    ui.beginTonemapping()
    ui.drawVirtualMirror(vec2(14, 24), vec2(486, 155))
    ui.endTonemapping(1, 1.8 - (sim.lightSuggestion * 0.8), true)

    ui.setCursor(vec2(-10, -60))
    ui.image(mirror.texture, mirror.size)

    local arcCenter = vec2(250, 185)
    ui.pathArcTo(arcCenter, 19, 3.25, 6.18, 35)
    ui.pathFillConvex(rgbm(0.26, 0.29, 0.12, 0.8))

    ui.pathArcTo(arcCenter, 29, 3.2, 6.21, 35)
    ui.pathStroke(rgbm(0.36, 0.4, 0.22, 0.6), false, 4)

    ui.pathArcTo(arcCenter, 19, 3.25, 6.18, 35)
    ui.pathStroke(rgbm(0.50, 0.60, 0.19, 0.9), false, 4)

    local nearest = ac.getCar.ordered(1)
    if nearest == nil then return end

    local AI = nearest.isHidingLabels
    local inRange = nearest.distanceToCamera < 30

    if settings.lights and inRange and AI and not settings.NOAI and not orbisstate then
        ui.setCursor(vec2(-10, -60))
        ui.image(mirror.lights, mirror.size)
    end

    if settings.orbis and orbisstate and sim.frame % 30 < 15 then
        ui.setCursor(vec2(-10, -60))
        ui.image(mirror.lights_orange, mirror.size, rgbm(1, 1, 1, 1))
    end

    if settings.ArrowEnabled and not orbisstate and inRange and AI and not settings.NOAI then
        local player = ac.getCar.ordered(0)
        local look = vec2(player.look.x, player.look.z)
        local diff = vec2(nearest.position.x - player.position.x, nearest.position.z - player.position.z)

        local angle = math.deg(look:angle(diff))
        local cross = look.x * diff.y - look.y * diff.x
        if cross >= 0 then angle = -angle end
        angle = angle + 90

        local opacity = settings.ArrowFade and math.clamp(math.lerp(1, 0, (nearest.distanceToCamera - 15) / 15), 0, 1) or 1

        ui.beginRotation()
        ui.setCursor(vec2(210, 143))
        ui.image(arrow.texture, arrow.size, rgbm(1, 1, 1, opacity))
        ui.endRotation(angle, vec2(0, 0))
    end
end

function script.update(dt)
    local orbis = OrbisList()
    local cpos = ac.getCar(sim.focusedCar).position
    local dist = 500
    local target, targetpast

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

    ac.debug("orbisstate:", orbisstate)
end

function script.settings()
    local accentColor = rgbm(.2, .6, 1, 1)
    local string_switch = false
    local settings_string = "Disable indicator"

    if ac.getPatchVersionCode() >= 3425 then
        accentColor = ac.getUI().accentColor
    end

    ui.configureStyle(accentColor, false, true)
    ui.drawSimpleLine(vec2(0, 23), vec2(300, 23), accentColor)

    ui.setCursor(vec2(10, 35))
    if ui.checkbox("Enable orbis detection", settings.orbis) then
        settings.orbis = not settings.orbis
    end

    ui.drawSimpleLine(vec2(0, 64), vec2(300, 64), rgbm(.4, .4, .4, .8))

    ui.setCursor(vec2(10, 97))
    if ui.checkbox("Light indicator", settings.lights) then
        settings.lights = not settings.lights
    end

    ui.setCursor(vec2(10, 124))
    if settings.lights and ui.checkbox("Enable proximity arrow (buggy)", settings.ArrowEnabled) then
        settings.ArrowEnabled = not settings.ArrowEnabled
    end

    if settings.lights then ui.setCursor(vec2(35, 151)) end
    if settings.ArrowEnabled and settings.lights and ui.checkbox("Enable arrow fading", settings.ArrowFade) then
        settings.ArrowFade = not settings.ArrowFade
    end

    if settings.ArrowEnabled and settings.lights then
        string_switch = true
    end

    if string_switch then
        settings_string = "Disable indicators"
    end

    ui.setCursor(vec2(10, 70))
    if ui.checkbox(settings_string .. " with non players", settings.NOAI) then
        settings.NOAI = not settings.NOAI
    end
end
