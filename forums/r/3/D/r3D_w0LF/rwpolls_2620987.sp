#include <sourcemod>

#define MAX_POLLS 10
#define MAX_POLL_OPTIONS 10

new String:g_pollQuestion[MAX_POLLS][255];
//Guess D stands for Display in this case, couldn't find sth better
char g_pollOptionsDName[MAX_POLLS][MAX_POLL_OPTIONS][255];
char g_pollOptionsName[MAX_POLLS][MAX_POLL_OPTIONS][255];
int g_pollCurrent[MAXPLAYERS+1];

//These are for each vote options
int g_pollOptionsStart[MAX_POLLS];
int g_pollOptionsRetry[MAX_POLLS];


new String:g_configFile[PLATFORM_MAX_PATH];
new bool:g_isPollRunning[MAXPLAYERS+1];
char g_hasPlayerVoted[MAXPLAYERS+1][MAX_POLLS][255];
int g_feedbackTime[MAXPLAYERS+1];

//bool g_bFailed[MAXPLAYERS+1]; //No real function yet, was meant to be a failsafe for database errors

Handle hDisplayPollTimer[MAXPLAYERS+1];
Handle cvar_database;
Handle cvar_feedbackTime;
Handle cvar_feedbackEnable;
Handle g_hPollsDb = INVALID_HANDLE;


