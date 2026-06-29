/*  [CS:GO] Jailbreak Gangs
 *
 *  Copyright (C) 2016 Michael Flaherty // michaelwflaherty.com // michaelwflaherty@me.com
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */
 
#include <sourcemod>
#include <sdkhooks>
#include <autoexecconfig>
#include <hl_gangs>

#include <store>
#include <hl_gangs_credits>

#define PLUGIN_VERSION "1.0.8"
#define TAG " \x03[Gangs]\x04"

/* Compiler Instructions */
#pragma semicolon 1
#pragma newdecls required

/* ConVars */
ConVar gcv_bPluginEnabled;
ConVar gcv_sDatabase;
ConVar gcv_iMaxGangSize;
ConVar gcv_bInviteStyle;
ConVar gcv_iHealthPrice;
ConVar gcv_iDamagePrice;
ConVar gcv_iGravityPrice;
ConVar gcv_iSpeedPrice;
ConVar gcv_iCreateGangPrice;
ConVar gcv_iRenamePrice;
ConVar gcv_iSizePrice;
ConVar gcv_fPriceMultiplier;

/* Price Globals */
int ga_iHealthPrice[MAXPLAYERS + 1] = {0, ...};
int ga_iDamagePrice[MAXPLAYERS + 1] = {0, ...};
int ga_iGravityPrice[MAXPLAYERS + 1] = {0, ...};
int ga_iSpeedPrice[MAXPLAYERS + 1] = {0, ...};
int ga_iSizePrice[MAXPLAYERS + 1] = {0, ...};
float g_fPriceMultiplier;

/* Gang Globals */
GangRank ga_iRank[MAXPLAYERS + 1] = {Rank_Invalid, ...};
int ga_iGangSize[MAXPLAYERS + 1] = {-1, ...};
int ga_iInvitation[MAXPLAYERS + 1] = {-1, ...};
int ga_iDateJoined[MAXPLAYERS + 1] = {-1, ...};
int ga_iHealth[MAXPLAYERS + 1] = {0, ...};
int ga_iDamage[MAXPLAYERS + 1] = {0, ...};
int ga_iGravity[MAXPLAYERS + 1] = {0, ...};
int ga_iSpeed[MAXPLAYERS + 1] = {0, ...};
int ga_iSize[MAXPLAYERS + 1] = {0, ...};
int ga_iTimer[MAXPLAYERS + 1] = {0, ...};
int ga_iCTKills[MAXPLAYERS + 1] = {0, ...};
int ga_iTempInt[MAXPLAYERS + 1] = {0, ...};
int ga_iTempInt2[MAXPLAYERS + 1] = {0, ...};
int g_iGangAmmount = 0;

char ga_sGangName[MAXPLAYERS + 1][128];
char ga_sInvitedBy[MAXPLAYERS + 1][128];

bool ga_bSetName[MAXPLAYERS + 1] = {false, ...};
bool ga_bIsPlayerInDatabase[MAXPLAYERS + 1] = {false, ...};
bool ga_bIsGangInDatabase[MAXPLAYERS + 1] = {false, ...};
bool ga_bHasGang[MAXPLAYERS + 1] = {false, ...};
bool ga_bRename[MAXPLAYERS + 1] = {false, ...};
bool g_bLR = false;

float ga_fChangedGravity[MAXPLAYERS + 1] = {0.0, ...};

/* Player Globals */
char ga_sSteamID[MAXPLAYERS + 1][30];
bool g_bLateLoad = false;
bool ga_bLoaded[MAXPLAYERS + 1] = {false, ...};

/* Database Globals */
Database g_hDatabase = null;
char g_sDatabaseName[60];

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max)
{
	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Store_SetClientCredits");
	MarkNativeAsOptional("Gangs_GetCredits");
	MarkNativeAsOptional("Gangs_SetCredits");


	CreateNative("Gangs_GetDamageModifier", Native_GetDmgModifier);
	CreateNative("Gangs_GetGangName", Native_GetGangName);
	CreateNative("Gangs_GetGangRank", Native_GetGangRank);
	CreateNative("Gangs_HasGang", Native_HasGang);
	CreateNative("Gangs_GetGangSize", Native_GetGangSize);
	CreateNative("Gangs_Message", Native_Message);
	CreateNative("Gangs_MessageToAll", Native_MessageToAll);

	RegPluginLibrary("hl_gangs_library");

	g_bLateLoad = bLate;
	return APLRes_Success;
}

public int Native_MessageToAll(Handle plugin, int numParams)
{
	char phrase[1024];
	int bytes;
	
	FormatNativeString(0, 1, 2, sizeof(phrase), bytes, phrase);

	PrintToChatAll("%s %s", TAG, phrase);
}

public int Native_Message(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}
	
	char phrase[1024];
	int bytes;
	
	FormatNativeString(0, 2, 3, sizeof(phrase), bytes, phrase);

	PrintToChat(client, "%s %s", TAG, phrase);
	return 0;
}

public int Native_GetDmgModifier(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	float fDamage = ga_iDamage[client] * 1.5;
	return view_as<int>(fDamage);
}

public int Native_GetGangName(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	SetNativeString(2, ga_sGangName[client], GetNativeCell(3));
	return 0;
}

public int Native_GetGangRank(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	return view_as<int>(ga_iRank[client]);
}

public int Native_HasGang(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}
	
	return view_as<int>(ga_bHasGang[client]);
}

public int Native_GetGangSize(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	return ga_iGangSize[client];
}
public Plugin myinfo =
{
	name = "[CS:GO] Jailbreak Gangs",
	author = "Headline",
	description = "An SQL-based gang plugin",
	version = PLUGIN_VERSION,
	url = "http://michaelwflaherty.com"
};

