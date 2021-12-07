//#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <smlib>
#include <emitsoundany>
#include <colors_csgo>

#define FIRST 1
#define UNIT_TYPE 2
#define MAX 32
#define DB_NAME "advanced_noscop"
#define PREFIX "[{orange}Advanced Noscop{default}] "

ConVar cv_HudDistance = null;
ConVar cv_Music = null;
ConVar cv_Directory = null;
ConVar cv_Weapons = null;
ConVar cv_Volume = null;
ConVar cv_Unit = null;
ConVar cv_MinimumPlayer = null;
ConVar cv_EnableRank = null;
ConVar cv_PlayerTop = null;

int gI_Music;
int gI_MCount;
int gI_TotalPlayer = 0;
int gI_PlayerCount = 0;

float gF_Distance[MAXPLAYERS+1];

char gC_ClientAuth3[MAXPLAYERS+1][32];
char gC_Sound[MAX][128];
char gC_Chat[2][MAX];
char gC_CurrentMap[64];
char gC_Unit[UNIT_TYPE][MAX] =
{
	"meter",
	"mile"
};

Database gH_SQL = null;

//OLD SYNTAX//
enum NoscopData
{
	String:Attacker[20],
	String:Victim[20],
	String:Weapon[32],
	String:Map[64],
	Float:Distance,
	Rank,
}

Player[MAXPLAYERS+1][NoscopData];


public Plugin myinfo =
{
    name = "Advanced Noscop",
    author = "Mish0UU",
    description = "Advanced Noscop",
    version = "1.1.0",
    url = "www.balkanstar.fr"
};

