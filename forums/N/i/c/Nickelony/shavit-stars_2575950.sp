#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <shavit>

#pragma newdecls required
#pragma semicolon 1

/* CVars */

ConVar gCV_FirstStar = null;
ConVar gCV_SecondStar = null;
ConVar gCV_ThirdStar = null;
ConVar gCV_FourthStar = null;

float gF_FirstStar = 1.75;
float gF_SecondStar = 1.50;
float gF_ThirdStar = 1.25;
float gF_FourthStar = 1.00;

/* Global variables */

char gS_StyleStrings[STYLE_LIMIT][STYLESTRINGS_SIZE][128];
char gS_ChatStrings[CHATSETTINGS_SIZE][128];
char gS_Map[160];

int gI_RankedPlayers;

int gI_Rank[MAXPLAYERS + 1];
int gI_Stars[MAXPLAYERS + 1];

int gI_RGBStyleColor[MAXPLAYERS + 1][3];

/* Handles etc. */

Menu gH_Top100Menu = null;
Handle gH_StarHUD = null;

char gS_MySQLPrefix[32];
Database gH_SQL = null;

bool gB_Stats = false;
bool gB_Late = false;

public Plugin myinfo =
{
	name = "[shavit] Star ranking",
	author = "Nickelony",
	description = "Star ranking system for shavit's bhop timer.",
	version = "1.0",
	url = "steamcommunity.com/id/nickelony"
};

// #Initiation {{{
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	gB_Late = late;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if(!LibraryExists("shavit-wr"))
	{
		SetFailState("shavit-wr is required for the plugin to work.");
	}
	
	if(gH_SQL == null)
	{
		Shavit_OnDatabaseLoaded();
	}
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_stars", Command_Stars, "Shows the required times to get each star for your current style.");
	RegConsoleCmd("sm_st", Command_Stars, "Shows the required times to get each star for your current style.");
	
	RegConsoleCmd("sm_rankstars", Command_RankStars, "Shows your current rank and stars you've collected.");
	RegConsoleCmd("sm_rankst", Command_RankStars, "Shows your current rank and stars you've collected.");
	
	RegConsoleCmd("sm_topstars", Command_TopStars, "Shows the top 100 star collectors list.");
	RegConsoleCmd("sm_topst", Command_TopStars, "Shows the top 100 star collectors list.");
	
	gCV_FirstStar = CreateConVar("shavit_stars_star1", "1.75", "WR * {value} = Required time for 1 star.", 0, true, 1.0);
	gCV_SecondStar = CreateConVar("shavit_stars_star2", "1.50", "WR * {value} = Required time for 2 stars.", 0, true, 1.0);
	gCV_ThirdStar = CreateConVar("shavit_stars_star3", "1.25", "WR * {value} = Required time for 3 stars.", 0, true, 1.0);
	gCV_FourthStar = CreateConVar("shavit_stars_star4", "1.00", "WR * {value} = Required time for 4 stars.\nSetting this to 1.00 means that you need the WR to have 4 stars.", 0, true, 1.0);
	
	gCV_FirstStar.AddChangeHook(OnConVarChanged);
	gCV_SecondStar.AddChangeHook(OnConVarChanged);
	gCV_ThirdStar.AddChangeHook(OnConVarChanged);
	gCV_FourthStar.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig();
	
	gH_StarHUD = CreateHudSynchronizer();
	CreateTimer(0.1, UpdateHUD_Timer, INVALID_HANDLE, TIMER_REPEAT);
	
	SQL_SetPrefix();
	
	if(gB_Late)
	{
		Shavit_OnChatConfigLoaded();
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gF_FirstStar = gCV_FirstStar.FloatValue;
	gF_SecondStar = gCV_SecondStar.FloatValue;
	gF_ThirdStar = gCV_ThirdStar.FloatValue;
	gF_FourthStar = gCV_FourthStar.FloatValue;
}

public void Shavit_OnChatConfigLoaded()
{
	for(int i = 0; i < CHATSETTINGS_SIZE; i++)
	{
		Shavit_GetChatStrings(i, gS_ChatStrings[i], 128);
	}
}

