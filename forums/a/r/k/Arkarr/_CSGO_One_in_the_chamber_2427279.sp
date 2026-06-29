#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <multicolors>

#define PLUGIN_AUTHOR 	"Arkarr"
#define PLUGIN_VERSION	"1.00 - Arkarr's version"
#define PLUGIN_TAG		"[OITC]"
#define PLUGIN_CTAG		"{green}[OITC]{default}"

#define SPAWN_FOLDER	"configs/oitc_spawns"

#define POSITION_X		"POSITION_X"
#define POSITION_Y		"POSITION_Y"
#define POSITION_Z		"POSITION_Z"

#define COLLISION_PUSH  17

#define NEXT_ROUND_TIMER  3.0

#define AMMO_ADD  0
#define AMMO_SET  1

Handle ARRAY_Spawns;
Handle CVAR_AmmunitionLogic;
Handle CVAR_MaxiumPoints;
Handle CVAR_RoudnsBeforeMapChange;

bool PluginEnabled;
bool Immunised[MAXPLAYERS + 1];
bool Winning;

int NumberOfSpawns;
int Rounds;

float Points[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[CSGO] One in the chamber", 
	author = PLUGIN_AUTHOR, 
	description = "Emulate CoD One In The Chamber game mode", 
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemode.net"
};

public void OnPluginStart()
{
	EngineVersion Game = GetEngineVersion();
	if (Game != Engine_CSGO && Game != Engine_CSS)
	SetFailState("%s This plugin is for CSGO/CSS only.", PLUGIN_TAG);
	
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	CVAR_AmmunitionLogic = CreateConVar("sm_oitc_ammunition_logic", "1", "How does the ammunition reward work ? 1 = ALWAYS 1 ammo no matterr what | 0 = Each kill reward with +1 ammo", _, true, 0.0, true, 1.0);
	CVAR_MaxiumPoints = CreateConVar("sm_oitc_maximum_points", "30", "How much points needed to win for each round ?");
	CVAR_RoudnsBeforeMapChange = CreateConVar("sm_oitc_rounds_before_map_change", "3", "How much round each map ?");
	
	RegAdminCmd("sm_createspawn", CMD_CreateSpawn, ADMFLAG_CHANGEMAP, "Create a new spawn location");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_PostThinkPost, OnPostThinkPost);
			SDKHook(i, SDKHook_WeaponDrop, Hook_WeaponDrop);
		}
	}
	
	ARRAY_Spawns = CreateArray();
}

public void OnMapStart()
{
	char mapName[45];
	GetCurrentMap(mapName, sizeof(mapName));
	PluginEnabled = LoadConfiguration(mapName);
	
	if (!PluginEnabled)
	{
		PrintToServer("%s Plugin is DISABLED", PLUGIN_TAG);
	}
	else
	{
		ServerCommand("mp_freezetime 0");
		ServerCommand("mp_warmuptime 0");
		ServerCommand("mp_roundtime_defuse 0");
		ServerCommand("mp_do_warmup_period 0");
		ServerCommand("mp_roundtime_hostage 1");
		ServerCommand("mp_teammates_are_enemies 1");
		ServerCommand("mp_ignore_round_win_conditions 1");
		ServerCommand("mp_maxrounds %i", GetConVarInt(CVAR_RoudnsBeforeMapChange));
	}
}

public void OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_WeaponDrop, Hook_WeaponDrop);
	
	Points[client] = 0.0;
}

/**************
	COMMANDS
**************/

