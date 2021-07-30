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

include("player_class/player_splitbullet.lua")

GM.Name     = "Split Bullet: Core"
GM.Author   = "TidalDevs"
GM.Website = "https://www.tidalverse.dev/"

GM.IsSplitBullet = true
GM.SplitBulletSuffix = ": Core"

DeriveGamemode("base")

// Don't allow moving out of bounds.
// TODO: Allow maps to set the player's axis via logic_splitbullet.
function GM:SetupMove(ply, mv, cmd)
    local pos = mv:GetOrigin()
    local axis = ply:GetNWString("PlayerAxis", 0) // This value might be unused.
    mv:SetOrigin(Vector(pos.x, axis, pos.z)) // So instead we're just setting it to 0, which is also fine.
end