public void Shavit_OnStyleConfigLoaded(int styles)
{
	if(styles == -1)
	{
		styles = Shavit_GetStyleCount();
	}
	
	for(int i = 0; i < styles; i++)
	{
		Shavit_GetStyleStrings(i, sStyleName, gS_StyleStrings[i][sStyleName], 128);
		Shavit_GetStyleStrings(i, sHTMLColor, gS_StyleStrings[i][sHTMLColor], 128);
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "shavit-stats"))
	{
		gB_Stats = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "shavit-stats"))
	{
		gB_Stats = false;
	}
}
// }}}

// #DBConnect {{{
public void Shavit_OnDatabaseLoaded()
{
	gH_SQL = Shavit_GetDatabase();
	SetSQLInfo();
}

public Action CheckForSQLInfo(Handle timer)
{
	return SetSQLInfo();
}

Action SetSQLInfo()
{
	if(gH_SQL == null)
	{
		gH_SQL = Shavit_GetDatabase();
		CreateTimer(0.5, CheckForSQLInfo);
	}
	
	else
	{
		SQL_DBConnect();
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

void SQL_SetPrefix()
{
	char[] sFile = new char[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, PLATFORM_MAX_PATH, "configs/shavit-prefix.txt");
	
	File fFile = OpenFile(sFile, "r");
	
	if(fFile == null)
	{
		SetFailState("Cannot open \"configs/shavit-prefix.txt\". Make sure this file exists and that the server has read permissions to it.");
	}
	
	char[] sLine = new char[PLATFORM_MAX_PATH * 2];
	
	while(fFile.ReadLine(sLine, PLATFORM_MAX_PATH * 2))
	{
		TrimString(sLine);
		strcopy(gS_MySQLPrefix, 32, sLine);
		
		break;
	}
	
	delete fFile;
}

void SQL_DBConnect()
{
	if(gH_SQL != null)
	{
		char[] sDriver = new char[8];
		gH_SQL.Driver.GetIdentifier(sDriver, 8);
		
		if(!StrEqual(sDriver, "mysql", false))
		{
			SetFailState("MySQL is the only supported database engine.");
		}
		
		char[] sQuery_01 = new char[256];
		FormatEx(sQuery_01, 256, "ALTER TABLE %splayertimes ADD COLUMN stars int;", gS_MySQLPrefix);
		
		char[] sQuery_02 = new char[256];
		FormatEx(sQuery_02, 256, "ALTER TABLE %susers ADD COLUMN stars int", gS_MySQLPrefix);
		
		Transaction txn = SQL_CreateTransaction();
		txn.AddQuery(sQuery_01);
		txn.AddQuery(sQuery_02);
		SQL_ExecuteTransaction(gH_SQL, txn, TXN_CreateColumn_Success, TXN_CreateColumn_Error, 0);
	}
}

public void TXN_CreateColumn_Success(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	OnMapStart();
	
	if(gB_Late)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			OnClientConnected(i);
		}
	}
}

public void TXN_CreateColumn_Error(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("ERROR: %s", error);
}
// }}}

// #OnPlayerJoin || #OnMapStart {{{
public void OnMapStart()
{
	GetCurrentMap(gS_Map, 160);
	GetMapDisplayName(gS_Map, gS_Map, 160);
	
	UpdateRankedPlayers();
}

void UpdateRankedPlayers()
{
	char[] sQuery = new char[256];
	FormatEx(sQuery, 256, "SELECT COUNT(*) count FROM %susers WHERE stars > 0;", gS_MySQLPrefix);
	gH_SQL.Query(SQL_UpdateRankedPlayers_Callback, sQuery, 0, DBPrio_High);
}

public void SQL_UpdateRankedPlayers_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null)
	{
		LogError("ERROR: %s", error);
		return;
	}
	
	if(results.FetchRow())
	{
		gI_RankedPlayers = results.FetchInt(0);
	}
}

