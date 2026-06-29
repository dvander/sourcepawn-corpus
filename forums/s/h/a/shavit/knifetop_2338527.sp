/*
 * Knifetop
 * by: shavit
 *
 * This file is part of Knifetop.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
*/

// code mostly taken from my previous plugin, the timer
// https://github.com/Shavitush/bhoptimer

#include <sourcemod>
#include <knifetop>

#undef REQUIRE_PLUGIN
#include <lastrequest>

#pragma semicolon 1
#pragma dynamic 131072
#pragma newdecls required

bool gB_Hosties = false;

Database gH_SQL = null;

int gI_KnifeKills[MAXPLAYERS+1] =  {0, ...};

bool gB_Late = false;

Handle gH_OnKnifeKill = null;

ConVar gCV_Enabled = null;
ConVar gCV_Team = null;
ConVar gCV_HostiesLR = null;
ConVar gCV_TopLimit = null;

public Plugin myinfo = 
{
	name = "Knifetop",
	author = "shavit",
	description = "Do you like stabbing? Compete with other players!",
	version = KNIFETOP_VERSION,
	url = "http://forums.alliedmods.net/member.php?u=163134"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Knifetop_GetKnifeKills", Native_GetKnifeKills);
	
	MarkNativeAsOptional("Knifetop_GetKnifeKills");
	
	RegPluginLibrary("knifetop");
	
	gB_Late = late;
	
	// hosties stuff
	MarkNativeAsOptional("IsClientInLastRequest");
	
	return APLRes_Success;
}

// forward - on knife kill, new amount
// cvar - team that it works on
// command ktop knifetop

public void OnPluginStart()
{
	EngineVersion evType = GetEngineVersion();
	
	if(evType != Engine_CSS && evType != Engine_CSGO)
	{
		SetFailState("This plugin was meant to be used in CS:S and CS:GO *only*.");
	}
	
	SQL_DBConnect();
	
	// int client
	// int new_amount
	gH_OnKnifeKill = CreateGlobalForward("Knifetop_OnKnifeKill", ET_Event, Param_Cell, Param_Cell);
	
	CreateConVar("knifetop_version", KNIFETOP_VERSION, "Knifetop's version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gCV_Enabled = CreateConVar("knifetop_enable", "1", "Is the plugin enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gCV_Team = CreateConVar("knifetop_team", "0", "Which teams should have knife kills counted?\n0 - Everyone\n2 - Terroists\n3 - Counter-Terrorists", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	gCV_HostiesLR = CreateConVar("knifetop_hosties_lr", "1", "In effect only if SM_Hosties 2 is installed on the server!\nIgnore knifetop_team if a knife kill was done between 2 players in a last request?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gCV_TopLimit = CreateConVar("knifetop_top_limit", "25", "Amount of people to display when using sm_knifetop.", FCVAR_PLUGIN, true, 1.0);
	
	AutoExecConfig();
	
	RegConsoleCmd("sm_knifetop", Command_Knifetop, "Opens a menu that shows the top25 stabbers!");
	RegConsoleCmd("sm_ktop", Command_Knifetop, "Opens a menu that shows the top25 stabbers!");
	
	HookEvent("player_death", Player_Death);
	
	gB_Hosties = LibraryExists("hosties");
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties"))
	{
		gB_Hosties = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "hosties"))
	{
		gB_Hosties = false;
	}
}

public void OnClientPutInServer(int client)
{
	gI_KnifeKills[client] = 0;
	
	if(!IsValidClient(client) || IsFakeClient(client) || gH_SQL == null)
	{
		return;
	}
	
	char sAuthID3[32];
	GetClientAuthId(client, AuthId_Steam3, sAuthID3, 32);

	char sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, MAX_NAME_LENGTH);
	
	int iLength = ((strlen(sName) * 2) + 1);
	char[] sEscapedName = new char[iLength]; // dynamic arrays! I love you, SourcePawn 1.7!
	SQL_EscapeString(gH_SQL, sName, sEscapedName, iLength);
	
	char sQuery[256];
	FormatEx(sQuery, 256, "INSERT INTO players (auth, name) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE name = '%s';", sAuthID3, sEscapedName, sEscapedName);

	SQL_TQuery(gH_SQL, SQL_InsertUser_Callback, sQuery, GetClientSerial(client), DBPrio_High);
}

public void SQL_InsertUser_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	int client = GetClientFromSerial(data);
	
	if(hndl == null)
	{
		if(!client)
		{
			LogError("Knifetop error! Failed to insert a disconnected player's data to the table. Reason: %s", error);
		}

		else
		{
			LogError("Knifetop error! Failed to insert \"%N\"'s data to the table. Reason: %s", client, error);
		}

		return;
	}
	
	if(!client)
	{
		return;
	}
	
	char sAuthID[32];
	GetClientAuthId(client, AuthId_Steam3, sAuthID, 32);
	
	char sQuery[256];
	FormatEx(sQuery, 256, "SELECT kills FROM players WHERE auth = '%s';", sAuthID);
	SQL_TQuery(gH_SQL, SQL_UpdateCache_Callback, sQuery, GetClientSerial(client), DBPrio_High);
}

public void SQL_UpdateCache_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null)
	{
		LogError("Knifetop (kill amount cache update) SQL query failed. Reason: %s", error);

		return;
	}

	int client = GetClientFromSerial(data);

	if(!client)
	{
		return;
	}

	while(SQL_FetchRow(hndl))
	{
		gI_KnifeKills[client] = SQL_FetchInt(hndl, 0);
	}
}