public void OnPluginStart()
{	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_OnRoundStart);	
	HookEvent("player_spawn", Event_OnPlayerSpawn);	
	
	cv_HudDistance = CreateConVar("an_minimum_distance_hud", "15.0", "Minimum distance to show message in HUD", FCVAR_NOTIFY, true, 0.0, true, 160.0);
	cv_Music = CreateConVar("an_music_enable", "1", "Enable music when HUD is displayed", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_Directory = CreateConVar("an_music_path", "advanced_noscop", "Path of sounds directory example : sound/advanced_noscop/", FCVAR_NOTIFY);
	cv_Volume = CreateConVar("an_music_volume", "0.5", "Music volume", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_Weapons = CreateConVar("an_weapons_allowed", "3", "Allowed weapons: 1 = AWP Only | 2 = SSG08 Only | 3 = AWP + SSG08", FCVAR_NOTIFY, true, 1.0, true, 3.0);
	cv_Unit = CreateConVar("an_weapons_unit", "1", "Unit of length used: 1 = Meter | 2 = Miles", FCVAR_NOTIFY, true, 1.0, true, 2.0);
	cv_MinimumPlayer = CreateConVar("an_minimum_player", "6", "Minimum number of player to save noscop distance", FCVAR_NOTIFY);
	cv_EnableRank = CreateConVar("an_enable_rank", "1", "Enable/Disable rank/top features", FCVAR_NOTIFY, false, 0.0, true, 1.0);
	cv_PlayerTop = CreateConVar("an_show_player_top", "50", "Number of player to display on top", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	
	LoadTranslations("advanced_noscop.phrases");
	
	RegConsoleCmd("sm_mynoscop", Cmd_MyNoscop);
	RegConsoleCmd("sm_noscop", Cmd_TopNoscop);
	
	AutoExecConfig(true);	
	
	for(int unit = 0; unit < UNIT_TYPE; unit++)
		Format(gC_Chat[unit], 8, "%t", gC_Unit[unit]);
				
	if(cv_EnableRank.IntValue)
		SQL_DBConnect();					
}

public void OnConfigsExecuted() 
{
	if(!cv_EnableRank.BoolValue)
		return;
		
	if(gH_SQL == null)
		SQL_DBConnect();
}

public void OnMapStart()
{			
	GetCurrentMap(gC_CurrentMap, sizeof(gC_CurrentMap));
	loadSounds();
}

public Action Cmd_MyNoscop(int client, int args)
{
	if(!cv_EnableRank.IntValue)
		return;
		
	if(Player[client][Distance] != 0.0)
	{
		CPrintToChatAll("%s%t", PREFIX, "an_chat_mynoscop", client, Player[client][Rank], gI_TotalPlayer, Player[client][Distance], gC_Unit[cv_Unit.IntValue-1], (Player[client][Distance] > 1.0 ? "s" : ""));
	}
	else
	{
		CPrintToChat(client, "%s%t", PREFIX, "an_chat_need_noscop");	
	}
}

public Action Cmd_TopNoscop(int client, int args)
{
	if(!cv_EnableRank.IntValue)
		return;
		
	char query[256];
	FormatEx(query, sizeof(query), "SELECT name, distance FROM advanced_noscop WHERE map = '%s' AND distance > 0.0 ORDER BY distance DESC LIMIT 0,%d;", gC_CurrentMap, cv_PlayerTop.IntValue);
	gH_SQL.Query(DisplayTop_Callback, query, client);
}

public void DisplayTop_Callback(Database db, DBResultSet result, char[] error, any id)
{
	if(result == null)
	{
		LogError("[Advanced_Noscop] Query Fail: %s", error);
		return;
	}
	
	Menu menu = CreateMenu(MenuHandler_Top);
	
	char sTitle[64];
	FormatEx(sTitle, sizeof(sTitle), "Advanced Noscop: (%s)\n ", gC_CurrentMap);
	
	SetMenuTitle(menu, sTitle);

	int iCount = 0;

	while(result.FetchRow())
	{
		iCount++;

		char sName[MAX_NAME_LENGTH];
		result.FetchString(0, sName, MAX_NAME_LENGTH);	
		float distance = result.FetchFloat(1);

		char sDisplay[128];
		FormatEx(sDisplay, sizeof(sDisplay), "#%d - %s (%.2f %s%s)", iCount, sName, distance, gC_Chat[cv_Unit.IntValue-1], distance > 1.0 ? "s":"");
		menu.AddItem("0", sDisplay);
	}
	if(!iCount)
		AddMenuItem(menu, "-1", "No record");
		
	menu.ExitButton = true;
	menu.Display(id, 30);
}

public int MenuHandler_Top(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
}

public void Event_OnRoundStart(Handle event, const char[] name, bool dB)
{
	if(!cv_EnableRank.BoolValue)
		return;
	
	gI_PlayerCount = 0;
	for(int i = 1; i <= GetMaxClients(); i++) 
	{
		if(IsClientInGame(i) && GetClientTeam(i) > 1) 
			gI_PlayerCount++;
	}		
	CacheTotalPlayer();
}

public void Event_OnPlayerSpawn(Handle event, const char[] name, bool dB)
{
	if(!cv_EnableRank.BoolValue)
		return;
		
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return;
		
	CacheRankPlayer(client);
}

public void OnClientPutInServer(int client)
{
	if(!IsValidClient(client) || IsFakeClient(client) || gH_SQL == null || !cv_EnableRank.BoolValue)
		return;
		
	GetClientAuthId(client, AuthId_Steam3, gC_ClientAuth3[client], sizeof(gC_ClientAuth3));
	
	GetCurrentMap(Player[client][Map], 64);
	
	Player[client][Distance] = 0.0;
	Player[client][Rank] = -1;
	
	char query[256];
	FormatEx(query, sizeof(query), "SELECT distance FROM advanced_noscop WHERE auth = '%s' AND map = '%s';", gC_ClientAuth3[client], Player[client][Map]);

	gH_SQL.Query(CheckPlayer_Callback, query, GetClientSerial(client));
}



public void CheckPlayer_Callback(Database db, DBResultSet result, char[] error, any data)
{
	if(result == null)
	{
		LogError("[Advanced_Noscop] Query Fail: %s", error);
		return;
	}
	
	int id = GetClientFromSerial(data);
	
	if(!id)
		return;

	while(result.FetchRow())
	{
		Player[id][Distance] = result.FetchFloat(0);
		updateName(id);
		return;
	}	
	
	char userName[MAX_NAME_LENGTH];
	GetClientName(id, userName, sizeof(userName));
	
	int len = strlen(userName) * 2 + 1;
	char[] escapedName = new char[len];
	gH_SQL.Escape(userName, escapedName, len);

	len = strlen(gC_ClientAuth3[id]) * 2 + 1;
	char[] escapedSteamId = new char[len];
	gH_SQL.Escape(gC_ClientAuth3[id], escapedSteamId, len);
	
	char query[512];
	Format(query, sizeof(query), "INSERT INTO `advanced_noscop` (auth, name, distance, map) VALUES ('%s', '%s', '0', '%s') ON DUPLICATE KEY UPDATE name = '%s';", escapedSteamId, escapedName, gC_CurrentMap, escapedName);
	gH_SQL.Query(Nothing_Callback, query, id);
}		

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
	
	if(!IsValidClient(victim) || !IsValidClient(attacker))
		return;
	
	char weapons[32];
	GetEventString(event, "weapon", weapons, sizeof(weapons));
	
	if(cv_Weapons.IntValue == 1 && StrEqual(weapons, "ssg08"))
		return;
	if(cv_Weapons.IntValue == 2 && StrEqual(weapons, "awp"))
		return;
		
	if(!GetEntProp(attacker, Prop_Send, "m_bIsScoped") && (StrEqual(weapons, "awp") || StrEqual(weapons, "ssg08")))
	{	
		GetClientName(attacker, Player[attacker][Attacker], 20); 
		GetClientName(victim, Player[attacker][Victim], 20);
	
		float distance = Entity_GetDistance(victim, attacker);		
		if(cv_Unit.IntValue == 1)
		{
			distance = Math_UnitsToMeters(distance);
		}
		else
		{
			distance = Math_UnitsToMiles(distance);
		}		
		gF_Distance[attacker] = distance;	
		
		if(cv_EnableRank.BoolValue)
		{
			if(distance > Player[attacker][Distance])
			{
				if(gI_PlayerCount >= cv_MinimumPlayer.IntValue)
				{
					DB_UpdateNoscop(attacker);
				}
			}
		}
		FormatEx(Player[attacker][Weapon], 32, "%s", weapons);					
		CreateTimer(0.1, Timer_Message, attacker);			
	}
}

public void DB_UpdateNoscop(int client)
{
	char query[512];	
	FormatEx(query, sizeof(query), "UPDATE `advanced_noscop` SET distance = %f WHERE auth = '%s' AND map = '%s'", gF_Distance[client], gC_ClientAuth3[client], Player[client][Map]);
	gH_SQL.Query(UpdateKills_Callback, query, client);
}

public void UpdateKills_Callback(Database db, DBResultSet result, char[] error, any data)
{
	if(result == null)
	{
		LogError("[Advanced_Noscop] Query Fail: %s", error);
		return;
	}
	Player[data][Distance] = gF_Distance[data];
}

public Action Timer_Message(Handle timer, any userid)
{
	if(IsClientInGame(userid))
		SendMessageToAll(userid);		
}

void SendMessageToAll(int id)
{
	if(gF_Distance[id] >= cv_HudDistance.FloatValue)
	{	
		PrintHintTextToAll("%t", "an_hud_message", Player[id][Victim], Player[id][Attacker], gF_Distance[id], gC_Chat[cv_Unit.IntValue-1], (gF_Distance[id] > 1.0 ? "s":"")/*, (cv_MinimumPlayer.IntValue < gI_PlayerCount ? noSaved : "")*/);
		if(cv_Music.BoolValue)
		{
			EmitSoundToAllAny(gC_Sound[gI_Music], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, cv_Volume.FloatValue);
			gI_Music++;
			
			if(gI_Music > gI_MCount)
			{
				gI_Music = FIRST;
			}
		}
	}
	else
	{
		char noSaved[64];
		FormatEx(noSaved, sizeof(noSaved), "%t", "an_noscop_no_saved");
		
		CPrintToChatAll("%t", "an_chat_message", Player[id][Victim], Player[id][Attacker], gF_Distance[id], gC_Chat[cv_Unit.IntValue-1], (gF_Distance[id] > 1.0 ? "s":""), Player[id][Weapon], (gI_PlayerCount < cv_MinimumPlayer.IntValue ? noSaved : ""));
	}	
}

stock bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client));
}