public void OnClientConnected(int client)
{
	gI_Rank[client] = 0;
	gI_Stars[client] = 0;
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
	{
		UpdatePlayerRank(client);
	}
	
	CreateTimer(30.0, Timer_UpdateStarsOnJoin, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_UpdateStarsOnJoin(Handle timer, any data)
{
	int client = GetClientFromSerial(data);
	
	if(!IsFakeClient(client))
	{
		for(int i = 0; i < TRACKS_SIZE; i++)
		{
			for(int j = 0; j < Shavit_GetStyleCount(); j++)
			{
				UpdatePlayerStars(client, i, j);
			}
		}
		
		UpdatePlayerRank(client);
	}
}

void UpdatePlayerStars(int client, int track, int style)
{
	char[] sAuthID = new char[32];
	
	if(!GetClientAuthId(client, AuthId_Steam3, sAuthID, 32))
	{
		return;
	}
	
	float fWRTime = 0.0;
	Shavit_GetWRTime(style, fWRTime, track);
	
	float fFirstStar = float(RoundToFloor((fWRTime * gF_FirstStar) * 100)) / 100;
	float fSecondStar = float(RoundToFloor((fWRTime * gF_SecondStar) * 100)) / 100;
	float fThirdStar = float(RoundToFloor((fWRTime * gF_ThirdStar) * 100)) / 100;
	float fFourthStar = 0.0;
	
	if(gF_FourthStar == 1.00)
	{
		fFourthStar = fWRTime + 0.005; // +0.005 because of rounding issues.
	}
	else
	{
		fFourthStar = float(RoundToFloor((fWRTime * gF_FourthStar) * 100)) / 100;
	}
	
	float fPBTime = 0.0;
	Shavit_GetPlayerPB(client, style, fPBTime, track);
	
	int stars = 0;
	
	if(fPBTime <= fFirstStar && fPBTime > fSecondStar)
	{
		stars = 1;
	}
	else if(fPBTime <= fSecondStar && fPBTime > fThirdStar)
	{
		stars = 2;
	}
	else if(fPBTime <= fThirdStar && fPBTime > fFourthStar)
	{
		stars = 3;
	}
	else if(fPBTime <= fFourthStar && fPBTime < fThirdStar)
	{
		stars = 4;
	}
	
	if(fWRTime == 0.0 || fPBTime == 0.0 || fPBTime > fFirstStar)
	{
		stars = 0;
	}
	
	char[] sQuery = new char[512];
	
	FormatEx(sQuery, 512, "UPDATE %splayertimes SET stars=%d WHERE auth='%s' AND map='%s' AND style='%d' AND track='%d';",
			gS_MySQLPrefix, stars, sAuthID, gS_Map, style, track);
	
	gH_SQL.Query(SQL_UpdatePlayerStars_Callback, sQuery, 0);
}

public void SQL_UpdatePlayerStars_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null)
	{
		LogError("ERROR: %s", error);
		return;
	}
	
	char[] sQuery = new char[512];
	
	FormatEx(sQuery, 256, "UPDATE %susers u INNER JOIN(SELECT auth, SUM(stars) starsum FROM %splayertimes GROUP BY auth) p ON u.auth=p.auth SET u.stars=p.starsum;",
			gS_MySQLPrefix, gS_MySQLPrefix);
	
	gH_SQL.Query(SQL_UpdateStars_Callback, sQuery, 0, DBPrio_Low);
}

public void SQL_UpdateStars_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null)
	{
		LogError("ERROR: %s", error);
		return;
	}
	
	char[] sQuery = new char[512];
	FormatEx(sQuery, 512, "SELECT auth, name, stars FROM %susers WHERE stars > 0 ORDER BY stars DESC LIMIT 100;", gS_MySQLPrefix);
	gH_SQL.Query(SQL_UpdateTopCollectors_Callback, sQuery, 0, DBPrio_Low);
}

public void SQL_UpdateTopCollectors_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null)
	{
		LogError("ERROR: %s", error);
		return;
	}
	
	if(gH_Top100Menu != null)
	{
		delete gH_Top100Menu;
	}
	
	gH_Top100Menu = new Menu(TopMenuHandler);
	
	int row = 0;
	
	while(results.FetchRow())
	{
		if(row > 100)
		{
			break;
		}
		
		char[] sAuthID = new char[32];
		results.FetchString(0, sAuthID, 32);
		
		char[] sName = new char[MAX_NAME_LENGTH];
		results.FetchString(1, sName, MAX_NAME_LENGTH);
		
		char[] sStars = new char[16];
		results.FetchString(2, sStars, 16);
		
		char[] sDisplay = new char[96];
		FormatEx(sDisplay, 96, "#%d - %s (%s stars)", (++row), sName, sStars);
		gH_Top100Menu.AddItem(sAuthID, sDisplay);
	}
	
	if(gH_Top100Menu.ItemCount == 0)
	{
		char[] sDisplay = new char[64];
		FormatEx(sDisplay, 64, "No collectors found!");
		gH_Top100Menu.AddItem("-1", sDisplay);
	}
	
	gH_Top100Menu.ExitButton = true;
}

