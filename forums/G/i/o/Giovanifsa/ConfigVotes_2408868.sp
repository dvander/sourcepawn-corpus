#include <sourcemod>
#include <sdktools>
#pragma newdecls required
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "Configuration Votes",
	author = "Nescau",
	description = "Allows players to vote for a config.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/nescaufsa/"
};

char g_caPath[PLATFORM_MAX_PATH];
char g_caNextConfigSave[PLATFORM_MAX_PATH];

ConVar g_cvVoteTime;
ConVar g_cvAutoVotes;
ConVar g_cvAutoVotesTime;
ConVar g_cvLoadConfigsDelay;

KeyValues g_kvConfigs = null;

bool g_bIgnoreTimedVotes = false;
bool g_bWarningSuppress = true;

Menu g_mMenu = null;
Handle g_hVoteTimer = INVALID_HANDLE;

public void OnPluginStart() 
{
	BuildPath(Path_SM, g_caPath, PLATFORM_MAX_PATH, "configs/cv_cfgs.txt");
	BuildPath(Path_SM, g_caNextConfigSave, PLATFORM_MAX_PATH, "data/cv_nextconfig.txt");
	
	g_cvVoteTime = CreateConVar("cv_votetime", "30", "Seconds before ending an running vote.", 0, true, 0.1);
	g_cvAutoVotes = CreateConVar("cv_autovote", "1", "Enables Config Votes to start a vote when the map time left reaches \"cv_maptimevote\" value.");
	g_cvAutoVotesTime = CreateConVar("cv_maptimevote", "8", "If \"cv_autovote\" is set to 1, and the map time reaches this CVar value, an vote will start.", 0, true, 6.0);
	g_cvLoadConfigsDelay = CreateConVar("cv_cfgloaddelay", "15", "Seconds before starting to load last voted configs.", 0, true, 0.1);
	
	RegAdminCmd("sm_cfgvote", StartCfgVote, ADMFLAG_VOTE, "Forces the config vote to start.");
	RegAdminCmd("sm_cfgvoteex", StartCfgVoteEx, ADMFLAG_BAN, "Forces the config vote to start. Automatic timed votes will be disabled for the map.");
	RegAdminCmd("sm_cfgvotecancel", CancelCfgVote, ADMFLAG_VOTE, "Forces the running vote to cancel.");
}

public Action CancelCfgVote(int client, int args)
{
	CancelRunningVotes(true);
	ReplyToCommand(client, "[CV] Any running votes were canceled.");
}

public Action StartCfgVote(int client, int args)
{
	CancelRunningVotes(true);
	LaunchVote();
}

public Action StartCfgVoteEx(int client, int args)
{
	g_bIgnoreTimedVotes = true;
	CancelRunningVotes(true);
	LaunchVote();
}

public void OnMapStart()
{
	g_bIgnoreTimedVotes = false;
	ParseKeyValues();
	
	CreateTimer(GetConVarFloat(g_cvLoadConfigsDelay), ExecuteLater, INVALID_HANDLE);
	
	if (GetConVarBool(g_cvAutoVotes))
		CreateTimer(1.0, TestTimeLeft, INVALID_HANDLE, TIMER_REPEAT);
}

public Action ExecuteLater(Handle timer, any data)
{
	char caExecuteString[128];
	
	KeyValues kv = new KeyValues("cv_autoexec");
	kv.ImportFromFile(g_caNextConfigSave);
	kv.GetString("command", caExecuteString, 128, "");
	
	if (!StrEqual(caExecuteString, ""))
	{
		ServerCommand(caExecuteString);
		PrintToServer("[CV] Last voted configuration has been loaded.\n[CV] Configuration: \"%s\"", caExecuteString);
		kv.SetString("command", "");
	}
	
	kv.Rewind();
	kv.ExportToFile(g_caNextConfigSave);
	delete kv;
}

void ParseKeyValues()
{
	if (g_kvConfigs != null)
		delete g_kvConfigs;
	
	g_kvConfigs = new KeyValues("cv");
	g_kvConfigs.ImportFromFile(g_caPath);
	int iParseCount = 0;
	
	char caHelper[128];
	char caHelper2[128];
	
	bool bGotoFirstSubKey = false;
	
	while (g_bWarningSuppress)
	{
		if (!bGotoFirstSubKey)
		{
			if (!g_kvConfigs.GotoFirstSubKey())
				break;
				
			bGotoFirstSubKey = true;
		} else {
			if (!g_kvConfigs.GotoNextKey())
				break;
		}
		
		g_kvConfigs.SavePosition();
		
		g_kvConfigs.GetSectionName(caHelper2, 128);
		g_kvConfigs.GetString("execute", caHelper, 128, "");
		
		if (StrEqual(caHelper, ""))
			LogError("[CV] In %s section: \"execute\" keyvalue is empty.", caHelper2);
		else
			iParseCount++;
	}
	
	g_kvConfigs.Rewind();
	
	LogMessage("[CV] %d configs loaded.", iParseCount);
	
	if (iParseCount == 0 || iParseCount > 64)
		SetFailState("[CV] \"configs/cv_cfgs.cfg\" is empty, invalid, or have more than 64 configs.");
}

