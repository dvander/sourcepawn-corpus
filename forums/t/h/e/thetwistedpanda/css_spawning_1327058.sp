/*
	v3.4.2
	------
	All sm_* cvars have been converted to css_* cvars, as the plugin is specific to CS:S and CS:GO

	v3.4.3
	------
	New CVar css_spawning_prevent_duration, which sets the time players are forced into spectate when css_spawning_prevent is active.
	New logic for css_spawning_strip_gear, _t, _ct cvars using an improved delayed method to prevent any potential conflicts.
	Cvars sm_spawning_strip_death and sm_spawning_clear depreciated
	Cvar sm_spawning_strip had its functionality expanded. Now accepts the following parameters (a total of desired effects):
	-- Strip @ Spawn, 1
	-- Strip Non Survivors (i.e. default equipment), 2
	-- Strip @ Death, 4
	-- Strip Weapons @ Round End (both map and player), 8
	-- Strip Weapons on map @ Round Start, 16
	-- Strip game_player_equip entities, 32
	Implemented the ability to delete game_player_equip entities, despite being advertised as an existing plugin feature.
	Functionality for CVar css_spawning_notify has been changed:
	-- 0 = No Chat
	-- 1 = Chat
	-- 2 = Hint
	-- 3 = Key Hint
	Added basic translation support.
	Added basic CS:GO support (untested).

	v3.4.4
	------
	Added Cvar css_spawning_optional_respawn, which displays a menu to clients asking if they'd like to respawn.
	-- Implements sm_spawnmenu, in case the optional respawn menu is cancelled from other external factors.
	Added Cvar css_spawning_optional_respawn_choices, which controls the number of choices displayed in the menu.
	-- If 1 is displayed, only Yes is an option. If 3, two No and 1 Yes and so forth.
	Cvar css_spawning_notify prevents usage of KeyHints on CS:GO rather than assuming end-user is intelligent enough not to.
	Added Cvars css_spawning_minimum_spawns_t and css_spawning_minimum_spawns_ct, which ensure x amount of spawn points exist.
	Modified css_spawning_prevent so that it works on all maps, not just ones with single teams.
	Fixed a bug with css_spawning_prevent_duration where no default value was being set.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
//#include <colors> //https://forums.alliedmods.net/showpost.php?p=1883578&postcount=311 - Use for CS:GO
#include <morecolors>	//https://www.doctormckay.com/download/scripting/include/morecolors.inc - Use for CS:S

#define PLUGIN_VERSION "3.4.5"

#define MAX_SPAWN_GEAR 10
#define SPAWN_UNLIMITED -1
#define SPAWN_DISABLED 0
#define SPAWN_LIMITED 1

#define STRIP_SPAWN 1
#define STRIP_DEFAULT 2
#define STRIP_DEATH 4
#define STRIP_END 8
#define STRIP_START 16
#define STRIP_ENTITY 32

#define NOTIFY_NONE 0
#define NOTIFY_CHAT 1
#define NOTIFY_HINT 2
#define NOTIFY_KEY 3

new g_iTeam[MAXPLAYERS + 1];
new g_iLast[MAXPLAYERS + 1];
new g_iSpawns[MAXPLAYERS + 1];
new g_iRemaining[MAXPLAYERS + 1];
new bool:g_bAuthed[MAXPLAYERS + 1];
new bool:g_bSurvived[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bHasSpawned[MAXPLAYERS + 1];
new bool:g_bNeedsClass[MAXPLAYERS + 1];
new String:g_sAuth[MAXPLAYERS + 1][24];
new Handle:g_hSpawning[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

new bool:g_bLateLoad;
new bool:g_bEnding;
new g_iEnabled;
new bool:g_bSpawning = true;
new bool:g_bStopHopping;
new bool:g_bSpawnNew;
new bool:g_bSeparateGear;
new g_iStrip;
new g_iSpawnMode;
new g_iNotify;
new g_iSpawnsRed;
new g_iSpawnsBlue;
new g_iGearAll;
new g_iOwnerEntity;
new g_iGearRed;
new g_iGearBlue;
new g_iHoppingPunishment;
new g_iRedSpawnPoints;
new g_iBlueSpawnPoints;
new g_iOptionalChoices;
new Float:g_fDisableTime = -1.0;
new Float:g_fSpawningDelay;
new Float:g_fDeleteDrop;
new String:g_sGearAll[MAX_SPAWN_GEAR][32];
new String:g_sGearRed[MAX_SPAWN_GEAR][32];
new String:g_sGearBlue[MAX_SPAWN_GEAR][32];

new Handle:g_hDisableTimer = INVALID_HANDLE;
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hSpawnMode = INVALID_HANDLE;
new Handle:g_hStopHopping = INVALID_HANDLE;
new Handle:g_hHoppingPunishment = INVALID_HANDLE;
new Handle:g_hSpawningDelay = INVALID_HANDLE;
new Handle:g_hNotify = INVALID_HANDLE;
new Handle:g_hSpawnsRed = INVALID_HANDLE;
new Handle:g_hSpawnsBlue = INVALID_HANDLE;
new Handle:g_hDisableTime = INVALID_HANDLE;
new Handle:g_hStrip = INVALID_HANDLE;
new Handle:g_hSpawnGear = INVALID_HANDLE;
new Handle:g_hSpawnGearRed = INVALID_HANDLE;
new Handle:g_hSpawnGearBlue = INVALID_HANDLE;
new Handle:g_hSeparateGear = INVALID_HANDLE;
new Handle:g_hSpawnNew = INVALID_HANDLE;
new Handle:g_hDeleteDrop = INVALID_HANDLE;
new Handle:g_hKv_Persistent = INVALID_HANDLE;
new Handle:g_hOptionalChoices = INVALID_HANDLE;
new Handle:g_hRedSpawnPoints = INVALID_HANDLE;
new Handle:g_hBlueSpawnPoints = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[CSS] Spawning",
	author = "Panduh (AlliedMods: thetwistedpanda)",
	description = "A spawning/respawning management plugin that provides pretty much every feature desired.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart ()
{
	LoadTranslations("common.phrases");
	LoadTranslations("css_spawning.phrases");

	decl String:sBuffer[256];
	CreateConVar("css_spawning_version", PLUGIN_VERSION, "[CSS] Spawning: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = CreateConVar("css_spawning_enabled", "1", "Enables/disables all features of this plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnCVarChange);
	g_iEnabled = GetConVarBool(g_hEnabled);

	g_hDisableTime = CreateConVar("css_spawning_disable", "-1.0", "The number of seconds after round_start that the css_spawning_mode and css_spawning_new disable. (-1.0 = Disabled)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hDisableTime, OnCVarChange);
	g_fDisableTime = GetConVarFloat(g_hDisableTime);

	g_hSpawnMode = CreateConVar("css_spawning_mode", "0", "Determines plugin functionality. (-1 = Infinite Respawns, 0 = No Respawn, 1 = Limited Respawns)", FCVAR_NONE, true, -1.0, true, 1.0);
	HookConVarChange(g_hSpawnMode, OnCVarChange);
	g_iSpawnMode = GetConVarInt(g_hSpawnMode);

	g_hSpawnsRed = CreateConVar("css_spawning_limit_t", "0", "The number of spawns players on the Terrorist team will receive.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSpawnsRed, OnCVarChange);
	g_iSpawnsRed = GetConVarInt(g_hSpawnsRed);

	g_hSpawnsBlue = CreateConVar("css_spawning_limit_ct", "0", "The number of spawns players on the Counter-Terrorist team will receive.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSpawnsBlue, OnCVarChange);
	g_iSpawnsBlue = GetConVarInt(g_hSpawnsBlue);

	g_hStopHopping = CreateConVar("css_spawning_prevent", "0", "If enabled, players may not respawn by joining spectate and then rejoining their own team. By doing so they're forced to sit in spectate for 30 seconds.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hStopHopping, OnCVarChange);
	g_bStopHopping = GetConVarBool(g_hStopHopping);

	g_hHoppingPunishment = CreateConVar("css_spawning_prevent_duration", "30", "The number of seconds clients are forced to remain in spectate if they've joined spectate to re-join their own team.", FCVAR_NONE);
	HookConVarChange(g_hHoppingPunishment, OnCVarChange);
	g_iHoppingPunishment = GetConVarInt(g_hHoppingPunishment);

	g_hSpawningDelay = CreateConVar("css_spawning_delay", "3.0", "The delay, in seconds, it takes for players to respawn after dying.", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hSpawningDelay, OnCVarChange);
	g_fSpawningDelay = GetConVarFloat(g_hSpawningDelay);

	g_hNotify = CreateConVar("css_spawning_notify", "2", "Determines printing functionality. (0 = None, 1 = Chat, 2 = Hint, 3 = Key Hint (No CS:GO Support))", FCVAR_NONE, true, 0.0, true, 3.0);
	HookConVarChange(g_hNotify, OnCVarChange);
	g_iNotify = GetConVarInt(g_hNotify);

	g_hStrip = CreateConVar("css_spawning_strip", "0", "Determines stripping functionality. Add Values Together:(0 = Disabled, 1 = Strip @ Spawn, 2 = Strip Non-Survivors @ Spawn, 4 = Strip @ Death, 8 = Strip @ Round End, 16 = Strip @ Round Start, 32 = Delete \"game_player_equip\" Entities)", FCVAR_NONE, true, 0.0, true, 63.0);
	HookConVarChange(g_hStrip, OnCVarChange);
	g_iStrip = GetConVarInt(g_hStrip);

	g_hSpawnGear = CreateConVar("css_spawning_strip_gear", "", "The equipment a player is to spawn with, comma delimited. The first weapon issued is the active weapon.", FCVAR_NONE);
	HookConVarChange(g_hSpawnGear, OnCVarChange);
	GetConVarString(g_hSpawnGear, sBuffer, sizeof(sBuffer));
	g_iGearAll = ExplodeString(sBuffer, ", ", g_sGearAll, sizeof(g_sGearAll), sizeof(g_sGearAll[]));

	g_hSeparateGear = CreateConVar("css_spawning_strip_separate", "0", "If enabled, the cvars css_spawning_strip_gear_t and css_spawning_strip_gear_ct will be used as opposed to css_spawning_strip_gear, which allow for a different spawn gear for each team.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSeparateGear, OnCVarChange);
	g_bSeparateGear = GetConVarBool(g_hSeparateGear);

	g_hSpawnGearRed = CreateConVar("css_spawning_strip_gear_t", "", "If css_spawning_separate_gear is enabled, the equipment players on the Terrorist team will spawn with (obeys same rules as css_spawning_strip_gear)", FCVAR_NONE);
	HookConVarChange(g_hSpawnGearRed, OnCVarChange);
	GetConVarString(g_hSpawnGearRed, sBuffer, sizeof(sBuffer));
	g_iGearRed = ExplodeString(sBuffer, ", ", g_sGearRed, sizeof(g_sGearRed), sizeof(g_sGearRed[]));

	g_hSpawnGearBlue = CreateConVar("css_spawning_strip_gear_ct", "", "If css_spawning_separate_gear is enabled, the equipment players on the Counter-Terrorist team will spawn with (obeys same rules as css_spawning_strip_gear)", FCVAR_NONE);
	HookConVarChange(g_hSpawnGearBlue, OnCVarChange);
	GetConVarString(g_hSpawnGearBlue, sBuffer, sizeof(sBuffer));
	g_iGearBlue = ExplodeString(sBuffer, ", ", g_sGearBlue, sizeof(g_sGearBlue), sizeof(g_sGearBlue[]));

	g_hDeleteDrop = CreateConVar("css_spawning_strip_drop", "0.0", "The number of seconds after a player drops a weapon that it will be deleted. (0.0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hDeleteDrop, OnCVarChange);
	g_fDeleteDrop = GetConVarFloat(g_hDeleteDrop);

	g_hSpawnNew = CreateConVar("css_spawning_new", "0", "If enabled, players will be able to spawn on connect if css_spawning_mode is disabled, provided the player has not died in-game. Adheres to css_spawning_disable.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSpawnNew, OnCVarChange);
	g_bSpawnNew = GetConVarBool(g_hSpawnNew);

	g_hOptionalChoices = CreateConVar("css_spawning_respawn_menu", "2", "The total number of menu options to display in the respawn menu. (-1 = Disabled, 0 = Yes/No, 1 = Yes, # = Randomized Yes/No Order)", FCVAR_NONE, true, -1.0);
	HookConVarChange(g_hOptionalChoices, OnCVarChange);
	g_iOptionalChoices = GetConVarInt(g_hOptionalChoices);

	g_hRedSpawnPoints = CreateConVar("css_spawning_minimum_spawns_t", "0", "Ensures the Terrorist team has at least this manu spawn points. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hRedSpawnPoints, OnCVarChange);
	g_iRedSpawnPoints = GetConVarInt(g_hRedSpawnPoints);

	g_hBlueSpawnPoints = CreateConVar("css_spawning_minimum_spawns_ct", "0", "Ensures the Counter-Terrorist team has at least this manu spawn points. (0 = Disabled)", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hBlueSpawnPoints, OnCVarChange);
	g_iBlueSpawnPoints = GetConVarInt(g_hBlueSpawnPoints);
	AutoExecConfig(true, "css_spawning");

	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	
	RegConsoleCmd("jointeam", Command_Join);
	RegConsoleCmd("sm_spawnmenu", Command_Menu);

	g_hKv_Persistent = CreateKeyValues("css_spawning_persistent");
	g_iOwnerEntity = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");
}

public OnPluginEnd()
{
	if(g_iEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !g_bAlive[i] && g_bNeedsClass[i])
				FakeClientCommand(i, "joinclass %d", GetRandomInt(1, 8));
		}
	}
}

public OnMapStart()
{
	if(g_iEnabled)
	{
		CheckPointCounts();
	}
}


public OnMapEnd()
{
	if(g_iEnabled)
	{
		g_bEnding = true;

		if(g_hDisableTimer != INVALID_HANDLE && CloseHandle(g_hDisableTimer))
			g_hDisableTimer = INVALID_HANDLE;
	}
}

public OnConfigsExecuted()
{
	if(g_iEnabled)
	{
		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i);
					switch(g_iTeam[i])
					{
						case CS_TEAM_T:
							g_iSpawns[i] = g_iSpawnsRed;
						case CS_TEAM_CT:
							g_iSpawns[i] = g_iSpawnsBlue;
					}

					SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
					g_bAuthed[i] = GetClientAuthString(i, g_sAuth[i], sizeof(g_sAuth[]));
				}
			}

			g_bLateLoad = false;
		}

		decl String:sTemp[64];
		if(g_iStrip & STRIP_ENTITY)
		{
			new iMax = GetMaxEntities();
			for(new i = MaxClients + 1; i < iMax; i++)
			{
				if(IsValidEntity(i) && IsValidEdict(i))
				{
					GetEdictClassname(i, sTemp, sizeof(sTemp));
					if(StrEqual(sTemp, "game_equip_player", false))
						AcceptEntityInput(i, "Kill");
				}
			}
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_iEnabled)
	{
		SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_iEnabled)
	{
		g_bAuthed[client] = GetClientAuthString(client, g_sAuth[client], sizeof(g_sAuth[]));
	}
}

public OnClientConnected(client)
{
	if(g_iEnabled)
	{
		g_iRemaining[client] = 0;
		g_bHasSpawned[client] = false;
		g_bNeedsClass[client] = false;
	}
}

public OnClientDisconnect(client)
{
	if(g_iEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = false;
		g_bSurvived[client] = false;

		if(g_bAuthed[client])
		{
			switch(g_iSpawnMode)
			{
				case SPAWN_LIMITED:
				{
					if(IsClientInGame(client))
						KvSetNum(g_hKv_Persistent, g_sAuth[client], g_iSpawns[client]);
				}
				case SPAWN_DISABLED:
				{
					if((g_bSpawnNew && g_bHasSpawned[client]) && IsClientInGame(client))
						KvSetNum(g_hKv_Persistent, g_sAuth[client], 1);
				}
			}
		}

		if(g_hSpawning[client] != INVALID_HANDLE && CloseHandle(g_hSpawning[client]))
			g_hSpawning[client] = INVALID_HANDLE;
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		g_bEnding = false;
		g_bSpawning = true;

		if(g_iSpawnMode != SPAWN_UNLIMITED)
		{
			CloseHandle(g_hKv_Persistent);
			g_hKv_Persistent = CreateKeyValues("css_spawning_persistent");

			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(!g_bAlive[i] && g_bNeedsClass[i])
					{
						FakeClientCommand(i, "joinclass %d", GetRandomInt(1, 8));
						g_bNeedsClass[i] = false;
					}

					if(!g_bAuthed[i])
						g_bAuthed[i] = GetClientAuthString(i, g_sAuth[i], sizeof(g_sAuth[]));
				}
			}
		}

		if(g_iStrip & STRIP_START)
		{
			decl String:sTemp[64];
			new iMax = GetMaxEntities();
			for(new i = MaxClients + 1; i < iMax; i++)
			{
				if(IsValidEdict(i) && IsValidEntity(i))
				{
					GetEdictClassname(i, sTemp, sizeof(sTemp));
					if(StrContains(sTemp, "weapon_") != -1 && GetEntDataEnt2(i, g_iOwnerEntity) == -1)
						AcceptEntityInput(i, "Kill");
				}
			}
		}

		if(g_fDisableTime > 0.0)
			g_hDisableTimer = CreateTimer(g_fDisableTime, Timer_StopSpawn, _);
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		g_bEnding = true;
		g_bSpawning = false;

		if(g_iSpawnMode != SPAWN_UNLIMITED)
		{
			CloseHandle(g_hKv_Persistent);
			g_hKv_Persistent = CreateKeyValues("css_spawning_persistent");

			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_bHasSpawned[i] = false;
					g_bSurvived[i] = IsPlayerAlive(i);

					if(!g_bAlive[i] && g_bNeedsClass[i])
					{
						FakeClientCommand(i, "joinclass %d", GetRandomInt(1, 8));
						g_bNeedsClass[i] = false;
					}

					if(g_hSpawning[i] != INVALID_HANDLE && CloseHandle(g_hSpawning[i]))
						g_hSpawning[i] = INVALID_HANDLE;

					if(g_iStrip & STRIP_END)
					{
						for (new j = 0; j <= 4; j++)
						{
							new iEntity = -1;
							while((iEntity = GetPlayerWeaponSlot(i, j)) > 0 && IsValidEdict(iEntity))
							{
								RemovePlayerItem(i, iEntity);
								AcceptEntityInput(iEntity, "Kill");
							}
						}
					}
				}
			}
		}

		if(g_iStrip & STRIP_END)
		{
			decl String:sTemp[64];
			new iMax = GetMaxEntities();
			for(new i = MaxClients + 1; i < iMax; i++)
			{
				if(IsValidEdict(i) && IsValidEntity(i))
				{
					GetEdictClassname(i, sTemp, sizeof(sTemp));
					if(StrContains(sTemp, "weapon_") != -1 && GetEntDataEnt2(i, g_iOwnerEntity) == -1)
						AcceptEntityInput(i, "Kill");
				}
			}
		}

		if(g_hDisableTimer != INVALID_HANDLE && CloseHandle(g_hDisableTimer))
			g_hDisableTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= 1)
			return Plugin_Continue;

		g_bAlive[client] = true;
		if(g_iStrip & STRIP_SPAWN)
			CreateTimer(0.1, Timer_GearPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		else
		{
			if(g_bSurvived[client])
				g_bSurvived[client] = false;
			else if(g_iStrip & STRIP_DEFAULT)
				CreateTimer(0.1, Timer_GearPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(g_iSpawnMode == SPAWN_LIMITED)
		{
			switch(g_bHasSpawned[client])
			{
				case true:
				{
					if(g_iSpawns[client] > 0)
					{
						g_iSpawns[client]--;
						if(g_iSpawns[client] == 1)
							NotifyClient(client, "%T", "Phrase_Remaining_Spawn", client, g_iSpawns[client]);
						else
							NotifyClient(client, "%T", "Phrase_Remaining_Spawns", client, g_iSpawns[client]);
					}
				}
				case false:
				{
					switch(g_iTeam[client])
					{
						case CS_TEAM_T:
							g_iSpawns[client] = g_iSpawnsRed;
						case CS_TEAM_CT:
							g_iSpawns[client] = g_iSpawnsBlue;
					}
				}
			}
		}

		g_bHasSpawned[client] = true;
		if(g_hSpawning[client] != INVALID_HANDLE && CloseHandle(g_hSpawning[client]))
			g_hSpawning[client] = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_bEnding)
			return Plugin_Continue;

		g_bAlive[client] = false;
		if(g_iSpawnMode != SPAWN_DISABLED)
		{
			if(!g_bSpawning)
				NotifyClient(client, "%T", "Phrase_Spawning_Disabled", client);
			else
			{
				switch(g_iSpawnMode)
				{
					case SPAWN_UNLIMITED:
					{
						g_hSpawning[client] = CreateTimer(g_fSpawningDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
						if(g_fSpawningDelay)
							NotifyClient(client, "%T", "Phrase_Spawn_Delay", client, g_fSpawningDelay);
					}
					case SPAWN_LIMITED:
					{
						switch(g_iTeam[client])
						{
							case CS_TEAM_T:
							{
								if(g_iSpawnsRed && g_iSpawns[client] > 0)
								{
									g_hSpawning[client] = CreateTimer(g_fSpawningDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
									if(g_fSpawningDelay)
										NotifyClient(client, "%T", "Phrase_Spawn_Delay", client, g_fSpawningDelay);
								}
							}
							case CS_TEAM_CT:
							{
								if(g_iSpawnsBlue && g_iSpawns[client] > 0)
								{
									g_hSpawning[client] = CreateTimer(g_fSpawningDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
									if(g_fSpawningDelay)
									{
										NotifyClient(client, "%T", "Phrase_Spawn_Delay", client, g_fSpawningDelay);
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
	if(g_iEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		if(g_hSpawning[client] != INVALID_HANDLE && CloseHandle(g_hSpawning[client]))
			g_hSpawning[client] = INVALID_HANDLE;

		g_iTeam[client] = GetEventInt(event, "team");
		g_iLast[client] = GetEventInt(event, "oldteam");
		if(g_iTeam[client] <= CS_TEAM_SPECTATOR)
		{
			g_bAlive[client] = false;
			if(g_bStopHopping)
				g_iRemaining[client] = GetTime() + g_iHoppingPunishment;
		}
		else if(g_bSpawning)
		{
			switch(g_iSpawnMode)
			{
				case SPAWN_DISABLED:
				{
					if(g_bSpawnNew && g_iLast[client] == CS_TEAM_NONE && !g_bHasSpawned[client])
						g_hSpawning[client] = CreateTimer(g_fSpawningDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				case SPAWN_LIMITED:
				{
					switch(g_iTeam[client])
					{
						case CS_TEAM_T:
							if(g_iSpawnsRed && g_iSpawns[client] > 0)
								g_hSpawning[client] = CreateTimer(g_fSpawningDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
						case CS_TEAM_CT:
							if(g_iSpawnsBlue && g_iSpawns[client] > 0)
								g_hSpawning[client] = CreateTimer(g_fSpawningDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				case SPAWN_UNLIMITED:
				{
					g_hSpawning[client] = CreateTimer(g_fSpawningDelay, Timer_SpawnPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}

	return Plugin_Continue;
}


public Action:Command_Menu(client, args)
{
	if(g_iEnabled)
	{
		if(client && CheckRespawnConditions(client) && g_iOptionalChoices != -1)
		{
			Menu_RequestRespawn(client);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_Join(client, args)
{
	if(g_iEnabled)
	{
		decl String:sBuffer[30];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		new iTemp = StringToInt(sBuffer);

		if(iTemp >= CS_TEAM_T && iTemp == g_iTeam[client])
			return Plugin_Handled;
		else if(g_bStopHopping)
		{
			new iTime = GetTime();
			if(g_iRemaining[client] > iTime && g_iTeam[client])
			{
				NotifyClient(client, "%T", "Phrase_Punish_ReTeam", client, (g_iRemaining[client] - iTime));
				return Plugin_Handled;
			}
		}
		else
		{
			if(g_iTeam[client] == CS_TEAM_NONE && iTemp >= CS_TEAM_T)
			{
				switch(g_iSpawnMode)
				{
					case SPAWN_DISABLED:
					{
						if(g_bSpawning && g_bSpawnNew)
						{
							if(!g_bAuthed[client] || KvGetNum(g_hKv_Persistent, g_sAuth[client], 0))
							{
								g_bHasSpawned[client] = true;
								g_bNeedsClass[client] = true;

								NotifyClient(client, "%T", "Phrase_Spawning_Next", client);
								CS_SwitchTeam(client, iTemp);
								return Plugin_Handled;
							}
						}
					}
					case SPAWN_LIMITED:
					{
						if(g_bSpawning)
						{
							if(!g_bAuthed[client] || (g_iSpawns[client] = KvGetNum(g_hKv_Persistent, g_sAuth[client], -1)) == 0)
							{
								g_bHasSpawned[client] = true;
								g_bNeedsClass[client] = true;

								NotifyClient(client, "%T", "Phrase_Spawning_Next", client);
								CS_SwitchTeam(client, iTemp);
								return Plugin_Handled;
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Timer_StopSpawn(Handle:timer)
{
	g_hDisableTimer = INVALID_HANDLE;

	g_bSpawning = false;
}

public Action:Timer_SpawnPlayer(Handle:timer, any:client)
{
	g_hSpawning[client] = INVALID_HANDLE;
	if(CheckRespawnConditions(client))
	{
		if(g_iOptionalChoices != -1)
			Menu_RequestRespawn(client);
		else
			CS_RespawnPlayer(client);
	}
}

CheckRespawnConditions(client)
{
	if(!g_iEnabled || g_bEnding || g_bAlive[client] || !g_bSpawning || g_iTeam[client] < CS_TEAM_T || g_hSpawning[client] != INVALID_HANDLE)
		return false;

	switch(g_iSpawnMode)
	{
		case SPAWN_LIMITED:
		{
			switch(g_iTeam[client])
			{
				case CS_TEAM_T:
				{
					if(!g_iSpawnsRed || g_iSpawns[client] == 0 && (g_bHasSpawned[client] || g_bNeedsClass[client]))
						return false;
				}
				case CS_TEAM_CT:
				{
					if(!g_iSpawnsBlue || g_iSpawns[client] == 0 && (g_bHasSpawned[client] || g_bNeedsClass[client]))
						return false;
				}
			}
		}
		case SPAWN_DISABLED:
		{
			if(!g_bSpawnNew || g_iLast[client] != CS_TEAM_NONE || g_bHasSpawned[client] || g_bNeedsClass[client])
				return false;
		}
	}

	return true;
}

Menu_RequestRespawn(client)
{
	decl String:sBuffer[128];
	new Handle:hMenu = CreateMenu(MenuHandler_MenuRespawn);

	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Respawn_Title", client);
	SetMenuTitle(hMenu, sBuffer);
	SetMenuExitButton(hMenu, false);
	SetMenuExitBackButton(hMenu, false);

	if(g_iOptionalChoices)
	{
		new iRandom = GetRandomInt(1, g_iOptionalChoices);

		for(new i = 1; i <= g_iOptionalChoices; i++)
		{
			if(i == iRandom)
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Respawn_Option_Yes", client);
				AddMenuItem(hMenu, "1", sBuffer);
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Respawn_Option_No", client);
				AddMenuItem(hMenu, "0", sBuffer);
			}
		}
	}
	else
	{
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Respawn_Option_Yes", client);
		AddMenuItem(hMenu, "1", sBuffer);

		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Respawn_Option_No", client);
		AddMenuItem(hMenu, "0", sBuffer);
	}

	DisplayMenu(hMenu, client, 20);
}

public MenuHandler_MenuRespawn(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if(param2 != MenuCancel_Disconnected)
				CPrintToChat(param1, "%t", "Phrase_Respawn_Menu_Closed");
		}
		case MenuAction_Select:
		{
			decl String:sOption[4];
			GetMenuItem(menu, param2, sOption, 4);
			if(CheckRespawnConditions(param1))
			{
				if(StringToInt(sOption))
					CS_RespawnPlayer(param1);
				else
					CPrintToChat(param1, "%t", "Phrase_Respawn_Menu_Closed");
				return;
			}
			
			if(!g_bAlive[param1])
				CPrintToChat(param1, "%t", "Phrase_Respawn_Not_Available");
		}
	}
}

public Action:Timer_GearPlayer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && g_bAlive[client])
	{
		for (new i = 0; i <= 5; i++)
		{
			new iEntity = -1;
			if(i == CS_SLOT_GRENADE)
			{
				while((iEntity = GetPlayerWeaponSlot(client, i)) > 0 && IsValidEdict(iEntity))
				{
					RemovePlayerItem(client, iEntity);
					AcceptEntityInput(iEntity, "Kill");
				}
			}
			else
			{
				if((iEntity = GetPlayerWeaponSlot(client, i)) > 0 && IsValidEdict(iEntity))
				{
					RemovePlayerItem(client, iEntity);
					AcceptEntityInput(iEntity, "Kill");
				}
			}
		}

		if(g_bSeparateGear)
		{
			switch(g_iTeam[client])
			{
				case CS_TEAM_T:
				{
					if(g_iGearRed)
					{
						new Handle:hPack;
						CreateDataTimer(0.1, Timer_Give, hPack);
						WritePackCell(hPack, userid);
						WritePackCell(hPack, g_iGearRed);
						for(new i = 0; i < g_iGearRed; i++)
							WritePackString(hPack, g_sGearRed[i]);
					}
				}
				case CS_TEAM_CT:
				{
					if(g_iGearBlue)
					{
						new Handle:hPack;
						CreateDataTimer(0.1, Timer_Give, hPack);
						WritePackCell(hPack, userid);
						WritePackCell(hPack, g_iGearBlue);
						for(new i = 0; i < g_iGearBlue; i++)
							WritePackString(hPack, g_sGearBlue[i]);
					}
				}
			}
		}
		else if(g_iGearAll)
		{
			new Handle:hPack;
			CreateDataTimer(0.1, Timer_Give, hPack);
			WritePackCell(hPack, userid);
			WritePackCell(hPack, g_iGearAll);
			for(new i = 0; i < g_iGearAll; i++)
				WritePackString(hPack, g_sGearAll[i]);
		}
	}
}

public Action:Timer_Give(Handle:timer, Handle:pack)
{
	decl String:sClassname[32];

	ResetPack(pack);
	new userid = ReadPackCell(pack);
	new client = GetClientOfUserId(userid);
	new count = ReadPackCell(pack);

	if(client && IsClientInGame(client) && !g_bEnding && g_bAlive[client])
	{
		for(new i = 0; i < count; i++)
		{
			ReadPackString(pack, sClassname, sizeof(sClassname));
			GivePlayerItem(client, sClassname);

			if(i == 0)
			{
				new Handle:hPack;
				CreateDataTimer(0.1, Timer_Equip, hPack);
				WritePackCell(hPack, userid);
				WritePackString(hPack, sClassname);
			}
		}
	}

	return Plugin_Stop;
}

public Action:Timer_Equip(Handle:timer, Handle:pack)
{
	decl String:sClassname[32];

	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	ReadPackString(pack, sClassname, sizeof(sClassname));

	if(client && IsClientInGame(client) && !g_bEnding && g_bAlive[client])
		FakeClientCommandEx(client, "use %s", sClassname);
}

public Action:Hook_WeaponDrop(client, weapon)
{
	if(weapon > 0 && IsValidEdict(weapon) && IsClientInGame(client))
	{
		if(GetClientHealth(client) <= 0)
		{
			if(g_iStrip & STRIP_DEATH)
				AcceptEntityInput(weapon, "Kill");
		}
		else if(g_fDeleteDrop > 0.0)
			CreateTimer(g_fDeleteDrop, Timer_DeleteWeapon, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Timer_DeleteWeapon(Handle:timer, any:ref)
{
	new weapon = EntRefToEntIndex(ref);
	if(weapon != INVALID_ENT_REFERENCE)
		if(GetEntDataEnt2(weapon, g_iOwnerEntity) == -1 && IsValidEdict(weapon))
			AcceptEntityInput(weapon, "Kill");
}

NotifyClient(client, const String:format[], any:...)
{
	if(g_iNotify == NOTIFY_NONE)
		return;

	decl String:sBuffer[192];
	VFormat(sBuffer, sizeof(sBuffer), format, 3);
	switch(g_iNotify)
	{
		case NOTIFY_CHAT:
			CPrintToChat(client, "%t%s", "Prefix_Chat", sBuffer);
		case NOTIFY_HINT:
			PrintHintText(client, "%t%s", "Prefix_Other", sBuffer);
		case NOTIFY_KEY:
		{
			if (GetUserMessageType() == UM_Protobuf)
				PrintHintText(client, "%t%s", "Prefix_Other", sBuffer);
			else
			{
				Format(sBuffer, sizeof(sBuffer), "%T%s", "Prefix_Other", client, sBuffer);

				new Handle:hBuffer = StartMessageOne("KeyHintText", client);
				BfWriteByte(hBuffer, 1);
				BfWriteString(hBuffer, sBuffer);
				EndMessage();
			}
		}
	}
}

CheckPointCounts()
{
	new iNeeded;
	new iEntity;
	decl iSpawnEntities[64];
	decl Float:fTemp[3];
	decl Float:fSpawnLocations[64][3];
	
	if(g_iRedSpawnPoints)
	{	
		new iRed;
		while((iEntity = FindEntityByClassname(iEntity, "info_player_terrorist")) != -1)
		{
			iSpawnEntities[iRed] = iEntity;
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fSpawnLocations[iRed]);
			iRed++;
		}

		iNeeded = g_iRedSpawnPoints - iRed;
		while(iNeeded > 0)
		{
			fTemp = fSpawnLocations[GetRandomInt(0, (iRed - 1))];
			fTemp[2] += 1.0;

			iEntity = CreateEntityByName("info_player_terrorist");
			DispatchSpawn(iEntity);
			TeleportEntity(iEntity, fTemp, NULL_VECTOR, NULL_VECTOR);
			iNeeded--;
		}
	}

	if(g_iBlueSpawnPoints)
	{	
		new iBlue;
		while((iEntity = FindEntityByClassname(iEntity, "info_player_counterterrorist")) != -1)
		{
			iSpawnEntities[iBlue] = iEntity;
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fSpawnLocations[iBlue]);
			iBlue++;
		}

		iNeeded = g_iBlueSpawnPoints - iBlue;
		while(iNeeded > 0)
		{
			fTemp = fSpawnLocations[GetRandomInt(0, (iBlue - 1))];
			fTemp[2] += 1.0;

			iEntity = CreateEntityByName("info_player_counterterrorist");
			DispatchSpawn(iEntity);
			TeleportEntity(iEntity, fTemp, NULL_VECTOR, NULL_VECTOR);
			iNeeded--;
		}
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_iEnabled = bool:StringToInt(newvalue);
		if(g_iEnabled && !StringToInt(oldvalue))
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i);
					switch(g_iTeam[i])
					{
						case CS_TEAM_T:
							g_iSpawns[i] = g_iSpawnsRed;
						case CS_TEAM_CT:
							g_iSpawns[i] = g_iSpawnsBlue;
					}

					SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
				}
			}
		}
	}
	else if(cvar == g_hSpawnMode)
		g_iSpawnMode = StringToInt(newvalue);
	else if(cvar == g_hDisableTime)
	{
		g_bSpawning = true;
		if(g_hDisableTimer != INVALID_HANDLE && CloseHandle(g_hDisableTimer))
			g_hDisableTimer = INVALID_HANDLE;

		g_fDisableTime = StringToFloat(newvalue);
		if(g_fDisableTime > 0.0 && !g_bEnding)
			g_hDisableTimer = CreateTimer(g_fDisableTime, Timer_StopSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(cvar == g_hStopHopping)
		g_bStopHopping = bool:StringToInt(newvalue);
	else if(cvar == g_hSpawningDelay)
		g_fSpawningDelay = StringToFloat(newvalue);
	else if(cvar == g_hNotify)
		g_iNotify = StringToInt(newvalue);
	else if(cvar == g_hSpawnsRed)
		g_iSpawnsRed = StringToInt(newvalue);
	else if(cvar == g_hSpawnsBlue)
		g_iSpawnsBlue = StringToInt(newvalue);
	else if(cvar == g_hStrip)
		g_iStrip = StringToInt(newvalue);
	else if(cvar == g_hSpawnGear)
		g_iGearAll = ExplodeString(newvalue, ", ", g_sGearAll, MAX_SPAWN_GEAR, 32);
	else if(cvar == g_hDeleteDrop)
		g_fDeleteDrop = StringToFloat(newvalue);
	else if(cvar == g_hSpawnNew)
		g_bSpawnNew = bool:StringToInt(newvalue);
	else if(cvar == g_hSeparateGear)
		g_bSeparateGear = bool:StringToInt(newvalue);
	else if(cvar == g_hSpawnGearRed)
		g_iGearRed = ExplodeString(newvalue, ", ", g_sGearRed, MAX_SPAWN_GEAR, 32);
	else if(cvar == g_hSpawnGearBlue)
		g_iGearBlue = ExplodeString(newvalue, ", ", g_sGearBlue, MAX_SPAWN_GEAR, 32);
	else if(cvar == g_hHoppingPunishment)
		g_iHoppingPunishment = StringToInt(newvalue);
	else if(cvar == g_hOptionalChoices)
		g_iOptionalChoices = StringToInt(newvalue);		
	else if(cvar == g_hRedSpawnPoints)
		g_iRedSpawnPoints = StringToInt(newvalue);		
	else if(cvar == g_hBlueSpawnPoints)
		g_iBlueSpawnPoints = StringToInt(newvalue);		
}