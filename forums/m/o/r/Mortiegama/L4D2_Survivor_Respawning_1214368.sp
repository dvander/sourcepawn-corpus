#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define L4D2 Survivor Respawn
#define PLUGIN_VERSION "1.0"

new bool:isRespawn;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

new Handle:cvarEnable;
new Handle:cvarRespawnTimeout;
new Handle:RespawnTimer[MAXPLAYERS + 1];

new teleporttarget[MAXPLAYERS+1] = 0;

public Plugin:myinfo = 
{
    name = "[L4D2] Survivor Respawning",
    author = "AtomicStryker & Mortiegama",
    description = "Survivors will die once incapped and respawn after a period of time.",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
	CreateConVar("l4d_survivorrespawn_version", PLUGIN_VERSION, "Survivor Respawning Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarEnable = CreateConVar("l4d_survivorrespawn_enable", "1", "Enables Survivors to respawn automatically (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRespawnTimeout = CreateConVar("l4d_survivorrespawn_timeout", "10", "How many seconds till the Survivor respawns (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);

	if (GetConVarInt(cvarEnable))
	{
		isRespawn = true;
	}

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("round_end", Event_RoundEnd);

	LoadTranslations("common.phrases");
	hGameConf = LoadGameConfigFile("l4drespawn");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");

}

public Event_PlayerIncapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new time = GetConVarInt(cvarRespawnTimeout);

	if (isRespawn && IsValidClient(client) && GetClientTeam(client) == 2)
	{
		ForcePlayerSuicide(client);
		RespawnTimer[client] = CreateTimer(GetConVarFloat(cvarRespawnTimeout), Timer_Respawn, client); 
		PrintHintText(client, "You will automatically respawn in %i seconds.", time);	
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new time = GetConVarInt(cvarRespawnTimeout);

	if (isRespawn && IsValidClient(client) && GetClientTeam(client) == 2)
	{
		ForcePlayerSuicide(client);
		RespawnTimer[client] = CreateTimer(GetConVarFloat(cvarRespawnTimeout), Timer_Respawn, client); 
		PrintHintText(client, "You will automatically respawn in %i seconds.", time);	
	}
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SDKCall(hRoundRespawn, client);

    		new flags = GetCommandFlags("give");
    		SetCommandFlags("give", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give baseball_bat");
		FakeClientCommand(client, "give autoshotgun");
		FakeClientCommand(client, "give pain_pills");
		FakeClientCommand(client, "give pipe_bomb");
    		SetCommandFlags("give", flags|FCVAR_CHEAT);

		decl Float:position[3], Float:anglestarget[3];

		new any:target = FindNewTarget(client, teleporttarget[client]);
		if (!IsClientInGame(target)) target = FindNewTarget(client, 1);
		if (target == client) target = FindNewTarget(client, target);

		GetClientAbsOrigin(target, position);
		GetClientAbsAngles(target, anglestarget);
		TeleportEntity(client, position, anglestarget, NULL_VECTOR);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    	for (new client=1; client<=MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			CloseHandle(RespawnTimer[client]);
			RespawnTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action:FindNewTarget(any:client, any:target)
{
	target++;
	
	for (new i = target; i >= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientHealth(i)>1 && (GetClientTeam(i) == 2) && client != i)
		{
			target = i;
			break;
		}
		if (i >= MaxClients)
		{
			target = 0;
		}
	}
	
	if (!IsClientInGame(target))
	{
		for (new i2 = 1; i2 >= MaxClients; i2++)
		{
			if (IsClientInGame(i2) && GetClientHealth(i2)>1 && (GetClientTeam(i2) == 2) && client != i2)
			{
				target = i2;
				break;
			}
			if (i2 >= MaxClients)
			{
				target = 0;
			}
		}
	}
	return target;
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsValidEntity(client))
		return false;

	return true;
}