void UpdatePlayerRank(int client)
{
	gI_Rank[client] = 0;
	gI_Stars[client] = 0;
	
	char[] sAuthID = new char[32];
	
	if(GetClientAuthId(client, AuthId_Steam3, sAuthID, 32))
	{
		char[] sQuery = new char[512];
		
		FormatEx(sQuery, 512, "SELECT COUNT(*) rank, p.stars FROM %susers u JOIN(SELECT stars FROM %susers WHERE auth = '%s' LIMIT 1) p WHERE u.stars >= p.stars LIMIT 1;",
				gS_MySQLPrefix, gS_MySQLPrefix, sAuthID);
		
		gH_SQL.Query(SQL_UpdatePlayerRank_Callback, sQuery, GetClientSerial(client), DBPrio_Low);
	}
}

public void SQL_UpdatePlayerRank_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null)
	{
		LogError("ERROR: %s", error);
		return;
	}
	
	int client = GetClientFromSerial(data);
	
	if(client == 0)
	{
		return;
	}
	
	if(results.FetchRow())
	{
		gI_Rank[client] = results.FetchInt(0);
		gI_Stars[client] = results.FetchInt(1);
	}
}
// }}}

// #OnMapFinished {{{
public void Shavit_OnFinish_Post(int client)
{
	CreateTimer(1.0, Timer_UpdateStars, GetClientSerial(client));
}

public Action Timer_UpdateStars(Handle timer, any data)
{
	int client = GetClientFromSerial(data);
	int track = Shavit_GetClientTrack(client);
	int style = Shavit_GetBhopStyle(client);
	
	UpdatePlayerStars(client, track, style);
	UpdatePlayerRank(client);
	
	return Plugin_Stop;
}
// }}}

// #Commands {{{
public Action Command_Stars(int client, int args)
{
	int track = Shavit_GetClientTrack(client);
	int style = Shavit_GetBhopStyle(client);
	
	float fWRTime = 0.0;
	Shavit_GetWRTime(style, fWRTime, track);
	
	float fFirstStar = float(RoundToFloor((fWRTime * gF_FirstStar) * 100)) / 100;
	float fSecondStar = float(RoundToFloor((fWRTime * gF_SecondStar) * 100)) / 100;
	float fThirdStar = float(RoundToFloor((fWRTime * gF_ThirdStar) * 100)) / 100;
	
	Shavit_PrintToChat(client, "Required times for stars:");
	PrintToChat(client, "★☆☆☆ - %.2f0", fFirstStar);
	PrintToChat(client, "★★☆☆ - %.2f0", fSecondStar);
	PrintToChat(client, "★★★☆ - %.2f0", fThirdStar);
	
	if(gF_FourthStar == 1.00)
	{
		PrintToChat(client, "★★★★ - WR");
	}
	else
	{
		float fFourthStar = float(RoundToFloor((fWRTime * gF_FourthStar) * 100)) / 100;
		PrintToChat(client, "★★★★ - %.2f0", fFourthStar);
	}
	
	return Plugin_Handled;
}

public Action Command_RankStars(int client, int args)
{
	int target = client;
	
	if(args > 0)
	{
		char[] sArgs = new char[MAX_TARGET_LENGTH];
		GetCmdArgString(sArgs, MAX_TARGET_LENGTH);
		
		target = FindTarget(client, sArgs, true, false);
		
		if(target == -1)
		{
			return Plugin_Handled;
		}
	}
	
	if(gI_Stars[target] == 0.0)
	{
		Shavit_PrintToChat(client, "%s%N%s hasn't collected any stars.", gS_ChatStrings[sMessageVariable2], target, gS_ChatStrings[sMessageText]);
		return Plugin_Handled;
	}
	
	Shavit_PrintToChat(client, "%s%N%s is ranked %s%d%s out of %d with %s%d%s stars.",
			gS_ChatStrings[sMessageVariable2], target, gS_ChatStrings[sMessageText],
			gS_ChatStrings[sMessageVariable], (gI_Rank[target] > gI_RankedPlayers)? gI_RankedPlayers:gI_Rank[target], gS_ChatStrings[sMessageText],
			gI_RankedPlayers,
			gS_ChatStrings[sMessageVariable], gI_Stars[target], gS_ChatStrings[sMessageText]);
	
	return Plugin_Handled;
}

