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

// This is how we determine what the player is given when they spawn.

DEFINE_BASECLASS( "player_default" )
 
local PLAYER = {} 

PLAYER.DisplayName			= "Split Guy"

PLAYER.WalkSpeed			= 450		-- How fast to move when not running
PLAYER.RunSpeed				= 450		-- How fast to move when running
PLAYER.CrouchedWalkSpeed	= 0.3		-- Multiply move speed by this when crouching
PLAYER.DuckSpeed			= 0.3		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.3		-- How fast to go from ducking, to not ducking
PLAYER.JumpPower			= 250		-- How powerful our jump should be
PLAYER.CanUseFlashlight		= true		-- Can we use the flashlight
PLAYER.MaxHealth			= 100		-- Max health we can have
PLAYER.MaxArmor				= 100		-- Max armor we can have
PLAYER.StartHealth			= 100		-- How much health we start with
PLAYER.StartArmor			= 100			-- How much armour we start with
PLAYER.DropWeaponOnDie		= false		-- Do we drop our weapon when we die
PLAYER.TeammateNoCollide	= true		-- Do we collide with teammates or run straight through them
PLAYER.AvoidPlayers			= true		-- Automatically swerves around other players
PLAYER.UseVMHands			= true		-- Uses viewmodel hands (does this work???)


function PLAYER:Loadout()
	self.Player:SetWalkSpeed(self.WalkSpeed)
	self.Player:SetRunSpeed(self.RunSpeed)
	self.Player:SetCrouchedWalkSpeed(self.CrouchedWalkSpeed)
	self.Player:SetDuckSpeed(self.DuckSpeed)
	self.Player:SetUnDuckSpeed(self.UnDuckSpeed)
	self.Player:SetJumpPower(self.JumpPower)
	self.Player:AllowFlashlight(self.CanUseFlashlight)
	self.Player:ShouldDropWeapon(self.DropWeaponOnDie)
	self.Player:SetNoCollideWithTeammates(self.TeammateNoCollide)
	self.Player:SetAvoidPlayers(self.AvoidPlayers)

	self.Player:SetMaxHealth(self.MaxHealth)
	self.Player:SetMaxArmor(self.MaxArmor)

	self.Player:SetHealth(self.StartHealth)
	self.Player:SetArmor(self.StartArmor)

    self.Player:RemoveAllItems()
    self.Player:RemoveAllAmmo()
	
    self.Player:GiveAmmo(256, "Pistol", true)
    self.Player:Give("weapon_glock")
end

function PLAYER:SetModel()
	local modelname = "models/splitbullet/player.mdl"
	util.PrecacheModel( modelname )
	self.Player:SetModel( modelname )
    self.Player:SetSkin(0)
end
 
player_manager.RegisterClass( "player_splitbullet", PLAYER, "player_default")
