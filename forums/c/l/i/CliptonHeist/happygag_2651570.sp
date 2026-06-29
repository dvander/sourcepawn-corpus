#include <sourcecomms>
#include <basecomm>
#include <cstrike>
#include <colorvariables>

Database g_Database = null;

bool g_bHappyGagged[MAXPLAYERS + 1] = {false, ...};
bool g_bSourcecommsLoaded = false;
bool g_bLate = false;

char g_sHappyPhrases[128][128];
int g_iPhraseCount = 0;
char g_sFilePath[256];

ArrayStack g_LoadQueue;
Handle g_hQueueTimer;

public Plugin myinfo = 
{
	name = "Happy Gag", 
	author = "The Doggy", 
	description = "Gags players and makes them happy :)", 
	version = "1.0.0",
	url = "coldcommunity.com"
};


public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_hgag", Command_HappyGag, ADMFLAG_BAN, "[SM] Gags a client for specified amount of time and sends predefined messages when they try to talk.");
	RegAdminCmd("sm_hungag", Command_HappyUngag, ADMFLAG_UNBAN, "[SM] Ungags a happy gagged client.");
	RegAdminCmd("sm_reloadphrases", Command_ReloadPhrases, ADMFLAG_CONFIG, "[SM] Reloads the phrases from happy_phrases.ini.");
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "configs/happy_phrases.ini");

	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");
	CreateTimer(1.0, InitializeDatabase);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(late)
		g_bLate = true;

	return APLRes_Success;
}

public void OnMapStart()
{
	BuildPhrases();
}

public bool BuildPhrases()
{
	if(!FileExists(g_sFilePath))
	{
		LogError("Phrases file could not be found in %s", g_sFilePath);
		return false;
	}

	g_iPhraseCount = 0;
	File file = OpenFile(g_sFilePath, "r");
	while(!file.EndOfFile())
	{
		char sLine[128];
		file.ReadLine(sLine, sizeof(sLine));

		TrimString(sLine);
		if(strlen(sLine) > 0)
		{
			Format(g_sHappyPhrases[g_iPhraseCount], sizeof(g_sHappyPhrases[]), "%s", sLine);
			g_iPhraseCount++;
		}

		if(g_iPhraseCount == sizeof(g_sHappyPhrases))
			break;
	}

	if(g_iPhraseCount > 0)
		return true;
	return false;
}

public void OnClientPostAdminCheck(int Client)
{
	if(!IsValidClient(Client)) return;
	LoadHappyGagStatus(Client);
}

public void OnClientDisconnect(int Client)
{
	if(!IsValidClient(Client)) return;
	SaveHappyGagStatus(Client);
}

public Action InitializeDatabase(Handle hTimer)
{
	char sError[256];
	g_Database = SQLite_UseDatabase("sourcemod-local", sError, sizeof(sError));

	if(!StrEqual(sError, ""))
	{
		LogError("Database couldn't connect due to error: %s", sError);
		if(g_Database != null)
		{
			delete g_Database;
			g_Database = null;
		}

		RetryDatabaseConnection();
	}
	else
		CreateTable();

	return Plugin_Stop;
}

public void RetryDatabaseConnection()
{
	CreateTimer(30.0, InitializeDatabase);
}

public void CreateTable()
{
	char sQuery[1024] = "";
	StrCat(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS happygag_gagged (");
	StrCat(sQuery, sizeof(sQuery), "steam_id TEXT PRIMARY KEY, ");
	StrCat(sQuery, sizeof(sQuery), "gagged INTEGER NOT NULL DEFAULT 0");
	StrCat(sQuery, sizeof(sQuery), ");");
	g_Database.Query(SQL_GenericQuery, sQuery);

	if(g_bLate)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
				LoadHappyGagStatus(i);
		}
	}
}