public Action CMD_CreateSpawn(client, args)
{
	if (!PluginEnabled)
		return Plugin_Handled;
	
	if (client == 0)
	{
		PrintToServer("%s This command is restricted to in-game.", PLUGIN_TAG);
		return Plugin_Handled;
	}
	
	float newSpawn[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", newSpawn);
	
	Handle trie = CreateTrie();
	SetTrieValue(trie, POSITION_X, newSpawn[0]);
	SetTrieValue(trie, POSITION_Y, newSpawn[1]);
	SetTrieValue(trie, POSITION_Z, newSpawn[2]);
	PushArrayCell(ARRAY_Spawns, trie);
	
	CPrintToChat(client, "%s New spawn added !", PLUGIN_CTAG);
	
	NumberOfSpawns++;
	
	SaveConfiguration();
	
	return Plugin_Handled;
}

/**************
	 EVENTS
**************/

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!PluginEnabled || !IsValidClient(client))
		return;
	
	CreateTimer(0.5, CheckAmmo, client);
		
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 100, 255, 100, 200);
	
	Immunised[client] = true;
	
	CreateTimer(5.0, TMR_SetMortality, client);
	
	CPrintToChat(client, "%s You are in god mode for 5 seconds !", PLUGIN_CTAG);
	
	if(NumberOfSpawns == 0)
		return;
	
	int spawnID = GetRandomInt(0, NumberOfSpawns - 1);
	Handle positions = GetArrayCell(ARRAY_Spawns, spawnID);
	
	float newSpawn[3];
	GetTrieValue(positions, POSITION_X, newSpawn[0]);
	GetTrieValue(positions, POSITION_Y, newSpawn[1]);
	GetTrieValue(positions, POSITION_Z, newSpawn[2]);
	
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_PUSH);
	
	TeleportEntity(client, newSpawn, NULL_VECTOR, NULL_VECTOR);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
		Points[i] = 0.0;
		
	Winning = false;
		
	char strRoundsLeft[45];
	char lastRounds[45];
	int roundsLeft = GetConVarInt(FindConVar("mp_maxrounds"))-Rounds;
	Format(strRoundsLeft, sizeof(strRoundsLeft), "%i rounds", roundsLeft);
	Format(lastRounds, sizeof(lastRounds), "%s", (roundsLeft == 0) ? "LAST ROUND" : strRoundsLeft);
	CPrintToChatAll("%s %s until next map", PLUGIN_CTAG, lastRounds);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(GameRules_GetProp("m_totalRoundsPlayed") == Rounds)
		GameRules_SetProp("m_totalRoundsPlayed", ++Rounds);
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	Rounds = GameRules_GetProp("m_totalRoundsPlayed");
	if(Rounds == GetConVarInt(FindConVar("mp_maxrounds")))
		CreateTimer(NEXT_ROUND_TIMER, TMR_ChangeMap);
}

public Action TMR_ChangeMap(Handle tmr)
{
	char nextMap[45];
	GetNextMap(nextMap, sizeof(nextMap));
	ForceChangeLevel(nextMap, "[OITC] Map change.");
}
		
public Action TMR_SetMortality(Handle tmr, any client)
{
	if(IsValidClient(client))
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client);
		
		Immunised[client] = false;
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int&attacker, int&inflictor, float&damage, int&damagetype, int&weapon, float damageForce[3], float damagePosition[3])
{
	if (!PluginEnabled)
		return Plugin_Continue;
		
	if (victim == attacker || attacker == 0)
		return Plugin_Continue;
	
	if (Immunised[victim])
		return Plugin_Handled;
	
	damage *= GetRandomFloat(100.0, 999.0);
	damageForce[0] *= GetRandomFloat(500.0, 800.0);
	damageForce[1] *= GetRandomFloat(500.0, 800.0);
	damageForce[2] *= GetRandomFloat(500.0, 800.0);
	
	if(weapon != -1)
	{
		char sWeapon[32];
		GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
		
		if(StrEqual(sWeapon, "weapon_knife"))
			Points[attacker]+= 2;
		else
			Points[attacker]+= 1;
			
		if(damagetype & CS_DMG_HEADSHOT)
			Points[attacker]+= 0.5;
			
		if(Points[attacker] >= GetConVarInt(CVAR_MaxiumPoints))
			PlayerWon(attacker);
		else
			PrintHintText(attacker, "Points : %.2f/%.2f", Points[attacker], GetConVarFloat(CVAR_MaxiumPoints));
			
		SetAmmo(GetPlayerWeaponSlot(attacker, CS_SLOT_SECONDARY));
	}
	
	return Plugin_Changed;
}

public Action Hook_WeaponDrop(client, weapon)
{
    if(IsValidEdict(weapon))
        AcceptEntityInput( weapon, "Kill" );        
    return Plugin_Continue;
} 

public Action Event_OnPlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	if (!PluginEnabled)
		return Plugin_Continue;
		
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(attacker == 0)
		return Plugin_Continue;
	
	CreateTimer(0.1, TMR_Refill, attacker);
	CreateTimer(3.0, TMR_Respawn, victim);
	
	return Plugin_Continue;
}

public Action TMR_Refill(Handle tmr, any client)
{
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
		SetAmmo(weapon);
	
	return Plugin_Continue;
}

public Action TMR_Respawn(Handle tmr, any client)
{
	if(IsValidClient(client))
		CS_RespawnPlayer(client);	
	
	return Plugin_Continue;
}

public Action OnPostThinkPost(entity)
{
	if (!PluginEnabled)
		return Plugin_Continue;
		
	SetEntProp(entity, Prop_Send, "m_bInBuyZone", 0);
	return Plugin_Continue;
}