void loadSounds()
{	
	gI_MCount = 0;
	
	char directory[PLATFORM_MAX_PATH];
	char path[PLATFORM_MAX_PATH];
	
	cv_Directory.GetString(directory, sizeof(directory));
	
	Format(path, sizeof(path), "sound/%s/", directory);
	DirectoryListing pluginsDir = OpenDirectory(path);
	
	if(pluginsDir != null)
	{
		char fileName[128];
		char soundName[512];
		while(pluginsDir.GetNext(fileName, sizeof(fileName)))
		{
			int fileExt = strlen(fileName) - 4;
			if(StrContains(fileName, ".mp3", false) == fileExt)
			{
				
				Format(soundName, sizeof(soundName), "sound/%s/%s", directory, fileName);
				AddFileToDownloadsTable(soundName);
				
				gI_MCount++;	
				
				Format(gC_Sound[gI_MCount], 2048, "%s", soundName);						
				ReplaceString(gC_Sound[gI_MCount], 128, "sound/", "");	
				
				PrecacheSoundAny(gC_Sound[gI_MCount], true);

			}
		}
	}
	gI_Music = GetRandomInt(FIRST, gI_MCount);	
}

void SQL_DBConnect()
{
	if(gH_SQL != null)
		delete gH_SQL;
		
	if(SQL_CheckConfig(DB_NAME))
	{
		Database.Connect(SQLConnect_Callback, DB_NAME);
	}
	else
	{
		LogError("[Advanced_Noscop] Startup failed. Error: %s", "\"advanced_noscop\" is not a specified entry in databases.cfg.");
	}
}