public Action LoadClientsFromQueue(Handle hTimer)
{
	while(!g_LoadQueue.Empty)
	{
		int serial = g_LoadQueue.Pop();
	
		int Client = GetClientFromSerial(serial);
		if(!IsValidClient(Client)) continue;

		char sSteam[32];
		if(!GetClientAuthId(Client, AuthId_Engine, sSteam, sizeof(sSteam)))
		{
			LogError("Couldn't get Client %N's SteamID, Auth servers may be down.", Client);
			continue;
		}

		char sQuery[1024];
		Format(sQuery, sizeof(sQuery), "SELECT gagged FROM happygag_gagged WHERE steam_id='%s';", sSteam);
		g_Database.Query(SQL_LoadClientGagStatus, sQuery, serial);
	}

	delete g_hQueueTimer;
}

public void LoadHappyGagStatus(int Client)
{
	if(!IsValidClient(Client) || g_Database == null) return;

	char sSteam[32];
	if(!GetClientAuthId(Client, AuthId_Engine, sSteam, sizeof(sSteam)))
	{
		g_LoadQueue.Push(GetClientSerial(Client));
		if(g_hQueueTimer == null)
			g_hQueueTimer == CreateTimer(30.0, LoadClientsFromQueue, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "SELECT gagged FROM happygag_gagged WHERE steam_id='%s';", sSteam);
	g_Database.Query(SQL_LoadClientGagStatus, sQuery, GetClientSerial(Client));
}

public void SQL_LoadClientGagStatus(Database db, DBResultSet results, const char[] error, any data)
{
	int Client = GetClientFromSerial(data);
	if(!IsValidClient(Client)) return;

	if(db == null)
	{
		LogError("SQL_LoadClientGagStatus Error: %s - Added %N to Load Queue", error, Client);
		g_LoadQueue.Push(data);

		if(g_hQueueTimer == null)
			g_hQueueTimer = CreateTimer(30.0, LoadClientsFromQueue, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if(results == null)
	{
		LogError("SQL_LoadClientGagStatus Error: %s", error);
		return;
	}

	if(!results.FetchRow()) return;

	int gagCol;
	results.FieldNameToNum("gagged", gagCol);
	g_bHappyGagged[Client] = view_as<bool>(results.FetchInt(gagCol));
}

public void SaveHappyGagStatus(int Client)
{
	if(!IsValidClient) return;

	char sSteam[32], sQuery[1024];
	if(!GetClientAuthId(Client, AuthId_Engine, sSteam, sizeof(sSteam)))
	{
		LogError("SaveHappyGagStatus Error: Could not get %N's SteamID.");
		return;
	}

	DataPack stupidPack = new DataPack();
	stupidPack.WriteCell(g_bHappyGagged[Client]);
	stupidPack.WriteString(sSteam);

	Format(sQuery, sizeof(sQuery), "INSERT INTO happygag_gagged (steam_id, gagged) VALUES('%s', '%i');", sSteam, g_bHappyGagged[Client]);
	g_Database.Query(SQL_FuckingSQLite, sQuery, stupidPack);
}

public void SQL_FuckingSQLite(Database db, DBResultSet results, const char[] sError, DataPack asdf)
{
	if(StrContains(sError, "steam_id", false) != -1)
	{
		char sSteam[32], sQuery[1024];
		asdf.Reset();
		bool gag = asdf.ReadCell();
		asdf.ReadString(sSteam, sizeof(sSteam));
		Format(sQuery, sizeof(sQuery), "UPDATE happygag_gagged SET gagged = %i WHERE steam_id = '%s';", gag, sSteam);
		g_Database.Query(SQL_GenericQuery, sQuery);
	}
}

public Action Command_HappyGag(int Client, int iArgs)
{
	if(Client == 0) {}
	else if(!IsValidClient(Client)) return Plugin_Handled;
	
	if(iArgs < 1)
	{
		CReplyToCommand(Client, "[SM] Invalid Syntax. Usage: sm_hgag <player> <opt:time> <opt:reason>");
		return Plugin_Handled;
	}

	char sTarget[64], sTime[8], sReason[128];
	GetCmdArg(1, sTarget, sizeof(sTarget));

	int iTarget = FindTarget(Client, sTarget, true, true);
	if(iTarget == -1) return Plugin_Handled;

	if(!g_bSourcecommsLoaded)
	{
		BaseComm_SetClientGag(iTarget, true);
		g_bHappyGagged[iTarget] = true;
		ShowActivity2(Client, "[SM] ", "Happy-Gagged %N for the session.", iTarget);
		return Plugin_Handled;
	}

	if(iArgs == 3)
	{
		GetCmdArg(3, sReason, sizeof(sReason));
		GetCmdArg(2, sTime, sizeof(sTime));
	}
	else if(iArgs == 2)
		GetCmdArg(2, sTime, sizeof(sTime));

	int iTime = -1;
	if(!StrEqual(sTime, ""))
		iTime = StringToInt(sTime);

	if(iTime == 0)
	{
		CReplyToCommand(Client, "[SM] Permanent gagging is not allowed, target will be gagged for the session.");
		iTime = -1;
	}

	SourceComms_SetClientGag(iTarget, true, iTime, true, sReason);
	g_bHappyGagged[iTarget] = true;

	if(iTime == -1)
		ShowActivity2(Client, "[SM] ", "Happy-Gagged %N for the session.", iTarget);
	else
	{
		ShowActivity2(Client, "[SM] ", "Happy-Gagged %N for %i minutes.", iTarget, iTime);
		SaveHappyGagStatus(iTarget);
	}

	return Plugin_Handled;
}

public Action Command_HappyUngag(int Client, int iArgs)
{
	if(Client == 0) {}
	else if(!IsValidClient(Client)) return Plugin_Handled;

	if(iArgs != 1)
	{
		CReplyToCommand(Client, "[SM] Invalid Syntax. Usage: sm_hungag <player>");
		return Plugin_Handled;
	}

	char sTarget[64];
	GetCmdArg(1, sTarget, sizeof(sTarget));

	int iTarget = FindTarget(Client, sTarget, true, false);
	if(iTarget == -1) return Plugin_Handled;

	if(!g_bSourcecommsLoaded)
	{
		BaseComm_SetClientGag(iTarget, false);
		g_bHappyGagged[iTarget] = false;
		ShowActivity2(Client, "[SM] ", "Happy-Ungagged %N", iTarget);
		return Plugin_Handled;
	}

	SourceComms_SetClientGag(iTarget, false);
	g_bHappyGagged[iTarget] = false;
	ShowActivity2(Client, "[SM] ", "Happy-Ungagged %N", iTarget);
	return Plugin_Handled;
}

public Action Command_ReloadPhrases(int Client, int iArgs)
{
	if(Client == 0) {}
	else if(!IsValidClient(Client)) return Plugin_Handled;

	if(BuildPhrases())
		CReplyToCommand(Client, "[SM] Successfully reloaded phrases.");
	else
		CReplyToCommand(Client, "[SM] Failed to reload phrases.");
	return Plugin_Handled;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "sourcecomms++", false))
		g_bSourcecommsLoaded = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "sourcecomms++", false))
		g_bSourcecommsLoaded = false;
}

public Action Listener_Say(int Client, const char[] sCommand, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Continue;

	if(BaseComm_IsClientGagged(Client) && g_bHappyGagged[Client] && g_iPhraseCount > 0)
	{
		CSetNextAuthor(Client);
		CPrintToChatAll("{teamcolor}%N{default} : %s", Client, g_sHappyPhrases[GetRandomInt(0, g_iPhraseCount - 1)]);
	}
	else if(!BaseComm_IsClientGagged(Client) && g_bHappyGagged[Client])
		g_bHappyGagged[Client] = false;

	return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{ 
    if (client >= 1 &&  
    client <= MaxClients &&  
    IsClientInGame(client) && 
    !IsFakeClient(client)) 
        return true; 
    return false; 
}

//generic query handler
public void SQL_GenericQuery(Database db, DBResultSet results, const char[] sError, any data)
{
	if(results == null)
	{
		PrintToServer("MySQL Query Failed: %s", sError);
		LogError("MySQL Query Failed: %s", sError);
		return;
	}
}