#include <sourcemod>
#include <sdktools>
#include <colors>
#include <autoexecconfig>
#include <SteamWorks>
#include <hexstocks>

#define TAG							"[GIVEAWAY]"
// Database queries
#define QUERY_INIT_DB_GIVEAWAYS		"CREATE TABLE IF NOT EXISTS `giveaways` (`giveawayID` int NOT NULL AUTO_INCREMENT, `start` date NOT NULL, `end` date NOT NULL, `type` tinyint NOT NULL, `winner` varchar(50) NOT NULL, `item` varchar(50) NOT NULL, `description` varchar(200) NOT NULL, PRIMARY KEY (`giveawayID`))"
#define QUERY_INIT_DB_ENTRIES		"CREATE TABLE IF NOT EXISTS `entries` (`entriesID` int NOT NULL AUTO_INCREMENT, `steamID` varchar(50) NOT NULL, `giveaway` int NOT NULL, PRIMARY KEY (`entriesID`))"
#define QUERY_CREATE_GIVEAWAY		"INSERT INTO `giveaways`(`start`, `end`, `type`, `winner`, `item`, `description`) VALUES(CURDATE(), '%s', %d, 0, '%s', '%s')"
#define QUERY_SELECT_GIVEAWAY		"SELECT `giveawayID`, `item`, `description`, `type` FROM `giveaways` WHERE `start` <= CURDATE() AND `end` > CURDATE()"
#define QUERY_SELECT_ENDED_GIVEAWAY	"SELECT `giveawayID`, `item` FROM `giveaways` WHERE `end` <= CURDATE() AND `winner` = 0"
#define QUERY_ADD_ENTRY				"INSERT INTO `entries`(`steamID`, `giveaway`) VALUES('%s', %d)"
#define QUERY_GET_ENTRY				"SELECT `entriesID` FROM `entries` WHERE `steamID` = '%s' AND `giveaway` = %d"
#define QUERY_GET_RANDOM_WINNER		"SELECT `steamID` FROM `entries` WHERE `giveaway` = %d ORDER BY RAND() LIMIT 1"
#define QUERY_GIVEAWAY_WINNER		"UPDATE `giveaways` SET `winner` = '%s' WHERE `giveawayID` = %d"
#define QUERY_GET_LAST_WINNER		"SELECT `winner`, `item` FROM `giveaways` WHERE `giveawayID` = %d"
#define QUERY_SELECT_GIVEAWAY_INFO	"SELECT `end`, (SELECT COUNT(*) FROM `entries` WHERE `giveaway` = %d) AS `entries`, `type` FROM `giveaways` WHERE `giveawayID` = %d"

Handle giveawayDB;
int giveaway;
int gType;
char skin[50];
char gDescription[200];
char gBuffer[255];
// ConVar bool
ConVar cv_bEnableMessage;
// ConVar int
ConVar cv_iSteamGroup;
// ConVar String
ConVar cv_sGiveawayMessage;
ConVar cv_sSteamGroupName;
ConVar cv_sSteamGroupLink;

public Plugin myinfo =
{
	name = "Giveaways manager",
	description = "Manage all giveaways for skins and add entries. There is only 1 possible running giveaway at the same moment.",
	author = "ShawnCZek",
	version = "1.0",
	url = "http://steamcommunity.com/id/shawnczek"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_giveaway_create", CMD_GiveawayCreate, ADMFLAG_ROOT, "sm_giveaway_create - Creates database tables");
	RegAdminCmd("sm_giveaway_add", CMD_GiveawayAdd, ADMFLAG_ROOT, "sm_giveaway_add <deadline> <type> <skin> <description> - Creates a new giveaway");
	RegAdminCmd("sm_giveaway_draw", CMD_GiveawayDraw, ADMFLAG_ROOT, "sm_giveaway_draw - Draws a winner of ended giveaways");
	RegAdminCmd("sm_giveaway_winner", CMD_GiveawayWinner, ADMFLAG_ROOT, "sm_giveaway_winner <giveawayID> - Gets the winner of a giveaway");
	
	RegConsoleCmd("sm_giveaway", CMD_Giveaway, "sm_giveaway - Writes information about running giveaway or the ended giveaway");
	RegConsoleCmd("sm_giveaway_enter", CMD_GiveawayEnter, "sm_giveaway_enter - Enters in the running giveaway");
	
	AutoExecConfig(true, "giveaway");
	cv_bEnableMessage = AutoExecConfig_CreateConVar("sm_giveaway_enablemessage", "1", "Enable auto message on every round start", 0, true, 0.0, true, 1.0);
	cv_sGiveawayMessage = AutoExecConfig_CreateConVar("sm_giveaway_automessage", "A giveaway is running! Use command {darkred}!giveaway {default}for more information", "Content of auto message (possible to use colors)");
	cv_iSteamGroup = AutoExecConfig_CreateConVar("sm_giveaway_steamgroup", "", "ID of Steam group where the client should be member");
	cv_sSteamGroupName = AutoExecConfig_CreateConVar("sm_giveaway_steamgroupname", "", "Name of the Steam group");
	cv_sSteamGroupLink = AutoExecConfig_CreateConVar("sm_giveaway_steamgrouplink", "", "Link to the Steam group");
	
	HookEvent("round_start", Event_RoundStart);
	
	DataBaseConnect();
}

