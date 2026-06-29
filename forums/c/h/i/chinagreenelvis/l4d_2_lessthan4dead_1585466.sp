#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "3.0 Beta 1"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Less Than 4 Dead / More Than 4 Dead",
	author = "chinagreenelvis",
	description = "Dynamically change the number of survivors",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1330706"
}

new bool:Enabled = false;
new survivorlimit = 0;
new survivors = 0;

new NewClient[MAXPLAYERS+1];

new Handle:lt4d_survivors = INVALID_HANDLE;
new Handle:lt4d_survivorsmin = INVALID_HANDLE;
new Handle:lt4d_survivorsmax = INVALID_HANDLE;
new Handle:lt4d_commons = INVALID_HANDLE;
new Handle:lt4d_commons_1player = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_1player = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_1player = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_1player = INVALID_HANDLE;
new Handle:lt4d_commons_2players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_2players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_2players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_2players = INVALID_HANDLE;
new Handle:lt4d_commons_3players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_3players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_3players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_3players = INVALID_HANDLE;
new Handle:lt4d_commons_4players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_4players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_4players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_4players = INVALID_HANDLE;
new Handle:lt4d_commons_5players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_5players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_5players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_5players = INVALID_HANDLE;
new Handle:lt4d_commons_6players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_6players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_6players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_6players = INVALID_HANDLE;
new Handle:lt4d_commons_7players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_7players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_7players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_7players = INVALID_HANDLE;
new Handle:lt4d_commons_8players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_8players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_8players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_8players = INVALID_HANDLE;
new Handle:lt4d_commons_9players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_9players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_9players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_9players = INVALID_HANDLE;
new Handle:lt4d_commons_10players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_10players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_10players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_10players = INVALID_HANDLE;
new Handle:lt4d_commons_11players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_11players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_11players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_11players = INVALID_HANDLE;
new Handle:lt4d_commons_12players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_12players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_12players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_12players = INVALID_HANDLE;
new Handle:lt4d_commons_13players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_13players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_13players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_13players = INVALID_HANDLE;
new Handle:lt4d_commons_14players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_14players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_14players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_14players = INVALID_HANDLE;
new Handle:lt4d_commons_15players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_15players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_15players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_15players = INVALID_HANDLE;
new Handle:lt4d_commons_16players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_16players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_16players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_16players = INVALID_HANDLE;
new Handle:lt4d_commons_17players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_17players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_17players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_17players = INVALID_HANDLE;
new Handle:lt4d_commons_18players = INVALID_HANDLE;
new Handle:lt4d_commons_megamob_18players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmin_18players = INVALID_HANDLE;
new Handle:lt4d_commons_mobmax_18players = INVALID_HANDLE;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