public void OnPluginStart()
{
	LoadTranslations("hl_gangs.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	
	AutoExecConfig_SetFile("hl_gangs");
	
	AutoExecConfig_CreateConVar("hl_gangs_version", PLUGIN_VERSION, "Headline's Gangs Plugin : Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	gcv_bPluginEnabled = AutoExecConfig_CreateConVar("hl_gangs_enabled", "1", "Enable the plugin? (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	gcv_bInviteStyle = AutoExecConfig_CreateConVar("hl_gangs_invite_style", "1", "Set invite style to pop up a Menu? \n      (1 = Menu, 0 = Registered Command)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	gcv_sDatabase = AutoExecConfig_CreateConVar("hl_gangs_database_name", "hl_gangs", "Name of the database for the plugin.");

	gcv_iMaxGangSize = AutoExecConfig_CreateConVar("hl_gangs_max_size", "6", "Initial size for a gang");

	gcv_iHealthPrice = AutoExecConfig_CreateConVar("hl_gangs_health_price", "20", "Price of the Health perk");

	gcv_iDamagePrice = AutoExecConfig_CreateConVar("hl_gangs_damage_price", "20", "Price of the Damage perk");

	gcv_iGravityPrice = AutoExecConfig_CreateConVar("hl_gangs_gravity_price", "20", "Price of the Gravity perk");

	gcv_iSpeedPrice = AutoExecConfig_CreateConVar("hl_gangs_speed_price", "20", "Price of the Speed perk");
	
	gcv_iSizePrice = AutoExecConfig_CreateConVar("hl_gangs_size_price", "20", "Price of the Size perk");

	gcv_iCreateGangPrice = AutoExecConfig_CreateConVar("hl_gangs_creation_price", "20", "Price of gang creation");

	gcv_iRenamePrice = AutoExecConfig_CreateConVar("hl_gangs_rename_price", "40", "Price to rename");	
	
	gcv_fPriceMultiplier = AutoExecConfig_CreateConVar("hl_gangs_pice_multiplier", "1.0", "Price multiplier for Perks. Disabled = 1.0");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	gcv_sDatabase.GetString(g_sDatabaseName, sizeof(g_sDatabaseName));

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	RegConsoleCmd("sm_gang", Command_Gang, "Open the gang menu!");
	RegConsoleCmd("sm_gangs", Command_Gang, "Open the gang menu!");

	if (gcv_bInviteStyle.BoolValue)
	{
		RegConsoleCmd("sm_accept", Command_Accept, "Accept an invitation!");
	}

	AddCommandListener(OnSay, "say"); 
	AddCommandListener(OnSay, "say_team");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			LoadSteamID(i);
			OnClientPutInServer(i);
		}
	}
}

public void OnClientConnected(int client)
{
	if (gcv_bPluginEnabled.BoolValue)
	{
		ResetVariables(client);
	}
}

public void OnClientDisconnect(int client)
{
	if (gcv_bPluginEnabled.BoolValue)
	{
		UpdateSQL(client);
		
		ResetVariables(client);
	}
}

public void OnConfigsExecuted()
{
	if (gcv_bPluginEnabled.BoolValue)
	{
		if (g_hDatabase == null)
		{
			SetDB();
		}
		if (g_bLateLoad)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					GetClientAuthId(i, AuthId_Steam2, ga_sSteamID[i], sizeof(ga_sSteamID[]));

					if (StrContains(ga_sSteamID[i], "STEAM_", true) != -1)
					{
						LoadSteamID(i);
					}
					else
					{
						CreateTimer(10.0, RefreshSteamID, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bLR = false;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bLR = false;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		if (ga_bHasGang[client])
		{
			if (ga_iHealth[client] != 0)
			{
				int iHealth = ga_iHealth[client] * 1 + 100;
				SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
			}
			if (ga_iGravity[client] != 0)
			{
				SetEntityGravity(client, GetClientGravityAmmount(client));
				ga_iTimer[client] = 0;
				CreateTimer(0.4, Timer_CheckSetGravity, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
			if (ga_iSpeed[client] != 0)
			{
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetClientSpeedAmmount(client));
			}
		}
	}
}

public Action Timer_CheckSetGravity(Handle hHandle, int iUserid)
{
	int client = GetClientOfUserId(iUserid);
	if (ga_iTimer[client] == 0)
	{
		if (GetEntityGravity(client) != 1.0 && GetEntityGravity(client) != GetClientGravityAmmount(client))
		{
			ga_fChangedGravity[client] = GetEntityGravity(client);
		}
	}
	else
	{
		if(GetEntityGravity(client) == ga_fChangedGravity[client])
		{
			// Do nothing
		}
		else
		{
			SetEntityGravity(client, GetClientGravityAmmount(client));
			return Plugin_Stop;
		}
	}
	ga_iTimer[client]++;
	return Plugin_Continue;
}


public Action RefreshSteamID(Handle hTimer, int iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if (!IsValidClient(client))
	{
		return;
	}

	GetClientAuthId(client, AuthId_Steam2, ga_sSteamID[client], sizeof(ga_sSteamID[]));
	
	if (StrContains(ga_sSteamID[client], "STEAM_", true) == -1) //still invalid - retry again
	{

		CreateTimer(10.0, RefreshSteamID, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LoadSteamID(client);
	}
}

public void OnClientPutInServer(int client) 
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 

	if (IsValidClient(client))
	{
		CreateTimer(2.0, Timer_AlertGang, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_AlertGang(Handle hTimer, int client)
{
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	PrintToGang(client, false, "%s %T", TAG, "GangAlert", LANG_SERVER, name);
}


public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if (!g_bLR && IsValidClient(attacker) && IsValidClient(victim) && ga_bHasGang[attacker] && attacker != victim && GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 2)
	{
		char sWeapon[32];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon)); 
		if (StrContains(sWeapon, "knife") != -1)
		{
			damage = damage + ga_iDamage[attacker] * 1.5;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
} 

public void OnClientPostAdminCheck(int client)
{
	if (gcv_bPluginEnabled.BoolValue)
	{	
		LoadSteamID(client);
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (GetPlayerAliveCount(2) == 1 && GetPlayerAliveCount(3) > 0)
	{
		LastRequest();
	}
	
	if (IsValidClient(attacker) && IsValidClient(client) && client != attacker && ga_bHasGang[attacker])
	{
		if (GetClientTeam(attacker) == 2 && GetClientTeam(client) == 3)
		{
			ga_iCTKills[attacker]++;
			char sQuery[300];
			Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_statistics SET ctkills = %i WHERE gang=\"%s\"", ga_iCTKills[attacker], ga_sGangName[attacker]);
			
			for (int i = 0; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (StrEqual(ga_sGangName[i], ga_sGangName[attacker]))
					{
						ga_iCTKills[i]++;
					}
				}
			}
			
			g_hDatabase.Query(SQLCallback_Void, sQuery);
		}
	}
}

/* SQL Callback On First Connection */
public void SQLCallback_Connect(Database db, const char[] error, any data)
{
	if (db == null)
	{
		SetDB();
	}
	else
	{
		g_hDatabase = db;		

		g_hDatabase.Query(SQLCallback_Void, "CREATE TABLE IF NOT EXISTS `hl_gangs_players` (`id` int(20) NOT NULL AUTO_INCREMENT, `steamid` varchar(32) NOT NULL, `playername` varchar(32) NOT NULL, `gang` varchar(32) NOT NULL, `rank` int(16) NOT NULL, `invitedby` varchar(32) NOT NULL, `date` int(32) NOT NULL, PRIMARY KEY (`id`)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1", 1);
		g_hDatabase.Query(SQLCallback_Void, "CREATE TABLE IF NOT EXISTS `hl_gangs_groups` (`id` int(20) NOT NULL AUTO_INCREMENT, `gang` varchar(32) NOT NULL, `health` int(16) NOT NULL, `damage` int(16) NOT NULL, `gravity` int(16) NOT NULL, `speed` int(16) NOT NULL, `size` int(16) NOT NULL, PRIMARY KEY (`id`)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1", 1);
		g_hDatabase.Query(SQLCallback_Void, "CREATE TABLE IF NOT EXISTS `hl_gangs_statistics` (`id` int(20) NOT NULL AUTO_INCREMENT, `gang` varchar(32) NOT NULL, `ctkills` int(16) NOT NULL, PRIMARY KEY (`id`)) DEFAULT CHARSET=utf8 AUTO_INCREMENT=1", 1);
		g_hDatabase.Query(SQLCallback_Void, "ALTER TABLE `hl_gangs_groups` MODIFY COLUMN `gang` varchar(32) NOT NULL unique", 1);
		g_hDatabase.Query(SQLCallback_Void, "ALTER TABLE `hl_gangs_statistics` MODIFY COLUMN `gang` varchar(32) NOT NULL unique", 1);
		
		DeleteDuplicates();
	}
}

void LoadSteamID(int client)
{
	if (gcv_bPluginEnabled.BoolValue)
	{
		if (!IsValidClient(client))
		{
			return;
		}
		GetClientAuthId(client, AuthId_Steam2, ga_sSteamID[client], sizeof(ga_sSteamID[]));

		if (StrContains(ga_sSteamID[client], "STEAM_", true) == -1) //if ID is invalid
		{
			CreateTimer(10.0, RefreshSteamID, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if (g_hDatabase == null) //connect not loaded - retry to give it time
		{
			CreateTimer(1.0, RepeatCheckRank, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			char sQuery[300];
			Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_players WHERE steamid=\"%s\"", ga_sSteamID[client]);
			g_hDatabase.Query(SQLCallback_CheckSQL_Player, sQuery, GetClientUserId(client));
		}
	}
}

public void SQLCallback_CheckSQL_Player(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	if (results == null)
	{
		LogError(error);
		return;
	}

	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else 
	{
		if (results.RowCount == 1)
		{
			results.FetchRow();

			results.FetchString(3, ga_sGangName[client], sizeof(ga_sGangName[]));
			ga_iRank[client] = view_as<GangRank>(results.FetchInt(4));
			results.FetchString(5, ga_sInvitedBy[client], sizeof(ga_sInvitedBy[]));
			ga_iDateJoined[client] = results.FetchInt(6);
			
			ga_bIsPlayerInDatabase[client] = true;
			ga_bHasGang[client] = true;
			ga_bLoaded[client] = true;

			ga_iHealth[client] = 0;
			ga_iDamage[client] = 0;
			ga_iGravity[client] = 0;
			ga_iSpeed[client] = 0;
			ga_iSize[client] = 0;

			char sQuery_2[300];
			Format(sQuery_2, sizeof(sQuery_2), "SELECT * FROM hl_gangs_groups WHERE gang=\"%s\"", ga_sGangName[client]);
			g_hDatabase.Query(SQLCallback_CheckSQL_Groups, sQuery_2, GetClientUserId(client));
		}
		else
		{
			if (results.RowCount > 1)
			{
				LogError("Player %L has multiple entries under their ID. Running script to clean up duplicates and keep original entry (oldest)", client);
				DeleteDuplicates();
				CreateTimer(20.0, RepeatCheckRank, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (g_hDatabase == null)
			{
				CreateTimer(2.0, RepeatCheckRank, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				ga_bHasGang[client] = false;
				ga_bLoaded[client] = true;
			}
		}
	}
}

public void SQLCallback_CheckSQL_Groups(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	if (results == null)
	{
		LogError(error);
		return;
	}

	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else 
	{
		if (results.RowCount == 1)
		{
			results.FetchRow();

			ga_iHealth[client] = results.FetchInt(2);
			ga_iDamage[client] = results.FetchInt(3);
			ga_iGravity[client] = results.FetchInt(4);
			ga_iSpeed[client] = results.FetchInt(5);
			ga_iSize[client] = results.FetchInt(6);

			char sQuery[300];
			Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_statistics WHERE gang=\"%s\"", ga_sGangName[client]);
			g_hDatabase.Query(SQL_Callback_CTKills, sQuery, GetClientUserId(client));
		}
	}
}

public void SQL_Callback_CTKills(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	if (results == null)
	{
		LogError(error);
		return;
	}

	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else 
	{
		
		if (results.RowCount == 1 && results.FetchRow())
		{
			ga_iCTKills[client] = results.FetchInt(2);
		}

	}
}


public Action RepeatCheckRank(Handle timer, int iUserID)
{
	int client = GetClientOfUserId(iUserID);
	LoadSteamID(client);
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		LogError("Error (%i): %s", data, error);
	}
}

public Action Command_Accept(int client, int args)
{
	if (!gcv_bPluginEnabled.BoolValue)
	{
		ReplyToCommand(client, "%t", "DisabledPlugin");
		return Plugin_Handled;
	}
	if (gcv_bInviteStyle.BoolValue)
	{
		ReplyToCommand(client, "%t","DisabledAcceptCommand");
		return Plugin_Handled;
	}

	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "PlayerNotInGame");
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != 2)
	{
		ReplyToCommand(client, "[SM] %t", "WrongTeam");
		return Plugin_Handled;
	}
	if (ga_bHasGang[client])
	{
		ReplyToCommand(client, "%s %t", TAG, "AlreadyInGang");
		return Plugin_Handled;
	}
	if (ga_iInvitation[client] == -1)
	{
		ReplyToCommand(client, "%s %t", TAG, "NotInvited");
		return Plugin_Handled;
	}
	if (ga_iGangSize[GetClientOfUserId(ga_iInvitation[client])] <= gcv_iMaxGangSize.IntValue + ga_iSize[GetClientOfUserId(ga_iInvitation[client])])
	{
		ReplyToCommand(client, "%s %t", TAG, "GangIsFull");
		return Plugin_Handled;
	}

	ga_sGangName[client] = ga_sGangName[GetClientOfUserId(ga_iInvitation[client])];
	ga_iDateJoined[client] = GetTime();
	ga_bHasGang[client] =  true;
	ga_bSetName[client] = false;

	char sName[MAX_NAME_LENGTH];
	GetClientName(GetClientOfUserId(ga_iInvitation[client]), sName, sizeof(sName));
	
	ga_iHealth[client] = ga_iHealth[GetClientOfUserId(ga_iInvitation[client])];
	ga_iDamage[client] = ga_iDamage[GetClientOfUserId(ga_iInvitation[client])];
	ga_iGravity[client] = ga_iGravity[GetClientOfUserId(ga_iInvitation[client])];
	ga_iSpeed[client] = ga_iSpeed[GetClientOfUserId(ga_iInvitation[client])];
	ga_iCTKills[client] = ga_iCTKills[GetClientOfUserId(ga_iInvitation[client])];
	ga_iSize[client] = ga_iSize[GetClientOfUserId(ga_iInvitation[client])];
	
	ga_sInvitedBy[client] = sName;
	ga_iGangSize[client] = 1;
	ga_iRank[client] = Rank_Normal;
	UpdateSQL(client);
	return Plugin_Handled;
}

public Action Command_Gang(int client, int args)
{
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "PlayerNotInGame");
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != 2)
	{
		ReplyToCommand(client, "[SM] %t", "WrongTeam");
		return Plugin_Handled;
	}
	StartOpeningGangMenu(client);
	return Plugin_Handled;
}


/*****************************************************************
*********************** MAIN GANG MENU  **************************
******************************************************************/


void StartOpeningGangMenu(int client)
{
	if (!StrEqual(ga_sGangName[client], ""))
	{
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_players WHERE gang = \"%s\"", ga_sGangName[client]);
		g_hDatabase.Query(SQLCallback_OpenGangMenu, sQuery, GetClientUserId(client));
	}
	else
	{
		OpenGangsMenu(client);
	}
}

public void SQLCallback_OpenGangMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}
	
	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else 
	{
		ga_iGangSize[client] = results.RowCount;
	}
	OpenGangsMenu(client);
}

void OpenGangsMenu(int client)
{
	Menu menu = CreateMenu(GangsMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	if (ga_bHasGang[client])
	{
		char sString[128];
		Format(sString, sizeof(sString), "%T \n%T %i \n%T: %s %i/%i", "GangsMenuTitle", client
																		, "Credits", client
																		, GetClientCredits(client)
																		, "CurrentGang", client
																		, ga_sGangName[client], ga_iGangSize[client], gcv_iMaxGangSize.IntValue + ga_iSize[client]);
		SetMenuTitle(menu, sString);
	}
	else
	{
		char sString[128];
		Format(sString, sizeof(sString), "%T \n%T: %i \n%T N/A", "GangsMenuTitle", client
																		, "Credits", client
																		, GetClientCredits(client)
																		, "CurrentGang", client);
		SetMenuTitle(menu, sString);
	}
	char sDisplayBuffer[128];
	
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T [%i %T]", "CreateAGang", client, gcv_iCreateGangPrice.IntValue, "Credits", client);
	menu.AddItem("create", sDisplayBuffer, (ga_bHasGang[client] || GetClientCredits(client) < gcv_iCreateGangPrice.IntValue)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "InviteToGang", client);
	menu.AddItem("invite", sDisplayBuffer, (ga_bHasGang[client] && ga_iRank[client] > Rank_Normal && ga_iGangSize[client] < gcv_iMaxGangSize.IntValue + ga_iSize[client])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "GangMembers", client);
	menu.AddItem("members", sDisplayBuffer, (ga_bHasGang[client])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "GangPerks", client);
	menu.AddItem("perks", sDisplayBuffer, (ga_bHasGang[client])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "GangAdmin", client);
	menu.AddItem("admin", sDisplayBuffer, (ga_iRank[client] >= Rank_Admin)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "LeaveGang", client);
	menu.AddItem("leave", sDisplayBuffer, (ga_bHasGang[client])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "TopGangs", client);
	menu.AddItem("topgangs", sDisplayBuffer);

	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int GangsMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if (StrEqual(sInfo, "create"))
			{
				SetClientCredits(param1, GetClientCredits(param1) - gcv_iCreateGangPrice.IntValue);
				StartGangCreation(param1);
			}
			else if (StrEqual(sInfo, "invite"))
			{
				OpenInvitationMenu(param1);
			}
			else if (StrEqual(sInfo, "members"))
			{
				StartOpeningMembersMenu(param1);
			}
			else if (StrEqual(sInfo, "perks"))
			{
				StartOpeningPerkMenu(param1);
			}
			else if (StrEqual(sInfo, "admin"))
			{
				OpenAdministrationMenu(param1);
			}
			else if (StrEqual(sInfo, "leave"))
			{
				OpenLeaveConfirmation(param1);
			}
			else if (StrEqual(sInfo, "topgangs"))
			{
				StartOpeningTopGangsMenu(param1);
			}

		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}



/*****************************************************************
***********************  GANG CREATION  **************************
******************************************************************/



void StartGangCreation(int client)
{
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "PlayerNotInGame", client);
		return;
	}
	if (GetClientTeam(client) != 2)
	{
		ReplyToCommand(client, "[SM] %t", "WrongTeam", client);
		return;
	}
	for (int i = 0; i <= 5; i++)
	{
		PrintToChat(client, "%s %t", TAG, "GangName");
	}
	ga_bSetName[client] = true;
}

public Action OnSay(int client, const char[] command, int args) 
{
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	if (ga_bSetName[client])
	{
		char sText[64], sFormattedText[2*sizeof(sText)+1]; 
		GetCmdArgString(sText, sizeof(sText));
		StripQuotes(sText);
		
		g_hDatabase.Escape(sText, sFormattedText, sizeof(sFormattedText));
		TrimString(sFormattedText);
		
		if (strlen(sFormattedText) > 16)
		{
			PrintToChat(client, "%s %t", TAG, "NameTooLong");
			return Plugin_Handled;
		}
		else if (strlen(sFormattedText) == 0)
		{
			return Plugin_Handled;
		}
		
		DataPack data = new DataPack();
		data.WriteCell(client);
		data.WriteString(sText);
		data.Reset();

		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_groups WHERE gang=\"%s\"", sFormattedText);
		g_hDatabase.Query(SQL_Callback_CheckName, sQuery, data);

		return Plugin_Handled;
	}
	else if (ga_bRename[client])
	{
		char sText[64], sFormattedText[2*sizeof(sText)+1]; 
		GetCmdArgString(sText, sizeof(sText));
		
		g_hDatabase.Escape(sText, sFormattedText, sizeof(sFormattedText));
		TrimString(sFormattedText);

		if (strlen(sFormattedText) > 16)
		{
			PrintToChat(client, "%s %t", TAG, "NameTooLong");
			return Plugin_Handled;
		}
		else if (strlen(sFormattedText) == 0)
		{
			return Plugin_Handled;
		}
		
		DataPack data = new DataPack();
		data.WriteCell(client);
		data.WriteString(sFormattedText);
		data.Reset();

		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_groups WHERE gang=\"%s\"", sFormattedText);
		g_hDatabase.Query(SQL_Callback_CheckName, sQuery, data);

		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void SQL_Callback_CheckName(Database db, DBResultSet results, const char[] error, DataPack data)
{
	if (db == null)
	{
		SetDB();
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}

	char sText[64];
	int client = data.ReadCell();
	data.ReadString(sText, sizeof(sText));
	delete data;

	if (!IsValidClient(client))
	{
		return;
	}
	else
	{
		if (ga_bSetName[client])
		{
			if (results.RowCount == 0)
			{

				strcopy(ga_sGangName[client], sizeof(ga_sGangName[]), sText);
				ga_bHasGang[client] = true;
				ga_iDateJoined[client] = GetTime();
				ga_bHasGang[client] =  true;
				ga_sInvitedBy[client] = "N/A";
				ga_iRank[client] = Rank_Owner;
				ga_iGangSize[client] = 1;

				ga_iHealth[client] = 0;
				ga_iDamage[client] = 0;
				ga_iGravity[client] = 0;
				ga_iSpeed[client] = 0;
				ga_iSize[client] = 0;
				
				UpdateSQL(client);

				CreateTimer(0.2, Timer_OpenGangMenu, client, TIMER_FLAG_NO_MAPCHANGE);
				
				char name[MAX_NAME_LENGTH];
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("%s %T", TAG, "GangCreated", LANG_SERVER, name, ga_sGangName[client]);

			}
			else
			{
				PrintToChat(client, "%s %t", TAG, "NameAlreadyUsed");
			}
			
			ga_bSetName[client] = false;
		}
		else if (ga_bRename[client])
		{
			if (results.RowCount != 0)
			{
				char sOldName[32];
				strcopy(sOldName, sizeof(sOldName), ga_sGangName[client]);
				strcopy(ga_sGangName[client], sizeof(ga_sGangName[]), sText);
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && StrEqual(ga_sGangName[i], sOldName))
					{
						strcopy(ga_sGangName[i], sizeof(ga_sGangName[]), sText);
					}
				}
				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_players SET gang=\"%s\" WHERE gang=\"%s\"", sText, sOldName);

				g_hDatabase.Query(SQLCallback_Void, sQuery);

				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_groups SET gang=\"%s\" WHERE gang=\"%s\"", sText, sOldName);

				g_hDatabase.Query(SQLCallback_Void, sQuery);
		
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_statistics SET gang=\"%s\" WHERE gang=\"%s\"", sText, sOldName);

				g_hDatabase.Query(SQLCallback_Void, sQuery);

				char name[MAX_NAME_LENGTH];
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("%s %T", TAG, "GangNameChange", LANG_SERVER, name, sOldName, sText);

				StartOpeningGangMenu(client);

			}
			else
			{
				PrintToChat(client, "%s %t", TAG, "NameAlreadyUsed");
			}
			
			ga_bRename[client] = false;
		}
	}
}

