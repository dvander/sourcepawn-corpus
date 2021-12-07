#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "RageQuit",
	author = "AtomicStryker, Troy",
	description = "Displays a message if someone leaves within short time after death",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:DeathTimer[MAXPLAYERS+1];
new Handle:rageTime;

public OnPluginStart()
{
	CreateConVar("sm_ragequit_version", PLUGIN_VERSION, "Rage Quit Version on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	rageTime = CreateConVar("sm_ragequit_timesetting", "10", "How long after death a disconnect is treated as ragequit", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
    
	HookEvent("player_death", Event_Death);
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
}

public OnMapEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (DeathTimer[i] != INVALID_HANDLE)
		{
			KillTimer(DeathTimer[i]);
			DeathTimer[i] = INVALID_HANDLE;
		}
	}
}

public Action:Event_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));    
	if(!client || !IsClientInGame(client) || IsFakeClient(client)) return;
        
	if (DeathTimer[client] != INVALID_HANDLE)
	{
		KillTimer(DeathTimer[client]);
		DeathTimer[client] = INVALID_HANDLE;
	}
	DeathTimer[client] = CreateTimer(GetConVarFloat(rageTime), RemovePlayerTimer, client);
}

public Action:RemovePlayerTimer(Handle:timer, any:client)
{
	DeathTimer[client] = INVALID_HANDLE;
}
	
public Action:PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new String:reason[64];
	GetEventString(event, "reason", reason, sizeof(reason));
	
	if ((DeathTimer[client] != INVALID_HANDLE) && StrEqual(reason, "Disconnect by user."))
	{
		KillTimer(DeathTimer[client]);
		DeathTimer[client] = INVALID_HANDLE;
	
		PrintToChatAll("%N has left in rage.", client);
	}
}