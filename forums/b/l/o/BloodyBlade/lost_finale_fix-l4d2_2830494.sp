#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar hLostFinaleFixOn;
bool bPluginOn = false, bHooked = false, IsLostFinale = false, HasAlreadyTeleported[MAXPLAYERS + 1] = {false, ...};
float safeOrigin[3], safeAngle[3];
int falling = 0;

public Plugin myinfo =
{
	name = "[L4D2] Lost Finale Fix",
	author = "cravenge(edit. by BloodyBlade)",
	description = "Fixes Finale Map In Lost Where Extra Survivors Are Spawned Below Saferoom.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2413738"
};

public void OnPluginStart()
{
	CreateConVar("lost_finale_fix-l4d2_version", PLUGIN_VERSION, "Lost Finale Fix Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hLostFinaleFixOn = CreateConVar("lost_finale_fix_on", "1.0", "Lost Finale Fix Plugin On/Off", CVAR_FLAGS);

	hLostFinaleFixOn.AddChangeHook(ConVarPluginOnChanged);

	AutoExecConfig(true, "lost_finale_fix-l4d2");
}

public void OnMapStart()
{
    char mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    if(StrEqual(mapname, "lost02_2"))
    {
        IsLostFinale = true;
    }
    else
    {
        IsLostFinale = false;
    }
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void IsAllowed()
{
	bPluginOn = hLostFinaleFixOn.BoolValue;
	if(bPluginOn && !bHooked && IsLostFinale)
	{
		bHooked = true;
		HookEvent("round_start", OnFixStart);
		HookEvent("player_spawn", OnFixSpawnStart);	
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("round_start", OnFixStart);
		UnhookEvent("player_spawn", OnFixSpawnStart);	
	}
}

Action OnFixStart(Event event, const char[] name, bool dontBroaadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			HasAlreadyTeleported[i] = false;
			CreateTimer(1.0, SafelyTeleport, i, TIMER_REPEAT);
			CreateTimer(10.0, StopTeleportation, i);
		}
	}
	return Plugin_Continue;
}

Action OnFixSpawnStart(Event event, const char[] name, bool dontBroaadcast)
{
	falling = GetClientOfUserId(event.GetInt("userid"));
	if(falling > 0 && IsClientInGame(falling) &&GetClientTeam(falling) == 2)
	{
		HasAlreadyTeleported[falling] = false;
		CreateTimer(1.0, SafelyTeleport, falling, TIMER_REPEAT);
		CreateTimer(10.0, StopTeleportation, falling);
	}
	return Plugin_Continue;
}

Action SafelyTeleport(Handle timer, any iFalling)
{
	if(iFalling > 0 && !HasAlreadyTeleported[iFalling])
	{
		TeleportEntity(iFalling, safeOrigin, safeAngle, NULL_VECTOR);
		return Plugin_Continue;
	}
	else
	{
		timer = null;
		return Plugin_Stop;
	}
}

Action StopTeleportation(Handle timer, any client)
{
	if(!HasAlreadyTeleported[client])
	{
		HasAlreadyTeleported[client] = true;
	}
	return Plugin_Stop;
}
