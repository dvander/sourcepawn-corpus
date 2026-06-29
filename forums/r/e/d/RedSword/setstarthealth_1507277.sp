#pragma semicolon 1

#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "Set Start Health",
	author = "RedSword / Bob Le Ponge", //Based on sm_sethealth code by MrBlip (useful for TF2)
	description = "Set health of a player when he spawns or when round starts",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//CVars
new Handle:g_hStartHealth;
new Handle:g_hStartHealthValue;
new Handle:g_hStartHealthType;

//Mod specific
new bool:g_bIsTF2;
new maxHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};

public OnPluginStart()
{
	//Allow multiples mod
	decl String:szBuffer[16];
	GetGameFolderName(szBuffer, sizeof(szBuffer));
	
	g_bIsTF2 = StrEqual(szBuffer, "tf", false);
	
	//CVARs
	CreateConVar("setstarthealthversion", PLUGIN_VERSION, "Set Health on Spawn version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hStartHealth		= CreateConVar("starthealth", "1", "Is plugin enabled ? 0=No, 1+ =Yes. 2=team 1 only. 3=team 2 only", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hStartHealthValue	= CreateConVar("starthealth_value", "100.0", "Value to change health to. Minimum 1.", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	g_hStartHealthType	= CreateConVar("starthealth_type", "1.0", "When to change health : 0 = On round start, 1 = On player spawn (Default).", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//Config
	AutoExecConfig(true, "setstarthealth");
	
	//Hooks
	HookEvent("player_spawn", Event_Spawn);
	
	if (g_bIsTF2)
		HookEvent("teamplay_round_start", Event_RoundStart);
	else
		HookEvent("round_start", Event_RoundStart);
}

//=====Events

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new enabled = GetConVarInt(g_hStartHealth);
	
	if (enabled == 0 || GetConVarInt(g_hStartHealthType) == 0)
		return bool:Plugin_Continue;
		
	new value = GetConVarInt(g_hStartHealthValue);
	
	new clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	if (clientId != 0 && IsClientInGame(clientId) && IsPlayerAlive(clientId))
	{
		if (enabled == 1 || GetClientTeam(clientId) == enabled)
		{
			setClientHealth(clientId, value);
		}
	}
	
	return bool:Plugin_Handled;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new enabled = GetConVarInt(g_hStartHealth);
	
	if (enabled == 0 || GetConVarInt(g_hStartHealthType) == 1)
		return bool:Plugin_Continue;
	
	new value = GetConVarInt(g_hStartHealthValue);
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (enabled == 1 || GetClientTeam(i) == enabled)
			{
				setClientHealth(i, value);
			}
		}
	}
	
	return bool:Plugin_Handled;
}

//=====Private

//Client is INGAME and ALIVE
setClientHealth(any:iClient, any:value)
{
	//Change max health if TF2
	if (g_bIsTF2)
	{
		new class = GetEntProp(iClient, Prop_Send, "m_iClass");
		
		if (value > maxHealth[class])
		{
			SetEntProp(iClient, Prop_Data, "m_iMaxHealth", value);
		}
	}
	//Then set health
	SetEntityHealth(iClient, value);
}