public Plugin myinfo =
{
	name = "RW Polls",
	author = "Red Wolf aka r3dw0lf",
	description = "A poll/survey plugin to get feedback from your players.",
	version = "1.0",
	url = "https://steamcommunity.com/id/klajdi369/"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_feedback", sendFeedback);
	BuildPath(Path_SM, g_configFile, sizeof(g_configFile), "configs/rwpolls.cfg");
	RegConsoleCmd("sm_showpolls", showPolls, "Prints a list of polls/votes in the database", ADMFLAG_ROOT);
	RegConsoleCmd("sm_getpolldata", getPollData, "Prints results of a given poll. Use \"sm_showpolls\" to get a poll ID", ADMFLAG_ROOT);
	RegConsoleCmd("sm_getfeedbacks", getFeedbacks, "Prints feedbacks from users", ADMFLAG_ROOT);
	cvar_database = CreateConVar("sm_rwpolls_database", "1", "Database to use. Change takes effect on plugin reload.\n0 = sourcemod-local | 1 = custom\nIf set to 1, a \"polls\" entry is needed in \"sourcemod\\configs\\databases.cfg\".", FCVAR_NOTIFY, true, 1.0, true, 1.0);
	cvar_feedbackEnable = CreateConVar("sm_rwpolls_feedback", "1", "Set this to 0 if you want to disable feedback", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	cvar_feedbackTime = CreateConVar("sm_rwpolls_feedbacktime", "300", "Minimum time needed to submit a feedback (in seconds)", FCVAR_NOTIFY, true, 60.0, false);
	AutoExecConfig(true);

}

public void OnMapStart()
{
	initializeDatabase();
	configLoad(0, 0);
}

public void OnClientPostAdminCheck(client)
{
	clearPlayerVotes(client);
	loadPlayerVotes(client, 0);
	CreateTimer(5.0, somechecks, client, TIMER_FLAG_NO_MAPCHANGE);
//	CreateTimer(GetConVarFloat(cvar_feedbackTime), feedbackAd, client);
}

public Action feedbackAd(Handle timer, int client)
{
	PrintToChat(client, "Use !feedback to let us know what you think of the server");
}

public Action getFeedbacks(int client, int args)
{
	if(args != 1)
	{
		PrintToConsole(client, "Usage: sm_getfeedbacks <page>");
		return Plugin_Handled;
	}
	char argbuff[16];
	GetCmdArgString(argbuff, sizeof(argbuff));
	
	int page = StringToInt(argbuff) == 0 ? 1 : StringToInt(argbuff);
	
	char buff[128];
	Format(buff, sizeof(buff), "SELECT (SELECT COUNT(*) FROM `feedback`) as total, playerName, feedback, map, FROM_UNIXTIME(time) FROM `feedback` LIMIT %i, %i", 0+(page*10)-10, 10+(page*10)-10);
	
	SQL_SetCharset(g_hPollsDb, "utf8");
	SQL_TQuery(g_hPollsDb, queryFeedbacks, buff, client);
	
	return Plugin_Handled;
}

public Action getPollData(int client, int args)
{
	if(args != 1)
	{
		PrintToConsole(client, "Usage: sm_getpolldata <SEARCH ID>");
		return Plugin_Handled;
	}
	
	char argbuff[16];
	GetCmdArgString(argbuff, sizeof(argbuff));
	int searchId = StringToInt(argbuff);
	
	char buff[512];
	Format(buff, sizeof(buff), "SELECT voteSelection, COUNT(voteSelection) AS tvoteSelection, (SELECT COUNT(voteSelection) FROM voters WHERE voteName LIKE (SELECT voteName FROM voters WHERE ID = %i)) as tVotes FROM voters WHERE voteName LIKE (SELECT voteName FROM voters WHERE ID = %i) GROUP BY voteSelection", searchId, searchId);

	SQL_TQuery(g_hPollsDb, queryPollResults, buff, client);
	return Plugin_Handled;
}

public Action showPolls(int client, int args)
{
	char buff[255];
	Format(buff, sizeof(buff), "SELECT voteName AS dVotes, ID FROM voters GROUP BY voteName");
	SQL_TQuery(g_hPollsDb, queryPolls, buff, client);
	return Plugin_Handled;
}

public Action sendFeedback(int client, int args)
{

	if(args == 0)
	{
		PrintToConsole(client, "Usage: sm_feedback YOUR FEEDBACK HERE");
		PrintToChat(client, "Usage: !feedback YOUR FEEDBACK HERE");
		return Plugin_Handled;
	}
	
	if(GetConVarInt(cvar_feedbackEnable) == 0)
	{
		PrintToConsole(client, "This feature has been disabled");
		return Plugin_Handled;
	}
	char argbuff[512];
	GetCmdArgString(argbuff, sizeof(argbuff));
	
	char szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));
	
	char name[64];
	GetClientName(client, name, sizeof(name));
	
	char map[64];
	GetCurrentMap(map, sizeof(map));
	
	char escbuff[1025];
	SQL_EscapeString(g_hPollsDb, argbuff, escbuff, 2*strlen(argbuff)+1);
	
	char buff[255];
	Format(buff, sizeof(buff), "INSERT INTO `feedback` (`steamID`, `playerName`, `feedback`, `time`, `map`) VALUES ('%s', '%s', '%s', UNIX_TIMESTAMP(), '%s')", szAuth, name, escbuff, map)

	if(g_feedbackTime[client] < GetConVarInt(cvar_feedbackTime))
	{
		g_feedbackTime[client] = RoundFloat(GetClientTime(client));
		if(g_feedbackTime[client] > GetConVarInt(cvar_feedbackTime))
		{
			SQL_TQuery(g_hPollsDb, insertFeedback, buff);
			PrintToConsole(client, "Thank you for your feedback, we will do our best to keep our players satisfied");
			PrintToChat(client, "Thank you for your feedback, we will do our best to keep our players satisfied");
		} else
		{
			PrintToConsole(client, "You have to wait %i more seconds before sending feedback", GetConVarInt(cvar_feedbackTime) - g_feedbackTime[client]);
			PrintToChat(client, "You have to wait %i more seconds before sending feedback", GetConVarInt(cvar_feedbackTime) - g_feedbackTime[client]);
		}
	} else
	{
		if((RoundFloat(GetClientTime(client)) - g_feedbackTime[client]) > GetConVarInt(cvar_feedbackTime))
		{
			g_feedbackTime[client] = RoundFloat(GetClientTime(client));
			SQL_TQuery(g_hPollsDb, insertFeedback, buff);
		} else
		{
			PrintToConsole(client, "You have to wait %i more seconds before sending feedback", GetConVarInt(cvar_feedbackTime) - (RoundFloat(GetClientTime(client)) - g_feedbackTime[client]));
			PrintToChat(client, "You have to wait %i more seconds before sending feedback", GetConVarInt(cvar_feedbackTime) - (RoundFloat(GetClientTime(client)) - g_feedbackTime[client]));
		}	
	}
	
	return Plugin_Handled;
}

public Action sortClientPolls(client)
{
	g_isPollRunning[client] = false;
	g_pollCurrent[client] = -1;
	
	int start = -1
	
	
	for(new i=0; i < sizeof(g_pollQuestion); i++)
	{
		//Check if the question exists

		if(strlen(g_pollQuestion[i]))
		{
			if(strlen(g_hasPlayerVoted[client][i]) == 0)
			{	
				if(g_pollOptionsStart[i] <= start || start == -1)
				{
					g_pollCurrent[client] = i;
					start = g_pollOptionsStart[i];
				}
			}
		} else
		{
			break;
		}
	}
	
	if(g_pollCurrent[client] != -1)
	{
		PrintToConsole(client, "First poll to run is: %s", g_pollQuestion[g_pollCurrent[client]]);
	} else
	{
		PrintToConsole(client, "You have no polls left to answer.");
		PrintToChat(client, "Use \x03 !feedback \x01 to let us know what you think of the server");
	}

}