public Action CheckAmmo(Handle timer, any client)
{
	if ((!IsValidClient(client) || !IsPlayerAlive(client)) || (GetClientTeam(client) == CS_TEAM_SPECTATOR))
	return;
	
	int c4 = GetPlayerWeaponSlot(client, CS_SLOT_C4);
	if (c4 != -1)
	RemovePlayerItem(client, c4);
	
	int secondary = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if (secondary != -1)
	RemovePlayerItem(client, secondary);
	
	int primary = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if (primary != -1)
	RemovePlayerItem(client, primary);
	
	int nadeslot = GetPlayerWeaponSlot(client, CS_SLOT_GRENADE);
	if (nadeslot != -1)
	RemovePlayerItem(client, nadeslot);
	
	GivePlayerItem(client, "weapon_deagle");
	
	SetEntProp(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY), Prop_Data, "m_iClip1", 0);
	SetEntProp(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY), Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	SetEntProp(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY), Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
	
	SetAmmo(GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY));
}

/**************
	 STOCKS
**************/

stock void PlayerWon(int client)
{
	if(!Winning)
	{
		PrintHintTextToAll("%N won with %.2f points !", client, Points[client]);	
		Winning = true;
		CS_TerminateRound(NEXT_ROUND_TIMER, CSRoundEnd_GameStart);
	}
}

stock void SetAmmo(weapon)
{
	if (!IsValidEntity(weapon))
		return;
	
	int client = GetEntPropEnt(weapon, Prop_Data, "m_hOwner");
	
	if (client == -1)
		return;
	
	int primammotype = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
	if (primammotype != -1)
	{
		if(GetConVarInt(CVAR_AmmunitionLogic) == AMMO_ADD)
			SetEntProp(weapon, Prop_Data, "m_iClip1", GetEntProp(weapon, Prop_Data, "m_iClip1")+1);
		else if(GetConVarInt(CVAR_AmmunitionLogic) == AMMO_SET)
			SetEntProp(weapon, Prop_Data, "m_iClip1", 1);
		SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
		SetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount", 0);
	}
}

stock bool LoadConfiguration(const char[] mapName)
{
	char path[75];
	BuildPath(Path_SM, path, sizeof(path), "%s/%s.cfg", SPAWN_FOLDER, mapName);
	
	if (!DirExists("addons/sourcemod/configs/oitc_spawns"))
		CreateDirectory("/addons/sourcemod/configs/oitc_spawns", 777);
	
	Handle file = INVALID_HANDLE;
	if (!FileExists(path))
		file = OpenFile(path, "w");
	else
		file = OpenFile(path, "r");
	
	char line[200];
	ClearArray(ARRAY_Spawns);
	
	while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
	{
		char positions[3][15];
		ExplodeString(line, ";", positions, sizeof positions, sizeof positions[]);
		
		Handle trie = CreateTrie();
		SetTrieValue(trie, POSITION_X, StringToFloat(positions[0]));
		SetTrieValue(trie, POSITION_Y, StringToFloat(positions[1]));
		SetTrieValue(trie, POSITION_Z, StringToFloat(positions[2]));
		
		PushArrayCell(ARRAY_Spawns, trie);
	}
	CloseHandle(file);
	
	NumberOfSpawns = GetArraySize(ARRAY_Spawns);
	
	if (NumberOfSpawns < 1)
	PrintToServer("%s ZERO SPAWNS FOUND !", PLUGIN_TAG);
	else
	PrintToServer("%s LOADED %i CUSTOM SPAWNS !", PLUGIN_TAG, NumberOfSpawns);
	
	return true;
}

stock void SaveConfiguration()
{
	char path[75], mapName[45];
	GetCurrentMap(mapName, sizeof(mapName));
	
	BuildPath(Path_SM, path, sizeof(path), "%s/%s.cfg", SPAWN_FOLDER, mapName);
	
	PrintToServer("%s Target file : %s", PLUGIN_TAG, path);
	Handle file = OpenFile(path, "w");
	for (int i = 0; i < GetArraySize(ARRAY_Spawns); i++)
	{
		Handle trie = GetArrayCell(ARRAY_Spawns, i);
		float Px = 0.0;
		float Py = 0.0;
		float Pz = 0.0;
		GetTrieValue(trie, POSITION_X, Px);
		GetTrieValue(trie, POSITION_Y, Py);
		GetTrieValue(trie, POSITION_Z, Pz);
		WriteFileLine(file, "%f;%f;%f", Px, Py, Pz);
		PrintToServer("%s New spawn saved : X: %f Y: %f Z: %f", PLUGIN_TAG, Px, Py, Pz);
	}
	CloseHandle(file);
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
}
