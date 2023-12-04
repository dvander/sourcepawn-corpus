#define PLUGIN_VERSION "2.9"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#tryinclude <hx_stats>

const int MAX_MARK = 6;
const int MAX_CAMPAIGN_NAME = 64;
const int MAX_CAMPAIGN_TITLE = 128;
const int MAX_MAP_NAME = 64;
const int MAP_RATING_ANY = -1;
const int MAP_GROUP_ANY = -1;

#define CVAR_FLAGS 			FCVAR_NOTIFY
#define LEN_CLASS			64	// Max UserMessage names string length

public Plugin myinfo = 
{
	name = "[L4D1 & L4D2] Map Changer",
	author = "Alex Dragokas",
	description = "Campaign and map chooser with rating system, groups and sorting",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
};

enum
{
	FINALE_CHANGE_NONE 				= 0,
	FINALE_CHANGE_VEHICLE_LEAVE 	= 1,
	FINALE_CHANGE_FINALE_WIN 		= 2,
	FINALE_CHANGE_CREDITS_START 	= 4,
	FINALE_CHANGE_CREDITS_END 		= 8
}

enum GAME_TYPE
{
	GAME_TYPE_NONE 		= -1,
	GAME_TYPE_COOP 		= 0,
	GAME_TYPE_VERSUS 	= 1,
	GAME_TYPE_SURVIVAL 	= 2
};

char GAME_TYPE_STR[][] =
{
	"coop",
	"versus",
	"survival"
};

KeyValues kv;
KeyValues kvinfo;

UserMsg StatsCrawlMsgId;

char mapListPath[PLATFORM_MAX_PATH];
char mapInfoPath[PLATFORM_MAX_PATH];
char voteBlockPath[PLATFORM_MAX_PATH];
char g_sLog[PLATFORM_MAX_PATH];
char g_Campaign[MAXPLAYERS+1][MAX_CAMPAIGN_NAME];
char g_sCurMap[MAX_MAP_NAME];
char g_sGameMode[32];
char g_sVoteResult[MAX_MAP_NAME];

int g_MapGroup[MAXPLAYERS+1];
int g_Rating[MAXPLAYERS+1];
int g_iVoteMark;

float g_fLastTime[MAXPLAYERS+1];

int iNumCampaignsGroup[3];
int iNumCampaignsCustom;

bool g_RatingMenu[MAXPLAYERS+1];
bool g_bLeft4Dead2;
bool g_bVeto;
bool g_bVotepass;
bool g_bVoteInProgress;
bool g_bVoteDisplayed;
bool g_bUMHooked;
bool g_bLateload;

StringMap g_hNameByMap;
StringMap g_hNameByMapCustom;
StringMap g_hCampaignByMap;
StringMap g_hCampaignByMapCustom;
StringMap g_hMapStamp;

ArrayList g_aMapOrder;
ArrayList g_aMapCustomOrder;
ArrayList g_aMapCustomFirst;
ArrayList g_hArrayVoteBlock;

ConVar g_hConVarGameMode;
ConVar g_hCvarDelay;
ConVar g_hCvarTimeout;
ConVar g_hCvarAnnounceDelay;
ConVar g_hCvarServerNameShort;
ConVar g_hCvarVoteMarkMinPlayers;
ConVar g_hCvarMapVoteAccessDef;
ConVar g_hCvarMapVoteAccessCustom;
ConVar g_ConVarHostName;
ConVar g_hCvarAllowDefault;
ConVar g_hCvarAllowCustom;
ConVar g_hCvarFinMapRandom;
ConVar g_hCvarVetoFlag;
ConVar g_hCvarChapterList;
ConVar g_hCvarFinaleChangeType;

Handle hDirectorChangeLevel;

Address TheDirector = Address_Null;

#if defined _hxstats_included
	bool g_bHxStatsAvail;
	ConVar g_hCvarVoteStatPoints;
	ConVar g_hCvarVoteStatPlayTime;
#else
	#pragma unused g_bLateload