public Action Timer_OpenGangMenu(Handle hTimer, int client)
{
	StartOpeningGangMenu(client);
}


/*****************************************************************
*********************** MEMBER LIST MENU *************************
******************************************************************/


void StartOpeningMembersMenu(int client)
{
	if (!StrEqual(ga_sGangName[client], ""))
	{
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_players WHERE gang=\"%s\"", ga_sGangName[client]);

		g_hDatabase.Query(SQLCallback_OpenMembersMenu, sQuery, GetClientUserId(client));
	}
}

public void SQLCallback_OpenMembersMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else
	{
		Menu menu = CreateMenu(MemberListMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
		
		char sTitleString[128];
		Format(sTitleString, sizeof(sTitleString), "%T", "MemberList", client);
		SetMenuTitle(menu, sTitleString);

		while (results.FetchRow())
		{
			char a_sTempArray[5][128]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF)
			results.FetchString(1, a_sTempArray[0], sizeof(a_sTempArray[])); // Steam-ID
			results.FetchString(2, a_sTempArray[1], sizeof(a_sTempArray[])); // Player Name
			results.FetchString(5, a_sTempArray[2], sizeof(a_sTempArray[])); // Invited By
			IntToString(results.FetchInt(4), a_sTempArray[3], sizeof(a_sTempArray[])); // Rank
			IntToString(results.FetchInt(6), a_sTempArray[4], sizeof(a_sTempArray[])); // Date


			char sInfoString[128];
			char sDisplayString[128];

			Format(sInfoString, sizeof(sInfoString), "%s;%s;%s;%i;%i", a_sTempArray[0], a_sTempArray[1], a_sTempArray[2], StringToInt(a_sTempArray[3]), StringToInt(a_sTempArray[4]));

			if (StrEqual(a_sTempArray[3], "0"))
			{
				Format(sDisplayString, sizeof(sDisplayString), "%s (%T)", a_sTempArray[1], "MemberRank", client);
			}
			else if (StrEqual(a_sTempArray[3], "1"))
			{
				Format(sDisplayString, sizeof(sDisplayString), "%s (%T)", a_sTempArray[1], "AdminRank", client);
			}
			else if (StrEqual(a_sTempArray[3], "2"))
			{
				Format(sDisplayString, sizeof(sDisplayString), "%s (%T)", a_sTempArray[1], "OwnerRank", client);
			}
			menu.AddItem(sInfoString, sDisplayString);
		}
		menu.ExitBackButton = true;

		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MemberListMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[128];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			OpenIndividualMemberMenu(param1, sInfo);
		}
		case MenuAction_Cancel:
		{
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

void OpenIndividualMemberMenu(int client, char[] sInfo)
{
	Menu menu = CreateMenu(IndividualMemberMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	SetMenuTitle(menu, "Information On : ");

	char sTempArray[5][64]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF)
	char sDisplayBuffer[32];

	ExplodeString(sInfo, ";", sTempArray, 5, sizeof(sTempArray[]));

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "Name", client, sTempArray[1]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "Steam ID : %s", sTempArray[0]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "InvitedBy", client, sTempArray[2]);
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);


	if (StrEqual(sTempArray[3], "0"))
	{
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %T", "Rank", client, "MemberRank", client);
	}
	else if (StrEqual(sTempArray[3], "1"))
	{
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %T", "Rank", client, "AdminRank", client);
	}
	else if (StrEqual(sTempArray[3], "2"))
	{
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %T", "Rank", client, "OwnerRank", client);
	}
	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	char sFormattedTime[64];
	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%x", StringToInt(sTempArray[4]));
	Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "DateJoined", client, sFormattedTime);

	menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

	menu.ExitBackButton = true;


	menu.Display(client, MENU_TIME_FOREVER);
}

