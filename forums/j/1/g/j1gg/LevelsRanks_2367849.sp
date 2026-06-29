#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools>
#undef REQUIRE_PLUGIN

// для будущей модульной системы // #define PLUGIN_CORE "[Levels Ranks] Core"
#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"
#define PLUGIN_VERSION "v1.0.7 beta"
#define Max_Paints 600
#define Max_Counts 64
#define Max_Length 192
#define DBTYPE_MYSQL 1
#define DBTYPE_SQLITE 2

#define DEFAULT "\x01"
#define RED "\x02"
#define GREEN "\x04"
#define LIME "\x05"
#define ORANGE "\x10"
#define PURPLE "\x0E"

new	ClientTeam[MAXPLAYERS+1],
	g_iCompetitiveRank[MAXPLAYERS+1],
	g_iIDKnife[MAXPLAYERS+1],
	g_iRank[MAXPLAYERS+1],
	g_iExp[MAXPLAYERS+1],
	
	// Cvars Bools
	g_bSpawnMenu,
	g_bSpawnMessage,
	g_bActiveKnife,

	// Cvars Integer - Give
	g_iGiveKillUsuallyExp,
	g_iGiveKillAssisterExp,
	g_iGiveKillHeadshotExp,	
	g_iGiveTaserExp,
	g_iGiveGrenadeExp,
	g_iGiveMolotovExp,
	g_iGiveDoubleExp,
	g_iGiveTripleExp,
	g_iGiveQuadroExp,
	g_iGivePentaExp,
	g_iGiveBombPlanted,
	g_iGiveBombDefused,
	g_iGiveBombPickup,
	g_iGiveRoundWin,
	g_iGiveRoundMVP,
	g_iGiveHostageRescued,
	g_iLoseHostageKilled,
	g_iLoseSuicideExp,
	g_iLoseBombDropped,
	g_iLoseKillUsuallyExp,
	g_iLoseRoundLose,	

	iRankOffset,
	IDGivePP,

	bool:g_bDoublekill[MAXPLAYERS+1],
	bool:g_bTriplekill[MAXPLAYERS+1],
	bool:g_bQuadrokill[MAXPLAYERS+1],
	bool:g_bPentakill[MAXPLAYERS+1],
	
	Float:KillTime[MAXPLAYERS+1],
	Float:GameTime[MAXPLAYERS+1],

	Handle:sp_mLevelUpHand = INVALID_HANDLE,
	Handle:sp_mLevelDownHand = INVALID_HANDLE,
	Handle:g_hRank = INVALID_HANDLE,
	Handle:g_hSaveKnife = INVALID_HANDLE,
	Handle:g_hPaintsSkin = INVALID_HANDLE,
	Handle:g_hGloves = INVALID_HANDLE,
	Handle:arbol[MAXPLAYERS+1] = INVALID_HANDLE,
	
	String:Download_Path[192],
	String:Download_Path2[192],	
	String:EmitSound_Path[192],
	String:EmitSound_Path2[192],
	String:Paints_Path[PLATFORM_MAX_PATH],
	String:AllExp[Max_Counts][Max_Length],
	String:AllPrefix[Max_Counts][Max_Length],	
	String:AllRanksMenu[][] = {
	"Rekrut",
	"Srebro - I",
	"Srebro - II",
	"Srebro - III",
	"Srebro - IV",
	"Srebro - Elita",
	"Mistrzowska - Srebrna Elita",
	"Złoty laur- I",
	"Złoty laur- II",
	"Złoty laur- III",
	"Złoty Laur - Mistrz",
	"Mistrzowski obrońca I",
	"Mistrzowski obrońca - II",
	"Elitarny Mistrzowki obrońca",
	"Wybitny Mistrzowski obrońca",
	"Mistrzowski Legendarny Orzeł",
	"Legendarny Mistrzowski Orzeł",
	"Mistrzowska pierwsza klasa",
	"Global Elite",
	"Najlepszy",
	"Mistrzunio",
	"Bóg"};