public Action Command_TopStars(int client, int args)
{
	gH_Top100Menu.SetTitle("Top 100 star collectors: (%d)\n ", gI_RankedPlayers);
	gH_Top100Menu.Display(client, 60);
	return Plugin_Handled;
}

public int TopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char[] sInfo = new char[32];
		menu.GetItem(param2, sInfo, 32);
		
		if(gB_Stats && !StrEqual(sInfo, "-1"))
		{
			Shavit_OpenStatsMenu(param1, sInfo);
		}
	}
	
	return 0;
}
// }}}

// #StarHUD {{{
public Action UpdateHUD_Timer(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i) || IsFakeClient(i))
		{
			continue;
		}
		
		TriggerHUDUpdate(i);
	}
	
	return Plugin_Continue;
}

void TriggerHUDUpdate(int client)
{
	int target = GetHUDTarget(client);
	int style = Shavit_GetBhopStyle(target);
	int track = Shavit_GetClientTrack(target);
	
	GetRGBStyleColor(client, style);
	
	float fWR = 0.0;
	Shavit_GetWRTime(style, fWR, track);
	
	float fWRTime = 0.0;
	Shavit_GetWRTime(style, fWRTime, track);
	
	float fFirstStar = float(RoundToFloor((fWRTime * gF_FirstStar) * 100)) / 100;
	float fSecondStar = float(RoundToFloor((fWRTime * gF_SecondStar) * 100)) / 100;
	float fThirdStar = float(RoundToFloor((fWRTime * gF_ThirdStar) * 100)) / 100;
	float fFourthStar = 0.0;
	
	if(gF_FourthStar == 1.00)
	{
		fFourthStar = fWRTime + 0.005; // +0.005 because of rounding issues.
	}
	else
	{
		fFourthStar = float(RoundToFloor((fWRTime * gF_FourthStar) * 100)) / 100;
	}
	
	float fPBTime = 0.0;
	Shavit_GetPlayerPB(client, style, fPBTime, track);
	
	SetHudTextParams(-1.0, 0.935, 0.5, gI_RGBStyleColor[client][0], gI_RGBStyleColor[client][1], gI_RGBStyleColor[client][2], 255, 0, 0.0, 0.0, 0.0);
	
	if(fPBTime <= fFirstStar && fPBTime > fSecondStar)
	{
		ShowSyncHudText(client, gH_StarHUD, "★☆☆☆\n%s", gS_StyleStrings[style][sStyleName]);
	}
	else if(fPBTime <= fSecondStar && fPBTime > fThirdStar)
	{
		ShowSyncHudText(client, gH_StarHUD, "★★☆☆\n%s", gS_StyleStrings[style][sStyleName]);
	}
	else if(fPBTime <= fThirdStar && fPBTime > fFourthStar)
	{
		ShowSyncHudText(client, gH_StarHUD, "★★★☆\n%s", gS_StyleStrings[style][sStyleName]);
	}
	else if(fPBTime <= fFourthStar && fPBTime < fThirdStar)
	{
		ShowSyncHudText(client, gH_StarHUD, "★★★★\n%s", gS_StyleStrings[style][sStyleName]);
	}
	
	if(fWRTime == 0.0 || fPBTime == 0.0 || fPBTime > fFirstStar)
	{
		ShowSyncHudText(client, gH_StarHUD, "☆☆☆☆\n%s", gS_StyleStrings[style][sStyleName]);
	}
}

int GetHUDTarget(int client)
{
	int target = client;
	
	if(IsClientObserver(client))
	{
		int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		
		if(iObserverMode >= 3 && iObserverMode <= 5)
		{
			int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			
			if(IsValidClient(iTarget, true))
			{
				target = iTarget;
			}
		}
	}
	
	return target;
}

