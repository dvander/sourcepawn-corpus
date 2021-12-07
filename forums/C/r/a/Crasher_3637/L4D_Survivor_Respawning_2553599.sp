#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define L4D Survivor Respawn
#define PLUGIN_VERSION "1.25"

new bool:isRespawn = false;
new bool:isBot = false;
new bool:isIncapped = false;
new bool:isHanging = false;
new bool:isRespected = false;
new bool:isRescuable[MAXPLAYERS + 1] = false;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

new Handle:cvarEnable;
new Handle:cvarEnableBot;
new Handle:cvarRespawnHanging;
new Handle:cvarRespawnIncapped;
new Handle:cvarRespawnRespect;
new Handle:cvarRespawnLimit;
new Handle:cvarRespawnTimeout;
new Handle:cvarRespawnHP;
new Handle:cvarRespawnBuffHP;
new Handle:RespawnTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:cvarIncapDelay;
new Handle:cvarHangingDelay;
new Handle:HangingTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:IncapTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:PluginStartTimer = INVALID_HANDLE;

new Handle:FirstWeapon;
new Handle:ThrownWeapon;
new Handle:PrimeHealth;
new Handle:SecondaryHealth;

new RespawnLimit[MAXPLAYERS + 1] = 0;
new BufferHP = -1;

public Plugin:myinfo = 
{
    name = "[L4D] Survivor Respawning",
    author = "Mortiegama",
    description = "When a Survivor dies, is hanging. or is incapped, will respawn after a period of time.",
    version = PLUGIN_VERSION,
    url = ""

	//Special Thanks:
	//AtomicStryker - SM_Respawn & Infected Ghost Everywhere
	//This plugin contains scripts from SM Respawn and uses the gamedata file
}