// SQL 
	
#include "include/levels_ranks/sql.inc"	
#include "levels_ranks/SQL.sp"
#include "levels_ranks/Gloves.sp"
#include "levels_ranks/Knifes.sp"
#include "levels_ranks/Hooks.sp"
	
public Plugin:myinfo = {name = PLUGIN_NAME, author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public OnPluginStart()
{
	decl String:game[80];
	GetGameFolderName(game, 80);
	
	if(!StrEqual(game, "csgo"))
	{
		SetFailState("[%s] Плагин работает только на CS:GO", PLUGIN_NAME);
	}

	g_hRank = RegClientCookie("RankLevel", "RankLevel", CookieAccess_Private);	
	g_hSaveKnife = RegClientCookie("SaveKnifeUsually", "SaveKnifeUsually", CookieAccess_Private);
	g_hPaintsSkin = RegClientCookie("PaintsSkin", "PaintsSkin", CookieAccess_Private);

	MakeGlovesPart();
	MakeHooks();
	new Handle:hCvar;

	CreateConVar("sm_levels_ranks", PLUGIN_VERSION, "Levels Ranks Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);	
	
	// Bools
	HookConVarChange((hCvar = CreateConVar("ranks_spawnmenu", "0")), OnSpawnMenuChange);	g_bSpawnMenu = GetConVarBool(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_spawnmessage", "1")), OnSpawnMessageChange);	g_bSpawnMessage = GetConVarBool(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_knife", "1")), OnActiveKnifeChange);	g_bActiveKnife = GetConVarBool(hCvar);
	
	// Integer
	HookConVarChange((hCvar = CreateConVar("ranks_kill", "2")), OnGiveKillExpChange);	g_iGiveKillUsuallyExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_assister", "1")), OnGiveKillAssisterChange);	g_iGiveKillAssisterExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_headshot", "1")), OnGiveKillHeadShotChange);	g_iGiveKillHeadshotExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_mydeath", "1")), OnLoseKillExpChange);	g_iLoseKillUsuallyExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_taserkill", "3")), OnGiveTaserExpChange);	g_iGiveTaserExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_doublekill", "4")), OnGiveDoubleExpChange);	g_iGiveDoubleExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_triplekill", "8")), OnGiveTripleExpChange);	g_iGiveTripleExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_quadrokill", "12")), OnGiveQuadroExpChange);	g_iGiveQuadroExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_pentakill", "16")), OnGivePentaExpChange);	g_iGivePentaExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_grenadekill", "7")), OnGiveGrenadeExpChange);	g_iGiveGrenadeExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_molotovkill", "14")), OnGiveMolotovExpChange);	g_iGiveMolotovExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_suicide", "6")), OnLoseSuicideExpChange);	g_iLoseSuicideExp = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_give_bombplanted", "3")), OnGiveBombPlantedChange);	g_iGiveBombPlanted = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_give_bombdefused", "3")), OnGiveBombDefusedChange);	g_iGiveBombDefused = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_give_bombpickup", "2")), OnGiveBombPickupChange);	g_iGiveBombPickup = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_lose_bombdropped", "2")), OnLoseBombDroppedChange);	g_iLoseBombDropped = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_give_roundwin", "1")), OnGiveRoundWinChange);	g_iGiveRoundWin = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_give_roundmvp", "2")), OnGiveRoundMVPChange);	g_iGiveRoundMVP = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_lose_roundlose", "1")), OnLoseRoundLoseChange);	g_iLoseRoundLose = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_lose_hostagekill", "2")), OnLoseHostageKilledChange);	g_iLoseHostageKilled = GetConVarInt(hCvar);
	HookConVarChange((hCvar = CreateConVar("ranks_give_hostageresc", "1")), OnGiveHostageRescuedChange);	g_iGiveHostageRescued = GetConVarInt(hCvar);

	sp_mLevelUpHand = CreateConVar("ranks_sound_levelup", "levels_ranks/levelup.mp3");
	sp_mLevelDownHand = CreateConVar("ranks_sound_leveldown", "levels_ranks/leveldown.mp3");
	CloseHandle(hCvar);

	AddCommandListener(ActivatedTrigger, "say");
	AddCommandListener(ActivatedTrigger, "say_team");
	RegAdminCmd("sm_levels_reset", ResetStatsSQL, ADMFLAG_ROOT);
	RegAdminCmd("sm_levels_purge", PurgeStatsSQL, ADMFLAG_ROOT);
	
	AutoExecConfig(true, "levels_ranks");
	LoadTranslations("levels_ranks.phrases");
	RegPluginLibrary("levels_ranks");
	
	// ClientPrefs	
	for(new client = 1; client <= MaxClients; client++)
    {
		if(IsClientInGame(client))
		{
			if(AreClientCookiesCached(client))
			{
				OnClientCookiesCached(client);
			}
		}
	}
	
	RegisterSQL();
}

