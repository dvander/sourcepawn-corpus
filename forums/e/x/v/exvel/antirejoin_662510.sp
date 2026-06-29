#include <sourcemod>


#define PLUGIN_VERSION "2.0.0"

public Plugin:myinfo = 
{
	name = "Anti-Rejoin",
	author = "exvel",
	description = "Plugin punishes players who are killed during a round then leave and rejoin the server in the same round then try to spawn to play the same round more than once. Such players simply will not spawn for the duration of the round.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new String:PlayerClass[MAXPLAYERS + 1][4];
new bool:NeedClass[MAXPLAYERS + 1];
new bool:Played[MAXPLAYERS + 1];

new Handle:db = INVALID_HANDLE;

//CVars' handles
new Handle:cvar_anti_rejoin = INVALID_HANDLE;
new Handle:cvar_lan = INVALID_HANDLE;

//Cvars' varibles
new bool:anti_rejoin = true;
new bool:isLAN = false;


public OnPluginStart()
{
	//Lets check what game is it and if it is not a CS:S return error
	decl String:gameName[80];
	GetGameFolderName(gameName, 80);
	
	if (!StrEqual(gameName, "cstrike"))
	{
		SetFailState("This plugin is only for Counter-Strike: Source");
	}
	
	// Creating keyvalues. It is our DB.
	db = CreateKeyValues("antirejoin");
	
	// Creating cvars
	CreateConVar("sm_anti_rejoin_version", PLUGIN_VERSION, "Anti-Rejoin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_anti_rejoin = CreateConVar("sm_anti_rejoin", "1", "0 = disabled, 1 = slays players who play the round more than once", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_lan = FindConVar("sv_lan");
	
	// Hooking cvar change
	HookConVarChange(cvar_anti_rejoin, OnCVarChange);
	HookConVarChange(cvar_lan, OnCVarChange);
	
	// Hooking events
	HookEvent("round_end", ClearInfo, EventHookMode_Post);
	HookEvent("round_start", ClearInfo, EventHookMode_Pre);
	HookEvent("game_newmap", ClearInfo, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	// This is for our punishment
	RegConsoleCmd("joinclass", Command_JoinClass);
}

// Here we can control our punishment. If player already played in this round
// he will not spawn because we blocked "joinclass" command
public Action:Command_JoinClass(client, args)
{
	decl String:steamId[30];
	GetClientAuthString(client, steamId, sizeof(steamId));
		
	if (GetClientTeam(client) == 1 || KvGetNum(db, steamId, 0) == 0 || IsFakeClient(client) || isLAN || !anti_rejoin)
	{
		NeedClass[client] = false;
		return Plugin_Continue;
	}
	
	if (args == 0)
	{
		PlayerClass[client] = "0";
		NeedClass[client] = true;
	}
	else
	{
		GetCmdArg(1, PlayerClass[client], sizeof(PlayerClass));
		NeedClass[client] = true;
	}
	
	FakeClientCommandEx(client, "spec_mode");
	
	return Plugin_Handled;
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
}

// If player respawned somehow (by other plugin for example) we will not punish him
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:steamId[30];
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAuthString(client, steamId, sizeof(steamId));
	
	KvDeleteKey(db, steamId);
	NeedClass[client] = false;
	Played[client] = false;
}

// If player died it means that he already played and if he will disconnect we can add his steamId to DB
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
	if (isLAN || IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	
	Played[client] = true;
	
	return Plugin_Continue;
}

// On each round start/end or new map start we must clear DB and all info
public Action:ClearInfo(Handle:event, const String:name[], bool:dontBroadcast)
{
	CloseHandle(db);
	db = CreateKeyValues("antirejoin");
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) != 1 && NeedClass[client])
		{
			// Ok, now we can spawn poor player. DB was cleared so "joinclass" command is available
			FakeClientCommandEx(client, "joinclass %s", PlayerClass[client]);
		}
		
		NeedClass[client] = false;
		Played[client] = false;
	}

	return Plugin_Continue;
}

// Just for sure
public OnClientPutInServer(client)
{
	NeedClass[client] = false;
	Played[client] = false;
}

// If player already played we will add him to DB
public OnClientDisconnect(client)
{
	if (isLAN || !anti_rejoin || IsFakeClient(client))
	{
		return;
	}
	
	if (Played[client])
	{
		decl String:steamId[30];
		GetClientAuthString(client, steamId, sizeof(steamId));
		
		KvSetNum(db, steamId, 1);
	}
}

// Get new values of cvars if they has being changed
public GetCVars()
{
	anti_rejoin = GetConVarBool(cvar_anti_rejoin);
	isLAN = GetConVarBool(cvar_lan);
}