#endif

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("MapChanger.phrases");
	
	CreateConVar("mapchanger_version", PLUGIN_VERSION, "MapChanger Version", FCVAR_DONTRECORD | CVAR_FLAGS);
	g_hCvarDelay = CreateConVar(				"l4d_mapchanger_delay",					"60",		"Minimum delay (in sec.) allowed between votes\n投票之間最小要間隔多久 (以秒為單位)。", CVAR_FLAGS );
	g_hCvarTimeout = CreateConVar(				"l4d_mapchanger_timeout",				"10",		"How long (in sec.) does the vote last\n投票持續多長時間 (以秒為單位)。", CVAR_FLAGS );
	g_hCvarAnnounceDelay = CreateConVar(		"l4d_mapchanger_announcedelay",			"2.0",		"Delay (in sec.) between announce and vote menu appearing\n公告和投票選單出現之間的間隔 (以秒為單位)。", CVAR_FLAGS );
	g_hCvarAllowDefault = CreateConVar(			"l4d_mapchanger_allow_default",			"1",		"Display default maps menu items? (1 - Yes, 0 - No)\n顯示預設地圖選項? (1 - 是, 0 - 否)。", CVAR_FLAGS );
	g_hCvarAllowCustom = CreateConVar(			"l4d_mapchanger_allow_custom",			"1",		"Display custom maps menu items? (1 - Yes, 0 - No)\n顯示第三方地圖選項? (1 - 是, 0 - 否)。", CVAR_FLAGS );
	g_hCvarServerNameShort = CreateConVar(		"l4d_mapchanger_servername_short", 		"", 		"Short name of your server (specify it, if you want custom campaign name will be prepended to it)\n您伺服器的簡稱 (如果您想要新增自定義活動的名稱，請在裡面輸入)。", CVAR_FLAGS);
	g_hCvarVoteMarkMinPlayers = CreateConVar(	"l4d_mapchanger_votemark_minplayers", 	"3", 		"Minimum number of players to allow starting the vote for mark (rating)\n允許開始對地圖評價進行投票的最少玩家數量。", CVAR_FLAGS);
	g_hCvarMapVoteAccessDef = CreateConVar(		"l4d_mapchanger_default_voteaccess", 	"kp", 		"Flag(s) allowed to access the vote for change to default maps\n允許進行更改預設地圖投票的權限。", CVAR_FLAGS);
	g_hCvarMapVoteAccessCustom = CreateConVar(	"l4d_mapchanger_custom_voteaccess", 	"k", 		"Flag(s) allowed to access the vote for change to custom maps\n允許進行更改第三方地圖投票的權限。", CVAR_FLAGS);
	g_hCvarVetoFlag = CreateConVar(				"l4d_mapchanger_vetoaccess",			"d",		"Flag(s) allowed to veto/votepass the vote\n允許 否決/通過 投票的權限。", CVAR_FLAGS );
	g_hCvarFinMapRandom = CreateConVar(			"l4d_mapchanger_fin_map_random", 		"1", 		"Choose the next map of custom campaign randomly? (1 - Yes, 0 - No)\n隨機更換第三方地圖戰役? (1 - 測試中, 0 - 否)。", CVAR_FLAGS);
	g_hCvarChapterList = CreateConVar(			"l4d_mapchanger_show_chapter_list", 	"1", 		"Show the list of chapters within campaign? (1 - Yes, 0 - No)\n是否顯示地圖中的章節? (1 - 是, 0 - 否)", CVAR_FLAGS);
	g_hCvarFinaleChangeType = CreateConVar(		"l4d_mapchanger_finale_change_type", 	"12", 		"0 - Don't change finale map (drop to lobby); 1 - instant on vehicle leaving; 2 - instant on finale win; 4 - Wait till credits screen appear; 8 - Wait till credits screen ends\n0 - 不要更改地圖(回到大廳); 1 - 車輛逃離瞬間; 2 - 最後獲勝的瞬間; 4 - 等到成績畫面出現; 8 - 等到成績畫面結束", CVAR_FLAGS);
	
	#if defined _hxstats_included
		g_hCvarVoteStatPoints = CreateConVar(		"l4d_mapchanger_vote_stat_points",		"10000",	"Minimum points in statistics system required to allow start the vote\n在統計系統中要開始投票最低需要多少點數", CVAR_FLAGS );
		g_hCvarVoteStatPlayTime = CreateConVar(		"l4d_mapchanger_vote_stat_playtime",	"600",		"Minimum play time (in minutes) in statistics system required to allow start the vote\n在統計系統中要開始投票時最短的公告時間(以分鐘為單位)", CVAR_FLAGS );
		
		if( g_bLateload )
		{
			g_bHxStatsAvail = (GetFeatureStatus(FeatureType_Native, "HX_GetPoints") == FeatureStatus_Available);
		}
	#endif
	
	AutoExecConfig(true, "l4d_mapchanger");
	
	StatsCrawlMsgId = view_as<UserMsg>(g_bLeft4Dead2 ? 43 : 39);
	
	if( (g_hConVarGameMode = FindConVar("mp_gamemode")) == null )
		SetFailState("Failed to find convar handle 'mp_gamemode'. Cannot load plugin.");
	
	g_ConVarHostName = FindConVar("hostname");
	
	g_hConVarGameMode.AddChangeHook(ConVarChangedCallback);
	g_hConVarGameMode.GetString(g_sGameMode, sizeof(g_sGameMode));
	
	RegConsoleCmd("sm_maps", 		Command_MapChoose, 					"Show map list to begin vote for changelevel / set mark etc.");
	RegConsoleCmd("sm_veto", 		Command_Veto, 		 				"Allow admin to veto current vote.");
	RegConsoleCmd("sm_votepass", 	Command_Votepass, 	 				"Allow admin to bypass current vote.");
	
	RegAdminCmd("sm_maps_reload", 	Command_ReloadMaps, ADMFLAG_ROOT, 	"Refresh the list of maps");
	
	HookEvent("round_start", 			Event_RoundStart);
	HookEvent("finale_win", 			Event_FinaleWin, 		EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving",	Event_VehicleLeaving,	EventHookMode_PostNoCopy);
	
	BuildPath(Path_SM, mapListPath, PLATFORM_MAX_PATH, "configs/%s", g_bLeft4Dead2 ? "MapChanger.l4d2.txt" : "MapChanger.l4d1.txt");
	BuildPath(Path_SM, mapInfoPath, PLATFORM_MAX_PATH, "configs/MapChanger_info.txt");
	BuildPath(Path_SM, voteBlockPath, PLATFORM_MAX_PATH, "data/mapchanger_vote_block.txt");
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/vote_map.log");
	
	g_aMapOrder = new ArrayList(ByteCountToCells(MAX_MAP_NAME));
	g_aMapCustomOrder = new ArrayList(ByteCountToCells(MAX_MAP_NAME));
	g_aMapCustomFirst = new ArrayList(ByteCountToCells(MAX_MAP_NAME));
	g_hArrayVoteBlock = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	
	g_hNameByMap = new StringMap();
	g_hNameByMapCustom = new StringMap();
	g_hCampaignByMap = new StringMap();
	g_hCampaignByMapCustom = new StringMap();
	g_hMapStamp = new StringMap();
	
	if( g_bLeft4Dead2 ) {
		AddMap("#L4D360UI_CampaignName_C1", "#L4D360UI_LevelName_COOP_C1M1", "c1m1_hotel");
		AddMap("#L4D360UI_CampaignName_C1", "#L4D360UI_LevelName_COOP_C1M2", "c1m2_streets");
		AddMap("#L4D360UI_CampaignName_C1", "#L4D360UI_LevelName_COOP_C1M3", "c1m3_mall");
		AddMap("#L4D360UI_CampaignName_C1", "#L4D360UI_LevelName_COOP_C1M4", "c1m4_atrium");
		AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M1", "c2m1_highway");
		AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M2", "c2m2_fairgrounds");
		AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M3", "c2m3_coaster");
		AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M4", "c2m4_barns");
		AddMap("#L4D360UI_CampaignName_C2", "#L4D360UI_LevelName_COOP_C2M5", "c2m5_concert");
		AddMap("#L4D360UI_CampaignName_C3", "#L4D360UI_LevelName_COOP_C3M1", "c3m1_plankcountry");
		AddMap("#L4D360UI_CampaignName_C3", "#L4D360UI_LevelName_COOP_C3M2", "c3m2_swamp");
		AddMap("#L4D360UI_CampaignName_C3", "#L4D360UI_LevelName_COOP_C3M3", "c3m3_shantytown");
		AddMap("#L4D360UI_CampaignName_C3", "#L4D360UI_LevelName_COOP_C3M4", "c3m4_plantation");
		AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M1", "c4m1_milltown_a");
		AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M2", "c4m2_sugarmill_a");
		AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M3", "c4m3_sugarmill_b");
		AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M4", "c4m4_milltown_b");
		AddMap("#L4D360UI_CampaignName_C4", "#L4D360UI_LevelName_COOP_C4M5", "c4m5_milltown_escape");
		AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M1", "c5m1_waterfront");
		AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M2", "c5m2_park");
		AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M3", "c5m3_cemetery");
		AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M4", "c5m4_quarter");
		AddMap("#L4D360UI_CampaignName_C5", "#L4D360UI_LevelName_COOP_C5M5", "c5m5_bridge");
		AddMap("#L4D360UI_CampaignName_C6", "#L4D360UI_LevelName_COOP_C6M1", "c6m1_riverbank");
		AddMap("#L4D360UI_CampaignName_C6", "#L4D360UI_LevelName_COOP_C6M2", "c6m2_bedlam");
		AddMap("#L4D360UI_CampaignName_C6", "#L4D360UI_LevelName_COOP_C6M3", "c6m3_port");
		AddMap("#L4D360UI_CampaignName_C7", "#L4D360UI_LevelName_COOP_C7M1", "c7m1_docks");
		AddMap("#L4D360UI_CampaignName_C7", "#L4D360UI_LevelName_COOP_C7M2", "c7m2_barge");
		AddMap("#L4D360UI_CampaignName_C7", "#L4D360UI_LevelName_COOP_C7M3", "c7m3_port");
		AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M1", "c8m1_apartment");
		AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M2", "c8m2_subway");
		AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M3", "c8m3_sewers");
		AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M4", "c8m4_interior");
		AddMap("#L4D360UI_CampaignName_C8", "#L4D360UI_LevelName_COOP_C8M5", "c8m5_rooftop");
		AddMap("#L4D360UI_CampaignName_C9", "#L4D360UI_LevelName_COOP_C9M1", "c9m1_alleys");
		AddMap("#L4D360UI_CampaignName_C9", "#L4D360UI_LevelName_COOP_C9M2", "c9m2_lots");
		AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M1", "c10m1_caves");
		AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M2", "c10m2_drainage");
		AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M3", "c10m3_ranchhouse");
		AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M4", "c10m4_mainstreet");
		AddMap("#L4D360UI_CampaignName_C10", "#L4D360UI_LevelName_COOP_C10M5", "c10m5_houseboat");
		AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M1", "c11m1_greenhouse");
		AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M2", "c11m2_offices");
		AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M3", "c11m3_garage");
		AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M4", "c11m4_terminal");
		AddMap("#L4D360UI_CampaignName_C11", "#L4D360UI_LevelName_COOP_C11M5", "c11m5_runway");
		AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M1", "C12m1_hilltop");
		AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M2", "C12m2_traintunnel");
		AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M3", "C12m3_bridge");
		AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M4", "C12m4_barn");
		AddMap("#L4D360UI_CampaignName_C12", "#L4D360UI_LevelName_COOP_C12M5", "C12m5_cornfield");
		AddMap("#L4D360UI_CampaignName_C13", "#L4D360UI_LevelName_COOP_C13M1", "c13m1_alpinecreek");
		AddMap("#L4D360UI_CampaignName_C13", "#L4D360UI_LevelName_COOP_C13M2", "c13m2_southpinestream");
		AddMap("#L4D360UI_CampaignName_C13", "#L4D360UI_LevelName_COOP_C13M3", "c13m3_memorialbridge");
		AddMap("#L4D360UI_CampaignName_C13", "#L4D360UI_LevelName_COOP_C13M4", "c13m4_cutthroatcreek");
		AddMap("#L4D360UI_CampaignName_C14", "#L4D360UI_LevelName_COOP_C14M1", "c14m1_junkyard");
		AddMap("#L4D360UI_CampaignName_C14", "#L4D360UI_LevelName_COOP_C14M2", "c14m2_lighthouse");
	}
	else {
		AddMap("No_Mercy", "#L4D360UI_Chapter_01_1", "l4d_hospital01_apartment");
		AddMap("No_Mercy", "#L4D360UI_Chapter_01_2", "l4d_hospital02_subway");
		AddMap("No_Mercy", "#L4D360UI_Chapter_01_3", "l4d_hospital03_sewers");
		AddMap("No_Mercy", "#L4D360UI_Chapter_01_4", "l4d_hospital04_interior");
		AddMap("No_Mercy", "#L4D360UI_Chapter_01_5", "l4d_hospital05_rooftop");
		AddMap("Crash_Course", "#L4D360UI_Chapter_02_1", "l4d_garage01_alleys");
		AddMap("Crash_Course", "#L4D360UI_Chapter_02_2", "l4d_garage02_lots");
		AddMap("Death_Toll", "#L4D360UI_Chapter_03_1", "l4d_smalltown01_caves");
		AddMap("Death_Toll", "#L4D360UI_Chapter_03_2", "l4d_smalltown02_drainage");
		AddMap("Death_Toll", "#L4D360UI_Chapter_03_3", "l4d_smalltown03_ranchhouse");
		AddMap("Death_Toll", "#L4D360UI_Chapter_03_4", "l4d_smalltown04_mainstreet");
		AddMap("Death_Toll", "#L4D360UI_Chapter_03_5", "l4d_smalltown05_houseboat");
		AddMap("Dead_Air", "#L4D360UI_Chapter_04_1", "l4d_airport01_greenhouse");
		AddMap("Dead_Air", "#L4D360UI_Chapter_04_2", "l4d_airport02_offices");
		AddMap("Dead_Air", "#L4D360UI_Chapter_04_3", "l4d_airport03_garage");
		AddMap("Dead_Air", "#L4D360UI_Chapter_04_4", "l4d_airport04_terminal");
		AddMap("Dead_Air", "#L4D360UI_Chapter_04_5", "l4d_airport05_runway");
		AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_1", "l4d_farm01_hilltop");
		AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_2", "l4d_farm02_traintunnel");
		AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_3", "l4d_farm03_bridge");
		AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_4", "l4d_farm04_barn");
		AddMap("Blood_Harvest", "#L4D360UI_Chapter_05_5", "l4d_farm05_cornfield");
		AddMap("Sacrifice", "#L4D360UI_Chapter_06_1", "l4d_river01_docks");
		AddMap("Sacrifice", "#L4D360UI_Chapter_06_2", "l4d_river02_barge");
		AddMap("Sacrifice", "#L4D360UI_Chapter_06_3", "l4d_river03_port");
		//AddMap("Last_Stand", "#L4D360UI_Chapter_07_1", "l4d_sv_lighthouse");
	}
	
	if( g_bLeft4Dead2 )
	{
		PrepareSig();
	}
	
	RegAdminCmd("sm_mapnext", CmdNextMap, ADMFLAG_ROOT, "Force change level to the next map");
	
	HookUserMessage(GetUserMessageId("DisconnectToLobby"), OnDisconnectToLobby, true);
}

