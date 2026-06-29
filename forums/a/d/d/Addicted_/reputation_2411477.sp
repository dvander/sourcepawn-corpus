/*
CHANGELOG

v1.0.0 -
	Initial Release
v1.0.1 -
	Fixed checking if can rep with sm_can_multiple_rep set to 0
	Chnaged auth method from AuthId_Steam2 to AuthId_Engine (Thanks xines)
v1.0.2 -
	Fixed some non-escaped strings for MySQL Queries
v1.0.3 -
	Minor syntax updates (Thanks xines)
v1.0.4 -
	New ConVars to allow easy editing of commands
*/

#pragma semicolon 1

#include <sourcemod>
#include <reputation>
#include <colors_csgo>

//#define CHAT_TAG "[{red}R{green}E{blue}P{default}] %T"

Handle db = null;

ConVar g_hDisplayRepCMDConvar;
ConVar g_hUpdateRepCMDConvar;
ConVar g_hAddRepCMDConvar;
ConVar g_hClearRepCMDConvar;
ConVar g_hMultipleRepsConvar;
ConVar g_hUpdateRepConvar;
ConVar g_hMinRepConvar;
ConVar g_hMaxRepConvar;
ConVar g_hChatPrefixConvar;
ConVar g_hConnectAnnounceConvar;
ConVar g_hReasonsConvar;

int reputation[MAXPLAYERS+1] = {0, ...};

bool canRep[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Reputation",
	author = "Addicted",
	version = "1.0.4",
	url = "tgnaddicted.com"
};

public void OnPluginStart()
{
	Connect();	

	g_hDisplayRepCMDConvar = CreateConVar("rep_display_rep_cmd", "sm_rep", "Command used to show a client's rep", _, _, _, _, _);
	g_hUpdateRepCMDConvar = CreateConVar("rep_update_rep_cmd", "sm_updaterep", "Command used to update a client's rep", _, _, _, _, _);
	g_hAddRepCMDConvar = CreateConVar("rep_add_rep_cmd", "sm_addrep", "Command used to add to a client's rep", _, _, _, _, _);
	g_hClearRepCMDConvar = CreateConVar("rep_clear_rep_cmd", "sm_clearrep", "Command used to clear a client's rep", _, _, _, _, _);
	g_hMultipleRepsConvar = CreateConVar("rep_can_multiple_rep", "0", "If enabled (1) then users are allowed to give multiple ratings to the same user", _, _, _, _, _);
	g_hUpdateRepConvar = CreateConVar("rep_can_update_rep", "1", "If enabled (1) then users are allowed to update previous ratings to a user (Only works with sm_can_multiple_rep set to 0)", _, _, _, _, _);
	g_hMinRepConvar = CreateConVar("rep_min_rep", "-10", "Lowest rating amount a player can give (Must be lower than sm_max_rep)", _, _, _, _, _);
	g_hMaxRepConvar = CreateConVar("rep_max_rep", "10", "Highest rating amount a player can give (Must be higher than sm_min_rep)", _, _, _, _, _);
	g_hChatPrefixConvar = CreateConVar("rep_chat_prefix", "1", "If enabled (1) then a chat prefix will be shown with rep amount (Will change method later)", _, _, _, _, _);
	g_hConnectAnnounceConvar = CreateConVar("rep_connect_announce", "1", "If enabled (1) then an announcement with rep amount will be shown on client connect", _, _, _, _, _);
	g_hReasonsConvar = CreateConVar("rep_rep_reasons", "1", "If enabled (1) then reasons can be used in ratings", _, _, _, _, _);
	AutoExecConfig();
	
	char showCMD[32], updateCMD[32], addCMD[32], clearCMD[32];
	
	GetConVarString(g_hDisplayRepCMDConvar, showCMD, sizeof(showCMD));
	GetConVarString(g_hUpdateRepCMDConvar, updateCMD, sizeof(updateCMD));
	GetConVarString(g_hAddRepCMDConvar, addCMD, sizeof(addCMD));
	GetConVarString(g_hClearRepCMDConvar, clearCMD, sizeof(clearCMD));
	
	RegConsoleCmd(showCMD, CMD_GetReputation, "Displays a client's reputation");
	RegConsoleCmd(updateCMD, CMD_UpdateReputation, "Updates a reputation to a client");
	RegConsoleCmd(addCMD, CMD_GiveReputation, "Adds reputation to a client");
	
	RegAdminCmd(clearCMD, CMD_ClearReputation, ADMFLAG_ROOT, "Clears a client's reputation");	
	
	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(HookPlayerChat, "say_team");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Reputation_GetRep", Native_GetRep);
	
	RegPluginLibrary("reputation");
	
	return APLRes_Success;
}

