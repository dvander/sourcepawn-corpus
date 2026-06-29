
new Handle:cvars[5] = { INVALID_HANDLE, ... }
new bool:enabled;
new Float:cvars_value[3];
new team;


#define PLUGIN_VERSION "0.15"

new Handle:h_timers[MAXPLAYERS+1];
new bool:allow_sprint[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Sprint: Source Plugin",
	author = "Alican 'AlicanC' Çubukçuoglu",
	description = "Sprint: Source Plugin",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=57980"
}

public OnPluginStart()
{
	LoadTranslations("plugin.sprintsource.base");

	CreateConVar("sprintsource_version", PLUGIN_VERSION, "Sprint: Source Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);


	cvars[0] = CreateConVar("sm_sprintsource_enable", "1", "Enable/Disable Sprint: Source.", FCVAR_NONE, true, 0.0, true, 1.0);
	cvars[1] = CreateConVar("sm_sprintsource_time", "3", "Sprint: Source sprint time.", FCVAR_NONE, true, 0.0);
	cvars[2] = CreateConVar("sm_sprintsource_cooldown", "10", "Sprint: Source sprint cooldown time.", FCVAR_NONE, true, 0.0);
	cvars[3] = CreateConVar("sm_sprintsource_sprintspeed", "2", "Sprint: Source sprint speed.", FCVAR_NONE, true, 0.0);
	cvars[4] = CreateConVar("sm_sprintsource_team", "0", "Sprint: 2 = Terrorists, 3 = CT, 0 = any", FCVAR_NONE, true, 0.0, true, 3.0);

	HookConVarChange(cvars[0], convar_changed);
	HookConVarChange(cvars[1], convar_changed);
	HookConVarChange(cvars[2], convar_changed);
	HookConVarChange(cvars[3], convar_changed);
	HookConVarChange(cvars[4], convar_changed);

	HookEventEx("player_spawn", player_spawn);
	RegAdminCmd("+ss_sprint", admcmd_sprint, ADMFLAG_SLAY);
	RegAdminCmd("-ss_sprint", admcmd_sprint_stop, ADMFLAG_SLAY);

	convar_changed(cvars[0], "", ""); 	// Late plugin load, this is just for get current cvars values
}

public convar_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	enabled = GetConVarBool(cvars[0]); 			// enable/disable
	cvars_value[0] = GetConVarFloat(cvars[1]);	// Sprint time
	cvars_value[1] = GetConVarFloat(cvars[2]);	// Sprint cooldown
	cvars_value[2] = GetConVarFloat(cvars[3]);	// Sprint speed
	team = GetConVarInt(cvars[4]);				// Sprint team
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!enabled)
	{
		return;
	}

	decl teamindx;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if((teamindx = GetClientTeam(client)) >= 2)
	{
		allow_sprint[client] = true;

		if(h_timers[client] != INVALID_HANDLE) // Timer running
		{
			KillTimer(h_timers[client]);
			h_timers[client] = INVALID_HANDLE;
		}

		if(team > 1 && team != teamindx) // team restriction
		{
			return;
		}
		PrintToChat(client, "%c[Sprint: Source]%c %t", "\x04", "\x01", "SprintSource Command");
	}
}

public Action:admcmd_sprint(client, args)
{
	// No no no no and no, you can't use command...
	decl teamindx;

	if(!enabled || client == 0 || !IsClientInGame(client) || (teamindx = GetClientTeam(client)) < 2 || !IsPlayerAlive(client) || !allow_sprint[client])
	{
		return Plugin_Handled;
	}

	// team restriction added
	if(team > 1 && team != teamindx)
	{
		ReplyToCommand(client, "[Sprint: Source] %s can't use this!", teamindx == 2 ? "Terrorists":"Counter-Terrorists");
		return Plugin_Handled;
	}

	// Client handle not reseted, block command
	if(h_timers[client] != INVALID_HANDLE)
	{
		if(allow_sprint[client]) // Allow player use sprint again ?
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", cvars_value[2]);
		}

		return Plugin_Handled;
	}

	h_timers[client] = CreateTimer(cvars_value[0], timer_sprint, client);
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", cvars_value[2]);
	PrintToChat(client, "%c[Sprint: Source]%c %t", "\x04", "\x01", "SprintSource Start");

	return Plugin_Handled;
}

public Action:admcmd_sprint_stop(client, args)
{
	decl teamindx;
	if(!enabled || client == 0 || !IsClientInGame(client) || (teamindx = GetClientTeam(client)) < 2 || !IsPlayerAlive(client) || !allow_sprint[client])
	{
		return Plugin_Handled;
	}

	if(team > 1 && team != teamindx)
	{
		return Plugin_Handled;
	}

	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	return Plugin_Handled;
}

public Action:timer_sprint(Handle:timer, any:client)
{
	h_timers[client] = INVALID_HANDLE;
	allow_sprint[client] = false;

	if(IsClientInGame(client) && GetClientTeam(client) >= 2 && IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		h_timers[client] = CreateTimer(cvars_value[1], timer_cool, client);
		PrintToChat(client, "%c[Sprint: Source]%c %t", "\x04", "\x01", "SprintSource End");
	}
}

public Action:timer_cool(Handle:timer, any:client)
{
	h_timers[client] = INVALID_HANDLE;
	allow_sprint[client] = true;

	if(IsClientInGame(client) && GetClientTeam(client) >= 2 && IsPlayerAlive(client))
	{
		PrintToChat(client, "%c[Sprint: Source]%c %t", "\x04", "\x01", "SprintSource Cool");
	}
}

/*

public OnClientPutInServer(client)
{
	if(enabled)
	{
		PrintToChat(client, "%c[Sprint: Source]%c %t", "\x04", "\x01", "SprintSource Running", PLUGIN_VERSION);
		PrintToChat(client, "%c[Sprint: Source]%c %t", "\x04", "\x01", "SprintSource Command");
	}
}
*/