public Action CmdNextMap(int client, int args)
{
	FinaleMapChange();
	return Plugin_Handled;
}

void PrepareSig()
{
	Handle hGamedata = LoadGameConfigFile("l4d_mapchanger");
	if( hGamedata == null )
		SetFailState("Failed to load \"l4d_mapchanger.txt\" gamedata.");
	
	StartPrepSDKCall(SDKCall_Raw);
	if( !PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CDirector::OnChangeChapterVote") )
		SetFailState("Error finding the 'CDirector::OnChangeChapterVote' signature.");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	
	hDirectorChangeLevel = EndPrepSDKCall();
	if( hDirectorChangeLevel == null )
		SetFailState("Unable to prep SDKCall 'CDirector::OnChangeChapterVote'");
	
	TheDirector = GameConfGetAddress(hGamedata, "CDirector");
	if( TheDirector == Address_Null )
		SetFailState("Unable to get 'CDirector' Address");
	
	delete hGamedata;
}

#if defined _hxstats_included
public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "hx_stats") == 0 )
	{
		g_bHxStatsAvail = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "hx_stats") == 0 )
	{
		g_bHxStatsAvail = false;
	}
}
#endif

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("[MapChanger] Current map is: %s (new round)", g_sCurMap);
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	if( g_hCvarFinaleChangeType.IntValue & FINALE_CHANGE_FINALE_WIN )
	{
		FinaleMapChange();
	}
	if( !g_bUMHooked )
	{
		HookUserMessageCredits();
	}
}

public void Event_VehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	if( g_hCvarFinaleChangeType.IntValue & FINALE_CHANGE_VEHICLE_LEAVE )
	{
		FinaleMapChange();
	}
	if( !g_bUMHooked )
	{
		HookUserMessageCredits();
	}
}

void HookUserMessageCredits()
{
	if( g_hCvarFinaleChangeType.IntValue & FINALE_CHANGE_CREDITS_START )
	{
		g_bUMHooked = true;
		HookUserMessage(StatsCrawlMsgId, OnCreditsScreen, false);
	}
}

public Action OnCreditsScreen(UserMsg msg_id, BfRead hMsg, const int[] players, int playersNum, bool reliable, bool init)
{
	UnhookUserMessage(StatsCrawlMsgId, OnCreditsScreen, false);
	g_bUMHooked = false;
	FinaleMapChange();
}

public Action OnDisconnectToLobby(UserMsg msg_id, BfRead hMsg, const int[] players, int playersNum, bool reliable, bool init)
{
	if( g_hCvarFinaleChangeType.IntValue & FINALE_CHANGE_CREDITS_END )
	{
		FinaleMapChange();
	}
	return Plugin_Handled;
}

void ReadFileToArrayList(char[] sPath, ArrayList list)
{
	static char str[MAX_NAME_LENGTH];
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		SetFailState("Failed to open file: \"%s\". You are missing at installing!", sPath);
	}
	else {
		list.Clear();
		while( !hFile.EndOfFile() && hFile.ReadLine(str, sizeof(str)) )
		{
			TrimString(str);
			list.PushString(str);
		}
		delete hFile;
	}
}

public void OnMapStart()
{
	static int ft_block;
	
	int ft = GetFileTime(voteBlockPath, FileTime_LastChange);
	if( ft != ft_block )
	{
		ft_block = ft;
		ReadFileToArrayList(voteBlockPath, g_hArrayVoteBlock);
	}
	
	Command_ReloadMaps(0, 0);
	GetCurrentMap(g_sCurMap, sizeof(g_sCurMap));
	PrintToServer("[MapChanger] Current map is: %s", g_sCurMap);
	CreateTimer(5.0, Timer_ChangeHostName, _, TIMER_FLAG_NO_MAPCHANGE);
	g_bUMHooked = false;
}

public Action Timer_ChangeHostName(Handle timer)
{
	static char sSrv[64];
	static char sShort[48];
	char sCampaign[64], sCampaignTr[64];
	bool bCustom = false;
	
	g_hCvarServerNameShort.GetString(sShort, sizeof(sShort));
	if( sShort[0] == '\0' )
		return;
	
	if( g_hCampaignByMap.GetString(g_sCurMap, sCampaign, sizeof(sCampaign)) ) {
	}
	else {
		g_hCampaignByMapCustom.GetString(g_sCurMap, sCampaignTr, sizeof(sCampaignTr));
		bCustom = true;
	}
	
	if( bCustom ) {
		FormatEx(sSrv, sizeof(sSrv), "%s | %s", sShort, sCampaignTr);
	}
	else {
		strcopy(sSrv, sizeof(sSrv), sShort);
	}
	g_ConVarHostName.SetString(sSrv);
}

public void OnAllPluginsLoaded()
{
	AddCommandListener(CheckVote, "callvote");
}

