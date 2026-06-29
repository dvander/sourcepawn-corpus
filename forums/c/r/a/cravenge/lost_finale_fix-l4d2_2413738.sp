#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new bool:IsLostFinale = false;
new bool:HasAlreadyTeleported = false;

public Plugin:myinfo =
{
	name = "[L4D2] Lost Finale Fix",
	author = "cravenge",
	description = "Fixes Finale Map In Lost Where Extra Survivors Are Spawned Below Saferoom.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("lost_finale_fix-l4d2_version", "1.0", "Lost Finale Fix Version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	HookEvent("round_start", OnFixStart);
	HookEvent("player_spawn", OnFixStart);
}

public OnMapStart()
{
	decl String:mapname[64];
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

public Action:OnFixStart(Handle:event, const String:name[], bool:dontBroaadcast)
{
	if(IsLostFinale)
	{
		new falling = GetClientOfUserId(GetEventInt(event, "userid"));
		if(falling <= 0 || falling > MaxClients || !IsClientInGame(falling))
		{
			return;
		}
		
		if(GetClientTeam(falling) == 2)
		{
			CreateTimer(1.0, SafelyTeleport, falling, TIMER_REPEAT);
		}
		
		CreateTimer(10.0, StopTeleportation);
	}
}

public Action:SafelyTeleport(Handle:timer, any:falling)
{
	new Float:safeOrigin[3], Float:safeAngle[3];
	safeOrigin[0] = 29.84;
	safeOrigin[1] = -122.82;
	safeOrigin[2] = 482.03;
	
	safeAngle[0] = 24.24;
	safeAngle[1] = 178.06;
	safeAngle[2] = 0.0;
	
	TeleportEntity(falling, safeOrigin, safeAngle, NULL_VECTOR);
	
	if(HasAlreadyTeleported)
	{
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action:StopTeleportation(Handle:timer)
{
	HasAlreadyTeleported = true;
	return Plugin_Stop;
}

