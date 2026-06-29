#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new Handle:mp_forcecamera;

new bool:b_sendproxy_available;

// Spectator Movement modes
enum Obs_Mode
{
	OBS_MODE_NONE = 0,	// not in spectator mode
	OBS_MODE_DEATHCAM,	// special mode for death cam animation
	OBS_MODE_FREEZECAM,	// zooms to a target, and freeze-frames on them
	OBS_MODE_FIXED,		// view from a fixed camera position
	OBS_MODE_IN_EYE,	// follow a player in first person view
	OBS_MODE_CHASE,		// follow a player in third person view
	OBS_MODE_ROAMING,	// free roaming

	NUM_OBSERVER_MODES
};

public Plugin:myinfo = 
{
	name = "Spectate Manager",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Spectate Manager",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru/"
};

public OnPluginStart()
{
	CreateConVar("sm_spectatemanager_version", PLUGIN_VERSION, "The plugin's version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);

	AddCommandListener(Cmd_spec_prev, "spec_prev");
	AddCommandListener(Cmd_spec_next, "spec_next");
	AddCommandListener(Cmd_spec_player, "spec_player");
	AddCommandListener(Cmd_spec_mode, "spec_mode");
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	
	LoadTranslations("common.phrases.txt");
	
	mp_forcecamera = FindConVar("mp_forcecamera");
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || IsFakeClient(client) || GetUserAdmin(client) != INVALID_ADMIN_ID)
		return;
	
	decl String:value[12];
	GetConVarString(mp_forcecamera, value, sizeof(value));
	
	SendConVarValue(client, mp_forcecamera, value);
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || IsFakeClient(client) || GetUserAdmin(client) != INVALID_ADMIN_ID)
		return;
		
	CreateTimer(6.0, DelayedSetObserv, client);
	
	CreateTimer(0.1, DelayedCheckDeath, client);
	
	SendConVarValue(client, mp_forcecamera, "1");
}

public Action:Cmd_spec_mode(client, const String:command[], argc)
{
	if (!client || IsPlayerAlive(client) || GetUserAdmin(client) != INVALID_ADMIN_ID)
		return Plugin_Handled;
	
	new Observing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	if (NextPrevClient(Observing, true) == -1)
		return Plugin_Handled;
	
	SetEntProp(client, Prop_Send, "m_iObserverMode", _:OBS_MODE_IN_EYE);
	
	return Plugin_Handled;
}

public Action:Cmd_spec_player(client, const String:command[], argc)
{
	if (!client || IsPlayerAlive(client) || GetUserAdmin(client) != INVALID_ADMIN_ID)
		return Plugin_Handled;
	
	decl String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	if (arg[0]!='\0')
	{
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		if (target_count != 1)
			return Plugin_Handled;
		
		new observclient = target_list[0];
		if (GetClientTeam(observclient) == GetClientTeam(client))
			return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action:Cmd_spec_next(client, const String:command[], argc)
{
	if (!client || IsPlayerAlive(client) || GetUserAdmin(client) != INVALID_ADMIN_ID)
		return Plugin_Handled;
	
	new Observing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	new NextObserv = NextPrevClient(Observing, true);
	
	if (NextObserv != -1)
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", NextObserv);
	else
		SetEntProp(client, Prop_Send, "m_iObserverMode", _:OBS_MODE_ROAMING);
		
	return Plugin_Handled;
}

public Action:Cmd_spec_prev(client, const String:command[], argc)
{
	if (!client || IsPlayerAlive(client) || GetUserAdmin(client) != INVALID_ADMIN_ID)
		return Plugin_Handled;
	
	new Observing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	new PrevObserv = NextPrevClient(Observing, false);
	if (PrevObserv != -1 )
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", PrevObserv);
	else
		SetEntProp(client, Prop_Send, "m_iObserverMode", _:OBS_MODE_ROAMING);
	
	return Plugin_Handled;
}

public Action:DelayedCheckDeath(Handle:timer, any:client)
{
	decl NextObserv, Observing;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsPlayerAlive(client))
		{
			Observing = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			if (Observing == client && GetClientTeam(client) == GetClientTeam(i))
			{
				NextObserv = NextPrevClient(client, true);
				if (NextObserv > 0)
					SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", NextObserv);
			}
		}
	}
}

public Action:DelayedSetObserv(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsPlayerAlive(client))
	{
		new Observing = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		new NextObserv = NextPrevClient(Observing, true);
		if (NextObserv != -1)
			SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", NextObserv);
	}
}

NextPrevClient(client, bool:Next = true, bool:Alive = true)
{
	if (client <= 0)
		client = 1;
		
	if (client > MaxClients)
		client = MaxClients;
		
	new i = client;
	
	if (Next)
	{
		if (i < MaxClients)
			i++;
	}
	else if (i > 1)
		i--;
	
	for (; ; )
	{
		if (IsClientInGame(i))
		{
			if (!Alive || (Alive && IsPlayerAlive(i)))
			{
				new Team = GetClientTeam(i);
				if (Team == GetClientTeam(client))
					break;
			}
		}
				
		if (i == MaxClients && Next)
			i = 0;
		if (i == 1 && !Next)
			i = MaxClients+1;
		
		if (i == client)
			return -1;
		if (Next)
			i++;
		else
			i--;
	}
	return i;
}