public Action CheckVote(int client, char[] command, int args)
{
	static char s[32];
	if( args >= 2 ) {
		GetCmdArg(1, s, sizeof(s));
		if( strcmp(s, "ChangeMission", false) == 0 ) {
			Command_MapChoose(client, 0);
			return Plugin_Stop;
		}
		else if( strcmp(s, "ChangeChapter", false) == 0 ) {
			Command_MapChoose(client, 0);
			return Plugin_Stop;
		}
	}
	if( args >= 1 ) {
		GetCmdArg(1, s, sizeof(s));
		if( strcmp(s, "RestartGame", false) == 0 ) {
			Command_MapChoose(client, 0);
			return Plugin_Stop;
		}
		else if( strcmp(s, "ReturnToLobby", false) == 0 ) {
			Command_MapChoose(client, 0);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public void ConVarChangedCallback (ConVar convar, const char[] oldValue, const char[] newValue)
{
	strcopy(g_sGameMode, sizeof(g_sGameMode), newValue);
	Command_ReloadMaps(0, 0);
}

void AddMap(char[] sCampaign, char[] sDisplay, char[] sMap)
{
	g_hNameByMap.SetString(sMap, sDisplay, false);
	g_hCampaignByMap.SetString(sMap, sCampaign, false);
	g_aMapOrder.PushString(sMap);
}

public Action Command_Veto(int client, int args)
{
	if( g_bVoteInProgress ) { // IsVoteInProgress() is not working here, sm bug?
		if( !HasVetoAccessFlag(client) )
		{
			ReplyToCommand(client, "%t", "no_access");
			return Plugin_Handled;
		}
		g_bVeto = true;
		CPrintToChatAll("%t", "veto", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[VETO]");
	}
	return Plugin_Handled;
}

public Action Command_Votepass(int client, int args)
{
	if( g_bVoteInProgress ) {
		if( !HasVetoAccessFlag(client) )
		{
			ReplyToCommand(client, "%t", "no_access");
			return Plugin_Handled;
		}
		g_bVotepass = true;
		CPrintToChatAll("%t", "votepass", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[PASS]");
	}
	return Plugin_Handled;
}

public Action Command_ReloadMaps(int client, int args)
{
	if( IsAddonChanged() )
	{
		GetAddonMissions();
	}
	if( !kv )
	{
		kv = new KeyValues("campaigns");
	}
	kvinfo = new KeyValues("info");
	if( FileExists(mapInfoPath) )
	{
		if( !kvinfo.ImportFromFile(mapInfoPath) )
		{
			SetFailState("[SM] ERROR: MapChanger - Incorrectly formatted file, '%s'", mapInfoPath);
		}
	}
	Actualize_MapChangerInfo();
	return Plugin_Handled;
}

bool IsAddonChanged()
{
	char addonFile[PLATFORM_MAX_PATH];
	FileType fileType;
	int iLen, iStamp, iOldStamp;
	DirectoryListing hDir;
	bool bChanged;
	char Paths[][] = {
		"addons", "addons/workshop"
	};
	for( int i = 0; i < sizeof(Paths); i++ )
	{
		hDir = OpenDirectory(Paths[i], false);
		if( hDir )
		{
			while( hDir.GetNext(addonFile, PLATFORM_MAX_PATH, fileType) )
			{
				if( fileType == FileType_File )
				{
					iLen = strlen(addonFile);
					
					if( iLen >= 4 && strcmp(addonFile[iLen - 4], ".vpk") == 0 )
					{
						Format(addonFile, sizeof(addonFile), "%s/%s", Paths[i], addonFile);
						iStamp = GetFileTime(addonFile, FileTime_Created);
						
						if( !g_hMapStamp.GetValue(addonFile, iOldStamp) || iStamp != iOldStamp )
						{
							bChanged = true;
						}
						g_hMapStamp.SetValue(addonFile, iStamp);
					}
				}
			}
			delete hDir;
		}
	}
	return bChanged;
}

void Actualize_MapChangerInfo()
{
	kv.Rewind();
	kv.GotoFirstSubKey();
	
	static char sCampaign[MAX_CAMPAIGN_NAME], map[MAX_MAP_NAME], DisplayName[MAX_CAMPAIGN_TITLE];
	ArrayList Compaigns = new ArrayList(50, 50);
	bool fWrite = false;

	kvinfo.Rewind();
	if( kvinfo.JumpToKey("campaigns") )
	{
		if( kvinfo.GotoFirstSubKey() )
		{
			do
			{
				kvinfo.GetSectionName(sCampaign, sizeof(sCampaign)); // retrieve campaign names
				Compaigns.PushString(sCampaign);
			} while( kvinfo.GotoNextKey() );
		}
	}
	
	int iGrp;
	static char sGrp[4];
	iNumCampaignsCustom = 0;
	for( int i = 0; i < sizeof(iNumCampaignsGroup); i++ )
		iNumCampaignsGroup[i] = 0;
	
	g_aMapCustomOrder.Clear();
	g_aMapCustomFirst.Clear();
	
	do
	{
		kv.GetSectionName(sCampaign, sizeof(sCampaign)); // compare to full list

		kvinfo.GoBack();
		kvinfo.JumpToKey(sCampaign, true);
		
		if( -1 == Compaigns.FindString(sCampaign) )
		{
			kvinfo.SetString("group", "0");
			kvinfo.SetString("mark", "0");
			iGrp = 0;
			fWrite = true;
		}
		else {
			kvinfo.GetString("group", sGrp, sizeof(sGrp), "0");
			iGrp = StringToInt(sGrp);
		}
		
		if( IsValidMapKv() )
		{
			FillCustomCampaignOrder();
			iNumCampaignsGroup[iGrp]++;
		}
		
	} while( kv.GotoNextKey() );
	delete Compaigns;
	
	if( fWrite )
	{
		kvinfo.Rewind();
		kvinfo.ExportToFile(mapInfoPath);
	}
	
	for( int i = 0; i < sizeof(iNumCampaignsGroup); i++ )
		iNumCampaignsCustom += iNumCampaignsGroup[i];
	
	// fill StringMaps
	kv.Rewind();
	kv.GotoFirstSubKey();
	do
	{
		kv.GetSectionName(sCampaign, sizeof(sCampaign));
		
		if( !kv.JumpToKey(g_sGameMode) )
		{
			if( !kv.JumpToKey("coop") ) // default
				continue;
		}
		
		if( kv.GotoFirstSubKey() ) {
			do
			{
				kv.GetString("Map", map, sizeof(map), "error");
				if( strcmp(map, "error") != 0 )
				{
					kv.GetString("DisplayName", DisplayName, sizeof(DisplayName), "error");
					if( strcmp(DisplayName, "error") != 0 )
					{
						g_hNameByMapCustom.SetString(map, DisplayName, false);
						g_hCampaignByMapCustom.SetString(map, sCampaign, false);
					}
				}
			} while( kv.GotoNextKey() );
			kv.GoBack();
		}
		kv.GoBack();
		
	} while( kv.GotoNextKey() );
}

stock char[] Translate(int client, const char[] format, any ...)
{
	static char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

public Action Command_MapChoose(int client, int args)
{
	static char sDisplay[64], sDisplayTr[64], sCampaign[64], sCampaignTr[64];
	int iCurMapNumber, iTotalMapsNumber;
	bool bCustom = false;
	
	Menu menu = new Menu(Menu_MapTypeHandler, MENU_ACTIONS_DEFAULT);
	
	if( g_hCampaignByMap.GetString(g_sCurMap, sCampaign, sizeof(sCampaign)) )
	{
		g_hNameByMap.GetString(g_sCurMap, sDisplay, sizeof(sDisplay));
		FormatEx(sCampaignTr, sizeof(sCampaignTr), "%T", sCampaign, client);
		FormatEx(sDisplayTr, sizeof(sDisplayTr), "%T", sDisplay, client);
	}
	else {
		g_hCampaignByMapCustom.GetString(g_sCurMap, sCampaignTr, sizeof(sCampaignTr));
		g_hNameByMapCustom.GetString(g_sCurMap, sDisplayTr, sizeof(sDisplayTr));
		GetMapNumber(sCampaignTr, g_sCurMap, iCurMapNumber, iTotalMapsNumber);
		bCustom = true;
	}
	
	if( bCustom ) {
		menu.SetTitle( "%T: [%i/%i] %s - %s", "Current_map", client, iCurMapNumber, iTotalMapsNumber, sCampaignTr, sDisplayTr); // Current map: %s - %s
	}
	else {
		menu.SetTitle( "%T: %s - %s", "Current_map", client, sCampaignTr, sDisplayTr); // Current map: %s - %s
	}
	
	if( g_hCvarAllowDefault.BoolValue )
	{
		menu.AddItem("default", Translate(client, "%t", "Default_maps")); 	// Стандартные карты
	}
	
	if( g_hCvarAllowCustom.BoolValue )
	{
		if( iNumCampaignsGroup[1] != 0 )
			menu.AddItem("group1", Translate(client, "%t", "Custom_maps_1")); 	// Доп. карты  << набор № 1 >>
			
		if( iNumCampaignsGroup[2] != 0 )
			menu.AddItem("group2", Translate(client, "%t", "Custom_maps_2")); 	// Доп. карты  << набор № 2 >>
		
		if( iNumCampaignsGroup[0] != 0 )
			menu.AddItem("group0", Translate(client, "%t", "Test_maps")); 		// Тестовые карты
		
		if( iNumCampaignsGroup[0] || iNumCampaignsGroup[1] || iNumCampaignsGroup[2] )
			menu.AddItem("group_all", Translate(client, "%t", "All_maps")); 		// Все карты
		
		if( iNumCampaignsCustom != 0 )
			menu.AddItem("rating", Translate(client, "%t", "By_rating")); 		// По рейтингу
	}
	menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int Menu_MapTypeHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			static char sgroup[32];
			menu.GetItem(ItemIndex, sgroup, sizeof(sgroup));

			if( strcmp(sgroup, "default") == 0 ) {
				g_MapGroup[client] = MAP_GROUP_ANY;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateDefcampaignMenu(client);
			}
			else if( strcmp(sgroup, "rating") == 0 ) {
				g_MapGroup[client] = MAP_GROUP_ANY;
				g_RatingMenu[client] = true;
				CreateMenuRating(client);
			}
			else if( strcmp(sgroup, "group0") == 0 ) {
				g_MapGroup[client] = 0;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateMenuCampaigns(client, 0, MAP_RATING_ANY);
			}
			else if( strcmp(sgroup, "group1") == 0 ) {
				g_MapGroup[client] = 1;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateMenuCampaigns(client, 1, MAP_RATING_ANY);
			}
			else if( strcmp(sgroup, "group2") == 0 ) {
				g_MapGroup[client] = 2;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateMenuCampaigns(client, 2, MAP_RATING_ANY);
			}
			else if( strcmp(sgroup, "group_all") == 0 ) {
				g_MapGroup[client] = MAP_GROUP_ANY;
				g_Rating[client] = MAP_RATING_ANY;
				g_RatingMenu[client] = false;
				CreateMenuCampaigns(client, -1, MAP_RATING_ANY);
			}
		}
	}
}

void CreateMenuRating(int client)
{
	Menu menu = new Menu(Menu_RatingHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "Rating_value_ask", client); 			// - Кампании с каким рейтингом показать? -
	menu.AddItem("1", Translate(client, "%t", "Rating_1")); 	// балл (отвратительная)
	menu.AddItem("2", Translate(client, "%t", "Rating_2")); 	// балла (не очень)
	menu.AddItem("3", Translate(client, "%t", "Rating_3")); 	// балла (средненькая)
	menu.AddItem("4", Translate(client, "%t", "Rating_4")); 	// балла (неплохая)
	menu.AddItem("5", Translate(client, "%t", "Rating_5")); 	// баллов (очень хорошая)
	menu.AddItem("6", Translate(client, "%t", "Rating_6")); 	// баллов (блестящая)
	menu.AddItem("0", Translate(client, "%t", "Rating_No")); 	// Ещё без оценки
	menu.ExitBackButton = true;
	menu.DisplayAt( client, 0, MENU_TIME_FOREVER);
}

public int Menu_RatingHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if( ItemIndex == MenuCancel_ExitBack )
				Command_MapChoose(client, 0);
		
		case MenuAction_Select:
		{
			static char sMark[8];
			menu.GetItem(ItemIndex, sMark, sizeof(sMark));
			int mark = StringToInt(sMark);
			
			g_Rating[client] = mark;
			CreateMenuCampaigns(client, MAP_GROUP_ANY, mark);
		}
	}
}

void CreateMenuCampaigns(int client, int ChosenGroup, int ChosenRating)
{
	static char BlackStar[] = "★";
	static char WhiteStar[] = "☆";
	
	Menu menu = new Menu(Menu_CampaignHandler, MENU_ACTIONS_DEFAULT);
	menu.ExitBackButton = true;

	static char Value[MAX_CAMPAIGN_NAME];
	FormatEx(Value, sizeof(Value), "%T", "Choose_campaign", client); // - Выберите кампанию -
	menu.SetTitle(Value);
	
	kv.Rewind();
	kv.GotoFirstSubKey();

	kvinfo.Rewind();
	kvinfo.JumpToKey("campaigns");
	
	static char campaign[MAX_CAMPAIGN_NAME];
	static char name[MAX_CAMPAIGN_TITLE];
	int group = 0, mark = 0;
	bool bAtLeastOne = false;
	do
	{
		kv.GetSectionName(campaign, sizeof(campaign));

		if( kvinfo.JumpToKey(campaign) )
		{
			group = kvinfo.GetNum("group", 0);
			mark = kvinfo.GetNum("mark", 0);
			kvinfo.GoBack();
		}
		if( (ChosenGroup == -1 || group == ChosenGroup) && (ChosenRating == -1 || mark == ChosenRating) )
		{
			if( IsValidMapKv() ) {
				FormatEx(name, sizeof(name), "%s%s   %s", StrRepeat(BlackStar, strlen(BlackStar), mark), StrRepeat(WhiteStar, strlen(WhiteStar), MAX_MARK - mark), campaign);
				menu.AddItem(campaign, name);
				bAtLeastOne = true;
			}
		}
	} while( kv.GotoNextKey() );
	
	if( bAtLeastOne )
	{
		menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
	} 
	else {
		if( g_RatingMenu[client] )
		{
			FormatEx(Value, sizeof(Value), "%T", "No_maps_rating", client); // Карт с такой оценкой ещё нет.
			PrintToChat(client, "\x03[MapChanger] \x05%s", Value);
			CreateMenuRating(client);
		} else {
			FormatEx(Value, sizeof(Value), "%T", "No_maps_in_group", client); // В этой группе ещё нет карт.
			PrintToChat(client, "\x03[MapChanger] \x05%s", Value);
			Command_MapChoose(client, 0);
		}
	}
}

// in. - KeyValue in position of concrete campaign section
bool IsValidMapKv()
{
	char map[MAX_MAP_NAME];
	bool bValid = false;

	// get the first map of campaign to check is it exist
	if( !kv.JumpToKey(g_sGameMode) )
	{
		if( !kv.JumpToKey("coop") ) // default
			return false;
	}
	if( kv.GotoFirstSubKey() ) {
		kv.GetString("Map", map, sizeof(map), "error");
		if ( strcmp(map, "error") != 0 )
		{
			if ( IsMapValidEx(map) )
				bValid = true;
		}
		kv.GoBack();
	}
	kv.GoBack();
	return bValid;
}

void FillCustomCampaignOrder()
{
	char map[MAX_MAP_NAME];
	bool bFirstMap = true;

	// get the first map of campaign to check is it exist
	if( !kv.JumpToKey(g_sGameMode) )
	{
		if( !kv.JumpToKey("coop") ) // default
			return;
	}
	if( kv.GotoFirstSubKey() )
	{
		do
		{
			kv.GetString("Map", map, sizeof(map), "error");
			if( strcmp(map, "error") != 0 )
			{
				if( IsMapValidEx(map) )
				{
					g_aMapCustomOrder.PushString(map);
					
					if( bFirstMap )
					{
						bFirstMap = false;
						g_aMapCustomFirst.PushString(map);
					}
				}
			}
		} while( kv.GotoNextKey() );
		kv.GoBack();
	}
	kv.GoBack();
}

char[] StrRepeat(char[] text, int maxlength, int times)
{
	char NewStr[MAX_CAMPAIGN_TITLE];

//	char[] NewStr = new char[times*maxlength];

	for( int i = 0; i < times*maxlength; i+= maxlength )
		for( int j = 0; j < maxlength; j++ ) {
			NewStr[i + j] = text[j];
		}
	if( times < 0 )
		NewStr[0] = '\0';
	else
		NewStr[times*maxlength] = '\0';
	return NewStr;
}

void CreateDefcampaignMenu(int client)
{
	Menu menu = new Menu(Menu_DefCampaignHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "Choose_campaign", client); // - Выберите кампанию -
	
	// extract uniq. campaign names
	ArrayList aUniq = new ArrayList(ByteCountToCells(64));
	StringMapSnapshot hSnap = g_hCampaignByMap.Snapshot();
	static char sMap[64], sCampaign[64], sCampaignTr[64];
	
	for( int i = 0; i < hSnap.Length; i++ )
	{
		hSnap.GetKey(i, sMap, sizeof(sMap));
		g_hCampaignByMap.GetString(sMap, sCampaign, sizeof(sCampaign));
		if( aUniq.FindString(sCampaign) == -1 ) {
			aUniq.PushString(sCampaign);
			FormatEx(sCampaignTr, sizeof(sCampaignTr), "%T", sCampaign, client);
			menu.AddItem(sCampaign, sCampaignTr, ITEMDRAW_DEFAULT);
		}
	}
	delete hSnap;
	delete aUniq;
	menu.ExitBackButton = true;
	menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
}


public int Menu_DefCampaignHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if( ItemIndex == MenuCancel_ExitBack )
				Command_MapChoose(client, 0);
		
		case MenuAction_Select:
		{
			static char campaign[MAX_CAMPAIGN_NAME];
			static char campaign_title[MAX_CAMPAIGN_TITLE];
			menu.GetItem(ItemIndex, campaign, sizeof(campaign), _, campaign_title, sizeof(campaign_title));
			
			CreateDefmapMenu(client, campaign, campaign_title);
		}
	}
}