public int IndividualMemberMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{

		}
		case MenuAction_Cancel:
		{
			StartOpeningMembersMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}
/*****************************************************************
*********************** INVITATION MENU **************************
******************************************************************/



void OpenInvitationMenu(int client)
{
	Menu menu = CreateMenu(InvitationMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	
	char sInfoString[64];
	char sDisplayString[64];
	char sMenuString[32];
	
	Format(sMenuString, sizeof(sMenuString), "%T", "InviteToGang", client);
	SetMenuTitle(menu, sMenuString);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && i != client)
		{
			Format(sInfoString, sizeof(sInfoString), "%i", GetClientUserId(i));
			Format(sDisplayString, sizeof(sDisplayString), "%N", i);
			menu.AddItem(sInfoString, sDisplayString, (ga_bHasGang[i] || ga_iRank[client] == Rank_Normal)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}

	menu.Display(client, MENU_TIME_FOREVER);

}

public int InvitationMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			int iUserID = StringToInt(sInfo);

			ga_iInvitation[GetClientOfUserId(iUserID)] = GetClientUserId(param1);

			if (ga_iGangSize[param1] >= gcv_iMaxGangSize.IntValue + ga_iSize[param1])
			{
				PrintToChat(param1, "%s %t", TAG, "GangIsFull");
			}

			if (!gcv_bInviteStyle.BoolValue)
			{
				PrintToChat(GetClientOfUserId(iUserID), "%s %t", TAG, "AcceptInstructions", ga_sGangName[param1]);
			}
			else
			{
				OpenGangInvitationMenu(GetClientOfUserId(iUserID));
			}
			StartOpeningGangMenu(param1);
		}
		case MenuAction_Cancel:
		{
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}


void OpenGangInvitationMenu(int client)
{
	Menu menu = CreateMenu(SentInviteMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
	char sDisplayString[64];
	char sTitleString[64];
	
	Format(sTitleString, sizeof(sTitleString), "%T", "GangInvitation", client);
	SetMenuTitle(menu, sTitleString);

	int sender = GetClientOfUserId(ga_iInvitation[client]);
	char senderName[MAX_NAME_LENGTH];
	GetClientName(sender, senderName, sizeof(senderName));

	Format(sDisplayString, sizeof(sDisplayString), "%T", "InviteString", client, senderName);
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

	Format(sDisplayString, sizeof(sDisplayString), "%T", "WouldYouLikeToJoin", client, ga_sGangName[sender]);
	menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

	Format(sDisplayString, sizeof(sDisplayString), "%T", "IWouldLikeTo", client);
	menu.AddItem("yes", sDisplayString);
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "IWouldNotLikeTo", client);
	menu.AddItem("no", sDisplayString);

	menu.Display(client, MENU_TIME_FOREVER);
}


