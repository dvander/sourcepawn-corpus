#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "3.2.9"
#define PLUGIN_PREFIX "\x04Spawning: \x03"

#define MODE_INFINITE -1
#define MODE_DISABLED 0
#define MODE_LIMITED 1

new g_iSpawns[MAXPLAYERS + 1];
new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1] = { false, ... };
new bool:g_bDied[MAXPLAYERS + 1] = { false, ... };
new bool:g_bClass[MAXPLAYERS + 1] = { false, ... };
new Handle:g_hRespawn[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

new bool:g_bEnabled, g_iMode, Float:g_fDisable = -1.0, bool:g_bSingle, Float:g_fDelay, g_iNotify, g_iLimitT, g_iLimitCT, g_iStrip, g_iDeath, Float:g_fDrop, g_iWeapons, String:g_sWeapons[10][32], bool:g_bNew, bool:g_bClear, g_iOwnerEntity;
new bool:g_bIsRespawn = true;
new bool:g_bIsRoundEnd = false;
new bool:g_bIsSingleTeam = false;
new bool:g_bLateLoad = false;

new Handle:g_hDisableTimer = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hMode = INVALID_HANDLE;
new Handle:g_hSingle = INVALID_HANDLE;
new Handle:g_hDelay = INVALID_HANDLE;
new Handle:g_hNotify = INVALID_HANDLE;
new Handle:g_hLimitT = INVALID_HANDLE;
new Handle:g_hLimitCT = INVALID_HANDLE;
new Handle:g_hDisable = INVALID_HANDLE;
new Handle:g_hStrip = INVALID_HANDLE;
new Handle:g_hGear = INVALID_HANDLE;
new Handle:g_hDeath = INVALID_HANDLE;
new Handle:g_hNew = INVALID_HANDLE;
new Handle:g_hClear = INVALID_HANDLE;
new Handle:g_hDrop = INVALID_HANDLE;
new Handle:g_hData = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Player Spawning", 
	author = "Twisted|Panda", 
	description = "A respawn plugin that provides pretty much any feature desired.", 
	version = PLUGIN_VERSION, 
	url = "http://ominousgaming.com"
}