public int Native_GetRep(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);

	return reputation[client];
}

public void OnClientPostAdminCheck(int client)
{
	if (db == INVALID_HANDLE)
		SetFailState("Failed to connect, SQL Error");

	if(!IsValidClient(client))
		return;
		
	CountRep(client);

	char sQuery[1256];

	char client_steamID[64];
	if (!GetClientAuthId(client, AuthId_Engine, client_steamID, sizeof(client_steamID)))
		return;

	if (!GetConVarBool(g_hMultipleRepsConvar))
	{
		for (int i; i < MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;
			
			char i_SteamID[64];
			if (!GetClientAuthId(i, AuthId_Engine, i_SteamID, sizeof(i_SteamID)))
				continue;

			Handle dp = CreateDataPack();
			WritePackCell(dp, client);
			WritePackCell(dp, i);
			
			canRep[client][i] = true;

			Format(sQuery, sizeof(sQuery), "SELECT COUNT(*) FROM `reputation` WHERE `giver_steamid` = \"%s\" AND `recipient_steamid` = \"%s\"", client_steamID ,i_SteamID);
			SQL_TQuery(db, SQL_MultipleRepCheck, sQuery, dp);
			
			canRep[i][client] = true;
			
			Format(sQuery, sizeof(sQuery), "SELECT COUNT(*) FROM `reputation` WHERE `giver_steamid` = \"%s\" AND `recipient_steamid` = \"%s\"", i_SteamID, client_steamID);
			SQL_TQuery(db, SQL_MultipleRepCheck, sQuery, dp);
		}
	}

	if (GetConVarBool(g_hConnectAnnounceConvar))
		CreateTimer(3.0, CreateMessage, client);
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client))
	{
		reputation[client] = 0;
		
		for (int i; i < MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;

			canRep[client][i] = true;
			canRep[i][client] = true;
		}
	}		
}

public Action HookPlayerChat(int client, const char[] command, int args)
{
	if (!GetConVarBool(g_hChatPrefixConvar))
		return Plugin_Continue;
	
	char szText[256];
	GetCmdArg(1, szText, sizeof(szText));
	
	if(szText[0] == '/' || szText[0] == '@' || StrEqual(szText, ""))
		return Plugin_Handled;
	
	Format(szText, sizeof(szText), "[{purple}%i {red}R{green}E{blue}P{default}] {teamcolor}%N :{default} %s", reputation[client], client, szText);
	
	if(IsPlayerAlive(client))
	{
		for (int i; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;
				
			CPrintToChatEx(i, client, szText);
		}
	}
	else
	{
		for (int i; i <= MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;
				
			if (IsPlayerAlive(i))
				continue;

			CPrintToChatEx(i, client, "{teamcolor}*DEAD*{default} %s", szText);
		}
	}
	
	return Plugin_Handled;
}

/* DATABASE STUFF */
public void Connect()
{
	if (SQL_CheckConfig("reputation"))
		SQL_TConnect(OnDatabaseConnect, "reputation");
	else
		SetFailState("Can't find 'reputation' entry in sourcemod/configs/databases.cfg!");
}

public void OnDatabaseConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		PrintToServer("Failed to connect: %s", error);
		SetFailState("Failed to connect, SQL Error:  %s", error);
		return;
	}

	db = hndl;
	SQL_CreateTables();
}