public int SentInviteMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if (StrEqual(sInfo, "yes"))
			{
				int sender = GetClientOfUserId(ga_iInvitation[param1]);
				
				ga_sGangName[param1] = ga_sGangName[sender];
				ga_iDateJoined[param1] = GetTime();
				ga_bHasGang[param1] =  true;
				ga_bSetName[param1] = false;
				
				ga_iHealth[param1] = ga_iHealth[sender];
				ga_iDamage[param1] = ga_iDamage[sender];
				ga_iGravity[param1] = ga_iGravity[sender];
				ga_iSpeed[param1] = ga_iSpeed[sender];
				ga_iSize[param1] = ga_iSize[sender];
				ga_iCTKills[param1] = ga_iCTKills[sender];
				
				char sName[MAX_NAME_LENGTH];
				GetClientName(sender, sName, sizeof(sName));
				ga_sInvitedBy[param1] = sName;
				ga_iGangSize[param1] = 1;
				ga_iRank[param1] = Rank_Normal;
				UpdateSQL(param1);
				
				char name[MAX_NAME_LENGTH];
				GetClientName(param1, name, sizeof(name));
				
				PrintToChatAll("%s %T", TAG, "GangJoined", LANG_SERVER, name, ga_sGangName[param1]);
			}
			else if (StrEqual(sInfo, "no"))		
			{
				// Do Nothing
			}
		}
		case MenuAction_Cancel:
		{
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}


/*****************************************************************
***********************    PERK MENU     *************************
******************************************************************/


public void StartOpeningPerkMenu(int client)
{
	if (IsValidClient(client))
	{
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT health, damage, gravity, speed, size FROM hl_gangs_groups WHERE gang=\"%s\"", ga_sGangName[client]);
		g_hDatabase.Query(SQLCallback_Perks, sQuery, GetClientUserId(client));
	}
}

public void SQLCallback_Perks(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	
	int client = GetClientOfUserId(data);
	
	if (!IsValidClient(client))
	{
		return;
	}
	else
	{
		Menu menu = CreateMenu(PerksMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
		
		char sTitleString[64];
		
		Format(sTitleString, sizeof(sTitleString), "%T", "GangPerks", client);
		SetMenuTitle(menu, sTitleString);

		if (results.RowCount == 1 && results.FetchRow())
		{
			ga_iHealth[client] = results.FetchInt(0); // Health
			ga_iDamage[client] = results.FetchInt(1); // Damage
			ga_iGravity[client] = results.FetchInt(2); // Gravity
			ga_iSpeed[client] = results.FetchInt(3); // Speed
			ga_iSize[client] = results.FetchInt(4);
		}
		
		char sDisplayBuffer[64];
		
		getMultipliedValues(client);
		
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T [%i/10] [%i %T]", "Health", client, ga_iHealth[client], ga_iHealthPrice[client], "Credits", client);
		menu.AddItem("health", sDisplayBuffer, (ga_iHealth[client] >= 10 || GetClientCredits(client) < ga_iHealthPrice[client])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);


		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T [%i/10] [%i %T]", "KnifeDamage", client, ga_iDamage[client], ga_iDamagePrice[client], "Credits", client);
		menu.AddItem("damage", sDisplayBuffer, (ga_iDamage[client] >= 10 || GetClientCredits(client) < ga_iDamagePrice[client])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);


		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T [%i/10] [%i %T]", "Gravity", client, ga_iGravity[client], ga_iGravityPrice[client], "Credits", client);
		menu.AddItem("gravity", sDisplayBuffer, (ga_iGravity[client] >= 10 || GetClientCredits(client) < ga_iGravityPrice[client])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);


		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T [%i/10] [%i %T]", "Speed", client, ga_iSpeed[client], ga_iSpeedPrice[client], "Credits", client);
		menu.AddItem("speed", sDisplayBuffer, (ga_iSpeed[client] >= 10 || GetClientCredits(client) < ga_iSpeedPrice[client])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T [%i/9] [%i %T]", "GangSize", client, ga_iSize[client], ga_iSizePrice[client], "Credits", client);
		menu.AddItem("size", sDisplayBuffer, (ga_iSize[client] >= 9 || GetClientCredits(client) < ga_iSizePrice[client])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

		menu.ExitBackButton = true;

		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int PerksMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			char sQuery[300];
			
			if (StrEqual(sInfo, "health"))
			{
				SetClientCredits(param1, GetClientCredits(param1) - ga_iHealthPrice[param1]);
				++ga_iHealth[param1];
				PrintToGang(param1, true, "%s %T", TAG, "HealthUpgrade", LANG_SERVER);
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_groups SET health=%i WHERE gang=\"%s\"", ga_iHealth[param1], ga_sGangName[param1]);
			}
			else if (StrEqual(sInfo, "damage"))
			{
				SetClientCredits(param1, GetClientCredits(param1) - ga_iDamagePrice[param1]);
				++ga_iDamage[param1];
				PrintToGang(param1, true, "%s %T", TAG, "DamageUpgrade", LANG_SERVER);
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_groups SET damage=%i WHERE gang=\"%s\"",  ga_iDamage[param1], ga_sGangName[param1]);
			}
			else if (StrEqual(sInfo, "gravity"))
			{
				SetClientCredits(param1, GetClientCredits(param1) - ga_iGravityPrice[param1]);
				PrintToGang(param1, true, "%s %T", TAG, "GravityUpgrade", LANG_SERVER);
				++ga_iGravity[param1];
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_groups SET gravity=%i WHERE gang=\"%s\"", ga_iGravity[param1], ga_sGangName[param1]);
				SetEntityGravity(param1, GetClientGravityAmmount(param1));
			}
			else if (StrEqual(sInfo, "speed"))
			{
				SetClientCredits(param1, GetClientCredits(param1) - ga_iSpeedPrice[param1]);
				PrintToGang(param1, true, "%s %T", TAG, "SpeedUpgrade", LANG_SERVER);
				++ga_iSpeed[param1];
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_groups SET speed=%i WHERE gang=\"%s\"", ga_iSpeed[param1], ga_sGangName[param1]);
				SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", GetClientSpeedAmmount(param1));
			}
			else if (StrEqual(sInfo, "size"))
			{
				SetClientCredits(param1, GetClientCredits(param1) - ga_iSizePrice[param1]);
				PrintToGang(param1, true, "%s %T", TAG, "SizeUpgrade", LANG_SERVER);
				++ga_iSize[param1];
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_groups SET size=%i WHERE gang=\"%s\"", ga_iSize[param1], ga_sGangName[param1]);
			}
			g_hDatabase.Query(SQLCallback_Void, sQuery, GetClientUserId(param1));
			
			StartOpeningPerkMenu(param1);
		}
		case MenuAction_Cancel:
		{
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}



/*****************************************************************
********************    PRICE MULTIPLIER     *********************
******************************************************************/


void getMultipliedValues(int client)
{
	g_fPriceMultiplier = GetConVarFloat(gcv_fPriceMultiplier);
	if (g_fPriceMultiplier <= 1.0) return;
	
	ga_iHealthPrice[client] = gcv_iHealthPrice.IntValue;
	ga_iDamagePrice[client] = gcv_iDamagePrice.IntValue;
	ga_iGravityPrice[client] = gcv_iGravityPrice.IntValue;
	ga_iSpeedPrice[client] = gcv_iSpeedPrice.IntValue;
	ga_iSizePrice[client] = gcv_iSizePrice.IntValue;
	
	if (ga_iHealth[client] > 0) 
	{
		for(int i = 0; i < ga_iHealth[client]; i++)
		{
			ga_iHealthPrice[client] = RoundToNearest(ga_iHealthPrice[client] * g_fPriceMultiplier);
		}
	}

	if (ga_iDamage[client] > 0) 
	{
		for(int i = 0; i < ga_iHealth[client]; i++)
		{
			ga_iDamagePrice[client] = RoundToNearest(ga_iDamagePrice[client] * g_fPriceMultiplier);
		}
	}

	if (ga_iGravity[client] > 0) 
	{
		for(int i = 0; i < ga_iHealth[client]; i++)
		{
			ga_iGravityPrice[client] = RoundToNearest(ga_iGravityPrice[client] * g_fPriceMultiplier);
		}
	}

	if (ga_iSpeed[client] > 0) 
	{
		for(int i = 0; i < ga_iHealth[client]; i++)
		{
			ga_iSpeedPrice[client] = RoundToNearest(ga_iSpeedPrice[client] * g_fPriceMultiplier);
		}
	}

	if (ga_iSize[client] > 0) 
	{
		for(int i = 0; i < ga_iHealth[client]; i++)
		{
			ga_iSizePrice[client] = RoundToNearest(ga_iSizePrice[client] * g_fPriceMultiplier);
		}
	}
}