void CreateDefmapMenu(int client, char[] campaign, char[] campaign_title)
{
	Menu menu = new Menu(Menu_DefMapHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("- %T [%s] -", "Choose_map", client, campaign_title);  // Выберите карту
	
	// extract all campaign maps
	StringMapSnapshot hSnap = g_hCampaignByMap.Snapshot();
	static char sMap[64], sCampaign[64], sDisplay[64], sDisplayTr[64], firstmap[64];
	
	char[][] sOrder = new char[hSnap.Length][64];
	int arrSize = 0;
	
	for( int i = 0; i < hSnap.Length; i++ )
	{
		hSnap.GetKey(i, sMap, sizeof(sMap));
		
		g_hCampaignByMap.GetString(sMap, sCampaign, sizeof(sCampaign));
		
		if( strcmp(sCampaign, campaign) == 0 )
		{
			g_hNameByMap.GetString(sMap, sDisplay, sizeof(sDisplay));
			strcopy(sOrder[arrSize], 64, sDisplay);
			arrSize++;
		}
	}
	delete hSnap;
	
	// StringMap snapshot order is sorted by hash, so I need to put this shit
	SortStrings(sOrder, arrSize, Sort_Ascending);

	hSnap = g_hNameByMap.Snapshot();
	
	for( int i = 0; i < arrSize; i++ )
	{
		for( int j = 0; j < hSnap.Length; j++ )
		{
			hSnap.GetKey(j, sMap, sizeof(sMap));
			g_hNameByMap.GetString(sMap, sDisplay, sizeof(sDisplay));
			
			if( strcmp(sOrder[i], sDisplay) == 0 )
			{
				FormatEx(sDisplayTr, sizeof(sDisplayTr), "%T", sDisplay, client);
				menu.AddItem(sMap, sDisplayTr);
				if( firstmap[0] == 0 )
				{
					strcopy(firstmap, sizeof(firstmap), sMap);
				}
			}
		}
	}
	delete hSnap;
	
	if( !g_hCvarChapterList.BoolValue )
	{
		delete menu;
		CheckVoteMap(client, firstmap, false);
		return;
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
}

public int Menu_DefMapHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if( ItemIndex == MenuCancel_ExitBack )
				CreateDefcampaignMenu(client);
		
		case MenuAction_Select:
		{
			static char map[MAX_MAP_NAME];
			menu.GetItem(ItemIndex, map, sizeof(map));
			CheckVoteMap(client, map, false);
		}
	}
}

/*
public void OnConfigsExecuted() // after server.cfg !
{
	// set survival mode for "The Last Stand"
	if (StrEqual(g_sCurMap, "l4d_sv_lighthouse"))
	{
		g_GameMode.SetString("survival");
	}
}
*/

void CreateMenuGroup(int client)
{
	Menu menu = new Menu(Menu_GroupHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle( "- %T [%s] ? -", "choose_new_map_type", client, g_Campaign[client]); // Какой тип присвоить
	menu.AddItem("1", Translate(client, "%t", "new_type_1")); // Тип: < набор № 1 >
	menu.AddItem("2", Translate(client, "%t", "new_type_2")); // Тип: < набор № 2 >
	menu.AddItem("0", Translate(client, "%t", "new_type_test")); // Тип: < тестовая карта >
	menu.ExitBackButton = true;
	menu.DisplayAt(client, 0, MENU_TIME_FOREVER);
}

public int Menu_GroupHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if( ItemIndex == MenuCancel_ExitBack )
				CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
		
		case MenuAction_Select:
		{
			static char sGroup[8];
			menu.GetItem(ItemIndex, sGroup, sizeof(sGroup));
			int group = StringToInt(sGroup);
			
			kvinfo.Rewind();
			kvinfo.JumpToKey("campaigns");
			kvinfo.JumpToKey(g_Campaign[client], true);
			kvinfo.SetNum("group", group);
			kvinfo.Rewind();
			kvinfo.ExportToFile(mapInfoPath);
			Actualize_MapChangerInfo();
			CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
		}
	}
}

