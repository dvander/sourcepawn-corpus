/**
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>

#define PLUGIN_VERSION "3.0b"

new Handle:roundend_cvars_reset_enabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Round end cvars reset",
	author = "St00ne",
	description = "Resets any cvar like sv_gravity, phys_pushscale and phys_timescale before a new round starts.",
	version = PLUGIN_VERSION,
	url = "http://www.esc90.fr"
}

public OnPluginStart()
{
	HookEventEx("round_end", round_end, EventHookMode_PostNoCopy);
	roundend_cvars_reset_enabled = CreateConVar("sm_roundend_cvars_reset_enabled", "1", "Enables/disables Round end cvars reset.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("sm_roundend_cvars_reset_version", PLUGIN_VERSION, "Version of Round end cvars reset plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	if (!FileExists("cfg/sourcemod/roundend_cvars_reset.cfg"))
	{
		LogError("Unable to load roundend_cvars_reset.cfg. File may not be present in cfg/sourcemod folder...");
	}
}

public round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(roundend_cvars_reset_enabled) == 1)
	{
		if (FileExists("cfg/sourcemod/roundend_cvars_reset.cfg"))
		{
			ServerCommand("exec sourcemod/roundend_cvars_reset.cfg");
		}
	}
}

/**END**/