/*****************************************************************
*******************    LEAVE CONFIRMATION     ********************
******************************************************************/


void OpenLeaveConfirmation(int client)
{
	Menu menu = CreateMenu(LeaveConfirmation_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempBuffer[128];
	
	Format(tempBuffer, sizeof(tempBuffer), "%T", "LeaveGang", client);
	SetMenuTitle(menu, tempBuffer);
	
	Format(tempBuffer, sizeof(tempBuffer), "%T", "AreYouSure", client);
	menu.AddItem("", tempBuffer, ITEMDRAW_DISABLED);
	if (ga_iRank[client] == Rank_Owner)
	{
		Format(tempBuffer, sizeof(tempBuffer), "%T", "OwnerWarning", client);
		menu.AddItem("", tempBuffer, ITEMDRAW_DISABLED);
	}

	Format(tempBuffer, sizeof(tempBuffer), "%T", "YesLeave", client);
	menu.AddItem("yes", tempBuffer);
	
	Format(tempBuffer, sizeof(tempBuffer), "%T", "NoLeave", client);
	menu.AddItem("no", tempBuffer);

	menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);
}

public int LeaveConfirmation_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if (StrEqual(sInfo, "yes"))
			{
				RemoveFromGang(param1);
			}
			else if (StrEqual(sInfo, "no"))
			{
				StartOpeningGangMenu(param1);
			}

		}
		case MenuAction_Cancel:
		{
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}




/*****************************************************************
*********************  ADMIN MAIN MENU  **************************
******************************************************************/


void OpenAdministrationMenu(int client)
{
	Menu menu = CreateMenu(AdministrationMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempBuffer[128];
	Format(tempBuffer, sizeof(tempBuffer), "%T", "GangAdmin", client);
	SetMenuTitle(menu, tempBuffer);
	
	char sDisplayString[128];
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "KickAMember", client);
	menu.AddItem("kick", "Kick a member", (ga_iRank[client] == Rank_Normal)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", client, gcv_iRenamePrice.IntValue, "Credits", client);
	menu.AddItem("rename", sDisplayString, (ga_iRank[client] == Rank_Owner && GetClientCredits(client) >= gcv_iRenamePrice.IntValue)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "Promote", client);
	menu.AddItem("promote", sDisplayString, (ga_iRank[client] == Rank_Normal)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	Format(sDisplayString, sizeof(sDisplayString), "%T", "Disband", client);
	menu.AddItem("disband", sDisplayString, (ga_iRank[client] == Rank_Owner)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);


	menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);

}

public int AdministrationMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[64];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if (StrEqual(sInfo, "kick"))
			{
				OpenAdministrationKickMenu(param1);
			}
			else if (StrEqual(sInfo, "rename"))
			{
				SetClientCredits(param1, GetClientCredits(param1) - 100);
				for (int i = 1; i <= 5; i++)
				{
					PrintToChat(param1, "%s %t", TAG, "GangName");
				}
				ga_bRename[param1] = true;
			}
			else if (StrEqual(sInfo, "promote"))
			{
				OpenAdministrationPromotionMenu(param1);
			}
			else if (StrEqual(sInfo, "disband"))
			{
				OpenDisbandMenu(param1);
			}
		}
		case MenuAction_Cancel:
		{
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}



/*****************************************************************
*******************  ADMIN PROMOTION MENU  ***********************
******************************************************************/




void OpenAdministrationPromotionMenu(int client)
{
	if (!StrEqual(ga_sGangName[client], ""))
	{
		char sQuery[200];
		Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_players WHERE gang=\"%s\"", ga_sGangName[client]);

		g_hDatabase.Query(SQLCallback_AdministrationPromotionMenu, sQuery, GetClientUserId(client));
	}
}

public void SQLCallback_AdministrationPromotionMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else
	{
		Menu menu = CreateMenu(AdministrationPromoMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
		
		char tempBuffer[128];
		Format(tempBuffer, sizeof(tempBuffer), "%T", "Promote", client);
		SetMenuTitle(menu, tempBuffer);

		while (results.FetchRow())
		{
			char sTempArray[3][128]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF)
			results.FetchString(1, sTempArray[0], sizeof(sTempArray[])); // Steam-ID
			results.FetchString(2, sTempArray[1], sizeof(sTempArray[])); // Player Name
			IntToString(results.FetchInt(4), sTempArray[2], sizeof(sTempArray[])); // Rank

			char sSteamID[34];
			GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));

			if (!StrEqual(sSteamID, sTempArray[0]))
			{
				char sInfoString[128];
				char sDisplayString[128];
				Format(sInfoString, sizeof(sInfoString), "%s;%s;%i", sTempArray[0], sTempArray[1], StringToInt(sTempArray[2]));
				Format(sDisplayString, sizeof(sDisplayString), "%s (%s)", sTempArray[1], sTempArray[0]);
				menu.AddItem(sInfoString, sDisplayString, (ga_iRank[client] == Rank_Owner)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
			}
		}
		menu.ExitBackButton = true;

		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int AdministrationPromoMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));

			OpenPromoteDemoteMenu(param1, sInfo);
		}
		case MenuAction_Cancel:
		{
			OpenAdministrationMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}


void OpenPromoteDemoteMenu(int client, const char[] sInfo)
{
	char sTempArray[3][32];
	ExplodeString(sInfo, ";", sTempArray, 3, 32);

	Menu menu = CreateMenu(AdministrationPromoDemoteMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempBuffer[128];
	Format(tempBuffer, sizeof(tempBuffer), "%T", "GangMembersRanks", client);
	SetMenuTitle(menu, tempBuffer);
	
	char sInfoString[32];
	
	Format(tempBuffer, sizeof(tempBuffer), "%T", "Simply", client);
	menu.AddItem("", tempBuffer, ITEMDRAW_DISABLED);
	
	Format(sInfoString, sizeof(sInfoString), "%s;normal", sTempArray[0]);
	Format(tempBuffer, sizeof(tempBuffer), "%T", "MemberRank", client);
	menu.AddItem(sInfoString, tempBuffer, (ga_iRank[client] != Rank_Owner)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

	Format(sInfoString, sizeof(sInfoString), "%s;admin", sTempArray[0]);
	Format(tempBuffer, sizeof(tempBuffer), "%T", "AdminRank", client);
	menu.AddItem(sInfoString, tempBuffer, (ga_iRank[client] != Rank_Owner)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

	menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);
}

public int AdministrationPromoDemoteMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			char sTempArray[2][32];
			ExplodeString(sInfo, ";", sTempArray, 2, 32);

			char sQuery[300];

			if (StrEqual(sTempArray[1], "normal"))
			{
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_players SET rank=0 WHERE steamid=\"%s\"", sTempArray[0]);
			}
			else if (StrEqual(sTempArray[1], "admin"))
			{
				Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_players SET rank=1 WHERE steamid=\"%s\"", sTempArray[0]);
			}
			
			g_hDatabase.Query(SQLCallback_Void, sQuery);
			char sSteamID[32];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));
					if (StrEqual(sSteamID, sTempArray[0]))
					{
						LoadSteamID(i);
						break;
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			OpenAdministrationMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}





/*****************************************************************
*********************   DISBAND MENU    **************************
******************************************************************/







