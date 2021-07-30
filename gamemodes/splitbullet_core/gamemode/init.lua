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

AddCSLuaFile("player_class/player_splitbullet.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

// These are just here so we can determine if the player has god mode on the client.
local meta = FindMetaTable( "Player" )
meta.DefaultGodEnable  = meta.DefaultGodEnable  or meta.GodEnable
meta.DefaultGodDisable = meta.DefaultGodDisable or meta.GodDisable

// Godmode can be called in addons, like drafts.
function meta:GodEnable()
	self:SetNWBool( "HasGodMode", true )
	self:DefaultGodEnable()
end

function meta:GodDisable()
	self:SetNWBool( "HasGodMode", false )
	self:DefaultGodDisable()
end

// Let's initialize the player when they spawn.
function GM:PlayerSpawn(player, transition)
	// Sets the player's class to the generic split bullet one
    player_manager.SetPlayerClass(player, "player_splitbullet")
	player_manager.RunClass(player, "SetModel")
	player_manager.RunClass(player, "Loadout")
	// According to the wiki, this enum lets players pass through each other. Anti-stuck, if you will.
	// If this is broken, look at https://wiki.facepunch.com/gmod/Enums/COLLISION_GROUP and find a better suitable replacement.
    player:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	player:SetEyeAngles(Angle( 0, 90, 0 )) // Players should be facing right by default. (Sidescrolling)
end

// Players should never be allowed to noclip.
// TODO: Drop players into a psuedo noclip "debug" mode.
// https://youtu.be/SmgdlF5a1hs?t=35
/*
function GM:PlayerNoClip(ply, desiredNoClipState)
	return false
end
*/

// Don't allow friendly fire.
function GM:EntityTakeDamage(target, dmginfo)
    return target:IsPlayer() and dmginfo:GetAttacker():IsPlayer() and target ~= dmginfo:GetAttacker()
end

// Draw a red overlay when the player gets damaged.
function GM:PlayerHurt(ply)
	ply:ScreenFade( SCREENFADE.IN, Color( 255, 0, 0, 24 ), 0.3, 0 )
end

// Don't allow players to use flashlights.
function GM:PlayerSwitchFlashlight(ply, flashState)
	return false
end