public OnMapStart() 
{
	iRankOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
	SDKHook(FindEntityByClassname(MaxClients+1, "cs_player_manager"), SDKHook_ThinkPost, Hook_OnThinkPost);
	LoadTranslations("levels_ranks.phrases");

	decl String:path[192];
	new Handle:filedownload = OpenFile("cfg/sourcemod/levels_ranks/downloads.txt", "r");
	
	if(filedownload == INVALID_HANDLE)
    {
        SetFailState("Fail exist cfg/sourcemod/levels_ranks/downloads.txt");
        return;
    }
	
	while(!IsEndOfFile(filedownload) && ReadFileLine(filedownload, path, 192))
    { 
        TrimString(path);
        if (IsCharAlpha(path[0])) AddFileToDownloadsTable(path);
    }
	
	CloseHandle(filedownload);		

	GetConVarString(sp_mLevelUpHand, Download_Path, sizeof(Download_Path));	
	Format(path, sizeof(path), "sound/%s", Download_Path);
	AddFileToDownloadsTable(path);
	Format(EmitSound_Path, sizeof(EmitSound_Path), "*%s", Download_Path);
	FakePrecacheSound(EmitSound_Path);

	GetConVarString(sp_mLevelDownHand, Download_Path2, sizeof(Download_Path2));	
	Format(path, sizeof(path), "sound/%s", Download_Path2);
	AddFileToDownloadsTable(path);
	Format(EmitSound_Path2, sizeof(EmitSound_Path2), "*%s", Download_Path2);
	FakePrecacheSound(EmitSound_Path2);
	
	ReadPaints();
	MakeBuildGlovesPart();
	MakeExpRanks();	
}

public OnMapEnd()
{
	iRankOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
	SDKUnhook(FindEntityByClassname(MaxClients+1, "cs_player_manager"), SDKHook_ThinkPost, Hook_OnThinkPost);
}

MakeExpRanks()
{
	BuildPath(Path_SM, Paints_Path, sizeof(Paints_Path), "configs/levels_ranks/expranks.ini");
	
	decl Handle:kv, String:id[Max_Counts], String:exp[Max_Counts], String:prefix[Max_Counts];
	kv = CreateKeyValues("Exp_Ranks");
	FileToKeyValues(kv, Paints_Path);

	if(!KvGotoFirstSubKey(kv)) {

		SetFailState("Levels Ranks: %s is incorrect", Paints_Path);
		CloseHandle(kv);
	}
	
	do 
	{
		KvGetSectionName(kv, id, sizeof(id));
		new id_rank = StringToInt(id);
		
		if(id_rank != 0)
		{
			KvGetString(kv, "exp", exp, sizeof(exp));
			strcopy(AllExp[id_rank-1], sizeof(AllExp[]), exp);
		}

		KvGetString(kv, "prefix", prefix, sizeof(prefix));
		strcopy(AllPrefix[id_rank], sizeof(AllPrefix[]), prefix);		
	} 
	while (KvGotoNextKey(kv));
	CloseHandle(kv);
}

