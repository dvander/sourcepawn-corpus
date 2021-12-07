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

#include <sourcemod>

#define PLUGIN_VERSION "2.1tf2"

new Handle:h_timers[MAXPLAYERS+1];

new Handle:cvars[7] = { INVALID_HANDLE, ... };
new bool:enabled;
new bool:ads_enabled;
new bool:welcome_enabled;
new Float:cvars_value[3];
new team;

new Float:MySpeed[MAXPLAYERS+1] = {0.0, ...};

public Plugin:myinfo = 
{
	name = "Auto Sprint Source",
	author = "St00ne",
	description = "Let players sprint by pressing their use key, or a custom sprint key.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	LoadTranslations("auto_sprint_source.phrases");
	
	//CreateConVar("sm_ass_version", PLUGIN_VERSION, "Auto Sprint Source Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	new Handle:version_cvar = CreateConVar("sm_autosprint_src_version", PLUGIN_VERSION, "Auto Sprint Source Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PRINTABLEONLY);
	SetConVarString(version_cvar, PLUGIN_VERSION, false, false);
	
	cvars[0] = CreateConVar("sm_ass_enabled", "1", "Enable/Disable Auto Sprint Source plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvars[1] = CreateConVar("sm_ass_time", "3", "Sprint time in seconds.", FCVAR_PLUGIN, true, 0.0);
	cvars[2] = CreateConVar("sm_ass_cooldown", "10", "Sprint cooldown time.", FCVAR_PLUGIN, true, 0.0);
	cvars[3] = CreateConVar("sm_ass_speed", "1.8", "Sprint speed ratio.", FCVAR_PLUGIN, true, 0.0);
	cvars[4] = CreateConVar("sm_ass_team", "0", "Sprint team restriction: 2 = Red, 3 = Blue, 0 = all.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvars[5] = CreateConVar("sm_ass_adverts", "1", "Enable/Disable sprint and cooldown messages", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvars[6] = CreateConVar("sm_ass_welcome", "1", "Enable/Disable sprint welcome info", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookConVarChange(cvars[0], convar_changed);
	HookConVarChange(cvars[1], convar_changed);
	HookConVarChange(cvars[2], convar_changed);
	HookConVarChange(cvars[3], convar_changed);
	HookConVarChange(cvars[4], convar_changed);
	HookConVarChange(cvars[5], convar_changed);
	HookConVarChange(cvars[6], convar_changed);
	
	HookEventEx("player_spawn", player_spawn);
	HookEventEx("player_team", player_team);
	HookEventEx("player_death", player_death);
	
	RegConsoleCmd("sprint", Cmd_StartSprint);
	
	convar_changed(cvars[0], "", "");			// On late plugin load, this is just to get current cvars values
}

public convar_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	enabled = GetConVarBool(cvars[0]);			// enable/disable
	cvars_value[0] = GetConVarFloat(cvars[1]);	// Sprint time
	cvars_value[1] = GetConVarFloat(cvars[2]);	// Sprint cooldown
	cvars_value[2] = GetConVarFloat(cvars[3]);	// Sprint speed ratio
	team = GetConVarInt(cvars[4]);				// Sprint team restriction
	ads_enabled = GetConVarBool(cvars[5]);		// enable/disable status messages
	welcome_enabled = GetConVarBool(cvars[6]);	// enable/disable welcome info
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(h_timers[client] != INVALID_HANDLE)	// Timer running
		{
			KillTimer(h_timers[client]);
			h_timers[client] = INVALID_HANDLE;
		}
		if(GetClientTeam(client) > 1)
		{
			MySpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed", _);
		}
	}
}

public player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(h_timers[client] != INVALID_HANDLE)	// Timer running
		{
			//SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", MySpeed[client]);
			KillTimer(h_timers[client]);
			h_timers[client] = INVALID_HANDLE;
		}
	}
}

public player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new teamid = GetEventInt(event, "team");
	
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(teamid < 2 || (team > 1 && team != teamid))
		{
			if(h_timers[client] != INVALID_HANDLE)	// Timer running
			{
				//SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
				if(MySpeed[client] != 0.0)
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", MySpeed[client]);
				}
				KillTimer(h_timers[client]);
				h_timers[client] = INVALID_HANDLE;
			}
		}
	}
}