public OnClientDisconnect(client)
{
	clearPlayerVotes(client);
	g_isPollRunning[client] = false;
}

public clearPlayerVotes(int client) //To be refined
{
	g_feedbackTime[client] = 0;
	
	if(g_pollCurrent[client] != -1)
	{
		if(hDisplayPollTimer[client] != null)
		{
			PrintToServer("Killing client %i's timer.", client);
			KillTimer(hDisplayPollTimer[client]);
			hDisplayPollTimer[client] = null;
		}
	}
		
	for (new i = 0; i < sizeof(g_hasPlayerVoted[]); i++)
	{
		if(strlen(g_hasPlayerVoted[client][i]))
		{
			ReplaceString(g_hasPlayerVoted[client][i], sizeof(g_hasPlayerVoted[][]), g_hasPlayerVoted[client][i], "")
			
		} else
		{
			break;
		}
	}
}

public Action somechecks(Handle timer, int client)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	char szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));

	sortClientPolls(client);
	if(g_pollCurrent[client] == -1)
	{
		return Plugin_Handled;
	}
		
	hDisplayPollTimer[client] = CreateTimer(float(g_pollOptionsStart[g_pollCurrent[client]]), initiatePoll, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled
}

public Action loadPlayerVotes(int client, int args)
{
	clearPlayerVotes(client);
	char szAuth[32];
	GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));
	char mainQuery[512];
	Format(mainQuery, sizeof(mainQuery), "SELECT voteName FROM voters WHERE steamID LIKE '%s'", szAuth);
	if(g_hPollsDb != INVALID_HANDLE)
	{
		SQL_TQuery(g_hPollsDb, checkVoter, mainQuery, client);
	} else
	{
		PrintToServer("Unable to load player votes, invalid database handle");
	}
}

public Action initiatePoll(Handle timer, int client)
{
	hDisplayPollTimer[client] = null;
	
	if(g_hPollsDb == INVALID_HANDLE)
	{
		PrintToServer("Unable to initiate poll, invalid database handle");
	} else if(g_isPollRunning[client] == false && IsClientInGame(client) && !IsFakeClient(client) && g_pollCurrent[client] != -1)
	{
		g_isPollRunning[client] = true;
		showMenu(client, g_pollCurrent[client]);
	} else if(IsClientInGame(client) && !IsFakeClient(client))
	{
		char szAuth[32];
		GetClientAuthId(client, AuthId_Steam2, szAuth, sizeof(szAuth));
		PrintToServer("A poll is already running for %s", szAuth);
	} else
	{
		// if(timer)
		// {
			// KillTimer(timer);
		// }
		LogError("Something went wrong: initiatePoll, client: %i, in game: %s, is fake client: %s", client, IsClientInGame(client) ? "yes" : "no", IsClientInGame(client) ? (IsFakeClient(client) ? "yes" : "no") : "Disconnected");
	}
}

public void showMenu(int client, int pollID)
{
	Menu menu = new Menu(menuHandler);
	SetMenuTitle(menu, g_pollQuestion[pollID]);
	for(new i=0; i < sizeof(g_pollOptionsName[]); i++)
	{	
		if(g_pollOptionsName[pollID][i][0])
		{
			AddMenuItem(menu, g_pollOptionsName[pollID][i], g_pollOptionsDName[pollID][i]);
		} else
		{
			break;
		}
	}
	
	DisplayMenu(menu, client, 30);
	
}