// Hooks Integer ConVars - Give
public OnGiveKillExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveKillUsuallyExp = GetConVarInt(hCvar);
public OnGiveKillAssisterChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveKillAssisterExp = GetConVarInt(hCvar);
public OnGiveKillHeadShotChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveKillHeadshotExp = GetConVarInt(hCvar);
public OnLoseKillExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iLoseKillUsuallyExp = GetConVarInt(hCvar);
public OnGiveTaserExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveTaserExp = GetConVarInt(hCvar);
public OnGiveDoubleExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveDoubleExp = GetConVarInt(hCvar);
public OnGiveTripleExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveTripleExp = GetConVarInt(hCvar);
public OnGiveQuadroExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveQuadroExp = GetConVarInt(hCvar);
public OnGivePentaExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGivePentaExp = GetConVarInt(hCvar);
public OnGiveGrenadeExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveGrenadeExp = GetConVarInt(hCvar);
public OnGiveMolotovExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveMolotovExp = GetConVarInt(hCvar);
public OnGiveBombPlantedChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveBombPlanted = GetConVarInt(hCvar);
public OnGiveBombDefusedChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveBombDefused = GetConVarInt(hCvar);
public OnGiveBombPickupChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveBombPickup = GetConVarInt(hCvar);
public OnGiveRoundWinChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveRoundWin = GetConVarInt(hCvar);
public OnGiveRoundMVPChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveRoundMVP = GetConVarInt(hCvar);
public OnGiveHostageRescuedChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iGiveHostageRescued = GetConVarInt(hCvar);

// Hooks Integer ConVars - Lose
public OnLoseSuicideExpChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iLoseSuicideExp = GetConVarInt(hCvar);
public OnLoseBombDroppedChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iLoseBombDropped = GetConVarInt(hCvar);
public OnLoseRoundLoseChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iLoseRoundLose = GetConVarInt(hCvar);
public OnLoseHostageKilledChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_iLoseHostageKilled = GetConVarInt(hCvar);

// Hooks Bool ConVars
public OnSpawnMessageChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_bSpawnMessage = GetConVarBool(hCvar);
public OnSpawnMenuChange(Handle:hCvar, const String:oldValue[], const String:newValue[])	g_bSpawnMenu = GetConVarBool(hCvar);
public OnActiveKnifeChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
    g_bActiveKnife = GetConVarBool(hCvar);
	
    if(g_bActiveKnife)
    {
        for(new i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i)) 
			{
				SDKHook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
			}
        }
    }
    else
    {
        for(new i = 1; i <= MaxClients; i++)
        {
			SDKUnhook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
        }
    }
}

stock FakePrecacheSound( const String:szPath[] )
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

