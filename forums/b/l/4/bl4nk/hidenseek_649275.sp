/**
 * Changelog:
 *   - Simplified the hostage removal procedure
 *   - Players now spawn with the correct amount of flashes/smokes
 *   - No more stray grenades laying around on the ground
 *   - Hiders spawn with a knife, but can not damage the seekers
 *     - This fixes the bug where players will get stuck in the default animation pose
 *   - No more spam when players change teams at the end of the round
 *   - Fixed the hider/seeker count not always using the correct team
 *   - Added cvars for the sky name and the lighting style
 *   - Added cvar to Enable/Disable the plugin
 *     - When the plugin is disabled, the old values of the changed cvars are restored
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

// Global Definitions
#define PLUGIN_VERSION "1.0.0-a4"

#define cDefault    0x01
#define cLightGreen 0x03
#define cGreen      0x04

#define TEAM_T  2
#define TEAM_CT 3

enum HNS_CVARS
{
	CVAR_GRAVITY,
	CVAR_LIMITTEAMS,
	CVAR_AUTOTEAMBALANCE,
	CVAR_FORCECAMERA,
	CVAR_SKYNAME
}

new ammoOffset;
new cashOffset;
new mapType;
new maxclients;
new maxentities;

new bool:forcedChange[MAXPLAYERS+1];
new bool:isHooked = false;
new bool:roundEnd = false;

new Handle:cvarEnable;
new Handle:cvarFlashGren;
new Handle:cvarLight;
new Handle:cvarNightvision;
new Handle:cvarRatio;
new Handle:cvarSky;
new Handle:cvarSmokeGren;

new String:oldValues[HNS_CVARS][32];

// Functions
public Plugin:myinfo =
{
	name = "HideNSeek",
	author = "bl4nk",
	description = "A Hide and Seek style game where one team hunts the other",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("hidenseek.phrases");

	CreateConVar("sm_hidenseek_version", PLUGIN_VERSION, "HideNSeek Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_hidenseek_enable", "1", "Enable/Disable the HideNSeek plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarFlashGren = CreateConVar("sm_hidenseek_flash", "2", "Amount of flash grenades for hiders", FCVAR_PLUGIN, true, 0.0);
	cvarLight = CreateConVar("sm_hidenseek_light", "a", "Lighting style to use, a-z (a = darkest, z = lightest)", FCVAR_PLUGIN);
	cvarNightvision = CreateConVar("sm_hidenseek_nightvision", "1", "Enable/Disable hiders spawning with nightvision", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarRatio = CreateConVar("sm_hidenseek_ratio", "0.25", "Ratio of seekers to hiders (def .25 = 1s to 4h)", FCVAR_PLUGIN, true, 0.0);
	cvarSky = CreateConVar("sm_hidenseek_sky", "sky_borealis01", "Name of the sky to use", FCVAR_PLUGIN);
	cvarSmokeGren = CreateConVar("sm_hidenseek_smoke", "2", "Amount of smoke grenades for hiders", FCVAR_PLUGIN, true, 0.0);

	maxclients = GetMaxClients();
	maxentities = GetMaxEntities();

	// Offsets for changing entity data
	cashOffset = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (cashOffset == -1)
		SetFailState("Could not find cash offset");

	ammoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	if (ammoOffset == -1)
		SetFailState("Could not find ammo offset");

	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarEnable))
	{
		isHooked = true;
		HookEvent("player_spawn", event_PlayerSpawn, EventHookMode_Post);
		HookEvent("player_death", event_PlayerDeath, EventHookMode_Post);
		HookEvent("player_team", event_PlayerTeam, EventHookMode_Pre);
		HookEvent("round_start", event_RoundStart, EventHookMode_Post);
		HookEvent("round_end", event_RoundEnd, EventHookMode_Post);

		LogMessage("[HideNSeek] - Loaded");
	}

	HookConVarChange(cvarEnable, CvarChange_Enable);
}

public CvarChange_Enable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarInt(cvarEnable))
	{
		if (isHooked)
		{
			isHooked = false;
			UnhookEvent("player_spawn", event_PlayerSpawn, EventHookMode_Post);
			UnhookEvent("player_death", event_PlayerDeath, EventHookMode_Post);
			UnhookEvent("player_team", event_PlayerTeam, EventHookMode_Pre);
			UnhookEvent("round_start", event_RoundStart, EventHookMode_Post);
			UnhookEvent("round_end", event_RoundEnd, EventHookMode_Post);

			HNS_RestoreCvars();
		}
	}
	else if (!isHooked)
	{
		isHooked = true;
		HookEvent("player_spawn", event_PlayerSpawn, EventHookMode_Post);
		HookEvent("player_death", event_PlayerDeath, EventHookMode_Post);
		HookEvent("player_team", event_PlayerTeam, EventHookMode_Pre);
		HookEvent("round_start", event_RoundStart, EventHookMode_Post);
		HookEvent("round_end", event_RoundEnd, EventHookMode_Post);

		HNS_ChangeCvars();
	}
}

public OnMapStart()
{
	// Detect map type (cs_/de_)
	decl String:mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));

	mapType = 0;
	if (strncmp(mapname, "cs_", 3) == 0)
		mapType = 1;
	else if (strncmp(mapname, "de_", 3) == 0)
		mapType = 2;
}

public OnConfigsExecuted()
{
	if (GetConVarInt(cvarEnable))
	{
		HNS_ChangeCvars();
	}
}

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Player spawned, give them time to get their items
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, PostPlayerSpawn, client);
}

public Action:PostPlayerSpawn(Handle:timer, any:client)
{
	// Get the player's team
	new team = GetClientTeam(client);

	// Get values for cvars
	new flashes = GetConVarInt(cvarFlashGren);
	new smokes = GetConVarInt(cvarSmokeGren);
	new nightvision = GetConVarInt(cvarNightvision);

	// Handle the player spawn stuff
	switch (mapType)
	{
		case 1: // cs_ maps
		{
			switch (team)
			{
				case TEAM_T: // Hiders
				{
					// Tell the player what team they're on
					PrintToChat(client, "%c[SM]%c %t", cGreen, cDefault, "Hiding Team");

					// Set the player's money to 0 so they can't buy stuff
					SetPlayerMoney(client, 0);

					// Strip the player's weapons
					StripAllWeapons(client);

					// Give the player a knife
					GivePlayerItem(client, "weapon_knife");

					// Give the player flash bangs
					if (flashes > 0)
					{
						GivePlayerItem(client, "weapon_flashbang");
						SetEntData(client, ammoOffset + 48, flashes);
					}

					// Give the player smoke grenades
					if (smokes > 0)
					{
						GivePlayerItem(client, "weapon_smokegrenade");
						SetEntData(client, ammoOffset + 52, smokes);
					}

					// Give the player nightvision
					if (nightvision == 1)
						GivePlayerItem(client, "item_nvgs");
				}
				case TEAM_CT: // Seekers
				{
					// Tell the player what team they're on
					PrintToChat(client, "%c[SM]%c %t", cGreen, cDefault, "Seeking Team");

					// Set the player's money to 0 so they can't buy stuff
					SetPlayerMoney(client, 0);

					// Strip the player's weapons and equip them with a knife
					StripAllWeapons(client);
					GivePlayerItem(client, "weapon_knife");

					// Make the player immune to damage
					SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				}
				default:
					return;
			}
		}
		case 2: // de_ maps
		{
			switch (team)
			{
				case TEAM_T: // Seekers
				{
					// Tell the player what team they're on
					PrintToChat(client, "%c[SM]%c %t", cGreen, cDefault, "Seeking Team");

					// Set the player's money to 0 so they can't buy stuff
					SetPlayerMoney(client, 0);

					// Strip the player's weapons and equip them with a knife
					StripAllWeapons(client);
					GivePlayerItem(client, "weapon_knife");

					// Make the player immune to damage
					SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				}
				case TEAM_CT: // Hiders
				{
					// Tell the player what team they're on
					PrintToChat(client, "%c[SM]%c %t", cGreen, cDefault, "Hiding Team");

					// Set the player's money to 0 so they can't buy stuff
					SetPlayerMoney(client, 0);

					// Strip the player's weapons
					StripAllWeapons(client);

					// Give the player a knife
					GivePlayerItem(client, "weapon_knife");

					// Give the player flash bangs
					if (flashes > 0)
					{
						GivePlayerItem(client, "weapon_flashbang");
						SetEntData(client, ammoOffset + 48, flashes);
					}

					// Give the player smoke grenades
					if (smokes > 0)
					{
						GivePlayerItem(client, "weapon_smokegrenade");
						SetEntData(client, ammoOffset + 52, smokes);
					}

					// Give the player nightvision
					if (nightvision == 1)
						GivePlayerItem(client, "item_nvgs");
				}
				default:
					return;
			}
		}
	}
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	// new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	// Set the attacker's money to 0 so they can't buy stuff
	SetPlayerMoney(attacker, 0);
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnd = false;

	// If the map is a cs_ map , remove all hostages
	if (mapType == 1)
		CreateTimer(0.1, timer_RemoveHostages);

	// Change the light environment to be a dark color
	decl String:lightScheme[4];
	GetConVarString(cvarLight, lightScheme, sizeof(lightScheme));
	SetLightStyle(0, lightScheme);
}

public Action:timer_RemoveHostages(Handle:timer)
{
	decl String:buffer[32];
	for(new i = maxclients + 1; i < maxentities; i++)
	{
		if (!IsValidEdict(i))
			continue;

		GetEdictClassname(i, buffer, sizeof(buffer));
		if(strcmp(buffer, "hostage_entity") == 0)
			RemoveEdict(i);
	}
}

public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundEnd = true;

	new Float:ratio = GetConVarFloat(cvarRatio);
	new team = GetEventInt(event, "winner");

	// Count players on each team
	new hiderCount, seekerCount;
	if (mapType == 1)
	{
		hiderCount = CountPlayers(TEAM_T);
		seekerCount = CountPlayers(TEAM_CT);
	}
	else if (mapType == 2)
	{
		seekerCount = CountPlayers(TEAM_T);
		hiderCount = CountPlayers(TEAM_CT);
	}

	// Calculate the new seeker count
	new seekerCount_new = RoundToFloor((hiderCount + seekerCount) * ratio);

	// Make sure the new seeker count is never 0
	if (!seekerCount_new)
		seekerCount_new = 1;

	switch (mapType)
	{
		case 1: // cs_ maps
		{
			switch (team)
			{
				case TEAM_T: // Hiders won, choose new seekers from them
				{
					// Announce which team won
					PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Round End", "Hiders");

					// Create an array of dead hiders
					new Handle:deadArray = CreateArray();
					for (new i = 1; i <= maxclients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) == TEAM_T)
						{
							PushArrayCell(deadArray, i);
						}
					}

					// Create an array of alive hiders
					new Handle:aliveArray = CreateArray();
					for (new i = 1; i <= maxclients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_T)
						{
							PushArrayCell(aliveArray, i);
						}
					}

					// Randomize the arrays
					SortADTArray(deadArray, Sort_Random, Sort_Integer);
					SortADTArray(aliveArray, Sort_Random, Sort_Integer);

					// Insert hiders from the alive array into the beginning of the dead array
					new deadSize = GetArraySize(deadArray);
					new aliveSize = GetArraySize(aliveArray);
					if (deadSize > 0)
					{
						for (new i = 0; i < aliveSize; i++)
						{
							ShiftArrayUp(deadArray, 0);
							SetArrayCell(deadArray, 0, GetArrayCell(aliveArray, i));
						}
					}
					else if (deadSize == 0)
					{
						for (new i = 0; i < aliveSize; i++)
						{
							PushArrayCell(deadArray, GetArrayCell(aliveArray, i));
						}
					}

					// Tell everyone that the teams are changing
					PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Swapping Teams");

					// Move all seekers over to hiders
					for (new i = 1; i <= maxclients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_CT)
						{
							forcedChange[i] = true;
							CS_SwitchTeam(i, TEAM_T);
						}
					}

					// Move chosen hiders over to seekers
					for (new i = 0, x; i < seekerCount_new; i++)
					{
						x = GetArrayCell(deadArray, i);
						forcedChange[x] = true;
						CS_SwitchTeam(x, TEAM_CT);
					}

					CloseHandle(deadArray);
					CloseHandle(aliveArray);
				}
				case TEAM_CT: // Seekers won, teams are to stay the same
				{
					// Announce which team won
					PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Round End", "Seekers");

					// Check ratio against player count to see if there should be more/less seekers
					if (seekerCount < seekerCount_new) // Too many hiders?
					{
						PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Too Many Players", "Hiders", cLightGreen, seekerCount_new-seekerCount, cDefault);

						// Create an array of hiders
						new Handle:hiderArray = CreateArray();
						for (new i = 1; i <= maxclients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_T)
							{
								PushArrayCell(hiderArray, i);
							}
						}

						// Randomize the array of hiders
						SortADTArray(hiderArray, Sort_Random, Sort_Integer);

						// Move hiders over to seekers
						new arraySize = GetArraySize(hiderArray);
						for (new i = 0, x; i < arraySize; i++)
						{
							if (seekerCount != seekerCount_new)
							{
								x = GetArrayCell(hiderArray, i);
								forcedChange[x] = true;
								CS_SwitchTeam(x, TEAM_CT);

								seekerCount++;
							}
							else
								break;
						}

						CloseHandle(hiderArray);
					}
					else if (seekerCount > seekerCount_new) // Too many seekers?
					{
						PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Too Many Players", "Seekers", cLightGreen, seekerCount-seekerCount_new, cDefault);

						// Create an array of seekers
						new Handle:seekerArray = CreateArray();
						for (new i = 1; i <= maxclients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_CT)
							{
								PushArrayCell(seekerArray, i);
							}
						}

						// Randomize the array of seekers
						SortADTArray(seekerArray, Sort_Random, Sort_Integer);

						// Move seekers over to hiders
						new arraySize = GetArraySize(seekerArray);
						for (new i = 0, x; i < arraySize; i++)
						{
							if (seekerCount != seekerCount_new)
							{
								x = GetArrayCell(seekerArray, i);
								forcedChange[x] = true;
								CS_SwitchTeam(x, TEAM_T);

								seekerCount--;
							}
							else
								break;
						}

						CloseHandle(seekerArray);
					}
				}
				default:
					return;
			}
		}
		case 2: // de_ maps
		{
			switch (team)
			{
				case TEAM_T: // Seekers won, teams are to stay the same
				{
					// Announce which team won
					PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Round End", "Seekers");

					// Check ratio against player count to see if there should be more/less seekers
					if (seekerCount < seekerCount_new) // Too many hiders?
					{
						PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Too Many Players", "Hiders", cLightGreen, seekerCount_new-seekerCount, cDefault);

						// Create an array of hiders
						new Handle:hiderArray = CreateArray();
						for (new i = 1; i <= maxclients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_CT)
							{
								PushArrayCell(hiderArray, i);
							}
						}

						// Randomize the array of hiders
						SortADTArray(hiderArray, Sort_Random, Sort_Integer);

						// Move hiders over to seekers
						new arraySize = GetArraySize(hiderArray);
						for (new i = 0, x; i < arraySize; i++)
						{
							if (seekerCount != seekerCount_new)
							{
								x = GetArrayCell(hiderArray, i);
								forcedChange[x] = true;
								CS_SwitchTeam(x, TEAM_T);

								seekerCount++;
							}
							else
								break;
						}

						CloseHandle(hiderArray);
					}
					else if (seekerCount > seekerCount_new) // Too many seekers?
					{
						PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Too Many Players", "Seekers", cLightGreen, seekerCount-seekerCount_new, cDefault);

						// Create an array of seekers
						new Handle:seekerArray = CreateArray();
						for (new i = 1; i <= maxclients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_T)
							{
								PushArrayCell(seekerArray, i);
							}
						}

						// Randomize the array of seekers
						SortADTArray(seekerArray, Sort_Random, Sort_Integer);

						// Move seekers over to hiders
						new arraySize = GetArraySize(seekerArray);
						for (new i = 0, x; i < arraySize; i++)
						{
							if (seekerCount != seekerCount_new)
							{
								x = GetArrayCell(seekerArray, i);
								forcedChange[x] = true;
								CS_SwitchTeam(x, TEAM_CT);

								seekerCount--;
							}
							else
								break;
						}

						CloseHandle(seekerArray);
					}
				}
				case TEAM_CT: // Hiders won, choose new seekers from them
				{
					// Announce which team won
					PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Round End", "Hiders");

					// Create an array of dead hiders
					new Handle:deadArray = CreateArray();
					for (new i = 1; i <= maxclients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) == TEAM_CT)
						{
							PushArrayCell(deadArray, i);
						}
					}

					// Create an array of alive hiders
					new Handle:aliveArray = CreateArray();
					for (new i = 1; i <= maxclients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_CT)
						{
							PushArrayCell(aliveArray, i);
						}
					}

					// Randomize the arrays
					SortADTArray(deadArray, Sort_Random, Sort_Integer);
					SortADTArray(aliveArray, Sort_Random, Sort_Integer);

					// Insert hiders from the alive array into the beginning of the dead array
					new deadSize = GetArraySize(deadArray);
					new aliveSize = GetArraySize(aliveArray);
					if (deadSize > 0)
					{
						for (new i = 0; i < aliveSize; i++)
						{
							ShiftArrayUp(deadArray, 0);
							SetArrayCell(deadArray, 0, GetArrayCell(aliveArray, i));
						}
					}
					else if (deadSize == 0)
					{
						for (new i = 0; i < aliveSize; i++)
						{
							PushArrayCell(deadArray, GetArrayCell(aliveArray, i));
						}
					}

					// Tell everyone that the teams are changing
					PrintToChatAll("%c[SM]%c %t", cGreen, cDefault, "Swapping Teams");

					// Move all seekers over to hiders
					for (new i = 1; i <= maxclients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_T)
						{
							forcedChange[i] = true;
							CS_SwitchTeam(i, TEAM_CT);
						}
					}

					// Move chosen hiders over to seekers
					for (new i = 0, x; i < seekerCount_new; i++)
					{
						x = GetArrayCell(deadArray, i);
						forcedChange[x] = true;
						CS_SwitchTeam(x, TEAM_T);
					}

					CloseHandle(deadArray);
					CloseHandle(aliveArray);
				}
				default:
					return;
			}
		}
	}
}

public Action:event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (forcedChange[client])
	{
		forcedChange[client] = false;

		if (roundEnd)
			return Plugin_Handled;
		else
			return Plugin_Continue;
	}

	new oldTeam = GetEventInt(event, "oldteam"), Handle:data = CreateDataPack();
	if (oldTeam)
	{
		WritePackCell(data, client);
		WritePackCell(data, oldTeam);

		CreateTimer(0.1, timer_ChangeTeam, data);
	}

	return Plugin_Continue;
}

public Action:timer_ChangeTeam(Handle:timer, any:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	new oldTeam = ReadPackCell(data);
	CloseHandle(data);

	forcedChange[client] = true;
	CS_SwitchTeam(client, oldTeam);
	PrintToChat(client, "%c[SM]%c %t", cGreen, cDefault, "No Team Changing");
}

stock CountPlayers(team)
{
	new count = 0;
	for (new i = 1; i <= maxclients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
		{
			count++;
		}
	}

	return count;
}

stock StripAllWeapons(client)
{
	if (!IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	new weaponIndex;
	for (new i = 0; i <= 4; i++)
	{
		while ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weaponIndex);
			RemoveEdict(weaponIndex);
		}
	}
}

stock SetPlayerMoney(client, amount)
	SetEntData(client, cashOffset, amount);

HNS_ChangeCvars()
{
	// Backup cvars in case the plugin is disabled
	HNS_BackupCvars();

	// Change the gravity to 450
	SetConVarInt(FindConVar("sv_gravity"), 450);

	// Unlimit the teams so there can be more hiders than seekers
	SetConVarInt(FindConVar("mp_limitteams"), 64);

	// Disable team balance
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);

	// Make it so player's can only spectate teammates, to prevent cheating
	SetConVarInt(FindConVar("mp_forcecamera"), 1);

	// Change the lighting scheme
	decl String:lightScheme[4];
	GetConVarString(cvarLight, lightScheme, sizeof(lightScheme));
	SetLightStyle(0, lightScheme);

	// Change the sky texture
	decl String:skyName[32];
	GetConVarString(cvarSky, skyName, sizeof(skyName));
	SetConVarString(FindConVar("sv_skyname"), skyName);
}

HNS_BackupCvars()
{
	Format(oldValues[CVAR_GRAVITY], sizeof(oldValues[]), "%i", GetConVarInt(FindConVar("sv_gravity")));
	Format(oldValues[CVAR_LIMITTEAMS], sizeof(oldValues[]), "%i", GetConVarInt(FindConVar("mp_limitteams")));
	Format(oldValues[CVAR_AUTOTEAMBALANCE], sizeof(oldValues[]), "%i", GetConVarInt(FindConVar("mp_autoteambalance")));
	Format(oldValues[CVAR_FORCECAMERA], sizeof(oldValues[]), "%i", GetConVarInt(FindConVar("mp_forcecamera")));

	decl String:skyName[32];
	GetConVarString(FindConVar("sv_skyname"), skyName, sizeof(skyName));
	strcopy(oldValues[CVAR_SKYNAME], sizeof(oldValues[]), skyName);
}

HNS_RestoreCvars()
{
	SetConVarInt(FindConVar("sv_gravity"), StringToInt(oldValues[CVAR_GRAVITY]));
	SetConVarInt(FindConVar("mp_limitteams"), StringToInt(oldValues[CVAR_LIMITTEAMS]));
	SetConVarInt(FindConVar("mp_autoteambalance"), StringToInt(oldValues[CVAR_AUTOTEAMBALANCE]));
	SetConVarInt(FindConVar("mp_forcecamera"), StringToInt(oldValues[CVAR_FORCECAMERA]));
	SetConVarString(FindConVar("sv_skyname"), oldValues[CVAR_SKYNAME]);
	SetLightStyle(0, "m");
}