public int menuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		g_isPollRunning[param1] = false;
		char info[32], szAuth[32];
		menu.GetItem(param2, info, sizeof(info));
		GetClientAuthId(param1, AuthId_Steam2, szAuth, sizeof(szAuth));
		
		Format(g_hasPlayerVoted[param1][g_pollCurrent[param1]], sizeof(g_hasPlayerVoted[][]), "%s", g_pollQuestion[g_pollCurrent[param1]]);
		
		char buff[255];
		Format(buff, sizeof(buff), "INSERT INTO `voters` (`steamID`, `voteName`, `voteSelection`, `time`) VALUES ('%s', '%s', '%s', '%i')", szAuth, g_pollQuestion[g_pollCurrent[param1]], info, GetTime());
		SQL_TQuery(g_hPollsDb, insertVoter, buff);
		

	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		if(g_pollOptionsRetry[g_pollCurrent[param1]] == 1)
		{
			hDisplayPollTimer[param1] = CreateTimer(float(g_pollOptionsStart[g_pollCurrent[param1]] / 2), initiatePoll, param1, TIMER_FLAG_NO_MAPCHANGE);
		}
		g_isPollRunning[param1] = false
		PrintToServer("Client %d's menu was cancelled.  Reason: %d, %s", param1, param2, g_pollOptionsRetry[g_pollCurrent[param1]] == 1 ? "Retrying" : "Closing");
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action configLoad(int client, int args)
{
//Check whether we have the file
	if(!FileExists(g_configFile))
	{
		SetFailState("Config file is missing: %s", g_configFile);
		return;
	}

//In a readable format
	new Handle:hKeyValues = CreateKeyValues("Polls");
	if(!FileToKeyValues(hKeyValues, g_configFile) || !KvGotoFirstSubKey(hKeyValues))
	{
		SetFailState("Config file could not be read. Syntax may be wrong: %s", g_configFile);
		return;
	}

//And then read it 	
	new iVote;
	do
	{
		// Question/Poll Name
		KvGetSectionName(hKeyValues, g_pollQuestion[iVote], sizeof(g_pollQuestion[]));
		//Debugging
		//PrintToConsole(client, "Questions: %s", g_pollQuestion[iVote]);
		
		new iOption;
		do
		{
			KvGotoFirstSubKey(hKeyValues, false);
			KvGetString(hKeyValues, NULL_STRING, g_pollOptionsDName[iVote][iOption], 255);
			KvGetSectionName(hKeyValues, g_pollOptionsName[iVote][iOption], 255);
			//Debugging
			//PrintToConsole(client, "Answer: %s", g_pollOptionsName[iVote][iOption]);
			
			//Getting settings keys and values, they are treated as normal poll elements, but filtered out and removed later (in this part) from the poll
			
			//As long as "retry" is the last setting, we dont need to do this for every setting as it will clear itself out,
			if(StrEqual(g_pollOptionsName[iVote][iOption], "start"))
			{
				g_pollOptionsStart[iVote] = StringToInt(g_pollOptionsDName[iVote][iOption]);
				//PrintToConsole(client, "Start value is: %i", g_pollOptionsStart[iVote]);
				
				Format(g_pollOptionsDName[iVote][iOption], sizeof(g_pollOptionsDName[][]), "");
				Format(g_pollOptionsName[iVote][iOption], sizeof(g_pollOptionsName[][]), "");
			} else if (StrEqual(g_pollOptionsName[iVote][iOption], "minplayers"))
			{
				//g_pollOptionsMinplayers[iVote] = StringToInt(g_pollOptionsDName[iVote][iOption]);
				//PrintToConsole(client, "Minplayers value is: %i", g_pollOptionsMinplayers[iVote]);
				
				Format(g_pollOptionsDName[iVote][iOption], sizeof(g_pollOptionsDName[][]), "");
				Format(g_pollOptionsName[iVote][iOption], sizeof(g_pollOptionsName[][]), "");
			} else if (StrEqual(g_pollOptionsName[iVote][iOption], "retry"))
			{
				g_pollOptionsRetry[iVote] = StrEqual(g_pollOptionsDName[iVote][iOption], "yes") ? 1 : 0;
				//PrintToConsole(client, "Retry value is: %i", g_pollOptionsRetry[iVote]);
				
				Format(g_pollOptionsDName[iVote][iOption], sizeof(g_pollOptionsDName[][]), "");
				Format(g_pollOptionsName[iVote][iOption], sizeof(g_pollOptionsName[][]), "");
			} else
			{
				iOption++;
			}
			
		} while(KvGotoNextKey(hKeyValues, false));
		KvGoBack(hKeyValues);
		
		iVote++;
	}
	while(KvGotoNextKey(hKeyValues, false));
}

initializeDatabase()
{
	new database;
	
//	database = GetConVarInt(cvar_database);
	database = 1;
	switch(database) {
		case 0 : {
			SQL_TConnect(DB_Connect, "storage-local");
		}
		case 1 : {
			if(SQL_CheckConfig("rwpolls")) {
				SQL_TConnect(DB_Connect, "rwpolls");
			} else {
				LogError("Unable to find \"rwpolls\" entry in \"sourcemod\\configs\\databases.cfg\".");
			}
		}
	}
}