//Every player who disconnects (for any reason including mapchange) triggers a team change (team < 2), so we don't need this
//public OnPlayerDisconnect(client)
//{
//	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client)
//	{
//		if(h_timers[client] != INVALID_HANDLE)	// Timer running
//		{
//			KillTimer(h_timers[client]);
//			h_timers[client] = INVALID_HANDLE;
//		}
//	}
//}

public Action:Cmd_StartSprint(client, args)
{
	// Baca says: you can't use this command...
	
	decl teamindx;
	
	if(!enabled || client == 0 || !IsClientInGame(client) || (teamindx = GetClientTeam(client)) < 2 || !IsPlayerAlive(client) || IsFakeClient(client))
	{
		return Plugin_Handled;
	}
	
	// team restriction - teamindx is higher than 1 anyway now
	if(team > 1 && team != teamindx)
	{
		ReplyToCommand(client, "[Auto Sprint Source] %s can't use this!", teamindx == 2 ? "Red":"Blue");
		return Plugin_Handled;
	}
	
	// Client handle not reset, command must be blocked
	if(h_timers[client] != INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	
	h_timers[client] = CreateTimer(cvars_value[0], timer_sprint, client);
	//SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", cvars_value[2]);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", MySpeed[client] * cvars_value[2]);
	if (ads_enabled)
	{
		PrintToChat(client, "%c[Auto Sprint Source]%c %t", "\x04", "\x01", "AutoSprintSource Start");
	}
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_USE)
	{
		decl teamindx;
		
		if(!enabled || client == 0 || !IsClientInGame(client) || (teamindx = GetClientTeam(client)) < 2 || !IsPlayerAlive(client) || IsFakeClient(client))
		{
			return Plugin_Continue;
		}
		
		// team restriction
		if(team > 1 && team != teamindx)
		{
			return Plugin_Continue;
		}
		
		if(h_timers[client] != INVALID_HANDLE)
		{
			return Plugin_Continue;
		}
		else
		{
			h_timers[client] = CreateTimer(cvars_value[0], timer_sprint, client);
			//SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", cvars_value[2]);
			SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", MySpeed[client] * cvars_value[2]);
			if (ads_enabled)
			{
				PrintToChat(client, "%c[Auto Sprint Source]%c %t", "\x04", "\x01", "AutoSprintSource Start");
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:timer_sprint(Handle:timer, any:client)
{
	h_timers[client] = INVALID_HANDLE;
	
	new teamid = GetClientTeam(client);
	
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		//SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", MySpeed[client]);
		if(enabled && teamid >= 2 && IsPlayerAlive(client))
		{
			if(team < 1 || team == teamid)
			{
				h_timers[client] = CreateTimer(cvars_value[1], timer_cool, client);
				if (ads_enabled)
				{
					PrintToChat(client, "%c[Auto Sprint Source]%c %t", "\x04", "\x01", "AutoSprintSource End");
				}
			}
		}
	}
}

public Action:timer_cool(Handle:timer, any:client)
{
	h_timers[client] = INVALID_HANDLE;
	
	new teamid = GetClientTeam(client);
	
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(teamid >= 2 && IsPlayerAlive(client) && enabled && ads_enabled)
		{
			if(team < 1 || team == teamid)
			{
				PrintToChat(client, "%c[Auto Sprint Source]%c %t", "\x04", "\x01", "AutoSprintSource Cool");
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(enabled && welcome_enabled)
		{
			PrintToChat(client, "%c[Auto Sprint Source]%c %t", "\x04", "\x01", "AutoSprintSource Running", PLUGIN_VERSION);
			PrintToChat(client, "%c[Auto Sprint Source]%c %t", "\x04", "\x01", "AutoSprintSource Command");
		}
	}
}

/**
 *Original portage to source by Alican 'AlicanC' Çubukçuoglu.
 *First rewrite with team restrictions by Bacardi.
 *Use key function by St00ne, who says:
 *Thanks to Shaman, Baca, Yak for his scripting FAQ, RedSword,
 *and: OMI, you could ve shared...
 */

/**END**/