/**************************************************************************************************************************
														EVENTS
**************************************************************************************************************************/

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (cv_bEnableMessage.BoolValue == true && giveaway != 0)
	{
		char sMessage[255];
		cv_sGiveawayMessage.GetString(sMessage, sizeof(sMessage));
		CPrintToChatAll("%s %s", TAG, sMessage);
	}
}

// Gets ID of the giveaway or inform about no giveaway
public void OnMapStart()
{
	GetGiveawayInfo();
}

/**************************************************************************************************************************
													ADMIN COMMANDS
**************************************************************************************************************************/

public Action CMD_GiveawayCreate(int client, int args)
{
	if (SQL_FastQuery(giveawayDB, QUERY_INIT_DB_GIVEAWAYS))
	{
		SQL_FastQuery(giveawayDB, QUERY_INIT_DB_ENTRIES);
		ReplyToCommand(client, "%s Tables were successfully created", TAG);
	}
	else
	{
		SQLError(giveawayDB, "creating database tables");
	}
	
	return Plugin_Handled;
}

public Action CMD_GiveawayAdd(int client, int args)
{
	if (args < 4)
	{
		ReplyToCommand(client, "%s Usage: sm_giveaway_add <deadline> <type> <skin> <description>", TAG);
		return Plugin_Handled;
	}
	// If there isn't a running giveaway
	if (giveaway != 0)
	{
		ReplyToCommand(client, "%s There is already a running giveaway", TAG);
		return Plugin_Handled;
	}
	
	char deadline[15];
	char argGroup[3];
	GetCmdArg(1, deadline, sizeof(deadline));
	GetCmdArg(2, argGroup, sizeof(argGroup));
	GetCmdArg(3, skin, sizeof(skin));
	GetCmdArg(4, gDescription, sizeof(gDescription));
	gType = StringToInt(argGroup);
	
	Format(gBuffer, sizeof(gBuffer), QUERY_CREATE_GIVEAWAY, deadline, gType, skin, gDescription);
	if (!SQL_FastQuery(giveawayDB, gBuffer))
	{
		SQLError(giveawayDB, "adding a giveaway");
	}
	else
	{
		ReplyToCommand(client, "%s The giveaway was successfully added", TAG);
		GetGiveawayInfo();
	}
	
	return Plugin_Handled;
}

