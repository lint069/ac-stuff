

local settings = ac.storage {
    ArrowEnabled = true,
    ArrowFade = true,
    NOAI = false,
    Proximity = true
}

local mirror = {
    texture = "./img/mirror.dds",
    lights = "./img/lights.png",
    lights_orange = "./img/lights_orange.png",
    size = vec2(520, 320)
}

local arrow = {
    texture = "./img/arrow.png",
    size = vec2(90, 90)
}

function script.windowMain()

    local sim = ac.getSim()
    local car = ac.getCar(sim.focusedCar)
    local nearest = ac.getCar.ordered(1) if nearest == nil then return end
    local inRange = nearest.distanceToCamera < 30
    local arrowOpacity
    local angle
    local notPlayer = nearest.isHidingLabels
    local orbis = orbisList()

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

    if settings.ArrowEnabled then
        local look_vec3 = ac.getCar.ordered(0).look
        local diff_vec3 = nearest.position - ac.getCar.ordered(0).position

        local look_vec2 = vec2(look_vec3.x, look_vec3.z)
        local diff_vec2 = vec2(diff_vec3.x, diff_vec3.z)
        angle = math.deg(look_vec2:angle(diff_vec2))
        local cross = look_vec2.x * diff_vec2.y - look_vec2.y * diff_vec2.x

        if cross >= 0 then angle = -angle end
        angle = angle + 90

        arrowOpacity = settings.ArrowFade and math.clamp(math.lerp(1, 0, (nearest.distanceToCamera - 15) / 15), 0, 1) or 1
    end

    ui.setCursor(vec2(-10, -60))
    ui.image(mirror.lights, mirror.size)

    ui.beginRotation()
    ui.setCursor(vec2(204, 138))
    ui.image(arrow.texture, arrow.size, rgbm(1, 1, 1, arrowOpacity))
    ui.endRotation(angle, vec2(0, 0))

    if inRange and settings.Proximity then
        if not settings.NOAI or not notPlayer then
            return 1
        end
    end
end

function script.settings()

    local accentColor = rgbm(.2, .6, 1, 1)

    if ac.getPatchVersionCode() >= 3425 then
        accentColor = ac.getUI().accentColor
    end

    ui.configureStyle(accentColor, false, true)
    ui.drawSimpleLine(vec2(0, 23), vec2(300, 23), accentColor)

    ui.setCursor(vec2(10, 35))
    if ui.checkbox("Proximity mode", settings.Proximity) then
        settings.Proximity = not settings.Proximity
    end
end