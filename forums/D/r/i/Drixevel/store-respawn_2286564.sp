#include <sourcemod>
#include <MoreColors>
#include <cstrike>
#include <tf2>
#include <store>

#define PLUGIN_NAME "[Store] Respawn Item Module"
#define PLUGIN_DESCRIPTION "Adds respawns to the public Sourcemod store."
#define PLUGIN_VERSION_CONVAR "store_respawns_version"
#define PLUGIN_VERSION "1.0.5"

//Config Globals
new g_respawnsPerRound = 10;

new Handle:hRestartGame = INVALID_HANDLE;
new respawn_uses[MAXPLAYERS + 1];

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "Rodrigo286, upgraded by Keith Warren(Drixevel)",
	description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=217443"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("CS_RespawnPlayer");
	MarkNativeAsOptional("TF2_RespawnPlayer");
	return APLRes_Success;
}

public OnPluginStart() 
{
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");
	
	CreateConVar(PLUGIN_VERSION_CONVAR, PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	HookEventEx("round_end", Round_End); 
	HookEventEx("teamplay_round_win", Round_End); 

	hRestartGame = FindConVar("mp_restartgame");
	if (hRestartGame != INVALID_HANDLE)
	{
		HookConVarChange(hRestartGame, ConvarChanged)
	}
	
	LoadConfig("Store_Respawn_Config", "respawn");
}

public Store_OnDatabaseInitialized()
{
	Store_RegisterPluginModule(PLUGIN_NAME, PLUGIN_DESCRIPTION, PLUGIN_VERSION_CONVAR, PLUGIN_VERSION);
}

LoadConfig(const String:sConfigName[], const String:sConfigFile[])
{
	new Handle:kv = CreateKeyValues(sConfigName);
	
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/store/%s.cfg", sConfigFile);
	
	if (!FileToKeyValues(kv, path)) 
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", path);
	}
	
	g_respawnsPerRound = KvGetNum(kv, "respawns_per_round", 10);
	
	CloseHandle(kv);
	
	Store_RegisterItemType("respawn", OnRespawnUse);
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("respawn", OnRespawnUse);
	}	
}

public Action:Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetUses();
}

public ConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StrEqual(newVal, "1"))
	{
		ResetUses();
	}
}

ResetUses()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		respawn_uses[i] = 0;
	}
}

public OnClientPutInServer(client) 
{
	respawn_uses[client] = 0;
}

public OnClientDisconnect(client)
{
	respawn_uses[client] = 0;
}

public Store_ItemUseAction:OnRespawnUse(client, itemId, bool:equipped)
{
	if (!client || !IsClientInGame(client))
	{
		return Store_DoNothing;
	}
	
	if (GetClientTeam(client) <= 1)
	{
		CPrintToChat(client, "%tThis command is not available to spectators.", "Store Tag Colored");

		return Store_DoNothing;
	}

	if (IsPlayerAlive(client)) 
	{
		CPrintToChat(client, "%tYou already have a life, do not need another !", "Store Tag Colored");

		return Store_DoNothing;
	}

	if (g_respawnsPerRound != 0 && respawn_uses[client] >= g_respawnsPerRound)
	{
		CPrintToChat(client, "%tYou can not buy more respawns in this round, the limit is %d !", "Store Tag Colored", g_respawnsPerRound);
		return Store_DoNothing;
	}

	CS_RespawnPlayer(client);
	TF2_RespawnPlayer(client);
	
	CPrintToChat(client, "%tYou bought a new life, be careful with it !", "Store Tag Colored");
	respawn_uses[client] += 1;

	return Store_DeleteItem;	
}