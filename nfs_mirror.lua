require("orbis")

local settings = ac.storage {
    orbis = true,
    lights = true,
    ArrowEnabled = true,
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
    size = vec2(90, 90)
}

local track = ac.getTrackID()
local sim = ac.getSim()
local orbisstate = false
local angle
local arrowOpacity
local blink = rgbm(1, 1, 1, 0)

function script.update(dt)
    local orbis = OrbisList()
    local cpos = ac.getCar(sim.focusedCar).position
    local dist = 500
    local target, targetpast

    if string.match(track, "shuto_revival_project") then
        for i = 1, #orbis do
            if dist > math.sqrt((cpos.x - orbis[i].x) ^ 2 + (cpos.z - orbis[i].z) ^ 2) then
                dist = math.sqrt((cpos.x - orbis[i].x) ^ 2 + (cpos.z - orbis[i].z) ^ 2)
                target = i
            end
        end
    end

    if target ~= targetpast then
        orbisstate = false
        targetpast = target
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
    ui.image(mirror.texture, mirror.size)

    ui.pathArcTo(vec2(250, 185), 19, 3.25, 6.18, 35)
    ui.pathFillConvex(rgbm(0.26, 0.29, 0.12, 0.8))

    ui.pathArcTo(vec2(250, 185), 29, 3.2, 6.21, 35)
    ui.pathStroke(rgbm(0.36, 0.4, 0.22, 0.6), false, 4)

    ui.pathArcTo(vec2(250, 185), 19, 3.25, 6.18, 35)
    ui.pathStroke(rgbm(0.50, 0.60, 0.19, 0.9), false, 4)

    if settings.orbis then
        if orbisstate and sim.frame % 30 < 15 then
            blink = rgbm(1, 1, 1, 1)
            ui.setCursor(vec2(-10, -60))
            ui.image(mirror.lights_orange, mirror.size, blink)
        end
    end

    local nearest = ac.getCar.ordered(1) if nearest == nil then return end
    local AI = nearest.isHidingLabels
    local inRange = nearest.distanceToCamera < 30

    if settings.lights then
        if inRange then
            if AI and not settings.NOAI then
                ui.setCursor(vec2(-10, -60))
                ui.image(mirror.lights, mirror.size)
            end
        end
    end

    if settings.ArrowEnabled then
        local look_vec3 = ac.getCar.ordered(0).look
        local diff_vec3 = nearest.position - ac.getCar.ordered(0).position

        local look_vec2 = vec2(look_vec3.x, look_vec3.z)
        local diff_vec2 = vec2(diff_vec3.x, diff_vec3.z)
        angle = math.deg(look_vec2:angle(diff_vec2))
        local cross = look_vec2.x * diff_vec2.y - look_vec2.y * diff_vec2.x

        if cross >= 0 then
            angle = -angle
        end
        angle = angle + 90

        arrowOpacity = settings.ArrowFade and math.clamp(math.lerp(1, 0, (nearest.distanceToCamera - 15) / 15), 0, 1) or 1

        if inRange then
            if AI and not settings.NOAI then
                ui.beginRotation()
                ui.setCursor(vec2(204, 138))
                ui.image(arrow.texture, arrow.size, rgbm(1, 1, 1, arrowOpacity))
                ui.endRotation(angle, vec2(0, 0))
            end
        end
    end
end

function script.settings()
    local accentColor = rgbm(.2, .6, 1, 1)
    local sbool = false
    local mstring = "Disable indicator"

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
    if settings.lights and ui.checkbox("Enable proximity arrow", settings.ArrowEnabled) then
        settings.ArrowEnabled = not settings.ArrowEnabled
    end

    if settings.lights then ui.setCursor(vec2(35, 151)) end
    if settings.ArrowEnabled and settings.lights and ui.checkbox("Enable arrow fading", settings.ArrowFade) then
        settings.ArrowFade = not settings.ArrowFade
    end

    if settings.ArrowEnabled and settings.lights then
        sbool = true
    end

    if sbool then
        mstring = "Disable indicators"
    end

    ui.setCursor(vec2(10, 70))
    if ui.checkbox(mstring .. " with non players", settings.NOAI) then
        settings.NOAI = not settings.NOAI
    end
end
