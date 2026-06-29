#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.3"

new bool:ThirdEnabled[MAXPLAYERS+1] = false;
new bool:IsRunning[MAXPLAYERS+1] = false;
new bool:DiedSince[MAXPLAYERS+1] = false;

new Handle:g_hDelay = INVALID_HANDLE;
new Float:g_fDelay = 0.2;


public Plugin:myinfo = 

{
	name = "TF2 Real Thirdperson",
	author = "EHG",
	description = "Allows usage of real thirdperson",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_thirdperson", Command_thirdperson, 0, "Usage: sm_thirdperson");
	RegAdminCmd("sm_firstperson", Command_firstperson, 0, "Usage: sm_firstperson");
	
	CreateConVar("sm_real_thirdperson_version", PLUGIN_VERSION, "TF2 Real Thirdperson Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hDelay 					= CreateConVar("sm_thirdperson_taunt_delay", "0.4", "Thirdperson delay after taunt");
	
	HookConVarChange(g_hDelay, Cvar_delay);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		OnClientPostAdminCheck(i);
	}
}


public Cvar_delay(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fDelay = GetConVarFloat(g_hDelay);
}

public OnConfigsExecuted()
{
	g_fDelay = GetConVarFloat(g_hDelay);
}

public OnClientPostAdminCheck(client)
{
	ThirdEnabled[client] = false;
	IsRunning[client] = false;
	DiedSince[client] = false;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	DiedSince[client] = true;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (ThirdEnabled[client])
	{
		SendConVarValue(client, FindConVar("sv_cheats"), "0");
		CreateTimer(0.2, Timer_ThirdpersonSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_ThirdpersonSpawn(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SendConVarValue(client, FindConVar("sv_cheats"), "1");
		ClientCommand(client, "thirdperson");
		ThirdEnabled[client] = true;
	}
}

public Action:Timer_ThirdpersonDelay(Handle:timer, any:client)
{
	if (IsValidClient(client) && !DiedSince[client])
	{
		ClientCommand(client, "thirdperson");
		IsRunning[client] = false;
	}
}

public Action:Timer_ThirdpersonDelayFast(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsRunning[client] && !DiedSince[client])
	{
		ClientCommand(client, "thirdperson");
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Stop;
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(condition == TFCond_Taunting && IsPlayerAlive(client) && IsValidClient(client))
	{
		if (ThirdEnabled[client])
		{
			ClientCommand(client, "thirdperson");
			IsRunning[client] = true;
			DiedSince[client] = false;
			CreateTimer(0.01, Timer_ThirdpersonDelayFast, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(g_fDelay, Timer_ThirdpersonDelay, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}


public Action:Command_thirdperson(client, args)
{
	if (!CheckCommandAccess(client, "sm_real_thirdperson_access", 0))
	{
		ReplyToCommand(client, "[SM] You do not have access to this command.");
		return Plugin_Handled;
	}
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[SM] Must be alive to use this command");
		return Plugin_Handled;
	}
	
	SendConVarValue(client, FindConVar("sv_cheats"), "1");
	ClientCommand(client, "thirdperson");
	
	ThirdEnabled[client] = true;
	return Plugin_Handled;
}

public Action:Command_firstperson(client, args)
{
	if (!CheckCommandAccess(client, "sm_real_thirdperson_access", 0))
	{
		ReplyToCommand(client, "[SM] You do not have access to this command.");
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[SM] Must be alive to use command");
		return Plugin_Handled;
	}
	
	if (ThirdEnabled[client] == true)
	{
		ClientCommand(client, "firstperson");
		if (GetConVarInt(FindConVar("host_timescale")) == 1) { SendConVarValue(client, FindConVar("sv_cheats"), "0"); }
		ThirdEnabled[client] = false;
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}


stock bool:IsValidClient(client)
{
    if (client <= 0) return false;
    if (client > MaxClients) return false;
    if (!IsClientConnected(client)) return false;
    return IsClientInGame(client);
}