void CreateMenuMark(int client)
{
	Menu menu = new Menu(Menu_MarkHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle( "- %T [%s] -", "set_rating", client, g_Campaign[client]); // Поставьте оценку кампании
	menu.AddItem("1", Translate(client, "%t", "Rating_1")); // балл (отвратительная)
	menu.AddItem("2", Translate(client, "%t", "Rating_2")); // балла (не очень)
	menu.AddItem("3", Translate(client, "%t", "Rating_3")); // балла (средненькая)
	menu.AddItem("4", Translate(client, "%t", "Rating_4")); // балла (неплохая)
	menu.AddItem("5", Translate(client, "%t", "Rating_5")); // баллов (очень хорошая)
	menu.AddItem("6", Translate(client, "%t", "Rating_6")); // баллов (блестящая)
	if( IsClientRootAdmin(client) )
		menu.AddItem("0", Translate(client, "%t", "Rating_remove")); // Удалить рейтинг
	menu.ExitBackButton = true;
	menu.DisplayAt( client, 0, MENU_TIME_FOREVER);
}

public int Menu_MarkHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if( ItemIndex == MenuCancel_ExitBack )
				CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
		
		case MenuAction_Select:
		{
			static char sMark[8];
			menu.GetItem(ItemIndex, sMark, sizeof(sMark));
			g_iVoteMark = StringToInt(sMark);
			
			if (g_iVoteMark == 0) {
				SetRating(g_Campaign[client], 0); // Remove rating is intended for admin only
				CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
			}
			else {
				if( IsClientRootAdmin(client) ) {
					StartVoteMark(client, g_Campaign[client]);
				}
				else {
					PrintToChat(client, "\04%t", "no_access");
				}
			}
		}
	}
}

public int Menu_CampaignHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if( ItemIndex == MenuCancel_ExitBack )
				if (g_RatingMenu[client])
					CreateMenuRating(client);
				else
					Command_MapChoose(client, 0);
		
		case MenuAction_Select:
		{
			static char campaign[MAX_CAMPAIGN_NAME];
			menu.GetItem(ItemIndex, campaign, sizeof(campaign));
			strcopy(g_Campaign[client], sizeof(g_Campaign[]), campaign);
			CreateCustomMapMenu(client, campaign);
		}
	}
}

void CreateCustomMapMenu(int client, char[] campaign)
{
	kv.Rewind();
	if( kv.JumpToKey(campaign) )
	{
		if( !kv.JumpToKey(g_sGameMode) )
		{
			if( !kv.JumpToKey("coop") ) { // default
				PrintToChat(client, "\x03[MapChanger] %T %s!", "no_maps_for_mode", client, g_sGameMode); // Не найдено карт в кофигурации для режима
				return;
			}
		}
		char map[MAX_MAP_NAME];
		char DisplayName[MAX_CAMPAIGN_TITLE];
		
		if( !g_hCvarChapterList.BoolValue )
		{
			kv.GotoFirstSubKey();
			kv.GetString("Map", map, sizeof(map), "error");
			LogVoteAction(client, "[TRY] Change map to: %s from %s", map, g_sCurMap);
			CheckVoteMap(client, map, true);
			return;
		}
		
		Menu menu2 = new Menu(Menu_MapHandler, MENU_ACTIONS_DEFAULT);
		menu2.SetTitle("- %T [%s] -", "Choose_map", client, campaign);  // Выберите карту
		
		kv.GotoFirstSubKey();
		do
		{
			kv.GetString("Map", map, sizeof(map), "error");
			if( strcmp(map, "error") != 0 )
			{
				kv.GetString("DisplayName", DisplayName, sizeof(DisplayName), "error");
				if( strcmp(DisplayName, "error") != 0 )
				{
					menu2.AddItem(map, DisplayName, ITEMDRAW_DEFAULT);
				}
			}
		} while( kv.GotoNextKey() );
		
		if (IsClientRootAdmin(client)) {
			menu2.AddItem("group", Translate(client, "%t", "Move_map_type"));  // Переместить в другую группу
		}
		menu2.AddItem("mark", Translate(client, "%t", "set_rating2"));  // Поставить оценку
		menu2.ExitBackButton = true;
		menu2.DisplayAt(client, 0, MENU_TIME_FOREVER);
	}
}

int GetRealClientCount() {
	int cnt;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && !IsFakeClient(i) ) cnt++;
	return cnt;
}

public int Menu_MapHandler(Menu menu, MenuAction action, int client, int ItemIndex)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
			if( ItemIndex == MenuCancel_ExitBack )
				CreateMenuCampaigns(client, g_MapGroup[client], g_Rating[client]);
		
		case MenuAction_Select:
		{
			static char map[MAX_MAP_NAME];
			static char DisplayName[MAX_CAMPAIGN_TITLE];
			menu.GetItem(ItemIndex, map, sizeof(map), _, DisplayName, sizeof(DisplayName));

			if( strcmp(map, "mark") == 0 )
			{
				if( GetRealClientCount() >= g_hCvarVoteMarkMinPlayers.IntValue || IsClientRootAdmin(client) ) 
				{
					CreateMenuMark(client);
				}
				else {
					PrintToChat(client, "%t", "Not_enough_votemark_players", g_hCvarVoteMarkMinPlayers.IntValue); // Not enough clients to start vote for mark (should be %i+)
					CreateCustomMapMenu(client, g_Campaign[client]);
				}
			}
			else if( strcmp(map, "group") == 0 )
			{
				CreateMenuGroup(client);
			} 
			else {
				LogVoteAction(client, "[TRY] Change map to: %s from %s", map, g_sCurMap);
				CheckVoteMap(client, map, true);
			}
		}
	}
}

void CheckVoteMap(int client, char[] map, bool bIsCustom)
{
	if( IsMapValidEx(map) )
	{
		if( IsClientRootAdmin(client) && GetRealClientCount() == 1 )
		{
			strcopy(g_sVoteResult, sizeof(g_sVoteResult), map);
			Handler_PostVoteAction(true);
			return;
		}
	
		if( CanVote(client, bIsCustom) )
		{
			float fCurTime = GetEngineTime();
		
			if( g_fLastTime[client] != 0 && !IsClientRootAdmin(client) )
			{
				if ( g_fLastTime[client] + g_hCvarDelay.FloatValue > fCurTime ) {
					PrintToChat(client, "\x03[MapChanger] %t", "too_often"); // "You can't vote too often!"
					LogVoteAction(client, "[DELAY] Attempt to vote too often. Time left: %i sec.", (g_fLastTime[client] + g_hCvarDelay.FloatValue) - fCurTime);
					return;
				}
			}
			g_fLastTime[client] = fCurTime;
			
			StartVoteMap(client, map);
		}
		else {
			PrintToChat(client, "\04%t", "no_access");
			LogVoteAction(client, "[DENY] Change map");
		}
	} else {
		if( client ) {
			PrintToChat(client, "\x03[MapChanger] %t %s %t", "map", map, "not_exist");  // Карта XXX больше не существует на сервере!
		}
		LogVoteAction(client, "[DENY] Map is not exist.");
	}
}

void StartVoteMap(int client, char[] map)
{
	if( g_bVoteInProgress || IsVoteInProgress() ) {
		PrintToChat(client, "%t", "vote_in_progress"); // Другое голосование ещё не закончилось!
		return;
	}
	strcopy(g_sVoteResult, sizeof(g_sVoteResult), map);
	
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	LogVoteAction(client, "[STARTED] Change map to: %s", map);
	
	Menu menu = new Menu(Handle_VoteMapMenu, MenuAction_DisplayItem | MenuAction_Display);
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	CreateTimer(g_hCvarAnnounceDelay.FloatValue, Timer_VoteDelayed, menu, TIMER_FLAG_NO_MAPCHANGE);
	
	char campaign[64], map_display[64], display[128];
	GetCampaignDisplay(map, campaign, sizeof(campaign), true, client);
	GetMapDisplay(map, map_display, sizeof(map_display), true, client);
	FormatEx(display, sizeof(display), "%s - %s", campaign, map_display);
	CPrintHintTextToAll("%t", "vote_started_announce", display);
}

Action Timer_VoteDelayed(Handle timer, Menu menu)
{
	if( g_bVotepass || g_bVeto ) {
		Handler_PostVoteAction(g_bVotepass);
		delete menu;
	}
	else {
		if( !IsVoteInProgress() ) {
			g_bVoteInProgress = true;
			menu.DisplayVoteToAll(g_hCvarTimeout.IntValue);
			g_bVoteDisplayed = true;
		}
		else {
			delete menu;
		}
	}
}