public OnPluginStart ()
{
	CreateConVar("sm_spawning_version", PLUGIN_VERSION, "Player Spawning Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_spawning_enabled", "1", "Enables/disables all features of this plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);

	g_hMode = CreateConVar("sm_spawning_mode", "0", "Determines plugin functionality. (-1 = Always Respawn, 0 = No Respawn, 1 = Limited Respawns)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hDisable = CreateConVar("sm_spawning_disable", "-1.0", "The number of seconds after round_start that the ability to respawn disables. (-1.0 = Disabled)", FCVAR_NONE, true, -1.0);
	g_hSingle = CreateConVar("sm_spawning_prevent", "0", "Prevents players from rejoining their own team to respawn on single team maps.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hDelay = CreateConVar("sm_spawning_delay", "3.0", "The delay, in seconds, it takes for players to respawn after dying.", FCVAR_NONE, true, 0.0);
	g_hNotify = CreateConVar("sm_spawning_notify", "1", "Determines printing functionality. (-1 = Hint Message, 0 = No Message, 1 = Chat Message)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hLimitT = CreateConVar("sm_spawning_limit_t", "0", "The number of spawns players on the Terrorist team will receive.", FCVAR_NONE, true, 0.0);
	g_hLimitCT = CreateConVar("sm_spawning_limit_ct", "0", "The number of spawns players on the Counter-Terrorist team will receive.", FCVAR_NONE, true, 0.0);
	g_hStrip = CreateConVar("sm_spawning_strip", "0", "If enabled, players will be stripped of all gear on spawn and all game_player_equips will be deleted.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hGear = CreateConVar("sm_spawning_strip_gear", "", "The equipment a player is to spawn with, comma delimited. The first weapon issued is the active weapon.", FCVAR_NONE);
	g_hDeath = CreateConVar("sm_spawning_strip_death", "0", "If enabled, players will be stripped of their gear right before death.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hDrop = CreateConVar("sm_spawning_strip_drop", "5.0", "The number of seconds after a player drops a weapon that it will be deleted. (0.0 = Disabled)", FCVAR_NONE, true, 0.0);
	g_hNew = CreateConVar("sm_spawning_new", "0", "If enabled, players will be able to spawn on connect if sm_spawning_mode is disabled, provided the player has not died in-game. Adheres to sm_spawning_disable.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hClear = CreateConVar("sm_spawning_clear", "0", "If enabled, players will be stripped of everything at the end of the round.", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_spawning");

	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_Pre);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	RegConsoleCmd("jointeam", Command_Join);

	HookConVarChange(g_hMode, Action_OnSettingsChange);
	HookConVarChange(g_hDisable, Action_OnSettingsChange);
	HookConVarChange(g_hSingle, Action_OnSettingsChange);
	HookConVarChange(g_hDelay, Action_OnSettingsChange);
	HookConVarChange(g_hNotify, Action_OnSettingsChange);
	HookConVarChange(g_hLimitT, Action_OnSettingsChange);
	HookConVarChange(g_hLimitCT, Action_OnSettingsChange);
	HookConVarChange(g_hStrip, Action_OnSettingsChange);
	HookConVarChange(g_hGear, Action_OnSettingsChange);
	HookConVarChange(g_hDeath, Action_OnSettingsChange);
	HookConVarChange(g_hDrop, Action_OnSettingsChange);
	HookConVarChange(g_hNew, Action_OnSettingsChange);
	HookConVarChange(g_hClear, Action_OnSettingsChange);

	g_hData = CreateKeyValues("sm_spawning");
	g_iOwnerEntity = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
	if(g_iOwnerEntity == -1)
		SetFailState("One of the offsets could not be located, please yell at the script author!");	
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginEnd()
{
	if(g_hDisableTimer != INVALID_HANDLE)
		if(CloseHandle(g_hDisableTimer))
			g_hDisableTimer = INVALID_HANDLE;

	for(new i = 1; i <= MaxClients; i++)
		if(g_hRespawn[i] != INVALID_HANDLE)
			if(CloseHandle(g_hRespawn[i]))
				g_hRespawn[i] = INVALID_HANDLE;
}

public OnConfigsExecuted()
{
	if(g_bLateLoad)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iTeam[i] = GetClientTeam(i);
				g_bAlive[i] = IsPlayerAlive(i) ? true : false;
			}
			else
			{
				g_iTeam[i] = 0;
				g_bAlive[i] = false;
			}
		}
	}
}

public OnMapStart()
{
	Void_SetDefaults();
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
}

public OnClientConnected(client)
{
	if(g_bEnabled)
	{
		g_bDied[client] = false;
		g_bClass[client] = false;
	}
}

public OnClientDisconnect(client)
{
	if (g_bEnabled)
	{
		g_iTeam[client] = 0;
		switch(g_iMode)
		{
			case MODE_LIMITED:
			{
				if(g_hRespawn[client] != INVALID_HANDLE)
					if(CloseHandle(g_hRespawn[client]))
						g_hRespawn[client] = INVALID_HANDLE;
						
				if(IsClientInGame(client))
				{
					decl String:g_sTempSteam[30];
					GetClientAuthString(client, g_sTempSteam, sizeof(g_sTempSteam));

					KvSetNum(g_hData, g_sTempSteam, g_iSpawns[client]);
				}
			}
			case MODE_DISABLED:
			{
				if((g_bNew && g_bDied[client]) && IsClientInGame(client))
				{
					decl String:g_sTempSteam[30];
					GetClientAuthString(client, g_sTempSteam, sizeof(g_sTempSteam));

					KvSetNum(g_hData, g_sTempSteam, 1);
				}
			}
		}
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bIsRoundEnd = false;
		g_bIsRespawn = true;
		if(g_iMode != MODE_INFINITE)
		{
			CloseHandle(g_hData);
			g_hData = CreateKeyValues("sm_spawning");

			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && g_bClass[i])
				{
					FakeClientCommand(i, "joinclass %d", GetRandomInt(1, 4));
					g_bClass[i] = false;
				}
			}
		}

		if(g_fDisable > 0.0)
			g_hDisableTimer = CreateTimer(g_fDisable, Timer_StopSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bIsRoundEnd = true;
		g_bIsRespawn = false;
		if(g_iMode != MODE_INFINITE)
		{
			CloseHandle(g_hData);
			g_hData = CreateKeyValues("sm_spawning");

			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_bDied[i] = false;
					if(g_bClass[i])
					{
						FakeClientCommand(i, "joinclass %d", GetRandomInt(1, 4));
						g_bClass[i] = false;
					}
				}
			}
		}

		if(g_bClear)
		{
			new wepIdx;
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					for (new j = 0; j <= 5; j++)
					{
						while((wepIdx = GetPlayerWeaponSlot(i, j)) != -1)
						{
							RemovePlayerItem(i, wepIdx);
							RemoveEdict(wepIdx);
						}
					}
				}
			}

			decl String:g_sEnt[64];
			new g_iMax = GetMaxEntities();
			for(new i = MaxClients; i < g_iMax; i++)
			{
				if(IsValidEdict(i) && IsValidEntity(i))
				{
					GetEdictClassname(i, g_sEnt, sizeof(g_sEnt));
					if(StrContains(g_sEnt, "weapon_") != -1)
						RemoveEdict(i);
				}
			}
		}

		if(g_fDisable > 0.0)
			if (g_hDisableTimer != INVALID_HANDLE)
				if(CloseHandle(g_hDisableTimer))
					g_hDisableTimer = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || !g_iTeam[client])
			return Plugin_Continue;

		g_bAlive[client] = true;
		g_bDied[client] = false;
		if(g_iStrip)
			CreateTimer(0.0, Timer_GearPlayer, client, TIMER_FLAG_NO_MAPCHANGE);

		if(g_iMode == MODE_LIMITED)
		{
			switch(g_bDied[client])
			{
				case true:
				{
					if(g_iSpawns[client] > 0)
					{
						g_iSpawns[client]--;
						switch(g_iNotify)
						{
							case -1:
							{
								switch(g_iSpawns[client])
								{
									case 1:
										PrintHintText(client, "You have %d spawn remaining!", g_iSpawns[client]);
									default:
										PrintHintText(client, "You have %d spawns remaining!", g_iSpawns[client]);
								}
							}
							case 1:
							{
								switch(g_iSpawns[client])
								{
									case 1:
										PrintToChat(client, "%sYou have %d spawn remaining!", PLUGIN_PREFIX, g_iSpawns[client]);
									default:
										PrintToChat(client, "%sYou have %d spawns remaining!", PLUGIN_PREFIX, g_iSpawns[client]);
								}
							}
						}
					}
				}
				case false:
				{
					if(g_iSpawns[client] == -1)
					{
						switch(g_iTeam[client])
						{
							case CS_TEAM_T:
								g_iSpawns[client] = g_iLimitT;
							case CS_TEAM_CT:
								g_iSpawns[client] = g_iLimitCT;
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_bAlive[client] = false;
		g_bDied[client] = true;
		if(g_iMode != MODE_DISABLED)
		{
			if(!g_bIsRespawn)
			{
				switch(g_iNotify)
				{
					case -1:
						PrintHintText(client, "The ability to spawn has been disabled for the rest of the round!");
					case 1:
						PrintToChat(client, "%sThe ability to spawn has been disabled for the rest of the round!", PLUGIN_PREFIX);
				}

				return Plugin_Continue;
			}
			else if(g_bIsRoundEnd)
			{
				switch(g_iNotify)
				{
					case -1:
						PrintHintText(client, "You will spawn on the next round!");
					case 1:
						PrintToChat(client, "%sYou will spawn on the next round!", PLUGIN_PREFIX);
				}

				return Plugin_Continue;
			}

			switch(g_iMode)
			{
				case MODE_INFINITE:
				{
					g_hRespawn[client] = CreateTimer(g_fDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
					if(g_fDelay)
					{
						switch(g_iNotify)
						{
							case -1:
								PrintHintText(client, "You will spawn in %.1f seconds!", g_fDelay);
							case 1:
								PrintToChat(client, "%sYou will spawn in %.1f seconds!", PLUGIN_PREFIX, g_fDelay);
						}
					}
				}
				case MODE_LIMITED:
				{
					switch(g_iTeam[client])
					{
						case CS_TEAM_T:
						{
							if(g_iLimitT && g_iSpawns[client] > 0)
							{
								g_hRespawn[client] = CreateTimer(g_fDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
								
								if(g_fDelay)
								{
									switch(g_iNotify)
									{
										case -1:
											PrintHintText(client, "You will spawn in %.1f seconds!", g_fDelay);
										case 1:
											PrintToChat(client, "%sYou will spawn in %.1f seconds!", PLUGIN_PREFIX, g_fDelay);
									}
								}
							}
						}
						case CS_TEAM_CT:
						{
							if(g_iLimitCT && g_iSpawns[client] > 0)
							{
								g_hRespawn[client] = CreateTimer(g_fDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
								
								if(g_fDelay)
								{
									switch(g_iNotify)
									{
										case -1:
											PrintHintText(client, "You will spawn in %.1f seconds!", g_fDelay);
										case 1:
											PrintToChat(client, "%sYou will spawn in %.1f seconds!", PLUGIN_PREFIX, g_fDelay);
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] <= CS_TEAM_SPECTATOR)
		{
			if(g_hRespawn[client] != INVALID_HANDLE)
				if(CloseHandle(g_hRespawn[client]))
					g_hRespawn[client] = INVALID_HANDLE;

			return Plugin_Continue;
		}

		if(g_bIsRespawn)
		{
			switch(g_iMode)
			{
				case MODE_DISABLED:
				{
					if(g_bNew && !g_bDied[client])
						if(g_iTeam[client] >= CS_TEAM_T)
							g_hRespawn[client] = CreateTimer(g_fDelay, Timer_CheckPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				case MODE_LIMITED:
				{
					switch(g_iTeam[client])
					{
						case CS_TEAM_T:
							if(g_iLimitT && g_iSpawns[client] > 0)
								g_hRespawn[client] = CreateTimer(g_fDelay, Timer_CheckPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
						case CS_TEAM_CT:
							if(g_iLimitCT && g_iSpawns[client] > 0)
								g_hRespawn[client] = CreateTimer(g_fDelay, Timer_CheckPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case MODE_INFINITE:
				{
					if(g_iTeam[client] >= CS_TEAM_T)
						g_hRespawn[client] = CreateTimer(g_fDelay, Timer_CheckPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Join(client, args)
{
	if(g_bEnabled)
	{
		decl String:g_sTemp[30];
		GetCmdArg(1, g_sTemp, sizeof(g_sTemp));
		new g_iTemp = StringToInt(g_sTemp);

		if((g_bSingle && g_bIsSingleTeam && g_iTemp == g_iTeam[client]) || (g_iTemp >= CS_TEAM_T && g_iTemp == g_iTeam[client]))
			return Plugin_Handled;
		else
		{
			if(g_iTeam[client] <= CS_TEAM_SPECTATOR)
			{
				switch(g_iMode)
				{
					case MODE_DISABLED:
					{
						if(g_bNew && g_bIsRespawn)
						{
							GetClientAuthString(client, g_sTemp, sizeof(g_sTemp));
							if(KvGetNum(g_hData, g_sTemp, 0))
							{
								g_bClass[client] = true;
								switch(g_iNotify)
								{
									case -1:
										PrintHintText(client, "You will be spawned on the next round!");
									case 1:
										PrintToChat(client, "%sYou will be spawned on the next round!", PLUGIN_PREFIX);
								}

								return Plugin_Handled;
							}
						}
					}
					case MODE_LIMITED:
					{
						GetClientAuthString(client, g_sTemp, sizeof(g_sTemp));
						g_iTemp = KvGetNum(g_hData, g_sTemp, -2);

						if(g_iTemp != -2)
						{
							g_iSpawns[client] = g_iTemp;
							if(g_iTemp == -1)
							{
								g_bClass[client] = true;
								return Plugin_Handled;
							}
						}
						else
							g_iSpawns[client] = -1;
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Timer_StopSpawn(Handle:timer)
{
	g_bIsRespawn = false;
	g_hDisableTimer = INVALID_HANDLE;
}

public Action:Timer_SpawnPlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client) && !g_bAlive[client] && g_iTeam[client] >= CS_TEAM_T && !g_bIsRoundEnd)
		CS_RespawnPlayer(client);
	
	g_hRespawn[client] = INVALID_HANDLE;
}

public Action:Timer_CheckPlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client) && !g_bAlive[client])
		g_hRespawn[client] = CreateTimer(g_fDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
	else
		g_hRespawn[client] = INVALID_HANDLE;
}

public Action:Timer_GearPlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client) && g_bAlive[client])
	{
		new wepIdx;
		for (new i = 0; i <= 3; i++)
		{
			if(i == CS_SLOT_GRENADE)
			{
				while((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
				{
					RemovePlayerItem(client, wepIdx);
					RemoveEdict(wepIdx);
				}
			}
			else
			{
				if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
				{
					RemovePlayerItem(client, wepIdx);
					RemoveEdict(wepIdx);
				}
			}
		}

		if(g_iWeapons)
		{
			for(new i = 0; i < g_iWeapons; i++)
				GivePlayerItem(client, g_sWeapons[i]);

			FakeClientCommand(client, "use %s", g_sWeapons[0]);
		}
	}
}

public Action:Hook_WeaponDrop(client, weapon)
{
	new health = GetClientHealth(client);
	if(health > 0)
	{
		if(g_fDrop > 0.0)
			CreateTimer(g_fDrop, Timer_DeleteWeapon, weapon);
	}
	else
	{
		if(g_iDeath)
			CreateTimer(0.1, Timer_DeleteWeapon, weapon);
	}

	return Plugin_Continue;
}

public Action:Timer_DeleteWeapon(Handle:timer, any:weapon)
{
	if (weapon && IsValidEdict(weapon) && IsValidEntity(weapon))
		if (GetEntDataEnt2(weapon, g_iOwnerEntity) == -1)
			RemoveEdict(weapon);
}

void:Void_SetDefaults()
{
	decl String:g_sTemp[256];
	new g_iTemp, g_iTempT, g_iTempCT;

	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_iMode = GetConVarInt(g_hMode);
	g_fDisable = GetConVarFloat(g_hDisable);
	g_bSingle = GetConVarInt(g_hSingle) ? true : false;
	g_fDelay = GetConVarFloat(g_hDelay);
	g_iNotify = GetConVarInt(g_hNotify);
	g_iLimitT = GetConVarInt(g_hLimitT);
	g_iLimitCT = GetConVarInt(g_hLimitCT);
	g_iStrip = GetConVarInt(g_hStrip);	
	g_iDeath = GetConVarInt(g_hDeath);
	g_fDrop = GetConVarFloat(g_hDrop);
	g_bNew = GetConVarInt(g_hNew) ? true : false;
	g_bClear = GetConVarInt(g_hClear) ? true : false;

	GetConVarString(g_hGear, g_sTemp, sizeof(g_sTemp));
	if(!StrEqual(g_sTemp, ""))
	{
		g_iWeapons = ExplodeString(g_sTemp, ", ", g_sWeapons, 10, 32);
		for(new i = 0; i < 10; i++)
			if(i < g_iWeapons)
				TrimString(g_sWeapons[i]);
			else
				g_sWeapons[i] = "";
	}
	else
	{
		g_iWeapons = 0;
		for(new i = 0; i < 10; i++)
			g_sWeapons[i] = "";
	}
	
	g_iTemp = -1;
	while((g_iTemp = FindEntityByClassname(g_iTemp, "info_player_terrorist")) != -1)
		g_iTempT++;

	g_iTemp = -1;
	while((g_iTemp = FindEntityByClassname(g_iTemp, "info_player_counterterrorist")) != -1)
		g_iTempCT++;

	if (g_iTempT == 0 || g_iTempCT == 0)
		g_bIsSingleTeam = true;
	else
		g_bIsSingleTeam = false;

	g_bIsRoundEnd = false;
	g_bIsRespawn = true;
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hMode)
		g_iMode = StringToInt(newvalue);
	else if(cvar == g_hDisable)
	{
		g_fDisable = StringToFloat(newvalue);
		if(StringToFloat(oldvalue) > 0.0)
		{
			if(g_hDisableTimer != INVALID_HANDLE)
				if(CloseHandle(g_hDisableTimer))
					g_hDisableTimer = INVALID_HANDLE;
		}

		if(g_fDisable > 0.0 && !g_bIsRoundEnd)
			g_hDisableTimer = CreateTimer(g_fDisable, Timer_StopSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(cvar == g_hSingle)
		g_bSingle = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hDelay)
		g_fDelay = StringToFloat(newvalue);
	else if(cvar == g_hNotify)
		g_iNotify = StringToInt(newvalue);
	else if(cvar == g_hLimitT)
		g_iLimitT = StringToInt(newvalue);
	else if(cvar == g_hLimitCT)
		g_iLimitCT = StringToInt(newvalue);
	else if(cvar == g_hStrip)
		g_iStrip = StringToInt(newvalue);
	else if(cvar == g_hGear)
	{
		if(!StrEqual(newvalue, ""))
		{
			g_iWeapons = ExplodeString(newvalue, ", ", g_sWeapons, 10, 32);
			for(new i = 0; i < 10; i++)
				if(i < g_iWeapons)
					TrimString(g_sWeapons[i]);
				else
					g_sWeapons[i] = "";
		}
		else
		{
			g_iWeapons = 0;
			for(new i = 0; i < 10; i++)
				g_sWeapons[i] = "";
		}
	}
	else if(cvar == g_hDeath)
		g_iDeath = StringToInt(newvalue);
	else if(cvar == g_hDrop)
		g_fDrop = StringToFloat(newvalue);
	else if(cvar == g_hNew)
		g_bNew = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hClear)
		g_bClear = StringToInt(newvalue) ? true : false;
}