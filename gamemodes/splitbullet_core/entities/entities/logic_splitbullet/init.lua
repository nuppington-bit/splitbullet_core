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

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

// This entity is just here to set global variables per-map.
function ENT:KeyValue(key, value)
    if key == "title" then // Map authors can set custom map names
        SetGlobalString("SplitBullet_MapName", value)
    elseif key == "author" then // Map authors can credit themselves here
        SetGlobalString("SplitBullet_MapAuthor", value)
    elseif key == "description" then // Map authors can describe their map here
        SetGlobalString("SplitBullet_MapDescription", value)
    elseif key == "music" then // Map authors can set a custom music track here
        SetGlobalString("SplitBullet_MapMusic", value)
    elseif key == "musicdelay" then // Delay before the music starts
        SetGlobalFloat("SplitBullet_MapMusicDelay", value)
    elseif key == "musicvolume" then // Map authors can set their music volume here
        SetGlobalFloat("SplitBullet_MapMusicVolume", value)
    elseif key == "fadein" then // Map authors can set a fade in duration here
        SetGlobalFloat("SplitBullet_MapFadeIn", value)
    elseif key == "fadeindelay" then // Delay before the fade in starts
        SetGlobalFloat("SplitBullet_MapFadeInDelay", value)
    elseif key == "fadeout" then // Map authors can set a fade out duration here
        SetGlobalFloat("SplitBullet_MapFadeOut", value)
    elseif key == "fadeoutdelay" then // Delay before the fade out starts
        SetGlobalFloat("SplitBullet_MapFadeOutDelay", value)
    end
end