public void SQL_CreateTables()
{
	int len = 0;
	char query[1256];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `reputation` (");
	len += Format(query[len], sizeof(query)-len, " `timestamp` INT(11) NOT NULL DEFAULT '0' ,");
	len += Format(query[len], sizeof(query)-len, " `giver_steamid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `giver_name` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `recipient_steamid` VARCHAR(22) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `recipient_name` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL ,");
	len += Format(query[len], sizeof(query)-len, " `amount` INT(12) NOT NULL DEFAULT '0' ,");
	len += Format(query[len], sizeof(query)-len, " `reason` VARCHAR(120) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL, ");
	len += Format(query[len], sizeof(query)-len, " UNIQUE (`timestamp`) ) ENGINE = MyISAM;");

	for (int i; i < MaxClients; i++)
	{
		if (!IsValidClient(i))
			continue;
			
		OnClientPostAdminCheck(i);
	}

	SQL_TQuery(db, SQL_ErrorCheckCallback, query);
}

public void SQL_ErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (!StrEqual("", error))
		LogError("SQL Error: %s", error);
}

public void SQL_GetReputationCount(Handle owner, Handle hndl, const char[] error, any client)
{
	if (!StrEqual("", error))
		LogError("SQL Error: %s", error);
	else
	{
		if (!IsValidClient(client))
			return;
		
		reputation[client] = 0;
		
		SQL_FetchRow(hndl);
		
		for (int i; i < SQL_GetRowCount(hndl); i++)
		{
			reputation[client] +=  SQL_FetchInt(hndl, 0);
			SQL_FetchRow(hndl);
		}
	}
}

public void SQL_MultipleRepCheck(Handle owner, Handle hndl, const char[] error, any dp)
{
	if (!StrEqual("", error))
		LogError("SQL Error: %s", error);
	else
	{
		ResetPack(dp);

		int client = ReadPackCell(dp);
		int target = ReadPackCell(dp);

		if (!IsValidClient(client) || !IsValidClient(target))
			return;

		SQL_FetchRow(hndl);

		if (SQL_FetchInt(hndl, 0) != 0)
			canRep[client][target] = false;
	}
}

/* COMMANDS */
public Action CMD_GetReputation(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (args < 1)
	{
		CPrintToChat(client, "[{red}R{green}E{blue}P{default}] You have {purple}%i{default} reputation", reputation[client]);
		return Plugin_Handled;
	}
	
	char arg1[120];
	GetCmdArg(1, arg1, sizeof(arg1));

	int target = FindTarget(client, arg1, true, false);

	if (IsValidClient(target))
		CPrintToChat(client, "[{red}R{green}E{blue}P{default}] {green}%N{default} has {purple}%i{default} reputation", target, reputation[target]);

	return Plugin_Handled;		
}

public Action CMD_UpdateReputation(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
		
	if (!GetConVarBool(g_hUpdateRepConvar) || GetConVarBool(g_hMultipleRepsConvar))
	{
		CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] This server has disabled this command");
		return Plugin_Handled;	
	}

	if (args < 2)
	{
		if (GetConVarBool(g_hReasonsConvar))
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Usage: sm_updaterep <client> [amount] <reason>");
		else
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Usage: sm_updaterep <client> [amount]");
			
		return Plugin_Handled;
	}
	
	char arg1[120], arg2[12], arg3[120];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if (GetConVarBool(g_hReasonsConvar))
	{	
		if (args > 2)
		{
			for (int i = 3; i <= args; i++)
			{
				char temp[32];
				GetCmdArg(i, temp, sizeof(temp));
				Format(arg3, sizeof(arg3), "%s %s", arg3, temp);
			}
		}
		else
			Format(arg3, sizeof(arg3), "No Reason Given");
	}
	
	int target = FindTarget(client, arg1, true, false);

	if (IsValidClient(target))
	{
		if (client == target)
		{
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] You cannot give yourself reputation");
			return Plugin_Handled;
		}
		
		int amount = StringToInt(arg2);
		
		if (amount > GetConVarInt(g_hMaxRepConvar) || amount < GetConVarInt(g_hMinRepConvar))
		{
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Invalid reputation amount (Must be between %i and %i)", GetConVarInt(g_hMinRepConvar), GetConVarInt(g_hMaxRepConvar));
			return Plugin_Handled;		
		}
		
		if (UpdateRep(client, target, amount, arg3))
		{
			if (GetConVarBool(g_hReasonsConvar))
				CPrintToChatAll("[{red}R{green}E{blue}P{default}] {green}%N{default} has updated their reputation to {green}%N{default}, it is now {purple}%i{default} (Reason: %s)", client, target, amount, arg3);
			else
				CPrintToChatAll("[{red}R{green}E{blue}P{default}] {green}%N{default} has updated their reputation to {green}%N{default}, it is now {purple}%i{default}", client, target, amount);
		}
	}

	return Plugin_Handled;		
}

