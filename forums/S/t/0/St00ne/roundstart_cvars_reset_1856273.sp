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

#define PLUGIN_VERSION "v3.0b"

new Handle:roundstart_cvars_reset_enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Round start cvars reset",
	author = "St00ne",
	description = "Resets any cvar like sv_gravity, phys_pushscale and phys_timescale at round start.",
	version = PLUGIN_VERSION,
	url = "http://www.esc90.fr"
}

public OnPluginStart()
{
	HookEventEx("round_freeze_end", round_freeze_end, EventHookMode_PostNoCopy);
	roundstart_cvars_reset_enabled = CreateConVar("sm_roundstart_cvars_reset_enabled", "1", "Enables/disables Round start cvars reset.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("sm_roundstart_cvars_reset_version", PLUGIN_VERSION, "Version of Round start cvars reset plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	if (!FileExists("cfg/sourcemod/roundstart_cvars_reset.cfg"))
	{
		LogError("Unable to load roundstart_cvars_reset.cfg. File may not be present in cfg/sourcemod folder...");
	}
}

public round_freeze_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(roundstart_cvars_reset_enabled) == 1)
	{
		if (FileExists("cfg/sourcemod/roundstart_cvars_reset.cfg"))
		{
			ServerCommand("exec sourcemod/roundstart_cvars_reset.cfg");
		}
	}
}

/**END**/