public OnPluginStart()
{
	CreateConVar("l4d_survivorrespawn_version", PLUGIN_VERSION, "Survivor Respawning Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarEnable = CreateConVar("l4d_survivorrespawn_enable", "1", "Enables Survivors to respawn automatically when incapped and/or killed (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarEnableBot = CreateConVar("l4d_survivorrespawn_enablebot", "1", "Allows Bots to respawn automatically when incapped and/or killed (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRespawnHanging = CreateConVar("l4d_survivorrespawn_hanging", "0", "Survivors will be killed when hanging and respawn afterwards (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRespawnIncapped = CreateConVar("l4d_survivorrespawn_incapped", "1", "Survivors will be killed when incapped and respawn afterwards (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRespawnRespect = CreateConVar("l4d_survivorrespawn_limitenable", "1", "Enables the respawn limit for Survivors (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRespawnLimit = CreateConVar("l4d_survivorrespawn_deathlimit", "2", "Amount of times a Survivor can respawn before permanently dying (Def 2)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarRespawnTimeout = CreateConVar("l4d_survivorrespawn_respawntimeout", "10", "How many seconds till the Survivor respawns (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarIncapDelay = CreateConVar("l4d_survivorrespawn_incapdelay", "25", "How many seconds till the Survivor is killed after being incapacitated (Def 25)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHangingDelay = CreateConVar("l4d_survivorrespawn_hangingdelay", "25", "How many seconds till the Survivor is killed while hanging (Def 25)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarRespawnHP = CreateConVar("sm_survivorrespawn_respawnhp", "70", "Amount of HP a Survivor will respawn with (Def 70)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarRespawnBuffHP = CreateConVar("sm_survivorrespawn_respawnbuffhp", "30", "Amount of buffer HP a Survivor will respawn with (Def 30)", FCVAR_PLUGIN, true, 0.0, false, _);	
	
	FirstWeapon = CreateConVar("l4d_survivorrespawn_firstweapon", "1", "Which primary weapon will be given to the Survivor (1 - Autoshotgun, 2 - M16, 3 - Hunting Rifle, 4 - None)", FCVAR_PLUGIN, true, 0.0, false, _);
	ThrownWeapon = CreateConVar("l4d_survivorrespawn_thrownweapon", "3", "Which throwable will be given to the Survivor (1 - Molotov, 2 - Pipe Bomb, 3 - None)", FCVAR_PLUGIN, true, 0.0, false, _);
	PrimeHealth = CreateConVar("l4d_survivorrespawn_primehealth", "1", "Which carriable health unit will be given to the Survivor (1 - Medkit, 2 - None)", FCVAR_PLUGIN, true, 0.0, false, _);
	SecondaryHealth = CreateConVar("l4d_survivorrespawn_secondaryhealth", "1", "Which medical supply will be given to the Survivor (1 - Pills, 2 - None)", FCVAR_PLUGIN, true, 0.0, false, _);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	LoadTranslations("common.phrases");
	hGameConf = LoadGameConfigFile("l4drespawn");
	AutoExecConfig(true, "plugin.L4D.SurvivorRespawn");
	BufferHP = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarEnable))
	{
		isRespawn = true;
	}

	if (GetConVarInt(cvarEnableBot))
	{
		isBot = true;
	}

	if (GetConVarInt(cvarRespawnHanging))
	{
		isHanging = true;
	}

	if (GetConVarInt(cvarRespawnIncapped))
	{
		isIncapped = true;
	}

	if (GetConVarInt(cvarRespawnRespect))
	{
		isRespected = true;
	}
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}	
	
	return Plugin_Stop;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new client=1; client<=MaxClients; client++)
	{
		RespawnLimit[client] = 0;
		
		if (RespawnTimer[client] != INVALID_HANDLE)
		{
			KillTimer(RespawnTimer[client]);
			RespawnTimer[client] = INVALID_HANDLE;
		}
	}
}

public Event_PlayerLedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (isRespawn && isHanging && IsValidClient(client))
	{
		HangingTimer[client] = CreateTimer(GetConVarFloat(cvarHangingDelay), Timer_HangingRespawn, client); 
		isRescuable[client] = true;
	}
}

public Action:Timer_HangingRespawn(Handle:timer, any:client)
{
	new limit = GetConVarInt(cvarRespawnLimit);

	if (IsValidClient(client) && isRescuable[client] && IsPlayerHanging(client))
	{
		if (RespawnLimit[client] < limit)
		{
			ForcePlayerSuicide(client);
			isRescuable[client] = false;
		}
		else if (RespawnLimit[client] >= limit)
		{
			PrintHintText(client, "You have reached your respawn limit and will be unable to revive on your own.");
			isRescuable[client] = false;
		}
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		isRescuable[client] = false;
	}
	
	if (HangingTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HangingTimer[client]);
		HangingTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Event_PlayerIncapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (isRespawn && isIncapped && IsValidClient(client))
	{
		IncapTimer[client] = CreateTimer(GetConVarFloat(cvarIncapDelay), Timer_IncapRespawn, client); 
		isRescuable[client] = true;
	}
}
		
public Action:Timer_IncapRespawn(Handle:timer, any:client)
{
	new limit = GetConVarInt(cvarRespawnLimit);
	
	if (IsValidClient(client) && isRescuable[client] && IsPlayerIncapped(client))
	{
		if (RespawnLimit[client] < limit)
		{
			ForcePlayerSuicide(client);
		}
		else if (RespawnLimit[client] >= limit)
		{
			PrintHintText(client, "You have reached your respawn limit and will be unable to revive on your own.");
		}
	}

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		isRescuable[client] = false;
	}
	
	if (IncapTimer[client] != INVALID_HANDLE)
	{
		KillTimer(IncapTimer[client]);
		IncapTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	new limit = GetConVarInt(cvarRespawnLimit);
	new time = GetConVarInt(cvarRespawnTimeout);

	if (isRespawn && !isRespected && IsValidClient(client))
	{
		RespawnTimer[client] = CreateTimer(GetConVarFloat(cvarRespawnTimeout), Timer_Respawn, client); 
		PrintHintText(client, "You will automatically respawn in %i seconds.", time);
		isRescuable[client] = false;
	}

	if (isRespawn && isRespected && IsValidClient(client))
	{
		if (RespawnLimit[client] < limit)
		{
			RespawnLimit[client] += 1;
			RespawnTimer[client] = CreateTimer(GetConVarFloat(cvarRespawnTimeout), Timer_Respawn, client); 
			PrintHintText(client, "You will automatically respawn in %i seconds.", time);
			isRescuable[client] = false;
		}
		else if (RespawnLimit[client] >= limit)
		{
			PrintHintText(client, "You have reached your respawn limit and will be unable to revive.");
			isRescuable[client] = false;
		}
	}
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"victim"));

	isRescuable[client] = false;
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		SDKCall(hRoundRespawn, client);
		
		SetHealth(client);
		GiveItems(client);
		Teleport(client);

		decl String:playername[64];
		GetClientName(client, playername, sizeof(playername));
		PrintToChatAll("Player \x05%s \x01has been respawned.", playername);
	}
	
	if (RespawnTimer[client] != INVALID_HANDLE)
	{
		KillTimer(RespawnTimer[client]);
		RespawnTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

SetHealth(client)
{
	new Float:sBuff = GetEntDataFloat(client, BufferHP);
	new sBonusHP = GetConVarInt(cvarRespawnHP);
	new sBuffHP = GetConVarInt(cvarRespawnBuffHP);

	SetEntProp(client, Prop_Send, "m_iHealth", sBonusHP, 1);
	SetEntDataFloat(client, BufferHP, sBuff + sBuffHP, true);
}

GiveItems(client)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
		
	switch (GetConVarInt(FirstWeapon))
	{
		case 1:
		{
			FakeClientCommand(client, "give autoshotgun");
		}
		case 2:
		{
			FakeClientCommand(client, "give rifle");
		}
		case 3:
		{
			FakeClientCommand(client, "give hunting_rifle");
		}
	}
	switch (GetConVarInt(ThrownWeapon))
		{
		case 1:
		{
			FakeClientCommand(client, "give molotov");
		}
		case 2:
		{
			FakeClientCommand(client, "give pipe_bomb");
		}
	}
	switch (GetConVarInt(PrimeHealth))
	{
		case 1:
		{
			FakeClientCommand(client, "give first_aid_kit");
		}
	}
	switch (GetConVarInt(SecondaryHealth))
	{
		case 1:
		{
			FakeClientCommand(client, "give pain_pills");
		}
	}
	
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

Teleport(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && i != client)
		{
			// get the position coordinates of any active living player
			new Float:coordinates[3];
			GetClientAbsOrigin(i, coordinates);
			TeleportEntity(client, coordinates, NULL_VECTOR, NULL_VECTOR);
			break;
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new client=1; client<=MaxClients; client++)
	{
		RespawnLimit[client] = 0;
		isRescuable[client] = false;
	}
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientInGame(client))
		return false;
		
	if (GetClientTeam(client) != 2)
		return false;

	if (IsFakeClient(client) && !isBot)
		return false;
	
	return true;
}

public IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) 
		return true;
		
	return false;
}

public IsPlayerHanging(client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) 
		return true;
		
	return false;
}