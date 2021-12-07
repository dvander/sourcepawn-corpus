#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <sendproxy>

#define PLUGIN_VERSION "1.3"

new Handle:sm_spectate_team, i_spectate_team,
	Handle:sm_allow_thirdperson, bool:b_allow_thirdperson,
Handle:mp_forcecamera;

new bool:b_sendproxy_available;

new g_iObserverMode, g_iObserverTarget;

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

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SendProxy_IsHooked");
	MarkNativeAsOptional("SendProxy_Hook");
}

public OnPluginStart()
{
	CreateConVar("sm_spectatemanager_version", PLUGIN_VERSION, "The plugin's version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	sm_spectate_team = CreateConVar("sm_spectate_team", "3", "Which team to spectate. 2 = Terrorists, 3 = Counter-Terrorists", FCVAR_PLUGIN, true, 2.0, true, 3.0);
	sm_allow_thirdperson = CreateConVar("sm_allow_thirdperson", "1", "Allow or Disallow the thirdperson view.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	i_spectate_team = GetConVarInt(sm_spectate_team);
	b_allow_thirdperson = GetConVarBool(sm_allow_thirdperson);
	
	HookConVarChange(sm_spectate_team, OnConVarChange);
	HookConVarChange(sm_allow_thirdperson, OnConVarChange);

	AddCommandListener(Cmd_spec_prev, "spec_prev");
	AddCommandListener(Cmd_spec_next, "spec_next");
	AddCommandListener(Cmd_spec_player, "spec_player");
	AddCommandListener(Cmd_spec_mode, "spec_mode");
	
	HookEvent("player_death", OnPlayerDeath);
	
	LoadTranslations("common.phrases.txt");
	
	mp_forcecamera = FindConVar("mp_forcecamera");
	
	if ((g_iObserverMode = FindSendPropOffs("CCSPlayer", "m_iObserverMode")) == -1)
		SetFailState("Could not find offset \"m_iObserverMode\"");
	if ((g_iObserverTarget = FindSendPropOffs("CCSPlayer", "m_hObserverTarget")) == -1)
		SetFailState("Could not find offset \"m_hObserverTarget\"");
}

public OnAllPluginsLoaded()
{
	b_sendproxy_available = GetExtensionFileStatus("sendproxy.ext") == 1 ? true : false;
}

public OnConfigsExecuted()
{
	SetConVarBool(mp_forcecamera, false, false, false);
	HookConVarChange(mp_forcecamera, OnForceCameraChange);
}

public OnLibraryRemoved(const String:name[])
{
	if (!strcmp(name, "sendproxy.ext"))
	{
		b_sendproxy_available = false;
	}
}

public OnLibraryAdded(const String:name[])
{
	if (!strcmp(name, "sendproxy.ext"))
	{
		b_sendproxy_available = true;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i)) continue;
			OnClientPutInServer(i);
		}
	}
}

public OnForceCameraChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StrEqual(oldValue, newValue, false)) return;
	SetConVarBool(mp_forcecamera, false, false, false);
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == sm_allow_thirdperson)
	{
		b_allow_thirdperson = bool:StringToInt(newValue);
	}
	else if (convar == sm_spectate_team)
	{
		i_spectate_team = StringToInt(newValue);
	}
}

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	if (b_sendproxy_available && !SendProxy_IsHooked(client, "m_iTeamNum"))
	{
		SendProxy_Hook(client, "m_iTeamNum", Prop_Int, ProxyCallback);
	}
}

public Action:ProxyCallback(entity, const String:PropName[], &iValue, element)
{
	if (!IsPlayerAlive(entity))
	{
		iValue = i_spectate_team;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || IsFakeClient(client))
	{
		return;
	}
		
	CreateTimer(6.0, DelayedSetObserv, GetClientUserId(client));
	
	CreateTimer(0.1, DelayedCheckDeath, GetClientUserId(client));
	
	SendConVarValue(client, mp_forcecamera, "1");
}

