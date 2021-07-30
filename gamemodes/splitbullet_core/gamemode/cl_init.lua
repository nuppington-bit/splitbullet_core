/*
	Copyright (c) 2021 TidalDevs

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/

include("shared.lua")

surface.CreateFont("VCROSDMono", {
	font = "VCR OSD Mono",
	size = 32,
})

// Convars
CreateClientConVar("sb_nohud", "0", true, false, "Disable the Split Bullet HUD. 0 = Off, 1 = On, 2 = HL2 HUD", 0, 2)
CreateClientConVar("sb_mousesensitivity", "0.25", true, false, "Change your Split Bullet mouse sensitivity.")

// These are just here so we can determine if the player has god mode on the client.
local meta = FindMetaTable( "Player" )
function meta:HasGodMode()
	return self:GetNWBool( "HasGodMode" )
end

local oldorigin // Origin lerping
local oldfov // Fov lerping
local reversed = false // This is used to reverse the player's pitch when they are looking the other way.
local zoom = false // Misleading variable name, it's used for first person mode.

// Disabled HUD elements (HL2 HUD)
local disabledHuds = {
    "CHudHealth",
    "CHudBattery",
    "CHudAmmo",
    "CHudCrosshair",
}

// Mouse cursor
// FIXME: This should be different than the world cursor.
local mouseCursor = {
    texture = surface.GetTextureID( "sprites/hud/v_crosshair1" ),
    color   = Color( 255, 255, 255, 255 ),
    x 	= ScrW()/2-48/2,
    y 	= ScrH()/2-48/2,
    w 	= 48,
    h 	= 48,
}

// World cursor (where the player is actually going to shoot and interact at)
local mouseWorld = {
    texture = surface.GetTextureID( "sprites/hud/v_crosshair1" ),
    color   = Color(0, 255, 255),
    x 	= ScrW()/2-32/2,
    y 	= ScrH()/2-32/2,
    w 	= 32,
    h 	= 32,
}

local mapmusic

// Gamemode has finished loading, let's set up the map.
function GM:InitPostEntity()
    local music = GetGlobalString("SplitBullet_MapMusic", "")
    local volume = GetGlobalFloat("SplitBullet_MapMusicVolume", 1)
    local delay = GetGlobalFloat("SplitBullet_MapMusicDelay", 0)
    if music ~= "" then
        function playbgm() // Don't repeat code
            mapmusic = CreateSound(game.GetWorld(), music)
            mapmusic:SetSoundLevel(0) // play everywhere
            mapmusic:Play()
            mapmusic:ChangeVolume(volume)
        end
        if delay > 0 then // Only use a timer if the map has a delay
            timer.Simple(delay, playbgm)
        else
            playbgm()
        end
    end
end

// ----- HUD -----

local healthMemory = 0 // Lerping the health bar
local health = 0 // Current health
local armorMemory = 0 // Lerping the armor bar
local armor = 300 // Current armor
local zoomer = 0 // Zoom distance (in y coords)
local zoomerMemory = 0 // Lerping zoom distance
local temppos = ScrW()/2 // Marquee text position (used for the placeholder information)
local dt = 0 // Delta Time

local rhombus = { // w: 200, h: 45
    { x = 32, y = 0 }, // Top left
    { x = 200, y = 0 }, // Top right
    { x = 168, y = 45 }, // Bottom right
    { x = 0, y = 45 }, // Bottom left
}

// Temporary hud.
function GM:HUDPaint()
    // Don't draw the hud if it's disabled.
    if GetConVar("sb_nohud"):GetInt() >= 1 then return end

    local ply = LocalPlayer()

    // Player's dead, don't draw anything.
    if !ply:Alive() or ply:Health() <= 0 then
        healthMemory = 100
        armorMemory = 100
        return
    end
    
    local offset = 2 // Offset for shadows
    local font = "VCROSDMono" // Font to draw text with (don't change unless you wan't to adjust every XY position)

    // draw the crosshairs first.

    // The world crosshair should not be off-screen.
    if mouseWorld.x >= ScrW()-mouseWorld.w then // Right side of the screen
        mouseWorld.x = ScrW()-mouseWorld.w
    elseif mouseWorld.x <= 0 then // Left side of the screen
        mouseWorld.x = 0
    end
    
    if mouseWorld.y >= ScrH()-mouseWorld.h then // Bottom of the screen
        mouseWorld.y = ScrH()-mouseWorld.h
    elseif mouseWorld.y <= 0 then // Top of the screen
        mouseWorld.y = 0
    end

    // The same should be for the main crosshair.
    if mouseCursor.x >= ScrW()-mouseCursor.w then // Right side of the screen
        mouseCursor.x = ScrW()-mouseCursor.w
    elseif mouseCursor.x <= 0 then // Left side of the screen
        mouseCursor.x = 0
    end
    
    if mouseCursor.y >= ScrH()-mouseCursor.h then // Bottom of the screen
        mouseCursor.y = ScrH()-mouseCursor.h
    elseif mouseCursor.y <= 0 then // Top of the screen
        mouseCursor.y = 0
    end


    // Cursor shadows
    local mouseShadow = table.Copy(mouseCursor)
    mouseShadow.color = Color(0,0,0,128)
    mouseShadow.x = mouseCursor.x+2
    mouseShadow.y = mouseCursor.y+2
    // World cursor shadows
    local mouseWorldShadow = table.Copy(mouseWorld)
    mouseWorldShadow.color = Color(0,0,0,128)
    mouseWorldShadow.x = mouseWorld.x+2
    mouseWorldShadow.y = mouseWorld.y+2

    if !zoom then
        // mouse crosshair
        draw.TexturedQuad( mouseShadow )
        draw.TexturedQuad( mouseCursor )
        // world crosshair
        draw.TexturedQuad( mouseWorldShadow )
        draw.TexturedQuad( mouseWorld )
    end

    // draw players' names
    for _, ent in ipairs(player.GetAll()) do
        if not IsValid(ent) then continue end
        if ent == ply then continue end
		local point = ent:GetPos() + ent:OBBCenter()
		local data2D = point:ToScreen()
		if ( not data2D.visible ) then continue end
        draw.SimpleText( ent:Nick(), "TargetID", data2D.x+2, data2D.y+2, Color(0,0,0,127), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        draw.SimpleText( ent:Nick(), "TargetID", data2D.x+1, data2D.y+1, Color(127,127,127,192), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( ent:Nick(), "TargetID", data2D.x, data2D.y, Color(255,255,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

    // Draw the temporary text to explain that everything isn't final.
    local temptext = "Welcome to Split Bullet"..self.SplitBulletSuffix.."! All assets are placeholders and are subject to change."
    surface.SetFont("DermaLarge")
    local tempsizex, tempsizey = surface.GetTextSize(temptext)
    surface.SetDrawColor(0,0,0,192)
    surface.DrawRect(0, 15-4, ScrW(), tempsizey+4)
    draw.SimpleText(temptext, "DermaLarge", temppos+(offset), 15+(offset), Color(0,0,0,127), TEXT_ALIGN_CENTER)
    draw.SimpleText(temptext, "DermaLarge", temppos+(offset/2), 15+(offset/2), Color(127,127,127,192), TEXT_ALIGN_CENTER)
    draw.SimpleText(temptext, "DermaLarge", temppos, 15, Color(255,255,255,255), TEXT_ALIGN_CENTER)

    // Draws the health bar.
    // This is messy but it looks great.
    health = math.Clamp(ply:Health(),0,100)
    if ply:HasGodMode() then
        health = 100 // Health bar should always be full in god mode.
    end
	healthMemory = math.Approach(healthMemory,health,dt*50)
    // Health bar back shadow
    local health_shape = table.Copy(rhombus)
    for k,v in pairs(health_shape) do
        v.x = v.x+100+offset
        v.y = v.y+100+offset
    end
    surface.SetDrawColor(0,0,0,127)
    draw.NoTexture()
	surface.DrawPoly(health_shape)
    // Health bar front shadow
    for k,v in pairs(health_shape) do
        v.x = v.x+(offset/2)
        v.y = v.y+(offset/2)
    end
    surface.SetDrawColor(127,127,127,192)
    draw.NoTexture()
	surface.DrawPoly(health_shape)
    // Health bar background
    for k,v in pairs(health_shape) do
        v.x = v.x-offset-(offset/2)
        v.y = v.y-offset-(offset/2)
    end
    surface.SetDrawColor(96,96,96,255)
    draw.NoTexture()
	surface.DrawPoly(health_shape)
    // Health bar foreground (red bar)
    local health_shape_memory = table.Copy(rhombus)
    health_shape_memory[2].x = health_shape_memory[3].x*(healthMemory*0.01)+32
    health_shape_memory[3].x = health_shape_memory[2].x-32
    for k,v in pairs(health_shape_memory) do
        v.x = v.x+100
        v.y = v.y+100
    end
    surface.SetDrawColor(255, 0, 0, 255)
    draw.NoTexture()
	surface.DrawPoly(health_shape_memory)

    // Draws the armor bar.
    // Equally as messy, but still looks nice.
    armor = math.Clamp(ply:Armor(),0,100)
    if armor > 0 then
        armorMemory = math.Approach(armorMemory,armor,dt*50)
        // Armor bar back shadow
        local armor_shape = table.Copy(rhombus)
        for k,v in pairs(armor_shape) do
            v.x = v.x+100+offset
            v.y = v.y+150+offset
        end
        surface.SetDrawColor(0,0,0,127)
        draw.NoTexture()
        surface.DrawPoly(armor_shape)
        // Armor bar front shadow
        for k,v in pairs(armor_shape) do
            v.x = v.x+(offset/2)
            v.y = v.y+(offset/2)
        end
        surface.SetDrawColor(127,127,127,192)
        draw.NoTexture()
        surface.DrawPoly(armor_shape)
        // Armor bar background
        for k,v in pairs(armor_shape) do
            v.x = v.x-offset-(offset/2)
            v.y = v.y-offset-(offset/2)
        end
        surface.SetDrawColor(96,96,96,255)
        draw.NoTexture()
        surface.DrawPoly(armor_shape)
        // Armor bar foreground (blue bar)
        local armor_shape_memory = table.Copy(rhombus)
        armor_shape_memory[2].x = armor_shape_memory[3].x*(armorMemory*0.01)+32
        armor_shape_memory[3].x = armor_shape_memory[2].x-32
        for k,v in pairs(armor_shape_memory) do
            v.x = v.x+100
            v.y = v.y+150
        end
        surface.SetDrawColor(0,127,255,255)
        draw.NoTexture()
        surface.DrawPoly(armor_shape_memory)
    end

    // This determines whether or not to draw the viewmodel.
    // Right now, let's only draw the viewmodel in first person.
    ply:DrawViewModel(zoom)

    // Getting the ammo from the weapon.
    local wep = ply:GetActiveWeapon() 
    local ammotext = ""
    local wepname = ""
    if IsValid(wep) then
        local clip = wep:Clip1()
        local maxclip = wep:GetMaxClip1()
        local count = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
        if clip < 0 then
            clip = 0
        end
        if clip == 0 and maxclip <= -1 and count > 0 then
            clip = 1
        end
        ammotext = clip.."/"..count // Ammo amount is set here.
        // Getting the name of the active weapon.
        if wep:GetPrintName() ~= "<MISSING SWEP PRINT NAME>" then // this is not a mistake, https://wiki.facepunch.com/gmod/Weapon:GetPrintName
            if ammotext == "0/0" then // If there is no ammo, then we don't need to show clip or ammo.
                ammotext = wep:GetPrintName()
            else
                wepname = wep:GetPrintName()
            end
        end
    end

    // If the player has godmode, let's make the health say infinity.
    local healthtext = health
    if ply:HasGodMode() then
        healthtext = "∞"
    end

    // health
    draw.SimpleText(healthtext, font, 200+(offset), 60+(offset), Color(0,0,0,127), TEXT_ALIGN_CENTER)
    draw.SimpleText(healthtext, font, 200+(offset/2), 60+(offset/2), Color(127,127,127,192), TEXT_ALIGN_CENTER)
    draw.SimpleText(healthtext, font, 200, 60, Color(255,0,0,255), TEXT_ALIGN_CENTER)

    // armor
    if armor > 0 then
        draw.SimpleText(armor, font, 200+(offset), 200+(offset), Color(0,0,0,127), TEXT_ALIGN_CENTER)
        draw.SimpleText(armor, font, 200+(offset/2), 200+(offset/2), Color(127,127,127,192), TEXT_ALIGN_CENTER)
        draw.SimpleText(armor, font, 200, 200, Color(0,127,255,255), TEXT_ALIGN_CENTER)
    end

    // weapon name
    draw.SimpleText(wepname, font, 100+(offset), ScrH()-200+(offset), Color(0,0,0,127))
    draw.SimpleText(wepname, font, 100+(offset/2), ScrH()-200+(offset/2), Color(127,127,127,192))
    draw.SimpleText(wepname, font, 100, ScrH()-200, Color(255,192,0,255))

    // ammo
    draw.SimpleText(ammotext, font, 100+(offset), ScrH()-150+(offset), Color(0,0,0,127))
    draw.SimpleText(ammotext, font, 100+(offset/2), ScrH()-150+(offset/2), Color(127,127,127,192))
    draw.SimpleText(ammotext, font, 100, ScrH()-150, Color(255,192,0,255))

    dt = FrameTime() // Delta time should be set after each render frame.

    // Marquee text scrolling
    if temppos <= -(tempsizex/2) then
        temppos = ScrW()+(tempsizex/2)
    end
    temppos = temppos - 1
end

// Draw weapon tracer.
function GM:PreDrawEffects()
    local ply = LocalPlayer()
    if !ply:Alive() or ply:Health() <= 0 then
        return // Don't draw effects if the player is dead.
    end
    local aim = ply:GetEyeTrace().HitPos --gui.ScreenToVector(mouseCursor.x, mouseCursor.y) -- ply:GetEyeTrace().HitPos
    local aimscreen = aim:ToScreen()
    render.SetMaterial(Material("sprites/light_ignorez"))
    render.DrawSprite( aim, 16, 16, Color(0, 255, 255))
    // World cursor x, y
    mouseWorld.x = aimscreen.x-mouseWorld.w/2
    mouseWorld.y = aimscreen.y-mouseWorld.h/2
end

// Render depth of field.
// FIXME: This has no effect?
function GM:RenderScene()
    if !zoom then
        RenderSuperDoF( oldorigin, Angle( 0, 90, 0 ), oldfov)
    end
end

local framemultiplier = 10 // Multiply the framrtime by this, used to make the camera lerp more smooth.

// Place the camera into 2D mode.
function GM:CalcView(player, origin, angles, fov)
    zoomer = 300 // Zooming back to normal.
    framemultiplier = 10 // Back to normal.
    if input.IsControlDown() then
        zoomer = 600 // Zooming out.
        framemultiplier = 20 // Make the camera smoother when zoomed out.
    elseif input.IsShiftDown() then
        zoomer = 100 // Zooming in.
        framemultiplier = 20 // Make it more responsive when up close.
    end
	zoomerMemory = math.Approach(zoomerMemory,zoomer,dt*50) // Lerping the zoom.

    if zoom then return end // First person, don't do anything.
    oldfov = fov

    local plyview = {}
    local trace = {}
    local orgpos = player:GetPos()
    local startpos = player:GetPos()+player:OBBCenter()
    local endpos = player:GetPos()+player:OBBCenter()

    startpos.y = startpos.y-100 // how far back the camera should start tracing.
    endpos.y = endpos.y-zoomer // how far back the camera should end tracing.

    trace.start = startpos
    trace.mask = MASK_SOLID_BRUSHONLY
    trace.endpos = endpos

    local result = util.TraceLine(trace)
    local back = result.HitPos.y
    local neworigin 
    if !zoom then
        neworigin = orgpos+Vector( 0, back, 50 )
    else
        neworigin = origin
    end

    // Let's put the player at their ragdoll instead of their OBB center.
    if !player:Alive() and IsValid(player:GetRagdollEntity()) then
        neworigin = player:GetRagdollEntity():GetPos()+Vector( 0, back/2, 0 )
    end

    if oldorigin == nil then
        oldorigin = neworigin
    end

    oldorigin = LerpVector(FrameTime() * framemultiplier, oldorigin, neworigin)

    plyview.origin = oldorigin
    plyview.fov = 75

    if zoom then
        plyview.angles = angles
    else
        plyview.angles = Angle( 0, 90, 0 )
    end

	return plyview
end

// Move the player's eyes every tick.
function GM:Think()
    if !zoom then
        local player = LocalPlayer()
        if !player:Alive() then return end

        local orgpos = player:GetPos()
        local start = orgpos + player:OBBCenter()
        --start.z = start.z+25
        local aa = start:ToScreen()
        // Cast the mouse cursor to the screen and rotate the player accordingly.
        local angle = math.atan2(aa.y - mouseCursor.y-(mouseCursor.h/2), aa.x - mouseCursor.x-(mouseCursor.w/2)) * (360 / math.pi)
        local pitch = 0

        // reverse the player's pitch when they look left.
        if angle <= 180 and angle >= -180 then
            pitch = 180
            angle = angle*-1
            reversed = true
        else
            reversed = false
        end
        player:SetEyeAngles(Angle(angle,pitch,0))
    end
end

// Mouse cursor and player movement.
function GM:StartCommand(player, cmd)
    if !player:Alive() then return end
    if !zoom then
        // Stop crouching (until we have animation support).
        cmd:RemoveKey(IN_DUCK)
        cmd:RemoveKey(IN_SPEED)
        // Stop forward movement.
        local side = cmd:GetSideMove()
        local forward = cmd:GetForwardMove()
        if side ~= 0 then
            if reversed then
                side = side*-1
            end
            cmd:SetForwardMove(side)
            cmd:SetSideMove(0)
        end
        // Get the mouse cursor position.
        local sensitivity = GetConVar("sb_mousesensitivity"):GetFloat()
        local x = mouseCursor.x + cmd:GetMouseX()*sensitivity
        local y = mouseCursor.y + cmd:GetMouseY()*sensitivity
        if x > 0 and x < ScrW() then
            mouseCursor.x = x
        end
        if y > 0 and y < ScrH() then
            mouseCursor.y = y
        end
    end
end

// Halos are outlines that draw in the world, we draw them here for the player and their weapon.
function GM:PreDrawHalos()
    local halotable = {}
    local ply = LocalPlayer()
    local wep = ply:GetActiveWeapon()

    if ply:IsValid() then
        if ply:Alive() then
            table.insert(halotable, ply)
            if wep:IsValid() then
                table.insert(halotable, wep)
            end
        end
    else
        halotable = {}
    end
    
    local pcolor = ply:GetPlayerColor()
    local actualpcolor = Color(0, 0, 0)

    actualpcolor.r = pcolor.x * 255
    actualpcolor.g = pcolor.y * 255
    actualpcolor.b = pcolor.z * 255

    halo.Add(halotable, actualpcolor)
end

// Don't draw the player unless they're not in first person.
function GM:ShouldDrawLocalPlayer()
    return !zoom
end

// Disable HL2 hud elements.
function GM:HUDShouldDraw(name)
    // Or better yet, enable the HL2 hud if this is set to 2.
    if GetConVar("sb_nohud"):GetInt() >= 2 then return true end
    return !table.HasValue(disabledHuds, name)
end

// Concommands for first person mode.
concommand.Add("splitbullet_firstperson", function()
    zoom = true
end, nil, "Enables firstperson") //, FCVAR_CHEAT)

concommand.Add("splitbullet_thirdperson", function()
    zoom = false
end, nil, "Enables thirdperson") //, FCVAR_CHEAT)

concommand.Add("splitbullet_toggleperson", function()
    zoom = !zoom
end, nil, "Toggles thirdperson/firstperson.") //, FCVAR_CHEAT)
