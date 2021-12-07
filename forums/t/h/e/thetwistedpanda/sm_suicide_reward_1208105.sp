#include <sourcemod>
#include <sdktools>
#include <colors>
#pragma semicolon 1

#define PLUGIN_VERSION "1.6.8"
#define PLUGIN_PREFIX "\x04Suicide: \x03"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hWeapon = INVALID_HANDLE;
new Handle:g_hMethod = INVALID_HANDLE;
new Handle:g_hSuicide = INVALID_HANDLE;

new bool:g_bEnabled, g_iMethod, Float:g_fSuicide, String:g_sWeapon[255], g_bEnding;
new g_iAttacker[MAXPLAYERS + 1];
new g_iDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
new Handle:g_hTimer[MAXPLAYERS + 1];
new bool:g_bCanSuicide[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Suicide Reward",
	author = "Twisted|Panda",
	description = "Provides a victim's attacker with credit for their suicide if damage was inflicted prior.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com"
}

public OnPluginStart()
{
	LoadTranslations("suicide_reward.phrases");

	CreateConVar("sm_suicide_reward_version", PLUGIN_VERSION, "Suicide Reward Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_suicide_reward", "1.0", "If enabled, players will receive credit for a player's suicide with sm_suicide_reward_event.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWeapon = CreateConVar("sm_suicide_reward_event", "player_suicide", "The cause of death used when a player suicides after being previously attacked.", FCVAR_NONE);
	g_hMethod = CreateConVar("sm_suicide_reward_mode", "1.0", "Determines detecting functioanlity. (-1 = Last Attacker, 0 = Single Highest Damage, 1 = Most Damage)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hSuicide = CreateConVar("sm_suicide_reward_delay", "-1.0", "The number of seconds after a suicide attempt a player must wait before killing himself/herself. -1.0 = Disabled", FCVAR_NONE, true, -1.0);
	AutoExecConfig(true, "sm_suicide_reward");

	HookConVarChange(g_hEnabled, OnSettingsChange);
	HookConVarChange(g_hWeapon, OnSettingsChange);
	HookConVarChange(g_hMethod, OnSettingsChange);
	HookConVarChange(g_hSuicide, OnSettingsChange);

	HookEvent("player_hurt", Event_OnPlayerHurt);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);

	AddCommandListener(Command_Kill, "kill");
	AddCommandListener(Command_Kill, "explode");

	Define_Defaults();
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_bCanSuicide[client] = false;
		if(g_hTimer[client] != INVALID_HANDLE && CloseHandle(g_hTimer[client]))
			g_hTimer[client] = INVALID_HANDLE;
			
		ClearAttackerData(client);
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iAttacker[i] = 0;
				if(g_iMethod >= 0)
					ClearVictimData(i);
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(g_hTimer[i] != INVALID_HANDLE && CloseHandle(g_hTimer[i]))
					g_hTimer[i] = INVALID_HANDLE;
			}
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || GetClientTeam(client) <= 1)
			return Plugin_Continue;

		g_iAttacker[client] = 0;
		if(g_iMethod >= 0)
			ClearVictimData(client);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!attacker || attacker > MaxClients)
			return Plugin_Continue;

		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || !IsClientInGame(attacker))
			return Plugin_Continue;

		switch(g_iMethod)
		{
			case -1:
				g_iAttacker[client] = attacker;
			case 0:
				g_iDamage[client][attacker] = GetEventInt(event, "dmg_health");
			case 1:
				g_iDamage[client][attacker] += GetEventInt(event, "dmg_health");
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_hTimer[client] != INVALID_HANDLE && CloseHandle(g_hTimer[client]))
			g_hTimer[client] = INVALID_HANDLE;

		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!attacker || attacker == client || attacker > MaxClients)
		{
			if(g_iMethod >= 0)
			{
				new _iTemp;
				for(new i = 1; i <= MaxClients; i++)
				{
					if(g_iDamage[client][i] && g_iDamage[client][i] > _iTemp)
					{
						_iTemp = g_iDamage[client][i];
						g_iAttacker[client] = i;
					}

					g_iDamage[client][i] = 0;
				}
			}

			if(!g_iAttacker[client] || !IsClientInGame(g_iAttacker[client]) || g_iAttacker[client] == client)
				return Plugin_Continue;

			SetEventInt(event, "userid", GetClientUserId(client));
			SetEventInt(event, "attacker", GetClientUserId(g_iAttacker[client]));
			SetEventString(event, "weapon", g_sWeapon);
			SetEntProp(g_iAttacker[client], Prop_Data, "m_iFrags", (GetClientFrags(g_iAttacker[client]) + 1));
		}

		g_iAttacker[client] = 0;
	}

	return Plugin_Continue;
}

public Action:Command_Kill(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(g_bCanSuicide[client] || g_fSuicide < 0 || g_bEnding)
			return Plugin_Continue;
		else
		{
			decl String:_sBuffer[256];
			if(g_hTimer[client] != INVALID_HANDLE)
			{
				CloseHandle(g_hTimer[client]);
				g_hTimer[client] = INVALID_HANDLE;
				Format(_sBuffer, sizeof(_sBuffer), "%T", "Suicide_Stop", client);
			}
			else
			{
				g_hTimer[client] = CreateTimer(g_fSuicide, Timer_Suicide, client);
				Format(_sBuffer, sizeof(_sBuffer), "%T", "Suicide_Start", client, RoundToFloor(g_fSuicide));
			}
			
			PrintToChat(client, "%s%s", PLUGIN_PREFIX, _sBuffer);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_Suicide(Handle:timer, any:client)
{
	g_hTimer[client] = INVALID_HANDLE;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		g_bCanSuicide[client] = true;

		new entity = CreateEntityByName("point_hurt");
		if(IsValidEntity(entity))
		{
			decl String:sName[64];
			GetEntPropString(client, Prop_Data, "m_iName", sName, sizeof(sName));
			DispatchKeyValue(client, "targetname", "StartPlayerSuicide");
			DispatchKeyValue(entity, "DamageTarget", "StartPlayerSuicide");
			DispatchKeyValue(entity, "Damage", "100000");
			DispatchKeyValue(entity, "DamageType", "0");
			DispatchSpawn(entity);

			AcceptEntityInput(entity, "Hurt");
			AcceptEntityInput(entity, "Kill");

			DispatchKeyValue(client, "targetname", sName);
		}
		
		g_bCanSuicide[client] = false;
	}
	
	return Plugin_Continue;
}

ClearVictimData(client)
{
	for(new i = 1; i <= MaxClients; i++)
		g_iDamage[client][i] = 0;
}

ClearAttackerData(client)
{
	for(new i = 1; i <= MaxClients; i++)
		g_iDamage[i][client] = 0;
}

Define_Defaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_iMethod = GetConVarInt(g_hMethod);
	GetConVarString(g_hWeapon, g_sWeapon, sizeof(g_sWeapon));
	g_fSuicide = GetConVarFloat(g_hSuicide);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hMethod)
		g_iMethod = StringToInt(newvalue);
	else if(cvar == g_hWeapon)
		GetConVarString(g_hWeapon, g_sWeapon, sizeof(g_sWeapon));
	else if(cvar == g_hSuicide)
		g_fSuicide = StringToFloat(newvalue);
}