void OpenDisbandMenu(int client)
{
	Menu menu = CreateMenu(DisbandMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	
	char tempString[128];
	
	Format(tempString, sizeof(tempString), "%T", "DisbandGang", client);
	SetMenuTitle(menu, tempString);

	Format(tempString, sizeof(tempString), "%T", "DisbandConfirmation", client);
	menu.AddItem("", tempString, ITEMDRAW_DISABLED);
	
	Format(tempString, sizeof(tempString), "%T", "YesDisband", client);
	menu.AddItem("disband", tempString, (ga_iRank[client] != Rank_Owner)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

	Format(tempString, sizeof(tempString), "%T", "NoDisband", client);
	menu.AddItem("no", tempString, (ga_iRank[client] != Rank_Owner)?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

	menu.ExitBackButton = true;

	menu.Display(client, MENU_TIME_FOREVER);
}

public int DisbandMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			if (StrEqual(sInfo, "disband"))
			{
				RemoveFromGang(param1);
			}
		}
		case MenuAction_Cancel:
		{
			OpenAdministrationMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

/*****************************************************************
*********************  ADMIN KICK MENU  **************************
******************************************************************/

void OpenAdministrationKickMenu(int client)
{
	if (!StrEqual(ga_sGangName[client], ""))
	{
		char sQuery[200];
		Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_players WHERE gang=\"%s\"", ga_sGangName[client]);

		g_hDatabase.Query(SQLCallback_AdministrationKickMenu, sQuery, GetClientUserId(client));
	}
}

public void SQLCallback_AdministrationKickMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else
	{

		Menu menu = CreateMenu(AdministrationKickMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
		
		char tempString[128];
		
		Format(tempString, sizeof(tempString), "%T", "KickGangMembers", client);
		SetMenuTitle(menu, tempString);

		while (results.FetchRow())
		{
			char sTempArray[3][128]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF)
			results.FetchString(1, sTempArray[0], sizeof(sTempArray[])); // Steam-ID
			results.FetchString(2, sTempArray[1], sizeof(sTempArray[])); // Player Name
			IntToString(results.FetchInt(4), sTempArray[2], sizeof(sTempArray[])); // Rank

			
			char sInfoString[128];
			char sDisplayString[128];

			Format(sInfoString, sizeof(sInfoString), "%s;%s", sTempArray[0], sTempArray[1]);
			Format(sDisplayString, sizeof(sDisplayString), "%s (%s)", sTempArray[1], sTempArray[0]);
			menu.AddItem(sInfoString, sDisplayString, (ga_iRank[client] > view_as<GangRank>(StringToInt(sTempArray[2])))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		}
		menu.ExitBackButton = true;

		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int AdministrationKickMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[256];
			char sTempArray[2][128];
			char sQuery1[128];
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			ExplodeString(sInfo, ";", sTempArray, 2, 128);
			
			Format(sQuery1, sizeof(sQuery1), "DELETE FROM hl_gangs_players WHERE steamid = \"%s\"", sTempArray[0]);
			g_hDatabase.Query(SQLCallback_Void, sQuery1);
			
			PrintToChatAll("%s %T", TAG, "GangMemberKick", LANG_SERVER, sTempArray[1], ga_sGangName[param1]);
			
			char sSteamID[64];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));
					if (StrEqual(sSteamID, sTempArray[0]))
					{
						ResetVariables(i);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			OpenAdministrationMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


/*****************************************************************
**********************  TOP GANGS MENU  **************************
******************************************************************/



void StartOpeningTopGangsMenu(int client)
{
	if (IsValidClient(client))
	{
		g_hDatabase.Query(SQL_Callback_TopMenu, "SELECT * FROM hl_gangs_statistics ORDER BY ctkills DESC", GetClientUserId(client));
	}
}

public void SQL_Callback_TopMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}

	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else
	{
		Menu menu = CreateMenu(TopGangsMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
		
		char menuTitle[64];
		Format(menuTitle, sizeof(menuTitle), "%T", "TopGangs", client);
		menu.SetTitle(menuTitle);
		if (results.RowCount == 0)
		{
			PrintToChat(client, "%s %t", TAG, "NoGangs");
			
			delete menu;
			return;
		}
		char sGangName[128];
		char sInfoString[128];

		
		ga_iTempInt2[client] = 0;
		g_iGangAmmount = 0;
		while (results.FetchRow())
		{
			g_iGangAmmount++;
			ga_iTempInt2[client]++;
			
			results.FetchString(1, sGangName, sizeof(sGangName));
			
			Format(sInfoString, sizeof(sInfoString), "%i;%s;%i", ga_iTempInt2[client], sGangName, results.FetchInt(2));

			menu.AddItem(sInfoString, sGangName);
		}

		menu.ExitBackButton = true;

		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int TopGangsMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sInfo[300];
			char sQuery[300];
			char sTempArray[3][128];
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));

			ExplodeString(sInfo, ";", sTempArray, 3, sizeof(sTempArray[]));

			ga_iTempInt2[param1] = StringToInt(sTempArray[0]);
			ga_iTempInt[param1] = StringToInt(sTempArray[2]);
			
			Format(sQuery, sizeof(sQuery), "SELECT * FROM `hl_gangs_players` WHERE `gang` = \"%s\" AND `rank` = 2", sTempArray[1]);
			g_hDatabase.Query(SQL_Callback_GangStatistics, sQuery, GetClientUserId(param1));

		}
		case MenuAction_Cancel:
		{
			StartOpeningGangMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}


public void SQL_Callback_GangStatistics(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	
	if (results == null)
	{
		LogError(error);
		return;
	}

	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	else
	{
		char sTempArray[2][128]; // Gang Name | Player Name 
		char sFormattedTime[64];
		char sDisplayString[128];
		
		results.FetchRow();


		results.FetchString(3, sTempArray[0], sizeof(sTempArray[]));
		results.FetchString(2, sTempArray[1], sizeof(sTempArray[]));
		int iDate = results.FetchInt(6);

		Menu menu = CreateMenu(MenuCallback_Void, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
		menu.SetTitle("Top Gangs");

		Format(sDisplayString, sizeof(sDisplayString), "%T : %s", "MenuGangName", client, sTempArray[0]);
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		Format(sDisplayString, sizeof(sDisplayString), "%T : %i/%i", "GangRank", client, ga_iTempInt2[client], g_iGangAmmount);
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		FormatTime(sFormattedTime, sizeof(sFormattedTime), "%x", iDate);
		Format(sDisplayString, sizeof(sDisplayString), "%T : %s", "DateCreated", client, sFormattedTime);
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		Format(sDisplayString, sizeof(sDisplayString), "%T : %s", "CreatedBy", client, sTempArray[1]);
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		Format(sDisplayString, sizeof(sDisplayString), "%T : %i ", "CTKills", client, ga_iTempInt[client]);
		menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

		menu.ExitBackButton = true;

		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuCallback_Void(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Do Nothing
		}
		case MenuAction_Cancel:
		{
			StartOpeningTopGangsMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	return;
}

/*****************************************************************
***********************  HELPER FUNCTIONS  ***********************
******************************************************************/


void UpdateSQL(int client)
{
	DeleteDuplicates();
	
	if (ga_bHasGang[client])
	{
		GetClientAuthId(client, AuthId_Steam2, ga_sSteamID[client], sizeof(ga_sSteamID[]));
		
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_players WHERE steamid=\"%s\"", ga_sSteamID[client]);

		g_hDatabase.Query(SQLCallback_CheckIfInDatabase_Player, sQuery, GetClientUserId(client));
	}
}

public void SQLCallback_CheckIfInDatabase_Player(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}

	int client = GetClientOfUserId(data);

	if (!IsValidClient(client))
	{
		return;
	}
	if (results.RowCount == 0)
	{
		ga_bIsPlayerInDatabase[client] = false;
	}
	else
	{
		ga_bIsPlayerInDatabase[client] = true;
	}
	char sQuery[300];
	if (!ga_bIsPlayerInDatabase[client])
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO hl_gangs_players (gang, invitedby, rank, date, steamid, playername) VALUES(\"%s\", \"%s\", %i, %i, \"%s\", \"%N\")", ga_sGangName[client], ga_sInvitedBy[client], ga_iRank[client], ga_iDateJoined[client], ga_sSteamID[client], client);
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_players SET gang=\"%s\",invitedby=\"%s\",playername=\"%N\",rank=%i,date=%i WHERE steamid=\"%s\"", ga_sGangName[client], ga_sInvitedBy[client], client, ga_iRank[client], ga_iDateJoined[client], ga_sSteamID[client]);
	}
	g_hDatabase.Query(SQLCallback_Void, sQuery);
	
	char sQuery2[128];

	Format(sQuery2, sizeof(sQuery2), "SELECT * FROM hl_gangs_groups WHERE gang=\"%s\"", ga_sGangName[client]);
	
	g_hDatabase.Query(SQLCALLBACK_GROUPS, sQuery2, GetClientUserId(client));
}

public void SQLCALLBACK_GROUPS(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}

	int client = GetClientOfUserId(data);

	if (!IsValidClient(client))
	{
		return;
	}

	if (results.RowCount == 0)
	{
		ga_bIsGangInDatabase[client] = false;
	}
	else
	{
		ga_bIsGangInDatabase[client] = true;
	}

	char sQuery[300];
	if (!ga_bIsGangInDatabase[client])
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO hl_gangs_groups (gang, health, damage, gravity, speed, size) VALUES(\"%s\", %i, %i, %i, %i, %i)", ga_sGangName[client], ga_iHealth[client], ga_iDamage[client], ga_iGravity[client], ga_iSpeed[client], ga_iSize[client]);
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_groups SET health=%i,damage=%i,gravity=%i,speed=%i,size=%i WHERE gang=\"%s\"", ga_iHealth[client], ga_iDamage[client], ga_iGravity[client], ga_iSpeed[client], ga_iSize[client], ga_sGangName[client]);

	}

	g_hDatabase.Query(SQLCallback_Void, sQuery);

	Format(sQuery, sizeof(sQuery), "SELECT * FROM hl_gangs_statistics WHERE gang = \"%s\"", ga_sGangName[client]);
	g_hDatabase.Query(SQL_Callback_LoadStatistics, sQuery, GetClientUserId(client));

}