public Action:Cmd_spec_mode(client, const String:command[], argc)
{
	if (!client || IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	new Observing = GetEntDataEnt2(client, g_iObserverTarget);
	
	if (NextPrevClient(Observing, true) == -1)
	{
		return Plugin_Handled;
	}
	
	new Obs_Mode:newmode;
	if (GetEntData(client, g_iObserverMode)  == _:OBS_MODE_IN_EYE && b_allow_thirdperson)
	{
		newmode = OBS_MODE_CHASE;
	}
	else
	{
		newmode = OBS_MODE_IN_EYE;
	}
	
	SetEntData(client, g_iObserverTarget, _:newmode);
	
	return Plugin_Handled;
}

public Action:Cmd_spec_player(client, const String:command[], argc)
{
	if (!client || IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	decl String:arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	if (arg[0] != '\0')
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
			return Plugin_Continue;
		}
		
		if (target_count != 1)
		{
			return Plugin_Continue;
		}
		
		new observclient = target_list[0];
		if (GetClientTeam(observclient) == i_spectate_team)
		{
			return Plugin_Continue;
		}
		else if ((observclient = GetRandomPlayer(i_spectate_team, true)) != 0)
		{
			SetEntDataEnt2(client, g_iObserverTarget, observclient);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

public Action:Cmd_spec_next(client, const String:command[], argc)
{
	if (!client || IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	new Observing = GetEntDataEnt2(client, g_iObserverTarget);
	
	new NextObserv = NextPrevClient(Observing, true);
	if (NextObserv != -1)
	{
		SetEntDataEnt2(client, g_iObserverTarget, NextObserv);
	}
	else
	{
		SetEntData(client, g_iObserverMode, _:OBS_MODE_ROAMING);
	}
		
	return Plugin_Handled;
}

public Action:Cmd_spec_prev(client, const String:command[], argc)
{
	if (!client || IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	new Observing = GetEntDataEnt2(client, g_iObserverTarget);
	
	new PrevObserv = NextPrevClient(Observing, false);
	if (PrevObserv != -1)
	{
		SetEntDataEnt2(client, g_iObserverTarget, PrevObserv);
	}
	else
	{
		SetEntData(client, g_iObserverMode, _:OBS_MODE_ROAMING);
	}
	
	return Plugin_Handled;
}

public Action:DelayedCheckDeath(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client) || IsPlayerAlive(client)) 
	{
		return;
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && i != client)
		{
			new Observing = GetEntDataEnt2(client, g_iObserverTarget);
			if (Observing == client)
			{
				new NextObserv = NextPrevClient(i, true);
				if (NextObserv > 0)
				{
					SetEntDataEnt2(i, g_iObserverTarget, NextObserv);
				}
			}
		}
	}
}

public Action:DelayedSetObserv(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client) || IsPlayerAlive(client)) 
	{
		return;
	}
	
	new observ = NextPrevClient(client, true);
	if (observ > 0)
	{
		SetEntDataEnt2(client, g_iObserverTarget, observ);
	}
}

stock GetRandomPlayer(team, bool:alive = false)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != team || !(alive && IsPlayerAlive(i))) continue;
		return i;
	}
	return 0;
}

NextPrevClient(client, bool:Next = true, bool:Alive = true)
{
	if (client <= 0)
	{
		client = 1;
	}
		
	if (client > MaxClients)
	{
		client = MaxClients;
	}
	
	new i = client;
	
	if (Next)
	{
		if (i < MaxClients)
		{
			i++;
		}
	}
	else if (i > 1)
	{
		i--;
	}
	
	for (; ; )
	{
		if (IsClientInGame(i))
		{
			if (!Alive || (Alive && IsPlayerAlive(i)))
			{
				if (GetClientTeam(i) == i_spectate_team)
				{
					break;
				}
			}
		}
				
		if (i == MaxClients && Next)
		{
			i = 0;
		}
		if (i == 1 && !Next)
		{
			i = MaxClients+1;
		}
		
		if (i == client)
		{
			return -1;
		}
		if (Next)
		{
			i++;
		}
		else
		{
			i--;
		}
	}
	return i;
}