public Action TestTimeLeft(Handle timer, any data) 
{
	if (g_bIgnoreTimedVotes)
		return Plugin_Stop;
	
	int iTimeLeft;
	if (GetMapTimeLeft(iTimeLeft))
	{
		if (iTimeLeft > 0 && iTimeLeft <= (GetConVarInt(g_cvAutoVotesTime) * 60))
		{
			if (GetClientCount() > 0)
			{
				g_bIgnoreTimedVotes = true;
				CancelRunningVotes(true);
				PrintToChatAll("[CV] Automatic configuration vote started.");
				LaunchVote();
			}
		}
	}
	
	else
	{
		LogError("[CV] \"cv_autovote\" is unsuported by this mod.");
		SetConVarBool(g_cvAutoVotes, false);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

void LaunchVote()
{
	g_mMenu = new Menu(MenuCallBack);
	g_mMenu.SetTitle("Vote for the next configuration:");
	SetMenuExitButton(g_mMenu, false);
	
	char caHelper[128];
	char caHelper2[128];
	char caHelper3[128];
	int iHelper;
	
	int initializeIds[64];
	int idsQuantity = 0;
	
	bool bGotoFirstSubKey = false;
	
	while (g_bWarningSuppress)
	{
		if (!bGotoFirstSubKey)
		{
			if(!g_kvConfigs.GotoFirstSubKey())
				break;
			
			bGotoFirstSubKey = true;
		} else {
			if (!g_kvConfigs.GotoNextKey())
				break;
		}
		
		g_kvConfigs.SavePosition();
		g_kvConfigs.GetSectionName(caHelper2, 128);
		g_kvConfigs.GetSectionSymbol(iHelper);
		
		g_kvConfigs.GetString("execute", caHelper, 128, "");
		if (!StrEqual(caHelper, ""))
		{
			initializeIds[idsQuantity] = iHelper;
			idsQuantity++;
			
			IntToString(iHelper, caHelper3, 128);
			g_mMenu.AddItem(caHelper3, caHelper2);
		}

	}
		
	g_kvConfigs.Rewind();
	
	InitializeVoteArray(initializeIds, idsQuantity);
	
	int iTimeLeft = 0;
	GetMapTimeLeft(iTimeLeft)
	
	if (iTimeLeft < 20)
		ExtendMapTimeLimit(iTimeLeft + 60);
	
	for (int b = 1; b < MaxClients; b++)
	{
		if (IsClientInGame(b) && !IsFakeClient(b))
			g_mMenu.Display(b, GetConVarInt(g_cvVoteTime));
	}
	
	g_hVoteTimer = CreateTimer(GetConVarFloat(g_cvVoteTime), TimerVotationEnds, INVALID_HANDLE);
}

public int MenuCallBack(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char caHelper[128];
		menu.GetItem(param2, caHelper, 128);
		Vote(StringToInt(caHelper));
	}
	
	else if (action == MenuAction_End)
	{
		delete menu;
		g_mMenu = null;
	}
}

void SetFileData(int id)
{
	char caString[128];
	char caStringName[128];
	
	g_kvConfigs.JumpToKeySymbol(id);
	g_kvConfigs.GetSectionName(caStringName, 128);
	g_kvConfigs.GetString("execute", caString, 128, "");
	g_kvConfigs.Rewind();
	
	KeyValues kv = new KeyValues("cv_autoexec");
	kv.ImportFromFile(g_caNextConfigSave);
	kv.SetString("command", caString);
	kv.Rewind();
	kv.ExportToFile(g_caNextConfigSave);
	delete kv;
	
	PrintToChatAll("[CV] Configuration vote finished.\n[CV] Next configuration: %s", caStringName);
}

void CancelRunningVotes(bool bKillTimer = false)
{
	if (g_mMenu != null)
	{
		g_mMenu.Cancel();
		delete g_mMenu;
		g_mMenu = null;
	}
	
	if (bKillTimer)
	{
		if (g_hVoteTimer != INVALID_HANDLE)
		{
			KillTimer(g_hVoteTimer);
			g_hVoteTimer = INVALID_HANDLE;
		}
	}
}

//Stores votes here
int g_iVotes[64][2]; //[LINE][0 for id, 1 for votes]

public Action TimerVotationEnds(Handle timer, any data)
{
	CancelRunningVotes();
	
	int iHighestVotedIds[64];
	int iArrayCount = 0;
	int iHighestVote = 0;
	
	//Searches for the highest vote count
	for (int a = 0; a < 64; a++)
	{
		if (g_iVotes[a][1] > iHighestVote)
			iHighestVote = g_iVotes[a][1];
	}
	
	//Puts all the more voted ids in the array
	for (int b = 0; b < 64; b++)
	{
		if (g_iVotes[b][0] != -1 && g_iVotes[b][1] == iHighestVote)
		{
			iHighestVotedIds[iArrayCount] = g_iVotes[b][0];
			iArrayCount++;
		}
	}
	
	if (iArrayCount == 1)
		SetFileData(iHighestVotedIds[0]);
	else
	{
		PrintToChatAll("[CV] %d configurations did get the same ammout of votes, selecting one of them...", iArrayCount);
		SetFileData(iHighestVotedIds[GetRandomInt(0, iArrayCount - 1)]);
	}
}

void InitializeVoteArray(int[] ids, int arraySize)
{
	for (int a = 0; a < 64; a++)
	{
		g_iVotes[a][0] = -1;
		g_iVotes[a][1] = 0;
	}
	
	for (int b = 0; b < arraySize; b++)
	{
		g_iVotes[b][0] = ids[b];
	}
}

void Vote(int id)
{
	//Search for the id in the g_iVotes. g_iVotes[LINES][0/1] was initialized by InitializeVoteArray().
	for (int a = 0; a < 64; a++)
	{
		if (g_iVotes[a][0] == id)
		{
			g_iVotes[a][1] += 1;
			break;
		}
	}
}