public OnPluginStart() 
{
	lt4d_commons = CreateConVar("lt4d_commons", "1", "Allow common infected regulation? 1: Yes, 0: No", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_commons_1player = CreateConVar("lt4d_commons_1player", "15", "Number of common infected for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_2players = CreateConVar("lt4d_commons_2players", "20", "Number of common infected for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_3players = CreateConVar("lt4d_commons_3players", "25", "Number of common infected for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_4players = CreateConVar("lt4d_commons_4players", "30", "Number of common infected for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_5players = CreateConVar("lt4d_commons_5players", "35", "Number of common infected for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_6players = CreateConVar("lt4d_commons_6players", "40", "Number of common infected for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_7players = CreateConVar("lt4d_commons_7players", "45", "Number of common infected for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_8players = CreateConVar("lt4d_commons_8players", "50", "Number of common infected for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_9players = CreateConVar("lt4d_commons_9players", "55", "Number of common infected for nine players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_10players = CreateConVar("lt4d_commons_10players", "60", "Number of common infected for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_11players = CreateConVar("lt4d_commons_11players", "65", "Number of common infected for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_12players = CreateConVar("lt4d_commons_12players", "70", "Number of common infected for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_13players = CreateConVar("lt4d_commons_13players", "75", "Number of common infected for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_14players = CreateConVar("lt4d_commons_14players", "80", "Number of common infected for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_15players = CreateConVar("lt4d_commons_15players", "85", "Number of common infected for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_16players = CreateConVar("lt4d_commons_16players", "90", "Number of common infected for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_17players = CreateConVar("lt4d_commons_17players", "95", "Number of common infected for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_18players = CreateConVar("lt4d_commons_18players", "100", "Number of common infected for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_commons_megamob_1player = CreateConVar("lt4d_commons_megamob_1player", "20", "Mega-mob size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_2players = CreateConVar("lt4d_commons_megamob_2players", "30", "Mega-mob size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_3players = CreateConVar("lt4d_commons_megamob_3players", "40", "Mega-mob size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_4players = CreateConVar("lt4d_commons_megamob_4players", "50", "Mega-mob size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_5players = CreateConVar("lt4d_commons_megamob_5players", "60", "Mega-mob size for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_6players = CreateConVar("lt4d_commons_megamob_6players", "70", "Mega-mob size for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_7players = CreateConVar("lt4d_commons_megamob_7players", "80", "Mega-mob size for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_8players = CreateConVar("lt4d_commons_megamob_8players", "90", "Mega-mob size for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_9players = CreateConVar("lt4d_commons_megamob_9players", "20", "Mega-mob size for nine player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_10players = CreateConVar("lt4d_commons_megamob_10players", "30", "Mega-mob size for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_11players = CreateConVar("lt4d_commons_megamob_11players", "40", "Mega-mob size for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_12players = CreateConVar("lt4d_commons_megamob_12players", "50", "Mega-mob size for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_13players = CreateConVar("lt4d_commons_megamob_13players", "60", "Mega-mob size for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_14players = CreateConVar("lt4d_commons_megamob_14players", "70", "Mega-mob size for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_15players = CreateConVar("lt4d_commons_megamob_15players", "80", "Mega-mob size for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_16players = CreateConVar("lt4d_commons_megamob_16players", "90", "Mega-mob size for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_17players = CreateConVar("lt4d_commons_megamob_17players", "80", "Mega-mob size for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_megamob_18players = CreateConVar("lt4d_commons_megamob_18players", "90", "Mega-mob size for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	lt4d_commons_mobmin_1player = CreateConVar("lt4d_commons_mobmin_1player", "4", "Minimum mob spawn size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_2players = CreateConVar("lt4d_commons_mobmin_2players", "6", "Minimum mob spawn size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_3players = CreateConVar("lt4d_commons_mobmin_3players", "8", "Minimum mob spawn size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_4players = CreateConVar("lt4d_commons_mobmin_4players", "10", "Minimum mob spawn size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_5players = CreateConVar("lt4d_commons_mobmin_5players", "12", "Minimum mob spawn size for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_6players = CreateConVar("lt4d_commons_mobmin_6players", "14", "Minimum mob spawn size for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_7players = CreateConVar("lt4d_commons_mobmin_7players", "16", "Minimum mob spawn size for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_8players = CreateConVar("lt4d_commons_mobmin_8players", "18", "Minimum mob spawn size for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_9players = CreateConVar("lt4d_commons_mobmin_9players", "20", "Minimum mob spawn size for nine player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_10players = CreateConVar("lt4d_commons_mobmin_10players", "22", "Minimum mob spawn size for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_11players = CreateConVar("lt4d_commons_mobmin_11players", "24", "Minimum mob spawn size for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_12players = CreateConVar("lt4d_commons_mobmin_12players", "26", "Minimum mob spawn size for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_13players = CreateConVar("lt4d_commons_mobmin_13players", "28", "Minimum mob spawn size for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_14players = CreateConVar("lt4d_commons_mobmin_14players", "30", "Minimum mob spawn size for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_15players = CreateConVar("lt4d_commons_mobmin_15players", "32", "Minimum mob spawn size for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_16players = CreateConVar("lt4d_commons_mobmin_16players", "34", "Minimum mob spawn size for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_17players = CreateConVar("lt4d_commons_mobmin_17players", "36", "Minimum mob spawn size for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmin_18players = CreateConVar("lt4d_commons_mobmin_18players", "38", "Minimum mob spawn size for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	lt4d_commons_mobmax_1player = CreateConVar("lt4d_commons_mobmax_1player", "10", "Maximum mob spawn size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_2players = CreateConVar("lt4d_commons_mobmax_2players", "20", "Maximum mob spawn size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_3players = CreateConVar("lt4d_commons_mobmax_3players", "25", "Maximum mob spawn size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_4players = CreateConVar("lt4d_commons_mobmax_4players", "30", "Maximum mob spawn size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_5players = CreateConVar("lt4d_commons_mobmax_5players", "35", "Maximum mob spawn size for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_6players = CreateConVar("lt4d_commons_mobmax_6players", "40", "Maximum mob spawn size for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_7players = CreateConVar("lt4d_commons_mobmax_7players", "45", "Maximum mob spawn size for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_8players = CreateConVar("lt4d_commons_mobmax_8players", "50", "Maximum mob spawn size for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_9players = CreateConVar("lt4d_commons_mobmax_9players", "55", "Maximum mob spawn size for nine player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_10players = CreateConVar("lt4d_commons_mobmax_10players", "60", "Maximum mob spawn size for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_11players = CreateConVar("lt4d_commons_mobmax_11players", "65", "Maximum mob spawn size for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_12players = CreateConVar("lt4d_commons_mobmax_12players", "70", "Maximum mob spawn size for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_13players = CreateConVar("lt4d_commons_mobmax_13players", "75", "Maximum mob spawn size for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_14players = CreateConVar("lt4d_commons_mobmax_14players", "80", "Maximum mob spawn size for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_15players = CreateConVar("lt4d_commons_mobmax_15players", "85", "Maximum mob spawn size for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_16players = CreateConVar("lt4d_commons_mobmax_16players", "90", "Maximum mob spawn size for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_17players = CreateConVar("lt4d_commons_mobmax_17players", "95", "Maximum mob spawn size for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_commons_mobmax_18players = CreateConVar("lt4d_commons_mobmax_18players", "100", "Maximum mob spawn size for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_survivors = CreateConVar("lt4d_survivors", "1", "Allow dyanamic survivor numbers? 1: Yes, 0: No", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_survivorsmin = CreateConVar("lt4d_survivorsmin", "1", "Minimum number of survivors to allow (additional slots are filled by bots)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_survivorsmax = CreateConVar("lt4d_survivorsmax", "4", "Maximum number of survivors to allow", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_2_lessthan4dead");
	
	LoadTranslations("common.phrases");
	hGameConf = LoadGameConfigFile("l4drespawn");
	
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("mission_lost", Event_MissionLost);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
}

public OnConfigsExecuted()
{
	if (GetConVarInt(lt4d_survivors) == 1)
	{
		new flags = GetConVarFlags(FindConVar("survivor_limit")); 
		if (flags & FCVAR_NOTIFY)
		{ 
			SetConVarFlags(FindConVar("survivor_limit"), flags ^ FCVAR_NOTIFY); 
		}
		new max = GetConVarInt(lt4d_survivorsmax);
		if (GetConVarInt(lt4d_survivorsmax) < GetConVarInt(lt4d_survivorsmin))
		{
			max = GetConVarInt(lt4d_survivorsmin);
		}
		SetConVarInt(FindConVar("survivor_limit"), max);
		SetConVarInt(FindConVar("sv_visiblemaxplayers"), max);
		SetConVarInt(FindConVar("director_no_survivor_bots"), 1);
		//for (new i = 1; i <= MaxClients; i++)
		//{
		//	if (IsClientConnected(i) && IsFakeClient(i)) 
		//	{
		//		KickClient(i);
		//	}
		//}
	}
}

public OnMapEnd()
{
	if (Enabled == true)
	{
		Enabled = false;
	}
}

public OnClientPutInServer(client)
{
	PlayerCheck();
}

public OnClientDisconnect(client)
{
	PlayerCheck();	
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
			CreateTimer(5.0, Timer_DifficultySet);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
			CreateTimer(5.0, Timer_DifficultySet);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{	
		if (GetClientTeam(client) == 2)
		{
			CreateTimer(1.0, Timer_DifficultyCheck);
		}
	}
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, Timer_DifficultyCheck);
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	CreateTimer(1.0, Timer_DifficultyCheck);
	if (GetConVarInt(lt4d_survivors) != 0 && NewClient[victim] == 1)
	{
		GiveRandomWeapon(victim);
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarInt(lt4d_survivors) == 1)
	{
		if (!IsFakeClient(client) && Enabled == true)
		{
			if (GetEventInt(event, "oldteam") == 2 && GetEventInt(event, "team") == 2)
			{
				NewClient[client] = 1;
				ChangeClientTeam(client, 1);
				PlayerCheck();
				CreateTimer(3.0, Timer_ChangeTeam, client);
			}
			if (GetEventInt(event, "oldteam") == 2 && GetEventInt(event, "team") == 3)
			{
				PlayerCheck();
			}
		}
	}
}

public Action:Timer_ChangeTeam(Handle:timer, any:client)
{
	ChangeClientTeam(client, 2);
	CreateTimer(1.0, Timer_Respawn, client);
}

public Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(5.0, Timer_DifficultySet);
}

PlayerCheck()
{
	if (GetConVarInt(lt4d_survivors) == 1)
	{
		if (Enabled == true)
		{
			CreateTimer(2.0, Timer_PlayerCheck);
		}
	}
}

public Action:Timer_PlayerCheck(Handle:timer)
{
	//PrintToChatAll("Performing PlayerCheck");
	new minsurvivors = GetConVarInt(lt4d_survivorsmin);
	new players = 0;
	new bots = 0;
	new survivorplayers = 0;
	new idlesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			players++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
		{
			bots++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
		{
			survivorplayers++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") > 0)
		{
			idlesurvivors++;
		}
	}
	new actualsurvivorplayers = survivorplayers + idlesurvivors;
	new waitingplayers = players - actualsurvivorplayers;
	new shouldbots = minsurvivors - actualsurvivorplayers;
	//PrintToChatAll("Actual players %i", players);
	//PrintToChatAll("Actual survivor players %i", actualsurvivorplayers);
	//PrintToChatAll("Survivor bots %i", bots);
	//PrintToChatAll("Idle survivors %i", idlesurvivors);
	if (shouldbots <= 0)
	{
		shouldbots = waitingplayers;
	}
	survivorlimit = actualsurvivorplayers + shouldbots;
	//PrintToChatAll("Survivor limit %i", survivorlimit);
	if (survivorlimit > 0)
	{
		SetConVarInt(FindConVar("survivor_limit"), survivorlimit, true, false);
		if (shouldbots > bots)
		{
			new addbots = shouldbots - bots;
			for (new i = 1; i <= addbots; i++)
			{
				//ServerCommand("sb_add");
				SetConVarInt(FindConVar("director_no_survivor_bots"), 0);
				new bot = CreateFakeClient("SurvivorBot");
				ChangeClientTeam(bot, 2);
				DispatchKeyValue(bot, "classname", "SurvivorBot");
				DispatchSpawn(bot);
				CreateTimer(0.1, Timer_KickFakeClient, bot);
				
			}
		}
		if (shouldbots < bots)
		{
			new subtractbots = bots - shouldbots;
			for (new i = 1; i <= subtractbots; i++)
			{
				CreateTimer(2.0, Timer_KickBots);
			}
		}
	}
	
}

public Action:Timer_KickFakeClient(Handle:timer, any:client)
{
	KickClient(client);
	CreateTimer(0.1, Timer_DirectorSurvivorBots);
}

public Action:Timer_DirectorSurvivorBots(Handle:timer)
{
	SetConVarInt(FindConVar("director_no_survivor_bots"), 1);
	CreateTimer(1.0, Timer_DifficultyCheck);
}

public Action:Timer_KickBots(Handle:timer)
{	
	//PrintToChatAll("A bot should be about to be kicked.")
	new bool:ABotHasBeenKicked = false;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (ABotHasBeenKicked == false)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) 
			{ 
				//PrintToChatAll("A bot is very likely about to be kicked.")
				if (IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
				{
					//PrintToChatAll("A bot is definitely about to be kicked.")
					if (IsPlayerAlive(i))
					{
						ForcePlayerSuicide(i);
					}
					KickClient(i);
					ABotHasBeenKicked = true;
					CreateTimer(1.0, Timer_DifficultyCheck);
				}
			}
		}
	}
}

public Action:Timer_DifficultySet(Handle:timer)
{
	//PrintToServer("Setting difficulty");
	survivors = GetConVarInt(FindConVar("survivor_limit"));
	SetDifficulty();
}

public Action:Timer_DifficultyCheck(Handle:timer)
{
	DifficultyCheck();
}

DifficultyCheck()
{
	//PrintToServer("Performing difficulty check");
	new alivesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(i)
		{
			if (IsClientConnected(i) && GetClientTeam(i) == 2) 
			{
				if (IsPlayerAlive(i))
				{
					alivesurvivors++;
				}
			}
		}
	}
	PrintToServer("Alive survivors %i", alivesurvivors);
	survivors = alivesurvivors;
	SetDifficulty();
}

SetDifficulty()
{
	if (GetConVarInt(lt4d_commons) == 1)
	{
		if (survivors <= 1)
		{
			PrintToServer("Setting commons for one player.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_1player));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_1player));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_1player));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_1player));
		}
		if (survivors == 2)
		{
			PrintToServer("Setting commons for two players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_2players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_2players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_2players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_2players));
		}
		if (survivors == 3)
		{
			PrintToServer("Setting commons for three players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_3players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_3players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_3players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_3players));
		}
		if (survivors == 4)
		{
			PrintToServer("Setting commons for four players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_4players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_4players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_4players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_4players));
		}
		if (survivors == 5)
		{
			PrintToServer("Setting commons for five players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_5players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_5players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_5players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_5players));
		}
		if (survivors == 6)
		{
			PrintToServer("Setting commons for six players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_6players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_6players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_6players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_6players));
		}
		if (survivors == 7)
		{
			PrintToServer("Setting commons for seven players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_7players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_7players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_7players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_7players));
		}
		if (survivors == 8)
		{
			PrintToServer("Setting commons for eight players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_8players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_8players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_8players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_8players));
		}
		if (survivors == 9)
		{
			PrintToServer("Setting commons for nine players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_9players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_9players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_9players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_9players));
		}
		if (survivors == 10)
		{
			PrintToServer("Setting commons for ten players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_10players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_10players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_10players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_10players));
		}
		if (survivors == 11)
		{
			PrintToServer("Setting commons for eleven players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_11players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_11players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_11players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_11players));
		}
		if (survivors == 12)
		{
			PrintToServer("Setting commons for twelve players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_12players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_12players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_12players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_12players));
		}
		if (survivors == 13)
		{
			PrintToServer("Setting commons for thirteen players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_13players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_13players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_13players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_13players));
		}
		if (survivors == 14)
		{
			PrintToServer("Setting commons for fourteen players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_14players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_14players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_14players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_14players));
		}
		if (survivors == 15)
		{
			PrintToServer("Setting commons for fifteen players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_15players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_15players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_15players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_15players));
		}
		if (survivors == 16)
		{
			PrintToServer("Setting commons for sixteen players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_16players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_16players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_16players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_16players));
		}
		if (survivors == 17)
		{
			PrintToServer("Setting commons for seventeen players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_17players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_17players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_17players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_17players));
		}
		if (survivors == 18)
		{
			PrintToServer("Setting commons for eighteen players.");
			SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_commons_18players));
			SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_commons_megamob_18players));
			SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_commons_mobmin_18players));
			SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_commons_mobmax_18players));
		}
	}
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	if (!IsPlayerAlive(client))
	{
		RespawnPlayer(client);
		CreateTimer(3.0, Timer_DifficultySet);
	}
	else
	{
		NewClient[client] = 0;
		CreateTimer(3.0, Timer_DifficultySet);
	}
}

static RespawnPlayer(client)
{
	SDKCall(hRoundRespawn, client);
	//CheatCommand(client, "give", "first_aid_kit");
	GiveRandomWeapon(client);
	TeleportPlayer(client);
}

static GiveRandomWeapon(client)
{
	new RandomWeapon = GetRandomInt(1, 9);
	if (RandomWeapon == 1)
	{
		CheatCommand(client, "give", "autoshotgun");
	}
	if (RandomWeapon == 1)
	{
		CheatCommand(client, "give", "pistol_magnum");
	}
	if (RandomWeapon == 2)
	{
		CheatCommand(client, "give", "pumpshotgun");
	}
	if (RandomWeapon == 3)
	{
		CheatCommand(client, "give", "rifle");
	}
	if (RandomWeapon == 4)
	{
		CheatCommand(client, "give", "rifle_ak47");
	}
	if (RandomWeapon == 5)
	{
		CheatCommand(client, "give", "rifle_desert");
	}
	if (RandomWeapon == 6)
	{
		CheatCommand(client, "give", "shotgun_chrome");
	}
	if (RandomWeapon == 7)
	{
		CheatCommand(client, "give", "shotgun_spas");
	}
	if (RandomWeapon == 8)
	{
		CheatCommand(client, "give", "smg");
	}
	if (RandomWeapon == 9)
	{
		CheatCommand(client, "give", "smg_silenced");
	}
}

static TeleportPlayer(client)
{
	new iClients[MAXPLAYERS+1];
	new iNumClients = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i) && NewClient[i] == 0)
		{
			iClients[iNumClients++] = i;
			decl String:clientname[64];
			GetClientName(i, clientname, 64);
			//PrintToServer("%s is a valid player to teleport to.", clientname);
		}
	}
	new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
	decl String:nameofclient[64];
	GetClientName(iRandomClient, nameofclient, 64);
	//PrintToServer("Teleporting new player to %s", nameofclient);
	new Float:coordinates[3];
	GetClientAbsOrigin(iRandomClient, coordinates);
	TeleportEntity(client, coordinates, NULL_VECTOR, NULL_VECTOR);
	NewClient[client] = 0;
}

stock CheatCommand(client, String:command[], String:arguments[]="")
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