//Callbacks for databases
public DB_Connect(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if(handle == INVALID_HANDLE) {
		LogError("Unable to connect. (%s)", error);
	} else {
		g_hPollsDb = handle;
		SQL_TQuery(g_hPollsDb, insertVoter, "CREATE TABLE IF NOT EXISTS `feedback` (`ID` int(11) NOT NULL AUTO_INCREMENT, `steamID` varchar(32) DEFAULT NULL, `playerName` varchar(64) DEFAULT NULL,`feedback` mediumtext, `time` int(11) DEFAULT NULL, `map` varchar(64) DEFAULT NULL, PRIMARY KEY(`ID`)) CHARSET=utf8");
		SQL_TQuery(g_hPollsDb, insertVoter, "CREATE TABLE IF NOT EXISTS `voters` (`ID` int(11) NOT NULL AUTO_INCREMENT, `steamID` varchar(32) DEFAULT NULL, `voteName` varchar(255) DEFAULT NULL, `voteSelection` varchar(255) DEFAULT NULL, `time` int(11) DEFAULT NULL, PRIMARY KEY(`ID`)) CHARSET=utf8");
	}
}

public insertVoter(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if(handle == INVALID_HANDLE) {
		LogError("Error inserting data in database. (%s)", error);
	}
}

public insertFeedback(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if(handle == INVALID_HANDLE) {
		LogError("Error inserting data in database. (%s)", error);
	}
}

public checkVoter(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if(handle == INVALID_HANDLE)
	{
		LogError("Error searching in database: %s", error);
		return;
	}

	char question[255];
	int i = 0;
	while(SQL_FetchRow(handle))
	{
		SQL_FetchString(handle, 0, question, sizeof(question));
		
		for(new j; j < sizeof(g_pollQuestion); j++)
		{
			if(strlen(g_pollQuestion[j]))
			{
				if(StrEqual(g_pollQuestion[j], question) == true)
				{	
					//PrintToConsole(data, "Question: %s has been answered", question);
					Format(g_hasPlayerVoted[data][j], sizeof(g_hasPlayerVoted[][]), "%s", question);
				}
				
			} else
			{
				break;
			}
		}
		i++;
	}
}

public queryPolls(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if(handle == INVALID_HANDLE)
	{
		LogError("Error searching in database: %s", error);
		return;
	}
	
	char question[255];
	int questionID;
	int i = 0;
	
	while(SQL_FetchRow(handle))
	{
		SQL_FetchString(handle, 0, question, sizeof(question));
		questionID = SQL_FetchInt(handle, 1);
		PrintToConsole(data, "%s | SEARCH ID: %i\n", question, questionID);
		i++;
	}
	
	PrintToConsole(data, "Found a total of %i questions", i);
}

public queryPollResults(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if(handle == INVALID_HANDLE)
	{
		LogError("Error searching in database: %s", error);
		return;
	}
	
	char pollSelection[128];
	int ipollSelection;
	int totalVotes;
	float votesShare;
	
	while(SQL_FetchRow(handle))
	{
		SQL_FetchString(handle, 0, pollSelection, sizeof(pollSelection));
		ipollSelection = SQL_FetchInt(handle, 1);
		totalVotes = SQL_FetchInt(handle, 2);
		votesShare = float(ipollSelection) / float(totalVotes) * 100.00;
		PrintToConsole(data, "Poll option: %s | Votes share: %.2f%", pollSelection, votesShare);
	}
	
	PrintToConsole(data, "Total votes: %i", totalVotes);

}

public queryFeedbacks(Handle:owner, Handle:handle, const String:error[], any:data)
{
	if(handle == INVALID_HANDLE)
	{
		LogError("Error searching in database: %s", error);
		return;
	}
	
	int total;
	char time[32];
	char playerName[64];
	char feedback[512];
	char map[64];
	
	while(SQL_FetchRow(handle))
	{
		total = SQL_FetchInt(handle, 0);
		SQL_FetchString(handle, 4, time, sizeof(time));
		SQL_FetchString(handle, 1, playerName, sizeof(playerName));
		SQL_FetchString(handle, 2, feedback, sizeof(feedback));
		SQL_FetchString(handle, 3, map, sizeof(map));
		PrintToConsole(data, "From: %s on map: %s\nMessage: %s\n", playerName, map, feedback);
	}
	
	if(total == 0)
	{
		PrintToConsole(data, "The page you entered does not exist or there are no feedbacks yet");
	} else
	{
		PrintToConsole(data, "Last feedback was on %s\n", time);
		PrintToConsole(data, "Total pages: %i", RoundToCeil(float(total)/10.0));
	}
}