public void SQL_Callback_LoadStatistics(Database db, DBResultSet results, const char[] error, int data)
{
	if (db == null)
	{
		SetDB();
	}
	if (results == null)
	{
		LogError(error);
		return;
	}

	int client = GetClientOfUserId(data);

	if (!IsValidClient(client))
	{
		return;
	}

	if (results.RowCount == 0)
	{
		ga_bIsGangInDatabase[client] = false;
	}
	else
	{
		ga_bIsGangInDatabase[client] = true;
	}

	char sQuery[300];
	if (!ga_bIsGangInDatabase[client])
	{
		Format(sQuery, sizeof(sQuery), "INSERT INTO hl_gangs_statistics (gang, ctkills) VALUES(\"%s\", %i)", ga_sGangName[client], ga_iCTKills[client]);
	}
	else
	{
		Format(sQuery, sizeof(sQuery), "UPDATE hl_gangs_statistics SET ctkills=%i WHERE gang=\"%s\"", ga_iCTKills[client], ga_sGangName[client]);
	}

	g_hDatabase.Query(SQLCallback_Void, sQuery);

}

void SetDB()
{
	if (g_hDatabase == null)
	{
		gcv_sDatabase.GetString(g_sDatabaseName, sizeof(g_sDatabaseName));
		Database.Connect(SQLCallback_Connect, g_sDatabaseName);
	}
}

void DeleteDuplicates()
{
	if (g_hDatabase != null)
	{
		g_hDatabase.Query(SQLCallback_Void, "delete hl_gangs_players from hl_gangs_players inner join (select min(id) minid, steamid from hl_gangs_players group by steamid having count(1) > 1) as duplicates on (duplicates.steamid = hl_gangs_players.steamid and duplicates.minid <> hl_gangs_players.id)", 4);
		g_hDatabase.Query(SQLCallback_Void, "delete hl_gangs_groups from hl_gangs_groups inner join (select min(id) minid, gang from hl_gangs_groups group by gang having count(1) > 1) as duplicates on (duplicates.gang = hl_gangs_groups.gang and duplicates.minid <> hl_gangs_groups.id)", 4);
		g_hDatabase.Query(SQLCallback_Void, "delete hl_gangs_statistics from hl_gangs_statistics inner join (select min(id) minid, gang from hl_gangs_statistics group by gang having count(1) > 1) as duplicates on (duplicates.gang = hl_gangs_statistics.gang and duplicates.minid <> hl_gangs_statistics.id)", 4);
	}
}

int GetClientCredits(int client)
{
	if (LibraryExists("store_zephyrus"))
	{
		return Store_GetClientCredits(client);
	}
	else
	{
		return Gangs_GetCredits(client);
	}
}

void SetClientCredits(int client, int iAmmount)
{
	if (LibraryExists("store_zephyrus"))
	{
		Store_SetClientCredits(client, iAmmount);
	}
	else
	{
		Gangs_SetCredits(client, iAmmount);
	}

}

void RemoveFromGang(int client)
{
	if (ga_iRank[client] == Rank_Owner)
	{
		char sQuery1[300];
		char sQuery2[300];
		char sQuery3[300];
		Format(sQuery1, sizeof(sQuery1), "DELETE FROM hl_gangs_players WHERE gang = \"%s\"", ga_sGangName[client]);
		Format(sQuery2, sizeof(sQuery2), "DELETE FROM hl_gangs_groups WHERE gang = \"%s\"", ga_sGangName[client]);
		Format(sQuery3, sizeof(sQuery2), "DELETE FROM hl_gangs_statistics WHERE gang = \"%s\"", ga_sGangName[client]);

		g_hDatabase.Query(SQLCallback_Void, sQuery1);
		g_hDatabase.Query(SQLCallback_Void, sQuery2);
		g_hDatabase.Query(SQLCallback_Void, sQuery3);
		
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("%s %T", TAG, "GangDisbanded", LANG_SERVER, name, ga_sGangName[client]);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && StrEqual(ga_sGangName[i], ga_sGangName[client]) && i != client)
			{
				ResetVariables(i);
			}
		}
		ResetVariables(client);
	}
	else
	{
		char sQuery1[128];
		Format(sQuery1, sizeof(sQuery1), "DELETE FROM hl_gangs_players WHERE steamid = \"%s\"", ga_sSteamID[client]);
		g_hDatabase.Query(SQLCallback_Void, sQuery1);
		
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		PrintToChatAll("%s %T", TAG, "LeftGang", LANG_SERVER, name, ga_sGangName[client]);
		ResetVariables(client);
	}
}


float GetClientGravityAmmount(int client)
{
	float fGravityAmmount;
	switch (ga_iGravity[client])
	{
		case 1:
		{
			fGravityAmmount = 0.98;
		}
		case 2:
		{
			fGravityAmmount = 0.96;
		}
		case 3:
		{
			fGravityAmmount = 0.94;
		}
		case 4:
		{
			fGravityAmmount = 0.92;
		}
		case 5:
		{
			fGravityAmmount = 0.90;
		}
		case 6:
		{
			fGravityAmmount = 0.89;
		}
		case 7:
		{
			fGravityAmmount = 0.88;
		}
		case 8:
		{
			fGravityAmmount = 0.87;
		}
		case 9:
		{
			fGravityAmmount = 0.86;
		}
		case 10:
		{
			fGravityAmmount = 0.85;
		}
	}
	return fGravityAmmount;
}


float GetClientSpeedAmmount(int client)
{
	float fSpeedAmmount;
	switch (ga_iSpeed[client])
	{
		case 1:
		{
			fSpeedAmmount = 1.01;
		}
		case 2:
		{
			fSpeedAmmount = 1.02;
		}
		case 3:
		{
			fSpeedAmmount = 1.03;
		}
		case 4:
		{
			fSpeedAmmount = 1.04;
		}
		case 5:
		{
			fSpeedAmmount = 1.05;
		}
		case 6:
		{
			fSpeedAmmount = 1.06;
		}
		case 7:
		{
			fSpeedAmmount = 1.07;
		}
		case 8:
		{
			fSpeedAmmount = 1.08;
		}
		case 9:
		{
			fSpeedAmmount = 1.09;
		}
		case 10:
		{
			fSpeedAmmount = 1.1;
		}
	}
	return fSpeedAmmount;
}

void PrintToGang(int client, bool bPrintToClient = false, const char[] sMsg, any ...)
{
	if(!IsValidClient(client))
	{
		return;
	}
	char sFormattedMsg[256];
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 4); 

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && StrEqual(ga_sGangName[i], ga_sGangName[client]) && !StrEqual(ga_sGangName[client], ""))
		{
			if (bPrintToClient)
			{
				PrintToChat(i, sFormattedMsg);
			}
			else
			{
				if (i == client)
				{
					// Do nothing
				}
				else
				{
					PrintToChat(i, sFormattedMsg);
				}
			}
		}
	}
}


void ResetVariables(int client)
{
	ga_iRank[client] = Rank_Invalid;
	ga_iGangSize[client] = -1;
	ga_iInvitation[client] = -1;
	ga_iDateJoined[client] = -1;
	ga_iHealth[client] = 0;
	ga_iDamage[client] = 0;
	ga_iGravity[client] = 0;
	ga_iSpeed[client] = 0;
	ga_iSize[client] = 0;
	ga_iTimer[client] = 0;
	ga_iCTKills[client] = 0;
	ga_iTempInt[client] = 0;
	ga_iTempInt2[client] = 0;
	ga_sGangName[client] = "";
	ga_sInvitedBy[client] = "";
	ga_bSetName[client] = false;
	ga_bIsPlayerInDatabase[client] = false;
	ga_bIsGangInDatabase[client] = false;
	ga_bHasGang[client] = false;
	ga_bRename[client] = false;
	ga_fChangedGravity[client] = 0.0;
	ga_sSteamID[client] = "";
	ga_bLoaded[client] = false;
	ga_iHealthPrice[client] = gcv_iHealthPrice.IntValue;
	ga_iDamagePrice[client] = gcv_iDamagePrice.IntValue;
	ga_iGravityPrice[client] = gcv_iGravityPrice.IntValue;
	ga_iSpeedPrice[client] = gcv_iSpeedPrice.IntValue;
	ga_iSizePrice[client] = gcv_iSizePrice.IntValue;
}

void LastRequest()
{
	if (g_bLR)
	{
		return;
	}
	
	g_bLR = true;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				if (ga_bHasGang[i])
				{
					PrintToChat(i, "%s %t", TAG, "GamePerksDisabled");
					if (GetClientHealth(i) > 100)
					{
						SetEntProp(i, Prop_Send, "m_iHealth", 100);
					}
					if (GetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue") != 1.0)
					{
						SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.0);
					}
					SetEntityGravity(i, 1.0);
				}
			}
		}
	}
}

int GetPlayerAliveCount(int team)
{
	int iAmmount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
		{
			iAmmount++;
		}
	}
	return iAmmount;
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}