public Action:ActivatedTrigger(client, const String:command[], arg)
{
	new String:KnifeMenuStr[][] = {"!лтшау", "knife" , "!knife"},
		String:MainMenuStr[][] = {"!думуд", "level" , "!level", "!lvl", "!дмд"};

	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	TrimString(text);

	if(client && IsClientInGame(client))
	{	
		if(g_bActiveKnife)
		{
			for(new i = 0; i < sizeof(KnifeMenuStr); i++)
			{
				if(StrEqual(text, KnifeMenuStr[i], false))
				{
					KnifeMenu(client);
					return Plugin_Handled;
				}
			}
		}
	
		for(new i = 0; i < sizeof(MainMenuStr); i++)
		{
			if(StrEqual(text, MainMenuStr[i], false))
			{
				MakePlace(client);
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
////////////////////////// MENUS ALL //////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

public MainMenu(client)
{
	decl String:text[64];
	SetGlobalTransTarget(client);
	new Handle:menu = CreateMenu(MainMenuHandler);
	new rank_client = g_iRank[client];
	SavePlayer(client);	
	if(g_iRank[client] < 21)
	{
		SetMenuTitle(menu, "%t", "MainMenuLowRank", PLUGIN_NAME, PLUGIN_VERSION, AllRanksMenu[rank_client], g_iExp[client], StringToInt(AllExp[rank_client]), g_iRank[client], myplace[client], g_player_count);
	}
	else if(g_iRank[client] == 21)
	{
		SetMenuTitle(menu, "%t", "MainMenuHighRank", PLUGIN_NAME, PLUGIN_VERSION, AllRanksMenu[rank_client], g_iExp[client], g_iRank[client], myplace[client], g_player_count);		
	}

	Format(text, sizeof(text), "%t", "AllRanks");
	AddMenuItem(menu, "0", text);
	
	Format(text, sizeof(text), "%t", "TOP");	
	AddMenuItem(menu, "1", text);
	
	if(g_bActiveKnife)
	{
		Format(text, sizeof(text), "%t", "Knifes");
		AddMenuItem(menu, "2", text);
	}
	
	if(g_bActiveGloves)
	{
		Format(text, sizeof(text), "%t", "Gloves");
		AddMenuItem(menu, "3", text);
	}	
	
	Format(text, sizeof(text), "%t", "Functions");
	AddMenuItem(menu, "4", text);
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 9);
}

public MainMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{		
	if(action == MenuAction_Select)
	{
		decl String:info[4];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		switch(StringToInt(info))
		{
			case 0: AllRankMenu(client);
			case 1: PrintTop(client); 
			case 2: KnifeMenu(client); 
			case 3: ArmsMenu(client); 
			case 4: FuncMenu(client);			
		}
	} 
	else if(action == MenuAction_End)  
	{ 
		CloseHandle(menu); 
	}
}

public AllRankMenu(client)
{
	decl String:text[192];
	SetGlobalTransTarget(client);
	new Handle:menu = CreateMenu(AllRankMenuHandler);
	
	Format(text, sizeof(text), "%t", "AllRanks");
	SetMenuTitle(menu, "%s | %s\n ", PLUGIN_NAME, text);

	for(new i = 0; i <= 21; i++)
	{
		if(i == 0)
		{
			Format(text, sizeof(text), "%s [0 exp]", AllRanksMenu[i]);
			AddMenuItem(menu, "", text, ITEMDRAW_DISABLED);
		}
		else if(i > 0)
		{
			Format(text, sizeof(text), "%s [%s exp]", AllRanksMenu[i], AllExp[i-1]);
			AddMenuItem(menu, "", text, ITEMDRAW_DISABLED);		
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 9);
}

public AllRankMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
}

public FuncMenu(client) 
{
	decl String:text[64];
	SetGlobalTransTarget(client);
	new flags = GetUserFlagBits(client);
	new Handle:menu = CreateMenu(FuncMenuHandler);

	Format(text, sizeof(text), "%t", "Functions");
	SetMenuTitle(menu, "%s | %s\n ", PLUGIN_NAME, text);
	
	Format(text, sizeof(text), "%t", "GivePoints");
	if(flags & ADMFLAG_PASSWORD || flags & ADMFLAG_ROOT)
	{
		AddMenuItem(menu, "0", text);
	}
	else
	{
		AddMenuItem(menu, "0", text, ITEMDRAW_DISABLED);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 9);
}

public FuncMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{	
	if(action == MenuAction_Select)
	{ 
		decl String:info[4];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		switch(StringToInt(info))
		{ 
			case 0: GivePointsPlayers(client);
		} 
	} 
	else if(action == MenuAction_End)  
	{ 
		CloseHandle(menu); 
	}	
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
////////////////////////// GIVE EXP ///////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

GivePointsPlayers(client, item = 0)
{
	decl String:givepp_id[15], String:givepp_nick[32], String:text[64];
	new Handle:menu = CreateMenu(GivePointsPlayers_CallBack);
	new flags = GetUserFlagBits(client);
	SetGlobalTransTarget(client);
	
	Format(text, sizeof(text), "%t", "GivePoints");	
	SetMenuTitle(menu, "%s | %s:\n ", PLUGIN_NAME, text);
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && (flags & ADMFLAG_ROOT))
		{
			IntToString(GetClientUserId(i), givepp_id, 15);
			givepp_nick[0] = '\0';
			GetClientName(i, givepp_nick, 32);
			AddMenuItem(menu, givepp_id, givepp_nick);
		}
		else if(IsClientInGame(i) && !IsFakeClient(i))
		{
			IntToString(GetClientUserId(i), givepp_id, 15);
			givepp_nick[0] = '\0';
			GetClientName(i, givepp_nick, 32);		
			AddMenuItem(menu, givepp_id, givepp_nick, i != client ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
	}
	
	DisplayMenuAtItem(menu, client, item, 0);
}

public GivePointsPlayers_CallBack(Handle:menu, MenuAction:action, client, item)
{	
	if(action == MenuAction_Select)
	{
		decl String:givepp_id[15];
		if(!GetMenuItem(menu, item, givepp_id, 15))
			return;

		IDGivePP = GetClientOfUserId(StringToInt(givepp_id));
		GivePointsPlayers2(client, 0);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public GivePointsPlayers2(client, item) 
{
	decl String:text[64];
	SetGlobalTransTarget(client);
	Format(text, sizeof(text), "%t", "GivePoints");
	new Handle:menu = CreateMenu(GivePointsPlayers2Handler);
	
	SetMenuTitle(menu, "%s | %s\n ", PLUGIN_NAME, text);
	AddMenuItem(menu, "opt1", "10");
	AddMenuItem(menu, "opt2", "50");
	AddMenuItem(menu, "opt3", "100");
	AddMenuItem(menu, "opt4", "500");
	AddMenuItem(menu, "opt5", "1000");	
	AddMenuItem(menu, "opt6", "5000");
	AddMenuItem(menu, "opt7", "-5000");	
	AddMenuItem(menu, "opt8", "-1000");
	AddMenuItem(menu, "opt9", "-500");
	AddMenuItem(menu, "opt10", "-100");	
	AddMenuItem(menu, "opt11", "-50");
	AddMenuItem(menu, "opt12", "-10");	
	SetMenuExitButton(menu, true);
	DisplayMenuAtItem(menu, client, item, 15);
}

public GivePointsPlayers2Handler(Handle:menu, MenuAction:action, client, itemNum) 
{	
	if(action == MenuAction_Select) 
	{
		new String:info[32], String:s_buffer[32];
        
		GetMenuItem(menu, itemNum, info, sizeof(info), _ , s_buffer, sizeof(s_buffer));
		new i_buffer = StringToInt(s_buffer);

		if(IsClientInGame(IDGivePP) && !IsFakeClient(IDGivePP))
		{
			g_iExp[IDGivePP] += i_buffer;	
			GivePointsPlayers2(client, GetMenuSelectionPosition());
			SetGlobalTransTarget(client);
		
			if(i_buffer > 0)
			{
				PrintToChat(client, "%N - %s %i (+%i)", IDGivePP, GREEN, g_iExp[IDGivePP], i_buffer);
			}
			else if(i_buffer < 0)
			{
				PrintToChat(client, "%N - %s %i (%i)", IDGivePP, RED, g_iExp[IDGivePP], i_buffer);	
			}
		}
		else
		{
			CloseHandle(menu);		
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/////////////////////////////////////////////
/////////////////////////////////////////////
///////// MAIN FUNCT ////////////////////////
/////////////////////////////////////////////
/////////////////////////////////////////////

public Hook_OnThinkPost(iEnt)
{
	SetEntDataArray(iEnt, iRankOffset, g_iCompetitiveRank, MaxClients+1);
	new Handle:hBuffer = StartMessageAll("ServerRankRevealAll");

	if(hBuffer == INVALID_HANDLE) 
	{ 
		PrintToServer("ServerRankRevealAll = INVALID_HANDLE"); 
	} 
	else 
	{ 
		EndMessage(); 
	} 	
}

public OnPostThinkPost(client)
{
	SetGlobalTransTarget(client);
	if(g_iRank[client] < 21)
	{
		if(g_iExp[client] >= StringToInt(AllExp[g_iRank[client]]))
		{
			EmitSoundToClient(client, EmitSound_Path);
			g_iRank[client] += 1;
			PrintToChat(client, " \x02[LR] %t", "LevelUp", DEFAULT, GREEN, AllRanksMenu[g_iRank[client]]);
		}
		else if(g_iRank[client] > 0 && g_iExp[client] < StringToInt(AllExp[g_iRank[client] - 1]))
		{
			EmitSoundToClient(client, EmitSound_Path2);
			g_iRank[client] -= 1;	
			PrintToChat(client, " \x02[LR] %t", "LevelDown", DEFAULT, RED, AllRanksMenu[g_iRank[client]]);
		}
	}
	else if(g_iRank[client] == 21)
	{
		if(g_iExp[client] < StringToInt(AllExp[g_iRank[client] - 1]))
		{
			g_iRank[client] -= 1;
			EmitSoundToClient(client, EmitSound_Path2);
			PrintToChat(client, " \x02[LR] %t", "LevelDown", DEFAULT, RED, AllRanksMenu[g_iRank[client]]);
		}
	}
	
	if(g_iRank[client] <= 18)
	{
		g_iCompetitiveRank[client] = g_iRank[client];
	}
	else if(g_iRank[client] > 18)
	{
		g_iCompetitiveRank[client] = 18;	
	}
}

public OnClientPostAdminCheck(client)
{
	g_bDoublekill[client] = false;
	g_bTriplekill[client] = false;
	g_bQuadrokill[client] = false;
	g_bPentakill[client] = false;

	CheckSaveGlove(client);
	
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	
	if(g_bActiveKnife)
	{
		SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
	}
}

public OnClientCookiesCached(client)
{
	decl String:SaveString[100], String:cookie1[100];
	GetClientCookie(client, g_hPaintsSkin, cookie1, sizeof(cookie1));
	
	if(strlen(cookie1) < 3) Format(cookie1, sizeof(cookie1), "0;0;0;0;0;0;0;0;");

	SetTrieValue_Arbol(client, cookie1);
	
	GetClientCookie(client, g_hRank, SaveString, sizeof(SaveString));
	g_iRank[client] = StringToInt(SaveString);

	GetClientCookie(client, g_hSaveKnife, SaveString, sizeof(SaveString));
	g_iIDKnife[client] = StringToInt(SaveString);	
	
	GetClientCookie(client, g_hGloves, SaveString, sizeof(SaveString));
	SelectedArms[client] = StringToInt(SaveString);		
} 

bool:IsValidClient(client) return (1 <= client <= MaxClients && IsClientInGame(client)) ? true : false;

public OnClientDisconnect(client)
{
	if(g_initialized[client] == true)
	{
		SavePlayer(client);
		g_initialized[client] = false;
	}	

	// SDK Hooks
	if(g_bActiveKnife)
	{
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
	}
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);

	// Cookies
	if(AreClientCookiesCached(client))
	{
		decl String:SaveString[15];
		SaveCookies(client);
		
		Format(SaveString, sizeof(SaveString), "%i", g_iRank[client]);
		SetClientCookie(client, g_hRank, SaveString);
		
		Format(SaveString, sizeof(SaveString), "%i", g_iIDKnife[client]);
		SetClientCookie(client, g_hSaveKnife, SaveString);
		
		Format(SaveString, sizeof(SaveString), "%i", SelectedArms[client]);
		SetClientCookie(client, g_hGloves, SaveString);		
	}

	if(arbol[client] != INVALID_HANDLE)
	{
		ClearTrie(arbol[client]);
		CloseHandle(arbol[client]);
		arbol[client] = INVALID_HANDLE;
	}
}

public OnPluginEnd()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && client > 0)
		{
			OnClientDisconnect(client);	
		}
	}
}