public int Handle_VoteMapMenu(Menu menu, MenuAction action, int param1, int param2)
{
	char display[MAX_CAMPAIGN_NAME], buffer[MAX_CAMPAIGN_NAME];
	int client = param1;

	switch( action )
	{
		case MenuAction_End:
		{
			if( g_bVoteInProgress && g_bVotepass ) { // in case vote is passed with CancelVote(), so MenuAction_VoteEnd is not called.
				Handler_PostVoteAction(true);
			}
			g_bVoteInProgress = false;
			delete menu;
		}
		
		case MenuAction_VoteEnd: // 0=yes, 1=no
		{
			if( (param1 == 0 || g_bVotepass) && !g_bVeto ) {
				Handler_PostVoteAction(true);
			}
			else {
				Handler_PostVoteAction(false);
			}
			g_bVoteInProgress = false;
		}
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			FormatEx(buffer, sizeof(buffer), "%T", display, client);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			char campaign[64], map_display[64], map[64];
			strcopy(map, sizeof(map), g_sVoteResult);
			GetCampaignDisplay(map, campaign, sizeof(campaign), true, client);
			GetMapDisplay(map, map_display, sizeof(map_display), true, client);
			FormatEx(display, sizeof(display), "%s - %s", campaign, map_display);
			FormatEx(buffer, sizeof(buffer), "%T", "vote_started_announce", client, display);
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void Handler_PostVoteAction(bool bVoteSuccess)
{
	if( bVoteSuccess )
	{
		LogVoteAction(-1, "[ACCEPTED] Vote for map: %s", g_sVoteResult);
		CPrintToChatAll("%t", "vote_success");
		
		L4D_ChangeLevel(g_sVoteResult);
	}
	else {
		LogVoteAction(-1, "[NOT ACCEPTED] Vote for map.");
		CPrintToChatAll("%t", "vote_failed");
	}
	g_bVoteInProgress = false;
}

void StartVoteMark(int client, char[] sCampaign)
{
	if( g_bVoteInProgress || IsVoteInProgress() ) {
		PrintToChat(client, "%t", "vote_in_progress"); // Другое голосование ещё не закончилось!
		return;
	}
	Menu menu = new Menu(Handle_VoteMarkMenu, MenuAction_DisplayItem | MenuAction_Display);
	menu.AddItem(sCampaign, "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(g_hCvarTimeout.IntValue);
	g_bVotepass = false;
	g_bVeto = false;
	LogVoteAction(client, "[STARTED] Vote for mark. Campaign: %s. Mark: %i", sCampaign, g_iVoteMark);
}

public int Handle_VoteMarkMenu(Menu menu, MenuAction action, int param1, int param2)
{
	static char display[MAX_CAMPAIGN_NAME], buffer[128], sCampaign[MAX_CAMPAIGN_NAME], sRate[32];
	int client = param1;
	
	switch( action )
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_VoteEnd: // 0=yes, 1=no
		{
			if( (param1 == 0 || g_bVotepass) && !g_bVeto ) {
				menu.GetItem(0, sCampaign, sizeof(sCampaign));
				SetRating(sCampaign, g_iVoteMark);
				LogVoteAction(-1, "[ACCEPTED] Vote for mark.");
			}
			else {
				LogVoteAction(-1, "[NOT ACCEPTED] Vote for mark.");
			}
		}
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			FormatEx(buffer, sizeof(buffer), "%T", display, client);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			menu.GetItem(0, sCampaign, sizeof(sCampaign));
			FormatEx(sRate, sizeof(sRate), "Rating_%i", g_iVoteMark);
			FormatEx(buffer, sizeof(buffer), "%T", "set_mark_vote_title", client, g_iVoteMark, sRate, client, sCampaign); // "Set mark %i (%t) for the map: %s ?"
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void SetRating(char[] sCampaign, int iMark)
{
	kvinfo.Rewind();
	kvinfo.JumpToKey("campaigns");
	kvinfo.JumpToKey(sCampaign, true);
	kvinfo.SetNum("mark", iMark);
	kvinfo.Rewind();
	kvinfo.ExportToFile(mapInfoPath);
}

stock void ReplaceColor(char[] message, int maxLen)
{
	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
	static char buffer[192];
	SetGlobalTransTarget(iClient);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));
	PrintToChat(iClient, "\x01%s", buffer);
}

stock void CPrintToChatAll(const char[] format, any ...)
{
	static char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			ReplaceColor(buffer, sizeof(buffer));
			PrintToChat(i, "\x01%s", buffer);
		}
	}
}

stock void CPrintHintTextToAll(const char[] format, any ...)
{
	static char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintHintText(i, buffer);
		}
	}
}

stock bool IsClientAdmin(int client)
{
	if( !IsClientInGame(client) ) return false;
	return( GetUserAdmin(client) != INVALID_ADMIN_ID && GetUserFlagBits(client) != 0 );
}
stock bool IsClientRootAdmin(int client)
{
	return( (GetUserFlagBits(client) & ADMFLAG_ROOT) != 0 );
}

void LogVoteAction(int client, const char[] format, any ...)
{
	static char sSteam[64];
	static char sIP[32];
	static char sName[MAX_NAME_LENGTH];
	static char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if( client != -1 ) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		GetClientIP(client, sIP, sizeof(sIP));
		LogToFileEx(g_sLog, "%s %s (%s | %s). Current map is: %s", buffer, sName, sSteam, sIP, g_sCurMap);
	}
	else {
		LogToFileEx(g_sLog, buffer);
	}
}