public void OnClientDisconnect(int client)
{
	gI_KnifeKills[client] = 0;
}

public int Native_GetKnifeKills(Handle handler, int numParams)
{
	int client = GetNativeCell(1);

	return gI_KnifeKills[client];
}

public void SQL_DBConnect()
{
	if(gH_SQL != null)
	{
		CloseHandle(gH_SQL);
	}

	if(SQL_CheckConfig("knifetop"))
	{
		char sError[255];

		if(!(gH_SQL = SQL_Connect("knifetop", true, sError, 255)))
		{
			SetFailState("Knifetop startup failed. Reason: %s", sError);
		}
		
		SQL_LockDatabase(gH_SQL);
		SQL_FastQuery(gH_SQL, "SET NAMES 'utf8';");
		SQL_UnlockDatabase(gH_SQL);
		
		SQL_TQuery(gH_SQL, SQL_CreateTable_Callback, "CREATE TABLE IF NOT EXISTS `players` (`auth` VARCHAR(32) NOT NULL, `name` VARCHAR(32) NOT NULL DEFAULT '< blank >', `kills` INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(`auth`));", 0, DBPrio_High);
	}

	else
	{
		SetFailState("Timer startup failed. Reason: %s", "\"knifetop\" is not a specified entry in databases.cfg.");
	}
}

public void SQL_CreateTable_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null)
	{
		LogError("Knifetop error! Data table creation failed. Reason: %s", error);

		return;
	}
	
	if(gB_Late)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			OnClientPutInServer(i);
		}
	}
}

public Action Command_Knifetop(int client, int args)
{
	if(!gCV_Enabled.BoolValue)
	{
		ReplyToCommand(client, "Knifetop is disabled.");
		
		return Plugin_Handled;
	}
	
	char sQuery[128];
	FormatEx(sQuery, 128, "SELECT name, kills, auth FROM players WHERE kills != 0 ORDER BY kills DESC LIMIT %d;", gCV_TopLimit.IntValue);
	
	SQL_TQuery(gH_SQL, SQL_Knifetop_Callback, sQuery, GetClientSerial(client));
	
	return Plugin_Handled;
}

public void SQL_Knifetop_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null)
	{
		LogError("Knifetop (select kills) SQL query failed. Reason: %s", error);

		return;
	}

	int client = GetClientFromSerial(data);

	if(!client)
	{
		return;
	}

	Menu menu = CreateMenu(MenuHandler_ShowSteamID3);
	
	char sTitle[32];
	FormatEx(sTitle, 32, "Top %d Stabber%s:", gCV_TopLimit.IntValue, gCV_TopLimit.IntValue > 1? "s":"");
	
	SetMenuTitle(menu, sTitle);

	int iCount = 0;

	while(SQL_FetchRow(hndl))
	{
		iCount++;

		// 0 - player name
		char sName[MAX_NAME_LENGTH];
		SQL_FetchString(hndl, 0, sName, MAX_NAME_LENGTH);

		// 1 - kills
		int iKills = SQL_FetchInt(hndl, 1);

		// 2 - steamid3
		char sAuth[32];
		SQL_FetchString(hndl, 2, sAuth, 32);

		char sDisplay[128];
		FormatEx(sDisplay, 128, "#%d - %s (%d stab%s)", iCount, sName, iKills, iKills > 1? "s":"");
		AddMenuItem(menu, sAuth, sDisplay);
	}

	if(!iCount)
	{
		AddMenuItem(menu, "-1", "No results.");
	}

	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
}

public int MenuHandler_ShowSteamID3(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, 32);
		
		PrintToConsole(param1, "SteamID3: %s", info);
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public void Player_Death(Handle event, const char[] name, bool dB)
{
	if(!gCV_Enabled.BoolValue)
	{
		return;
	}
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!IsValidClient(client) || !IsValidClient(attacker))
	{
		return;
	}
	
	if((gB_Hosties && gCV_HostiesLR.BoolValue && IsClientInLastRequest(attacker) && IsClientInLastRequest(client)) || !gCV_Team.IntValue || gCV_Team.IntValue == GetClientTeam(attacker))
	{
		char sWeaponName[64];
		GetEventString(event, "weapon", sWeaponName, 64);
		
		if(StrContains(sWeaponName, "knife") != -1 || StrContains(sWeaponName, "bayonet") != -1)
		{
			gI_KnifeKills[attacker]++;
			
			Call_StartForward(gH_OnKnifeKill);
			Call_PushCell(attacker);
			Call_PushCell(gI_KnifeKills[attacker]);
			Call_Finish();
			
			DB_UpdateKills(attacker, gI_KnifeKills[attacker]);
		}
	}
}

public void DB_UpdateKills(int client, int kills)
{
	char sAuthID[32];
	GetClientAuthId(client, AuthId_Steam3, sAuthID, 32);
	
	char sQuery[256];
	FormatEx(sQuery, 256, "UPDATE players SET kills = %d WHERE auth = '%s';", kills, sAuthID);
	SQL_TQuery(gH_SQL, SQL_UpdateKills_Callback, sQuery);
}

public void SQL_UpdateKills_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl == null)
	{
		LogError("Knifetop (update kills) SQL query failed. Reason: %s", error);

		return;
	}
}