// Sh*t method.
void GetRGBStyleColor(int client, int style)
{
	int iRedA, iRedB, iGreenA, iGreenB, iBlueA, iBlueB;
	
	char[] sRedA = new char[2];
	strcopy(sRedA, 2, gS_StyleStrings[style][sHTMLColor][0]);
	
	char[] sRedB = new char[2];
	strcopy(sRedB, 2, gS_StyleStrings[style][sHTMLColor][1]);
	
	char[] sGreenA = new char[2];
	strcopy(sGreenA, 2, gS_StyleStrings[style][sHTMLColor][2]);
	
	char[] sGreenB = new char[2];
	strcopy(sGreenB, 2, gS_StyleStrings[style][sHTMLColor][3]);
	
	char[] sBlueA = new char[2];
	strcopy(sBlueA, 2, gS_StyleStrings[style][sHTMLColor][4]);
	
	char[] sBlueB = new char[2];
	strcopy(sBlueB, 2, gS_StyleStrings[style][sHTMLColor][5]);
	
	if(StringToInt(sRedA) == 0)
	{
		if(StrEqual(sRedA, "A")) iRedA = 10;
		if(StrEqual(sRedA, "B")) iRedA = 11;
		if(StrEqual(sRedA, "C")) iRedA = 12;
		if(StrEqual(sRedA, "D")) iRedA = 13;
		if(StrEqual(sRedA, "E")) iRedA = 14;
		if(StrEqual(sRedA, "F")) iRedA = 15;
	}
	else iRedA = StringToInt(sRedA);
	
	if(StringToInt(sRedB) == 0)
	{
		if(StrEqual(sRedB, "A")) iRedB = 10;
		if(StrEqual(sRedB, "B")) iRedB = 11;
		if(StrEqual(sRedB, "C")) iRedB = 12;
		if(StrEqual(sRedB, "D")) iRedB = 13;
		if(StrEqual(sRedB, "E")) iRedB = 14;
		if(StrEqual(sRedB, "F")) iRedB = 15;
	}
	else iRedB = StringToInt(sRedB);
	
	if(StringToInt(sGreenA) == 0)
	{
		if(StrEqual(sGreenA, "A")) iGreenA = 10;
		if(StrEqual(sGreenA, "B")) iGreenA = 11;
		if(StrEqual(sGreenA, "C")) iGreenA = 12;
		if(StrEqual(sGreenA, "D")) iGreenA = 13;
		if(StrEqual(sGreenA, "E")) iGreenA = 14;
		if(StrEqual(sGreenA, "F")) iGreenA = 15;
	}
	else iGreenA = StringToInt(sGreenA);
	
	if(StringToInt(sGreenB) == 0)
	{
		if(StrEqual(sGreenB, "A")) iGreenB = 10;
		if(StrEqual(sGreenB, "B")) iGreenB = 11;
		if(StrEqual(sGreenB, "C")) iGreenB = 12;
		if(StrEqual(sGreenB, "D")) iGreenB = 13;
		if(StrEqual(sGreenB, "E")) iGreenB = 14;
		if(StrEqual(sGreenB, "F")) iGreenB = 15;
	}
	else iGreenB = StringToInt(sGreenB);
	
	if(StringToInt(sBlueA) == 0)
	{
		if(StrEqual(sBlueA, "A")) iBlueA = 10;
		if(StrEqual(sBlueA, "B")) iBlueA = 11;
		if(StrEqual(sBlueA, "C")) iBlueA = 12;
		if(StrEqual(sBlueA, "D")) iBlueA = 13;
		if(StrEqual(sBlueA, "E")) iBlueA = 14;
		if(StrEqual(sBlueA, "F")) iBlueA = 15;
	}
	else iBlueA = StringToInt(sBlueA);
	
	if(StringToInt(sBlueB) == 0)
	{
		if(StrEqual(sBlueB, "A")) iBlueB = 10;
		if(StrEqual(sBlueB, "B")) iBlueB = 11;
		if(StrEqual(sBlueB, "C")) iBlueB = 12;
		if(StrEqual(sBlueB, "D")) iBlueB = 13;
		if(StrEqual(sBlueB, "E")) iBlueB = 14;
		if(StrEqual(sBlueB, "F")) iBlueB = 15;
	}
	else iBlueB = StringToInt(sBlueB);
	
	gI_RGBStyleColor[client][0] = iRedA * 16 + iRedB;
	gI_RGBStyleColor[client][1] = iGreenA * 16 + iGreenB;
	gI_RGBStyleColor[client][2] = iBlueA * 16 + iBlueB;
}
// }}}