public Action CMD_GiveReputation(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (args < 2)
	{
		if (GetConVarBool(g_hReasonsConvar))
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Usage: sm_addrep <client> [amount] <reason>");
		else
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Usage: sm_addrep <client> [amount]");
		
		return Plugin_Handled;
	}

	char arg1[120], arg2[12], arg3[120];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if (GetConVarBool(g_hReasonsConvar))
	{	
		if (args > 2)
		{
			for (int i = 3; i <= args; i++)
			{
				char temp[32];
				GetCmdArg(i, temp, sizeof(temp));
				Format(arg3, sizeof(arg3), "%s %s", arg3, temp);
			}
		}
		else
			Format(arg3, sizeof(arg3), "No Reason Given");
	}
	
	int target = FindTarget(client, arg1, true, false);
	
	if (IsValidClient(target))
	{
		if (client == target)
		{
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] You cannot give yourself reputation");
			return Plugin_Handled;
		}
		
		int amount = StringToInt(arg2);
		
		if (amount > GetConVarInt(g_hMaxRepConvar) || amount < GetConVarInt(g_hMinRepConvar))
		{
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Invalid reputation amount (Must be between %i and %i)", GetConVarInt(g_hMinRepConvar), GetConVarInt(g_hMaxRepConvar));
			return Plugin_Handled;		
		}

		if (!GetConVarBool(g_hMultipleRepsConvar))
		{
			if (!canRep[client][target])
			{
				CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] You have already given reputation to this user");

				if (GetConVarBool(g_hUpdateRepConvar))
					CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] You can use !updaterep to change your previous rating to {green}%N{default}", target);

				return Plugin_Handled;
			}
		}

		if (AddReputation(client, target, amount, arg3))
		{
			if (GetConVarBool(g_hReasonsConvar))
				CPrintToChatAll("[{red}R{green}E{blue}P{default}] {green}%N{default} has given {green}%N{default} {purple}%i{default} reputation (Reason: %s) ({green}%N's{default} reputation is now {purple}%i{default})", client, target, amount, arg3, target, reputation[target]);
			else
				CPrintToChatAll("[{red}R{green}E{blue}P{default}] {green}%N{default} has given {green}%N{default} {purple}%i{default} reputation ({green}%N's{default} reputation is now {purple}%i{default})", client, target, amount, target, reputation[target]);
		}
	}

	return Plugin_Handled;
}

public Action CMD_ClearReputation(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (args < 1)
	{
		CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Usage: sm_clearrep <client>");
		return Plugin_Handled;
	}
	
	char arg1[120];
	GetCmdArg(1, arg1, sizeof(arg1));

	int target = FindTarget(client, arg1, true, false);

	if (IsValidClient(target))
	{
		char sQuery[1256];
		
		char target_steamID[64];
	
		if (!GetClientAuthId(target, AuthId_Engine, target_steamID, sizeof(target_steamID)))
		{
			CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Error Clearing Rep of %N", target);
			return Plugin_Handled;
		}
		
		Format(sQuery, sizeof(sQuery), "DELETE FROM `reputation` WHERE `recipient_steamid` = \"%s\"", target_steamID);
		SQL_TQuery(db, SQL_ErrorCheckCallback, sQuery);		
		
		CPrintToChatAll("[{red}R{green}E{blue}P{default}] {green}%N{default} has cleared {green}%N's{default} reputation", client, target);
		
		for (int i; i < MaxClients; i++)
		{
			if (!IsValidClient(i))
				continue;
				
			canRep[i][target] = true;
		}
		
		CountRep(target);
	}
	else
	{
		CReplyToCommand(client, "[{red}R{green}E{blue}P{default}] Error Clearing Rep of %N", target);
		return Plugin_Handled;		
	}

	return Plugin_Handled;
}