void L4D_ChangeLevel(char[] sMapName) // Thanks to Lux
{
	if( !IsMapValidEx(sMapName) )
	{
		PrintToChatAll("Cannot change map. Invalid: %s", sMapName);
		return;
	}
	
	PrintToServer("[MapChanger] Changing map to: %s ...", sMapName);
	
	DataPack dp = new DataPack();
	dp.WriteString(sMapName);

	CreateTimer(2.0, Timer_AlternateChangeMap, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	
	if ( g_bLeft4Dead2 )
	{
		if( hDirectorChangeLevel != null )
		{
			SDKCall(hDirectorChangeLevel, TheDirector, sMapName);
		}
		else {
			ForceChangeLevel(sMapName, "Map Vote");
		}
	}
	else {
		ForceChangeLevel(sMapName, "Map Vote");
	}
}

public Action Timer_AlternateChangeMap(Handle timer, DataPack dp)
{
	static char sMapName[MAX_MAP_NAME];
	
	dp.Reset();
	dp.ReadString(sMapName, sizeof sMapName);
	
	ServerCommand("changelevel %s", sMapName);
	ServerExecute();
}

void FinaleMapChange()
{
	char sMapName[MAX_MAP_NAME];
	
	int idx = g_aMapOrder.FindString(g_sCurMap); // search default maps

	if( idx != -1 ) 
	{
		idx++;
		if( idx >= g_aMapOrder.Length )
		{
			idx = 0;
		}
		g_aMapOrder.GetString(idx, sMapName, sizeof sMapName);
	}
	else {
		idx = g_aMapCustomOrder.FindString(g_sCurMap); // search custom maps
		
		if( idx != -1 )
		{
			if( g_hCvarFinMapRandom.BoolValue )
			{
				idx = GetRandomInt(0, g_aMapCustomFirst.Length - 1);
				g_aMapCustomFirst.GetString(idx, sMapName, sizeof sMapName);
			}
			else {
				idx++;
				if( idx >= g_aMapCustomOrder.Length )
				{
					idx = 0;
				}
				g_aMapCustomOrder.GetString(idx, sMapName, sizeof sMapName);
			}
		}
		else {
			g_aMapOrder.GetString(0, sMapName, sizeof sMapName);
		}
	}
	
	L4D_ChangeLevel(sMapName);
}

bool IsMapValidEx(char[] map)
{
	static char path[PLATFORM_MAX_PATH];
	return FindMap(map, path, sizeof(path)) == FindMap_Found;
}

void GetAddonMissions()
{
	delete kv;
	kv = new KeyValues("campaigns");
	
	char missionFile[64];
	StringMap hMapDef = new StringMap();
	FileType fileType;
	DirectoryListing hDir;
	
	if( g_bLeft4Dead2 )
	{
		for( int i = 1; i <= 14; i++ )
		{
			FormatEx(missionFile, sizeof(missionFile), "campaign%i.txt", i);
			hMapDef.SetValue(missionFile, 1);
		}
		hMapDef.SetValue("credits.txt", 1);
		hMapDef.SetValue("holdoutchallenge.txt", 1);
		hMapDef.SetValue("holdouttraining.txt", 1);
		hMapDef.SetValue("parishdash.txt", 1);
		hMapDef.SetValue("shootzones.txt", 1);
	}
	else {
		hDir = OpenDirectory("missions", false);
		if( hDir )
		{
			while( hDir.GetNext(missionFile, PLATFORM_MAX_PATH, fileType) )
			{
				if( fileType == FileType_File )
				{
					hMapDef.SetValue(missionFile, 1);
				}
			}
			delete hDir;
		}
	}
	
	hDir = OpenDirectory("missions", true, ".");
	if( hDir )
	{
		while( hDir.GetNext(missionFile, PLATFORM_MAX_PATH, fileType) )
		{
			if( fileType == FileType_File )
			{
				if( !StringMap_KeyExists(hMapDef, missionFile) )
				{
					Format(missionFile, sizeof(missionFile), "missions/%s", missionFile);
					ParseMissionFile(missionFile);
				}
			}
		}
		delete hDir;
	}
	delete hMapDef;
}

bool StringMap_KeyExists(StringMap hMap, char[] key)
{
	int v;
	return hMap.GetValue(key, v);
}

bool ParseMissionFile(char[] missionFile)
{
	File hFile = OpenFile(missionFile, "r", true, NULL_STRING);
	if( hFile == null )
	{
		PrintToServer("Failed to open mission file: \"%s\".", missionFile);
		return false;
	}
	
	static char str[512], sName[64], sTitle[64], sCampaign[64], sMap[64], sMapDisplay[64], sPrevMap[64], sPrevMapDisplay[64];
	sName[0] = 0;
	sTitle[0] = 0;
	sCampaign[0] = 0;
	sPrevMap[0] = 0;
	sPrevMapDisplay[0] = 0;
	
	GAME_TYPE eType, eCurGameType;
	
	while( !hFile.EndOfFile() && hFile.ReadLine(str, sizeof(str)) )
	{
		TrimString(str);
		
		if( sName[0] == 0 )
		{
			KV_GetValue(str, "Name", sName);
		}
		if( sTitle[0] == 0 )
		{
			KV_GetValue(str, "DisplayTitle", sTitle);
		}
		
		eType = KV_FindGameMode(str);
		
		if( eType != GAME_TYPE_NONE )
		{
			if( eCurGameType != GAME_TYPE_NONE && sPrevMap[0] != 0 )
			{
				AddCustomMap(sCampaign, eCurGameType, sPrevMap, sPrevMapDisplay);
				sPrevMap[0] = 0;
				sPrevMapDisplay[0] = 0;
			}
			
			eCurGameType = eType;
			
			if( sCampaign[0] == 0 ) // usually, "DisplayTitle" is more suitable
			{
				strcopy(sCampaign, sizeof(sCampaign), strlen(sTitle) > 5 || (strlen(sTitle) > strlen(sName)) ? sTitle : sName);
			}
		}
		
		if( eCurGameType != GAME_TYPE_NONE )
		{
			if( KV_GetValue(str, "Map", sMap) )
			{
				if( sPrevMap[0] != 0 ) // dump map info when the next "map" key is met
				{
					AddCustomMap(sCampaign, eCurGameType, sPrevMap, sPrevMapDisplay);
					sPrevMapDisplay[0] = 0;
				}
				strcopy(sPrevMap, sizeof(sPrevMap), sMap);
			}
			if( KV_GetValue(str, "DisplayName", sMapDisplay) )
			{
				ClearDisplayName(sMapDisplay, sizeof(sMapDisplay));
				strcopy(sPrevMapDisplay, sizeof(sPrevMapDisplay), sMapDisplay);
			}
		}
	}
	if( sPrevMap[0] != 0 ) // dump the leftover
	{
		AddCustomMap(sCampaign, eCurGameType, sPrevMap, sPrevMapDisplay);
	}
	kv.Rewind();
	kv.ExportToFile(mapListPath);
	return true;
}

void AddCustomMap(char[] sCampaign, GAME_TYPE eType, char[] sMap, char[] sMapDisplay)
{
	int num;
	char sKey[4];
	kv.Rewind();
	
	if( kv.JumpToKey(sCampaign, true) )
	{
		if( kv.JumpToKey(GAME_TYPE_STR[eType], true) )
		{
			if( kv.GotoFirstSubKey(true) )
			{
				do
				{
					++num;
				} while( kv.GotoNextKey() );
				
				kv.GoBack();
			}
			++num;
			
			IntToString(num, sKey, sizeof(sKey));
			
			if( kv.JumpToKey(sKey, true) )
			{
				kv.SetString("Map", sMap);
				kv.SetString("DisplayName", sMapDisplay);
			}
		}
	}
	//PrintToServer("(%s) Map: \"%s\" (%s)", GAME_TYPE_STR[eType], sMap, sMapDisplay);
}

GAME_TYPE KV_FindGameMode(char[] str)
{
	if( KV_HasKey(str, "coop") )
	{
		return GAME_TYPE_COOP;
	}
	if( KV_HasKey(str, "versus") )
	{
		return GAME_TYPE_VERSUS;
	}
	if( KV_HasKey(str, "survival") )
	{
		return GAME_TYPE_SURVIVAL;
	}
	return GAME_TYPE_NONE;
}

bool KV_HasKey(char[] str, char[] key)
{
	int posKey, posComment;
	char substr[64];
	FormatEx(substr, sizeof(substr), "\"%s\"", key);
	
	posKey = StrContains(str, substr, false);
	if( posKey != -1 )
	{
		posComment = StrContains(str, "//", true);
		if( posComment == -1 || posComment > posKey )
		{
			for( int i = 0; i < posKey; i++ ) // is token first in line, e.g. not "DisplayName" "Coop"
			{
				if( str[i] != 32 && str[i] != 9 )
					return false;
			}
			return true;
		}
	}
	return false;
}

bool KV_GetValue(char[] str, char[] key, char buffer[64])
{
	buffer[0] = 0;
	int posKey, posComment, sizeKey;
	char substr[64];
	FormatEx(substr, sizeof(substr), "\"%s\"", key);
	
	posKey = StrContains(str, substr, false);
	if( posKey != -1 )
	{
		posComment = StrContains(str, "//", true);
		
		if( posComment == -1 || posComment > posKey )
		{
			sizeKey = strlen(substr);
			buffer = UnQuote(str[posKey + sizeKey]);
			return true;
		}
	}
	return false;
}

char[] UnQuote(char[] Str)
{
	int pos;
	static char buf[64];
	strcopy(buf, sizeof(buf), Str);
	TrimString(buf);
	if (buf[0] == '\"') {
		strcopy(buf, sizeof(buf), buf[1]);
	}
	pos = FindCharInString(buf, '\"');
	if( pos != -1 ) {
		buf[pos] = '\x0';
	}
	return buf;
}

void ClearDisplayName(char[] str, int size) // trim numbering, like: "1. Mission name" / "1: Mission name"
{
	int pos;
	if( size > 3 )
	{
		if( IsCharNumeric(str[0]) )
		{
			if( !IsCharNumeric(str[1]) )
				pos = 1;
			
			if( str[1] == '.' || str[1] == ':' )
			{
				pos = 2;
				if( str[2] == ' ' )
				{
					pos = 3;
				}
			}
			Format(str, size, str[pos]);
		}
	}
}

stock bool GetCampaignDisplay(char[] map, char[] name, int maxlen, bool bTranslate = false, int client = 0)
{
	if( g_hCampaignByMap.GetString(map, name, maxlen) )
	{
		if( bTranslate )
		{
			Format(name, maxlen, "%T", name, client);
		}
		return true;
	}
	else {
		g_hCampaignByMapCustom.GetString(map, name, maxlen);
		return true;
	}
}

stock bool GetMapDisplay(char[] map, char[] name, int maxlen, bool bTranslate = false, int client = 0)
{
	if( g_hNameByMap.GetString(map, name, maxlen) )
	{
		if( bTranslate )
		{
			Format(name, maxlen, "%T", name, client);
		}
		return true;
	}
	else {
		g_hNameByMapCustom.GetString(map, name, maxlen);
		return true;
	}
}

stock bool IsCustomMap(char[] map)
{
	static char sCampaign[64];
	return !g_hCampaignByMap.GetString(map, sCampaign, sizeof(sCampaign));
}

stock void GetMapNumber(const char[] campaign, const char[] sMap, int &iCurNumber, int &iTotalNumber)
{
	static char map[MAX_MAP_NAME];
	iTotalNumber = 0;
 	kv.Rewind();
	if( kv.JumpToKey(campaign) )
	{
		if( !kv.JumpToKey(g_sGameMode) )
		{
			if( !kv.JumpToKey("coop") ) { // default
				return;
			}
		}
		kv.GotoFirstSubKey();
		do
		{
			kv.GetString("Map", map, sizeof(map), "error");
			if( strcmp(map, "error") != 0 )
			{
				iTotalNumber++;
				
				if( strcmp(map, sMap) == 0 )
				{
					iCurNumber = iTotalNumber;
				}
			}
		} while( kv.GotoNextKey()) ;
	}
}

bool InDenyFile(int client, ArrayList list)
{
	static char sName[MAX_NAME_LENGTH], str[MAX_NAME_LENGTH];
	static char sSteam[64];
	
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
	GetClientName(client, sName, sizeof(sName));
	
	for( int i = 0; i < list.Length; i++ )
	{
		list.GetString(i, str, sizeof(str));
	
		if( strncmp(str, "STEAM_", 6, false) == 0 )
		{
			if( strcmp(sSteam, str, false) == 0 )
			{
				return true;
			}
		}
		else {
			if( StrContains(str, "*") ) // allow masks like "Dan*" to match "Danny and Danil"
			{
				ReplaceString(str, sizeof(str), "*", "");
				if( StrContains(sName, str, false) != -1 )
				{
					return true;
				}
			}
			else {
				if( strcmp(sName, str, false) == 0 )
				{
					return true;
				}
			}
		}
	}
	return false;
}

bool CanVote(int client, bool bIsCustom)
{
	if( InDenyFile(client, g_hArrayVoteBlock) )
	{
		return false;
	}
	
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	
	static char sReq[32];
	if( !bIsCustom )
	{
		g_hCvarMapVoteAccessDef.GetString(sReq, sizeof(sReq));
	}
	else {
		g_hCvarMapVoteAccessCustom.GetString(sReq, sizeof(sReq));
	}
	if( sReq[0] != 0 )
	{
		int iReqFlags = ReadFlagString(sReq);
		if( iUserFlag & iReqFlags )
			return true;
	}
	#if defined _hxstats_included
	if( g_bHxStatsAvail && g_hCvarVoteStatPoints.IntValue && g_hCvarVoteStatPlayTime.IntValue )
	{
		if( HX_IsClientRegistered(client) )
		{
			int iPoints = HX_GetPoints(client, HX_COUNTING_ACTUAL, HX_POINTS);
			if( iPoints < g_hCvarVoteStatPoints.IntValue )
				return false;
			
			int iTime = HX_GetPoints(client, HX_COUNTING_ACTUAL, HX_TIME);
			if( iTime < g_hCvarVoteStatPlayTime.IntValue )
				return false;
		}
		else {
			return false;
		}
	}
	#endif
	return true;
}

bool HasVetoAccessFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	
	char sReq[32];
	g_hCvarVetoFlag.GetString(sReq, sizeof(sReq));
	if( strlen(sReq) == 0 ) return true;
	
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}