public Action CMD_GiveawayDraw(int client, int args)
{
	if (giveaway != 0)
	{
		ReplyToCommand(client, "%s You can't draw a running giveaway", TAG);
	}
	else
	{
		DBResultSet giveawayQuery = SQL_Query(giveawayDB, QUERY_SELECT_ENDED_GIVEAWAY);
		if (giveawayQuery == null)
		{
			SQLError(giveawayDB, "getting an ended giveaway");
		}
		else
		{
			if (giveawayQuery.RowCount == 0)
			{
				CReplyToCommand(client, "%s All ended giveaways have a winner. For get the winner use command {darkred}!giveaway_winner{default}", TAG);
			}
			else
			{
				while (SQL_FetchRow(giveawayQuery))
				{
					char endedGiveawaySkin[50];
					int endedGiveaway = SQL_FetchInt(giveawayQuery, 0);
					SQL_FetchString(giveawayQuery, 1, endedGiveawaySkin, sizeof(endedGiveawaySkin));
					
					Format(gBuffer, sizeof(gBuffer), QUERY_GET_RANDOM_WINNER, endedGiveaway);
					DBResultSet queryWinner = SQL_Query(giveawayDB, gBuffer);
					if (queryWinner == null)
					{
						SQLError(giveawayDB, "getting a random winner");
					}
					else
					{
						while (SQL_FetchRow(queryWinner))
						{
							char endedGiveawayWinner[50];
							SQL_FetchString(queryWinner, 0, endedGiveawayWinner, sizeof(endedGiveawayWinner));
							Format(gBuffer, sizeof(gBuffer), QUERY_GIVEAWAY_WINNER, endedGiveawayWinner, endedGiveaway);
							if (SQL_FastQuery(giveawayDB, gBuffer))
							{
								CReplyToCommand(client, "%s Winner of the giveaway for {green}%s {default}is {red}%s{default}", TAG, endedGiveawaySkin, endedGiveawayWinner);
								CPrintToChatAll("%s Winner of the giveaway for {green}%s {default}is {red}%s{default}", TAG, endedGiveawaySkin, endedGiveawayWinner);
							}
							else
							{
								SQLError(giveawayDB, "setting a winner");
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action CMD_GiveawayWinner(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%s Usage: sm_giveaway_winner <giveawayID>", TAG);
	}
	else
	{
		char argGiveaway[15];
		GetCmdArg(1, argGiveaway, sizeof(argGiveaway));
		int endedGiveaway = StringToInt(argGiveaway);
		Format(gBuffer, sizeof(gBuffer), QUERY_GET_LAST_WINNER, endedGiveaway);
		DBResultSet giveawayQuery = SQL_Query(giveawayDB, gBuffer);
		if (giveawayQuery == null)
		{
			SQLError(giveawayDB, "getting a winner of the giveaway");
		}
		else
		{
			if (giveawayQuery.RowCount == 0)
			{
				ReplyToCommand(client, "%s There is no giveaway with ID %d", TAG, endedGiveaway);
			}
			else
			{
				while (SQL_FetchRow(giveawayQuery))
				{
					char winner[50];
					SQL_FetchString(giveawayQuery, 0, winner, sizeof(winner));
					char item[50];
					SQL_FetchString(giveawayQuery, 1, item, sizeof(item));
					CReplyToCommand(client, "%s Winner of the giveaway for {green}%s {default}is {red}%s{default}", TAG, item, winner);
					
					Format(gBuffer, sizeof(gBuffer), QUERY_SELECT_GIVEAWAY_INFO, endedGiveaway, endedGiveaway);
					DBResultSet queryInfo = SQL_Query(giveawayDB, gBuffer);
					if (queryInfo == null)
					{
						SQLError(giveawayDB, "getting additional info");
					}
					else
					{
						while (SQL_FetchRow(queryInfo))
						{
							char date[15];
							SQL_FetchString(queryInfo, 0, date, sizeof(date));
							int entries = SQL_FetchInt(queryInfo, 1);
							int type = SQL_FetchInt(queryInfo, 2);
							CReplyToCommand(client, "%s Entries: {red}%d{default}", TAG, entries);
							CReplyToCommand(client, "%s Ended: {red}%s{default}", TAG, date);
							CReplyToCommand(client, "%s Type: {red}%d{default}", TAG, type);
						}
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

/**************************************************************************************************************************
														COMMANDS
**************************************************************************************************************************/

public Action CMD_Giveaway(int client, int args)
{
	if (giveaway == 0)
	{
		ReplyToCommand(client, "%s There is no running giveaway", TAG);
	}
	else
	{
		Format(gBuffer, sizeof(gBuffer), QUERY_SELECT_GIVEAWAY_INFO, giveaway, giveaway);
		DBResultSet giveawayQuery = SQL_Query(giveawayDB, gBuffer);
		if (giveawayQuery == null)
		{
			SQLError(giveawayDB, "getting additional info");
		}
		else
		{
			while (SQL_FetchRow(giveawayQuery))
			{
				char date[15];
				SQL_FetchString(giveawayQuery, 0, date, sizeof(date));
				int entries = SQL_FetchInt(giveawayQuery, 1);
				CReplyToCommand(client, "%s We are hosting a giveaway for {green}%s{default}. For enter use command {darkred}!giveaway_enter{default}", TAG, skin);
				CReplyToCommand(client, "%s {lightgreen}%s{default}", TAG, gDescription);
				CReplyToCommand(client, "%s All entries: {red}%d{default}", TAG, entries);
				CReplyToCommand(client, "%s Ends: {red}%s{default}", TAG, date);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action CMD_GiveawayEnter(int client, int args)
{
	if (giveaway == 0)
	{
		ReplyToCommand(client, "%s There is no running giveaway", TAG);
	}
	else
	{
		char clientID[50];
		GetClientAuthId(client, AuthId_Steam2, clientID, sizeof(clientID));
		Format(gBuffer, sizeof(gBuffer), QUERY_GET_ENTRY, clientID, giveaway);
		DBResultSet giveawayQuery = SQL_Query(giveawayDB, gBuffer);
		if (giveawayQuery == null)
		{
			SQL_GetError(giveawayDB, gBuffer, sizeof(gBuffer));
			PrintToServer("%s Error while getting an entry from client \"%N\": %s", TAG, client, gBuffer);
		}
		else
		{
			if (giveawayQuery.RowCount == 0)
			{
				if ((gType == 2 && CheckAdminFlag(client, "a")) || (gType == 1 && SteamWorks_GetUserGroupStatus(client, cv_iSteamGroup.IntValue)) || gType == 0)
				{
					Format(gBuffer, sizeof(gBuffer), QUERY_ADD_ENTRY, clientID, giveaway);
					if (SQL_FastQuery(giveawayDB, gBuffer))
					{
						CReplyToCommand(client, "%s You successfully entered in a giveaway for {green}%s{default}. Good luck!", TAG, skin);
					}
					else
					{
						SQLError(giveawayDB, "adding an entry");
					}
				}
				else if (gType == 2)
				{
					CReplyToCommand(client, "%s For entering you must {red}be VIP{default}. To buy VIP use command {darkred}!vip{default}", TAG);
				}
				else
				{
					char sName[255];
					cv_sSteamGroupName.GetString(sName, sizeof(sName));
					char sLink[255];
					cv_sSteamGroupLink.GetString(sLink, sizeof(sLink));
					CReplyToCommand(client, "%s For entering you must be member of Steam group {red}%s{default}", TAG, sName);
					CReplyToCommand(client, "Link: {lightgreen}%s{default}", sLink);
				}
			}
			else
			{
				CReplyToCommand(client, "%s You are already in a giveaway for {green}%s{default}", TAG, skin);
			}
		}
	}
	
	return Plugin_Handled;
}

/**************************************************************************************************************************
														STOCKS
**************************************************************************************************************************/

stock void SQLError(Handle handle, char[] message)
{
	SQL_GetError(handle, gBuffer, sizeof(gBuffer));
	PrintToServer("%s Error while %s: %s", TAG, message, gBuffer);
}

stock void GetGiveawayInfo()
{
	DBResultSet giveawayQuery = SQL_Query(giveawayDB, QUERY_SELECT_GIVEAWAY);
	if (giveawayQuery == null)
	{
		SQLError(giveawayDB, "getting a giveaway");
	}
	else
	{
		if (giveawayQuery.RowCount == 0)
		{
			PrintToServer("%s There is no running giveaway or the giveaway has ended. If the giveaway has ended, you should choose the winner", TAG);
		}
		else
		{
			while (SQL_FetchRow(giveawayQuery))
			{
				giveaway = SQL_FetchInt(giveawayQuery, 0);
				SQL_FetchString(giveawayQuery, 1, skin, sizeof(skin));
				SQL_FetchString(giveawayQuery, 2, gDescription, sizeof(gDescription));
				gType = SQL_FetchInt(giveawayQuery, 3);
			}
		}
	}
}

void DataBaseConnect() 
{
	char error[255];
	giveawayDB = SQL_Connect("giveaway", false, error, sizeof(error));
	 
	if (giveawayDB == INVALID_HANDLE) {
		PrintToServer("%s Could not connect: %s", TAG, error);
	} else {
		PrintToServer("%s Connection successful", TAG);
	}
	SQL_FastQuery(giveawayDB, "SET NAMES \"UTF8\"");  
}