/* MAIN FUNCTIONS */
public bool AddReputation(int client, int target, int amount, char[] reason)
{
	if(!IsValidClient(client) || !IsValidClient(target))
		return false;
		
	char sQuery[1256];
	
	char client_steamID[64], target_steamID[64];
	if (!GetClientAuthId(client, AuthId_Engine, client_steamID, sizeof(client_steamID)))
		return false;

	if (!GetClientAuthId(target, AuthId_Engine, target_steamID, sizeof(target_steamID)))
		return false;
		
	char escapedReason[120];
	if (!SQL_EscapeString(db, reason, escapedReason, sizeof(escapedReason)))
		return false;
		
	char clientName[MAX_NAME_LENGTH], escapedClientName[MAX_NAME_LENGTH], targetName[MAX_NAME_LENGTH], escapedTargetName[MAX_NAME_LENGTH];
	
	if (!GetClientName(client, clientName, sizeof(clientName)))
		return false;
		
	if (!GetClientName(client, targetName, sizeof(targetName)))
		return false;
	
	if (!SQL_EscapeString(db, clientName, escapedClientName, sizeof(escapedClientName)))
		return false;

	if (!SQL_EscapeString(db, targetName, escapedTargetName, sizeof(escapedTargetName)))
		return false;
	
	Format(sQuery, sizeof(sQuery), "INSERT INTO `reputation` (`timestamp`, `giver_steamid`, `giver_name`, `recipient_steamid`, `recipient_name`, `amount`, `reason`) VALUES ('%i', '%s', '%N', '%s', '%N', '%i', '%s')", GetTime(), client_steamID, escapedClientName, target_steamID, escapedTargetName, amount, escapedReason);
	SQL_TQuery(db, SQL_ErrorCheckCallback, sQuery);
	
	reputation[target]+= amount;
	canRep[client][target] = false;
	
	return true;
}

public bool UpdateRep(int client, int target, int amount, char[] reason)
{
	if(!IsValidClient(client) || !IsValidClient(target))
		return false;
		
	char sQuery[1256];
	
	char client_steamID[64], target_steamID[64];
	if (!GetClientAuthId(client, AuthId_Engine, client_steamID, sizeof(client_steamID)))
		return false;

	if (!GetClientAuthId(target, AuthId_Engine, target_steamID, sizeof(target_steamID)))
		return false;

	char escapedReason[120];
	if (!SQL_EscapeString(db, reason, escapedReason, sizeof(escapedReason)))
		return false;

	Format(sQuery, sizeof(sQuery), "UPDATE `reputation` SET `amount`= %i, `reason`=\"%s\" WHERE `giver_steamid` = \"%s\" AND `recipient_steamid` = \"%s\"", amount, escapedReason, client_steamID, target_steamID);
	SQL_TQuery(db, SQL_ErrorCheckCallback, sQuery);
	
	canRep[client][target] = false;
	
	CountRep(target);

	return true;
}

public void CountRep(int client)
{
	char sQuery[1256];
	
	char client_steamID[64];
	if (!GetClientAuthId(client, AuthId_Engine, client_steamID, sizeof(client_steamID)))
		return;
	
	Format(sQuery, sizeof(sQuery), "SELECT `amount` FROM `reputation` WHERE `recipient_steamid` = \"%s\"", client_steamID);
	SQL_TQuery(db, SQL_GetReputationCount, sQuery, client);		
}

/* TIMERS */
public Action CreateMessage(Handle timer, int client)
{
	CPrintToChatAll("%N [{purple}%i {red}R{green}E{blue}P{default}] {green}joined{default}", client, reputation[client]);	
}

/* STOCK FUNCTIONS */
stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (IsFakeClient(client))
		return false;

	return true;
}