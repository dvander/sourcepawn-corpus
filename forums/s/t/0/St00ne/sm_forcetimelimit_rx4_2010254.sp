/**
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

#define PLUGIN_VERSION "1.0x4"
#include <sourcemod>
#include <sdktools>

new Handle:g_hTimeLimitEnforcer = INVALID_HANDLE;
new g_iTimeLimit = 0;
new Handle:g_enable = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Time Limit Enforcer rx",
	author = "St00ne",
	description = "Forces a map to end when mp_timelimit has been reached (time checked every 30 seconds).",
	version = PLUGIN_VERSION,
	url = "http://www.esc90.fr/"
};

public OnPluginStart()
{
	CreateConVar("sm_forcetimelimit_version", PLUGIN_VERSION, "Time limit enforcer version.", FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_enable = CreateConVar("sm_forcetimelimit_enable", "0", "Enables/disables Time limit enforcer.", FCVAR_NONE, true, 0.0, true, 1.0);
	// mp_timelimit related forwards gone to OnConfigsExecuted...
}

public OnConfigsExecuted()
{
	new Handle:hTimeLimit = FindConVar("mp_timelimit");
	g_iTimeLimit = GetConVarInt(hTimeLimit)*60;
	HookConVarChange(hTimeLimit, ConVar_TimeLimitChanged);
	g_hTimeLimitEnforcer = CreateTimer(30.0, Timer_CheckTimeLimit, GetTime(), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public OnMapEnd()
{
	if(g_hTimeLimitEnforcer != INVALID_HANDLE)
	{
		KillTimer(g_hTimeLimitEnforcer);
		g_hTimeLimitEnforcer = INVALID_HANDLE;
	}
}

public Action:Timer_CheckTimeLimit(Handle:timer, any:time)
{
	if(g_iTimeLimit != 0 && (GetTime() - time) >= g_iTimeLimit)
	{
		if (GetConVarInt(g_enable) == 1)
		{
			new iGameEnd  = FindEntityByClassname(-1, "game_end");
			if (iGameEnd == -1 && (iGameEnd = CreateEntityByName("game_end")) == -1) 
			{
				LogError("Unable to create entity \"game_end\"!");
			} 
			else 
			{
				g_hTimeLimitEnforcer = INVALID_HANDLE;
				AcceptEntityInput(iGameEnd, "EndGame");
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

public ConVar_TimeLimitChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!StrEqual(oldValue, newValue))
	{
		g_iTimeLimit = StringToInt(newValue)*60;
	}
}

//***Thanks to Jannik 'Peace-Maker' Hartung, strontiumdog aka <eva>dog, and Bacardi.***//

//***END***//