public void SQLConnect_Callback(Database db, char[] error, any data)
{
	if(db == null)
	{
		LogError("[Advanced_Noscop] Can't connect to server. Error: %s", error);
		return;
	}		
	gH_SQL = db;
	gH_SQL.Query(Nothing_Callback, "CREATE TABLE IF NOT EXISTS `advanced_noscop` (`auth` varchar(32) NOT NULL, `name` varchar(64) NOT NULL, `distance` float DEFAULT '0', `map` varchar(64) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8;", DBPrio_High);
}

public void Nothing_Callback(Database db, DBResultSet result, char[] error, any data)
{
	if(result == null)
		LogError("[Advanced_Noscop] Error: %s", error);
}

void updateName(int client)
{
	char userName[MAX_NAME_LENGTH];
	GetClientName(client, userName, sizeof(userName));
	
	int len = strlen(userName) * 2 + 1;
	char[] escapedName = new char[len];
	gH_SQL.Escape(userName, escapedName, len);

	len = strlen(gC_ClientAuth3[client]) * 2 + 1;
	char[] escapedSteamId = new char[len];
	gH_SQL.Escape(gC_ClientAuth3[client], escapedSteamId, len);

	char query[128];
	FormatEx(query, sizeof(query), "UPDATE `advanced_noscop` SET name = '%s' WHERE auth = '%s';", escapedName, escapedSteamId);
	gH_SQL.Query(Nothing_Callback, query, client);

}

void CacheTotalPlayer()
{
	gI_TotalPlayer = 0;
	
	char query[256];
	FormatEx(query, sizeof(query), "SELECT count(distinct auth) FROM `advanced_noscop` WHERE map = '%s';", gC_CurrentMap);
	gH_SQL.Query(CacheTotalPlayer_Callback, query, DBPrio_High);
}

public void CacheTotalPlayer_Callback(Database db, DBResultSet result, char[] error, any data)
{
	if(result == null)
	{
		LogError("[Advanced_Noscop] Query Fail: %s", error);
		return;
	}		
	while(result.FetchRow())
	{
		gI_TotalPlayer = result.FetchInt(0);
	}
}

void CacheRankPlayer(int client)
{
	char query[256];
	FormatEx(query, sizeof(query), "SELECT auth, distance FROM `advanced_noscop` WHERE distance >= %.2f AND map = '%s' ORDER BY distance DESC;", Player[client][Distance], gC_CurrentMap);
	gH_SQL.Query(CacheRankPlayer_Callback, query, client);
}

public void CacheRankPlayer_Callback(Database db, DBResultSet result, char[] error, any client)
{
	if(result == null)
	{
		LogError("[Advanced_Noscop] Query Fail: %s", error);
		return;
	}
	int count = 0;	
	
	while(result.FetchRow())
		count++;
		
	Player[client][Rank] = count;
}
