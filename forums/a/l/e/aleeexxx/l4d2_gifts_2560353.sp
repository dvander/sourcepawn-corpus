#define PLUGIN_VERSION		"1.3.4"

/*
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	Plugin Info:

*	Name	:	[L4D2] Gifts Drop & Spawn
*	Author	:	Aceleraci�n
*	Descrp	:	Drop gifts when a special infected died and win gift & special weapon
*	Link	:	https://forums.alliedmods.net/showthread.php?t=302731

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	Change Log:

1.3.4 (13-November-2017)
	- The dependency on the database was removed. The plugin can work without the need for database.
	- The translations were updated to show the ads for the gifts without points when there is not database.
	- The points earned by gifts and the command "sm_giftpoints" is activated if the plugin is working with a database.

1.3.3 (09-November-2017)
	- Added function "PrecacheModelGifts" and "PrecacheSoundGifts"
	- Fixed the problem of gifts that did not spawn when reloading the configuration file with the command "sm_reloadgifts"
	- Changed PrintToChat to Client_PrintToChat and PrintToChatAll to Client_PrintToChatAll (except when printing points)
	- Fixed the color lightgreen of translations.

1.3.2 (05-November-2017)
	- Added array's Client's Gifts Points (CurrentPointsForMap & CurrentPointsForRound)
	- Added dimensional array's Client's Gifts Number (CurrentGiftsForMap && CurrentGiftsForRound)
	- Added array's Client's Gifts Total (CurrentGiftsTotalForMap && CurrentGiftsTotalForRound)
	- Added command "sm_giftpoints" alias "sm_giftp" for players to view points for gifts collected in the current map and
	  current round.
	- Added command "sm_giftcollect" alias "sm_giftc" for players to view the number for gifts collected in the current map and
	  current round specific for type the gift.

1.3.1 (04-October-2017)
	- Added translations, required for the spawn gifts
	- Fixed the name of weapons for print to chat when spawn gifts

1.3 (03-October-2017)
	- Added a config file for the gifts "l4d2_gifts" replacing the definitions. 
	  Here you specify the path and model type, and the type of gift whether standard or special.
	- Changed cvar l4d2_gifts_pointsA for l4d2_gifts_pointsE
	- Fixed the gifts with models not physic that did not show up
	- Added OnPlayerRunCmd forward when a survivor presses +USE on gifts static.
	- Added command "sm_reloadgifts" for reloads the settings from the config file "l4d2_gifts"
	- Added cvar "l4d2_gifts_probabilityE" to the probability for gifts standard (animals and other objects) 
	  with respect to chance of infected drop gift. (Chance of infected drop gift represents 100% of these).
	- Added cvar "l4d2_gifts_probabilityS" to the probability for gift special with respect to chance of infected drop gift.
	- Added definition MAX_GIFTS to set the maximum of gifts.

1.2.1 (19-July-2017)
	- Added weapons to the gifts square for give to the player when he catches the gifts

1.2 (01-June-2017)
	- Added cvar "l4d2_gifts_pointsA" to the points for take a gift (animals and other objects).
	- Added cvar "l4d2_gifts_pointsS" to the points for take a gift square.
	- Added sound for gifts animals and gifts square when these are caught
	- Added the config file that should be executed after plugin load.
	- Added the databases config to the points of the gifts
	- Added a hook for when the console variables values is changed.

1.1 (15-March-2017)
	- Added command "sm_gift" for admins to spawn gifts. Used for the developer.
	- Added cvar "l4d2_gifts_enabled" to toggle to turn on or off the gifts.
	- Added cvar "l4d2_gifts_giflife" to the time that the gift stay on ground in seconds.
	- Added cvar "l4d2_gifts_chance" to the chance (%) of infected drop gift.
	- Added TAG CHAT for PrintChatToAll to the gifts spawned

1.0 (20-January-2017)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#include <sourcemod>
#include <smlib>
#include <l4d_stocks>
#pragma newdecls required

#define DATABASE_CONFIG 	"l4dstats"
#define TAG_GIFT			"{G}[{L}GIFTS{G}]\x01"
#define PLUGIN_FCVAR		0 //FCVAR_PLUGIN
#define	MAX_GIFTS			20
#define MAX_STRING_WIDTH	64
#define MAX_TYPEGIFTS		2
#define TYPE_ESTANDAR		0
#define TYPE_SPECIAL		1
#define TEAM_SURVIVOR		2

#define COLOR_CYAN  		"0 255 255 255"
#define COLOR_LIGHT_GREEN 	"144 238 144 255"
#define COLOR_PURPLE 		"128 0 128 255"
#define COLOR_PINK 			"250 88 130 255"
#define COLOR_RED 			"255 0 0 255"
#define COLOR_ORANGE 		"254 100 46 255"
#define COLOR_YELLOW 		"255 255 0 255"

#define AURA_CYAN  			"0 255 255"
#define AURA_BLUE  			"0 0 255"
#define AURA_GREEN 			"144 238 144"
#define AURA_PINK 			"250 88 130"
#define AURA_RED 			"255 0 0"
#define AURA_ORANGE 		"254 100 46"
#define AURA_YELLOW 		"255 255 0"

#define SND_REWARD1			"level/loud/climber.wav"
#define SND_REWARD2			"level/gnomeftw.wav"

// Database handle
Database db = null;

ConVar cvar_gift_enable;
ConVar cvar_gift_life;
ConVar cvar_gift_chance;
ConVar cvar_gift_EPoints;
ConVar cvar_gift_SPoints;
ConVar cvar_gift_probabilityE;
ConVar cvar_gift_probabilityS;

char weapons_name[8][2][50] = 
{
	{"weapon_rifle_ak47", "rifle ak47"},
	{"weapon_rifle_m60", "rifle m60"},
	{"machete", "machete"},
	{"knife", "knife"},
	{"katana", "katana"},
	{"baseball_bat","baseball bat"},
	{"weapon_grenade_launcher", "grenade launcher"},
	{"weapon_sniper_awp", "sniper awp"}
};

int probability_weapon[8] = { 30, 30, 40, 40, 40, 50, 15, 5};

int CurrentPointsForMap[MAXPLAYERS+1];
int CurrentPointsForRound[MAXPLAYERS+1];
int CurrentGiftsForMap[MAXPLAYERS+1][MAX_TYPEGIFTS];
int CurrentGiftsForRound[MAXPLAYERS+1][MAX_TYPEGIFTS];
int CurrentGiftsTotalForMap[MAXPLAYERS+1];
int CurrentGiftsTotalForRound[MAXPLAYERS+1];

char g_sModel[MAX_GIFTS][MAX_STRING_WIDTH];
char g_sTypeModel[MAX_GIFTS][10];
char g_sTypeGift[MAX_GIFTS][10];
float g_fScale[MAX_GIFTS];

int g_GifLife[2000];
char g_sGifType[2000][10];
int g_GifEntIndex[2000];
float g_GiftMov[2000];

bool bDatabase;
bool bGiftEnable;
int iGiftLife;
int iGiftChance;
int iGiftEPoints;
int iGiftSPoints;
int iGiftEProbability;
int iGiftSProbability;
bool g_RoundEnd;

char sPath_gifts[PLATFORM_MAX_PATH];
int g_iCountGifts;

public Plugin myinfo = 
{
	name = "[L4D2] Gifts Drop & Spawn",
	author = "Aceleraci�n",
	description = "Drop gifts when a special infected died and win gift & special weapon",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302731"
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_gifts.phrases");
	
	CreateConVar("l4d2_gifts", PLUGIN_VERSION, "Plugin version", 0 );
	cvar_gift_enable = CreateConVar("l4d2_gifts_enabled",	"1", "Enable gifts 0: Disable, 1: Enable", PLUGIN_FCVAR, true, 0.0, true, 1.0);
	cvar_gift_life = CreateConVar("l4d2_gifts_giflife",	"60",	"How long the gift stay on ground (seconds)", PLUGIN_FCVAR, true, 0.0);
	cvar_gift_chance = CreateConVar("l4d2_gifts_chance", "10",	"Chance (%) of infected drop gift.", PLUGIN_FCVAR, true, 1.0, true, 100.0);
	cvar_gift_EPoints = CreateConVar("l4d2_gifts_pointsE", "10", "Points for take a gift standard (animals and other objects). Disabled if there is not database", PLUGIN_FCVAR, true, 1.0);
	cvar_gift_SPoints = CreateConVar("l4d2_gifts_pointsS", "20", "Points for take a gift special. Disabled if there is not database", PLUGIN_FCVAR, true, 1.0);
	cvar_gift_probabilityE = CreateConVar("l4d2_gifts_probabilityE", "92", "Probability for gifts standard (animals and other objects) with respect to chance of infected drop gift.", PLUGIN_FCVAR, true, 1.0, true, 100.0);
	cvar_gift_probabilityS = CreateConVar("l4d2_gifts_probabilityS", "8", "Probability for gift special with respect to chance of infected drop gift.", PLUGIN_FCVAR, true, 1.0, true, 100.0);
	
	AutoExecConfig(true, "l4d2_gifts");
	
	BuildPath(Path_SM, sPath_gifts, PLATFORM_MAX_PATH, "data/l4d2_gifts.cfg");
	
	if(!FileExists(sPath_gifts))
	{
		SetFailState("Cannot find the file 'data/l4d2_gifts.cfg'");
	}
	
	if(!LoadConfigGifts(false))
	{
		SetFailState("Cannot load the file 'data/l4d2_gifts.cfg'");
	}
	
	if(g_iCountGifts == 0 )
	{
		SetFailState("Do not have models in 'data/l4d2_gifts.cfg'");
	}
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_use", Event_PlayerUse);
	
	HookConVarChange(cvar_gift_enable, Cvar_Changed1);
	HookConVarChange(cvar_gift_life,	Cvar_Changed2);
	HookConVarChange(cvar_gift_chance, Cvar_Changed3);
	HookConVarChange(cvar_gift_EPoints, Cvar_Changed4);
	HookConVarChange(cvar_gift_SPoints, Cvar_Changed5);
	HookConVarChange(cvar_gift_probabilityE, Cvar_Changed6);
	HookConVarChange(cvar_gift_probabilityS, Cvar_Changed6);
	
	RegConsoleCmd("sm_giftpoints", Command_GiftPoints, "View points for gifts collected");
	RegConsoleCmd("sm_giftp", Command_GiftPoints, "View points for gifts collected");
	RegConsoleCmd("sm_giftcollect", Command_GiftCollected, "View number of gifts collected");
	RegConsoleCmd("sm_giftc", Command_GiftCollected, "View number of gifts collected");
	
	RegAdminCmd("sm_gift", Command_Gift, ADMFLAG_ROOT);
	RegAdminCmd("sm_reloadgifts", Command_ReloadGift, ADMFLAG_ROOT);
}

public void OnMapStart()
{
	PrecacheModelGifts();
	PrecacheSoundGifts();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			CurrentPointsForMap[i] = 0;
			for (int j=0; j < MAX_TYPEGIFTS; j++)
			{
				CurrentGiftsForMap[i][j] = 0;
			}
			CurrentGiftsTotalForMap[i] = 0;
		}
	}
}


public void PrecacheModelGifts()
{
	for( int i = 0; i < g_iCountGifts; i++ )
	{
		CheckPrecacheModel(g_sModel[i]);
	}
}

public void PrecacheSoundGifts()
{
	PrecacheSound(SND_REWARD1, true);
	PrecacheSound(SND_REWARD2, true);
}

public void CheckPrecacheModel(char[] Model)
{
	if (!IsModelPrecached(Model))
	{
		PrecacheModel(Model, false);
	}
}

public void OnConfigsExecuted()
{
	GetCvars();
	
	if (!ConnectDB())
	{
		LogError("Connecting to database failed. Read error log for further details.");
		LogError("[GIFTS] Not database found. Points is disabled");
		bDatabase = false;
	}
	else
	{
		bDatabase = true;
	}
}

public void Cvar_Changed1(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);
	if(value == 0 || value == 1)
	{
		SetConVarInt(cvar_gift_enable, value, false, false);
	}
	else
	{
		SetConVarInt(cvar_gift_enable, GetConVarInt(cvar_gift_enable), false, false);
	}
	
	GetCvars();
}

public void Cvar_Changed2(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);
	if(value > 0.0)
	{
		SetConVarInt(cvar_gift_life, value, false, false);
	}
	else
	{
		SetConVarInt(cvar_gift_life, GetConVarInt(cvar_gift_life), false, false);
	}
	
	GetCvars();
}

public void Cvar_Changed3(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);
	if(value > 0 && value <= 100)
	{
		SetConVarInt(cvar_gift_chance, value, false, false);
	}
	else
	{
		SetConVarInt(cvar_gift_chance, GetConVarInt(cvar_gift_chance), false, false);
	}
	
	GetCvars();
}

public void Cvar_Changed4(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetConVarInt(cvar_gift_EPoints, StringToInt(newValue), false, false);
	GetCvars();
}

public void Cvar_Changed5(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetConVarInt(cvar_gift_SPoints, StringToInt(newValue), false, false);
	GetCvars();
}

public void Cvar_Changed6(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int value = StringToInt(newValue);
	if(value > 0 && value <= 100)
	{
		GetCvars();
	}
}

void GetCvars()
{
	//Values of cvars
	bGiftEnable = GetConVarBool(cvar_gift_enable);
	iGiftLife = GetConVarInt(cvar_gift_life);
	iGiftChance = GetConVarInt(cvar_gift_chance);
	iGiftEPoints = GetConVarInt(cvar_gift_EPoints);
	iGiftSPoints = GetConVarInt(cvar_gift_SPoints);
	iGiftEProbability = GetConVarInt(cvar_gift_probabilityE);
	iGiftSProbability = GetConVarInt(cvar_gift_probabilityS);
}

bool ConnectDB()
{
	if (db != null)
		return true;

	if (SQL_CheckConfig(DATABASE_CONFIG))
	{
		char Error[256];
		db = SQL_Connect(DATABASE_CONFIG, true, Error, sizeof(Error));

		if (db == INVALID_HANDLE)
		{
			LogError("Failed to connect to database: %s", Error);
			return false;
		}

		if (!CheckDatabaseValidity())
		{
			LogError("Database is missing required table or tables.");
			return false;
		}
	}
	else
	{
		LogError("Databases.cfg missing '%s' entry!", DATABASE_CONFIG);
		return false;
	}

	return true;
}

bool CheckDatabaseValidity()
{
	if (!SQL_FastQuery(db, "SELECT * FROM players WHERE 1 = 2"))
	{
		return false;
	}

	return true;
}

public Action Command_Gift(int client, int args)
{
	if (!bGiftEnable)
		return Plugin_Handled;
	
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	if(GetClientTeam(client) != 2 || IsFakeClient(client))
		return Plugin_Handled;
	
	DropGift(client);
	return Plugin_Handled;
}

//==========================================
// CONSOLE COMMANDS
//==========================================

public Action Command_GiftPoints(int client, int args)
{
	if (!bGiftEnable)
		return Plugin_Handled;
	
	if (!bDatabase)
	{
		ReplyToCommand(client, "[GIFTS] Points is disabled");
		return Plugin_Handled;
	}
	
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	if(GetClientTeam(client) != 2 || IsFakeClient(client))
		return Plugin_Handled;
	
	Client_PrintToChat(client, false, "%s %t", TAG_GIFT, "Your Points for gifts collected");
	Client_PrintToChat(client, false, "%t", "In current map: %d", CurrentPointsForMap[client]);
	Client_PrintToChat(client, false, "%t", "In current round: %d", CurrentPointsForRound[client]);
	
	return Plugin_Handled;
}

public Action Command_GiftCollected(int client, int args)
{
	if (!bGiftEnable)
		return Plugin_Handled;
	
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	if(GetClientTeam(client) != 2 || IsFakeClient(client))
		return Plugin_Handled;
	
	Client_PrintToChat(client, false, "%s %t", TAG_GIFT, "Number of gifts collected");
	Client_PrintToChat(client, false, "{B}Standard: %t", "In current map: %d | In current round: %d", CurrentGiftsForMap[client][TYPE_ESTANDAR], CurrentGiftsForRound[client][TYPE_ESTANDAR]);
	Client_PrintToChat(client, false, "{B}Special: %t", "In current map: %d | In current round: %d", CurrentGiftsForMap[client][TYPE_SPECIAL], CurrentGiftsForRound[client][TYPE_SPECIAL]);
	Client_PrintToChat(client, false, "{B}Total: %t", "In current map: %d | In current round: %d", CurrentGiftsTotalForMap[client], CurrentGiftsTotalForRound[client]);
	
	return Plugin_Handled;
}

//==========================================
// ADMINS COMMANDS
//==========================================

public Action Command_ReloadGift(int client, int args)
{
	if(!LoadConfigGifts(true))
	{
		LogError("Cannot load the file 'data/l4d2_gifts.cfg'");
		SetConVarInt(cvar_gift_enable, 0 , false, false);
		GetCvars();
	}
	
	if(g_iCountGifts == 0 )
	{
		LogError("���Do not have models!!!");
		SetConVarInt(cvar_gift_enable, 0 , false, false);
		GetCvars();
	}
	
	return Plugin_Handled;
}

public bool LoadConfigGifts(bool precache)
{
	KeyValues hFile = CreateKeyValues("Gifts");
	
	if(!FileToKeyValues(hFile, sPath_gifts) )
	{
		CloseHandle(hFile);
		return false;
	}
	
	KvGotoFirstSubKey(hFile);
	
	g_iCountGifts = 0;
	char sTemp[MAX_STRING_WIDTH];
	int i = 0;
	do
	{
		char sNum[8];
		KvGetSectionName(hFile, sNum, sizeof(sNum));
		int num = StringToInt(sNum);
		
		if(num > MAX_GIFTS || i >= MAX_GIFTS)
			break;
		
		KvGetString(hFile, "model", sTemp, MAX_STRING_WIDTH);
			
		if(strlen(sTemp) == 0)
			continue;
		
		if(FileExists(sTemp, true))
		{
			strcopy(g_sModel[i], MAX_STRING_WIDTH, sTemp);
			KvGetString(hFile, "type", g_sTypeModel[i], sizeof(g_sTypeModel[]), "static");
			KvGetString(hFile, "gift", g_sTypeGift[i], sizeof(g_sTypeGift[]));
			g_fScale[i] = KvGetFloat(hFile, "scale", 1.0);
			g_iCountGifts++;
			i++;
		}
	} 
	while (KvGotoNextKey(hFile));
	
	CloseHandle(hFile);

	if(precache)
	{
		PrecacheModelGifts();
	}
	return true;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable) 
		return;
	
	g_RoundEnd = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR)
		{
			CurrentPointsForRound[i] = 0;
			for (int j=0; j < MAX_TYPEGIFTS; j++)
			{
				CurrentGiftsForRound[i][j] = 0;
			}
			CurrentGiftsTotalForRound[i] = 0;
		}
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable) 
		return;
	
	g_RoundEnd = true;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable)
		return;
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (IsValidClient(victim) && GetClientTeam(victim) == 3 && IsValidClient(attacker) && GetClientTeam(attacker) == 2)
	{
		if(Infected_Admitted(victim) != -1)
		{
			if (GetRandomInt(1, 100) < iGiftChance)
			{
				DropGift(victim);
			}
		}
		
	}
}

// When a Survivor presses +USE on gifts physics
public Action Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	if (!bGiftEnable)
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int gift = EntRefToEntIndex(GetEventInt(event, "targetid"));
	
	if(!IsValidClient(client))
		return;
	
	if (IsValidEntity(gift))
	{
		char classname[30];
		GetEntityClassname(gift, classname, sizeof(classname));
		
		if(StrContains(classname, "physics") != -1)
		{
			if(g_GifEntIndex[gift] == EntIndexToEntRef(gift))
			{
				int Score;
				if(StrEqual(g_sGifType[gift], "standard"))
				{
					//Points for Gifts Standard
					Score = iGiftEPoints;
					NotifyGift(client, TYPE_ESTANDAR, Score);
				}
				else
				{
					//Points for Gifts Special
					Score = iGiftSPoints;
					NotifyGift(client, TYPE_SPECIAL, Score);
				}
				
				if (bDatabase)
				{
					char query[600];
					char ClientID[100];
					GetClientRankAuthString(client, ClientID, sizeof(ClientID));
					Format(query, sizeof(query), "UPDATE players SET points = points + %i WHERE steamid = '%s'", Score, ClientID);
					
					DataPack data = CreateDataPack();
					WritePackCell(data, client);
					WritePackCell(data, Score);
					SendSQLUpdate(query, SQLCallback, data);
				}
				AcceptEntityInput(gift, "kill");
			}
		}
	}
}

// When a Survivor presses +USE on gifts static
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (!bGiftEnable)
		return Plugin_Continue;
	
	//Check if its a valid player
	if (!IsValidClient(client)) 
	{
		return Plugin_Continue;
	}
	if (buttons & IN_USE)
	{
		int gift = GetClientAimTarget(client, false);
		
		if (IsValidEntity(gift))
		{
			char classname[30];
			float myPos[3];
			float gfPos[3];
			GetEntPropVector(gift, Prop_Send, "m_vecOrigin", gfPos);
			
			if (IsPlayerAlive(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
			{
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", myPos);
				//PrintToChatAll("%f", GetVectorDistance(myPos, gfPos));
				if (GetVectorDistance(myPos, gfPos) < 70.0)
				{
					GetEntityClassname(gift, classname, sizeof(classname));
					if(StrContains(classname, "dynamic") != -1)
					{
						if(g_GifEntIndex[gift] == EntIndexToEntRef(gift))
						{
							int Score;
							if(StrEqual(g_sGifType[gift], "standard"))
							{
								//Points for Gifts Standard
								Score = iGiftEPoints;
								NotifyGift(client, TYPE_ESTANDAR, Score);
							}
							else
							{
								//Points for Gifts Special
								Score = iGiftSPoints;
								NotifyGift(client, TYPE_SPECIAL, Score);
							}
							
							if (bDatabase)
							{
								char query[600];
								char ClientID[100];
								GetClientRankAuthString(client, ClientID, sizeof(ClientID));
								Format(query, sizeof(query), "UPDATE players SET points = points + %i WHERE steamid = '%s'", Score, ClientID);
								
								DataPack data = CreateDataPack();
								WritePackCell(data, client);
								WritePackCell(data, Score);
								SendSQLUpdate(query, SQLCallback, data);
							}
							AcceptEntityInput(gift, "kill");
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void SendSQLUpdate(const char[] query, SQLTCallback callback=INVALID_FUNCTION, Handle data = INVALID_HANDLE)
{
	if (db == INVALID_HANDLE)
	{
		return;
	}

	if (callback == INVALID_FUNCTION)
	{
		callback = SQLCallback;
	}

	SQL_TQuery(db, callback, query, data);
}

public void SQLCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (db == INVALID_HANDLE)
	{
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error: %s (Update points player. Query failed)", error);
		return;
	}
	
	ResetPack(data);
	int client = ReadPackCell(data);
	int Score = ReadPackCell(data);
	CloseHandle(data);
	
	if(!IsValidClient(client))
		return;
	
	AddScore(client, Score);
}

public void NotifyGift(int client, int type, int Score)
{
	if(type == TYPE_ESTANDAR)
	{
		if (bDatabase)
		{
			Client_PrintToChatAll(false, "%s %t", TAG_GIFT, "Spawn Gift Standard", client, Score);
			PrintToChat(client, "\x04+%i", Score);
		}
		else
		{
			Client_PrintToChatAll(false, "%s %t", TAG_GIFT, "Spawn Gift Standard Not Points", client);
		}
		EmitSoundToAll(SND_REWARD1);
		AddCollect(client, type);
	}
	else if(type == TYPE_SPECIAL)
	{
		int index = 0;
		int Sum = 0;
		Sum += probability_weapon[0];
		Sum += probability_weapon[1];
		Sum += probability_weapon[2];
		Sum += probability_weapon[3];
		Sum += probability_weapon[4];
		Sum += probability_weapon[5];
		Sum += probability_weapon[6];
		Sum += probability_weapon[7];
		if (Sum > 0)
		{
			float X = 100.0 / Sum;
			float Y = GetRandomFloat(0.0, 100.0);
			float A = 0.0;
			float B = probability_weapon[0] * X;
			if (Y >= A && Y < A + B)
			{
				index = 0;
			}			
			A = A + B;
			B = probability_weapon[1] * X;
			if (Y >= A && Y < A + B)
			{
				index = 1;
			}
			A = A + B;
			B = probability_weapon[2] * X;
			if (Y >= A && Y < A + B)
			{
				index = 2;
			}
			A = A + B;
			B = probability_weapon[3] * X;
			if (Y >= A && Y < A + B)
			{
				index = 3;
			}		
			A = A + B;
			B = probability_weapon[4] * X;
			if (Y >= A && Y < A + B)
			{
				index = 4;
			}
			A = A + B;
			B = probability_weapon[5] * X;
			if (Y >= A && Y < A + B)
			{
				index = 5;
			}
			A = A + B;
			B = probability_weapon[6] * X;
			if (Y >= A && Y < A + B)
			{
				index = 6;
			}
			A = A + B;
			B = probability_weapon[7] * X;
			if (Y >= A && Y < A + B)
			{
				index = 7;
			}
		}
		
		if(index >= 0 && index < 8)
		{
			GiveWeapon(client, weapons_name[index][0]);
			if (bDatabase)
			{
				Client_PrintToChatAll(false, "%s %t", TAG_GIFT, "Spawn Gift Special", client, Score, weapons_name[index][1]);
				PrintToChat(client, "\x04+%i", Score);
			}
			else
			{
				Client_PrintToChatAll(false, "%s %t", TAG_GIFT, "Spawn Gift Special Not Points", client, weapons_name[index][1]);
			}
			EmitSoundToAll(SND_REWARD2);
		}
		AddCollect(client, type);
	}
}

void GiveWeapon(int client, const char[] weapon)
{
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", weapon);
	SetCommandFlags("give", flagsgive);
}

void GetClientRankAuthString(int client, char[] auth, int maxlength)
{
	if (GetConVarInt(FindConVar("sv_lan")))
	{
		GetClientAuthId(client, AuthId_Steam2, auth, maxlength);

		if (!StrEqual(auth, "BOT", false))
		{
			GetClientIP(client, auth, maxlength);
		}
	}
	else
	{
		GetClientAuthId(client, AuthId_Steam2, auth, maxlength);

		if (StrEqual(auth, "STEAM_ID_LAN", false))
		{
			GetClientIP(client, auth, maxlength);
		}
	}
}

int GetRandomIndexGift(const char[] sType)
{
	int[] GiftsIndex = new int[g_iCountGifts];
	int count = 0;
	
	for(int i=0; i < g_iCountGifts; i++)
	{
		if(StrEqual(g_sTypeGift[i], sType))
		{
			GiftsIndex[count] = i;
			count++;
		}
	}
	
	int random = GetRandomInt(0, count-1);
	return GiftsIndex[random];
}

void DropGift(int client)
{
	
	char randomTypeGift[10];
	int Sum = 0;
	Sum += iGiftEProbability;
	Sum += iGiftSProbability;
	if (Sum > 0 && Sum <= 100)
	{
		float X = 100.0 / float(Sum);
		float Y = GetRandomFloat(0.0, 100.0);
		float A = 0.0;
		float B = iGiftEProbability * X;
		if (Y >= A && Y < A + B)
		{
			randomTypeGift = "standard";
		}			
		A = A + B;
		B = iGiftSProbability * X;
		if (Y >= A && Y < A + B)
		{
			randomTypeGift = "special";
		}
	}
	
	float gifPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", gifPos);
	gifPos[2] += 10.0;
	
	int gift = -1; //prop_physics_override
	int random = GetRandomIndexGift(randomTypeGift);
	
	if(StrEqual(g_sTypeModel[random], "physics"))
	{
		gift = CreateEntityByName("prop_physics_override");
	}
	else if(StrEqual(g_sTypeModel[random], "static"))
	{
		gift = CreateEntityByName("prop_dynamic_override");
	}
	
	if(gift != -1)
	{
		
		DispatchKeyValue(gift, "model", g_sModel[random]);
		
		if(StrEqual(g_sTypeGift[random], "special"))
		{
			int color = GetRandomInt(1, 7);
			switch(color)
			{
				case 1:
					DispatchKeyValue(gift, "rendercolor", COLOR_CYAN);
				case 2:
					DispatchKeyValue(gift, "rendercolor", COLOR_LIGHT_GREEN);
				case 3:
					DispatchKeyValue(gift, "rendercolor", COLOR_PURPLE);
				case 4:
					DispatchKeyValue(gift, "rendercolor", COLOR_PINK);
				case 5:
					DispatchKeyValue(gift, "rendercolor", COLOR_RED);
				case 6:
					DispatchKeyValue(gift, "rendercolor", COLOR_ORANGE);
				case 7:
					DispatchKeyValue(gift, "rendercolor", COLOR_YELLOW);
			}
		}
		
		Format(g_sGifType[gift], sizeof(g_sGifType[]), "%s", g_sTypeGift[random]);
		DispatchKeyValueVector(gift, "origin", gifPos);
		SetEntProp(gift, Prop_Send, "m_nSolidType", 6);
		DispatchSpawn(gift);
		
		SetEntPropFloat(gift, Prop_Send, "m_flModelScale", g_fScale[random]);
		
		int rmdAura = GetRandomInt(1, 7);
		int color[3];
		switch(rmdAura)
		{
			case 1:
			{
				GetColor(AURA_CYAN, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 2:
			{
				GetColor(AURA_BLUE, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 3:
			{
				GetColor(AURA_GREEN, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 4:
			{
				GetColor(AURA_PINK, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 5:
			{
				GetColor(AURA_RED, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 6:
			{
				GetColor(AURA_ORANGE, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
			case 7:
			{
				GetColor(AURA_YELLOW, color);
				L4D2_SetEntityGlow(gift, L4D2Glow_Constant, 0, 0, color, false);
			}
		}
		g_GifLife[gift] = 0;
		g_GifEntIndex[gift] = EntIndexToEntRef(gift);
		CreateTimer(1.0, Timer_GiftLife, EntIndexToEntRef(gift), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) 
		return false;
	
	if (!IsClientConnected(client)) 
		return false;
	
	if (!IsClientInGame(client)) 
		return false;
	
	return true;
}

int Infected_Admitted(int client)
{
	int class = GetEntProp(client, Prop_Send, "m_zombieClass");
	
	if(class == 1 || class == 2 || class == 3 || class == 4 || class == 5 || class == 6)
	{
		return class;
	}
	
	return -1;
}

public Action Timer_GiftLife( Handle timer, any ref)
{
	int gift = EntRefToEntIndex(ref);
	if (IsValidEntity(gift))
	{
		g_GifLife[gift] += 1;
		if( g_RoundEnd || g_GifLife[gift] > iGiftLife)
		{
			g_GifLife[gift] = 0;
			AcceptEntityInput(gift, "kill");
			return Plugin_Stop;
		}
		g_GiftMov[gift] = 0.0;
		CreateTimer(0.1, Timer_RotationGift, ref, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}

public Action Timer_RotationGift( Handle timer, any ref)
{
	int gift = EntRefToEntIndex(ref);
	if (IsValidEntity(gift))
	{
		g_GiftMov[gift] += 0.1;
		if( g_RoundEnd || g_GiftMov[gift] >= 1.0)
		{
			g_GiftMov[gift] = 0.0;
			return Plugin_Stop;
		}
		RotateAdvance(gift, 15.0, 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void RotateAdvance(int index, float value, int axis)
{
	if (IsValidEntity(index))
	{
		float rotate_[3];
		GetEntPropVector(index, Prop_Data, "m_angRotation", rotate_);
		rotate_[axis] += value;
		TeleportEntity( index, NULL_VECTOR, rotate_, NULL_VECTOR);
	}
}

public void AddScore(int client, int Score)
{
	CurrentPointsForRound[client] += Score;
	CurrentPointsForMap[client] += Score;
}

public void AddCollect(int client, int type)
{
	CurrentGiftsForRound[client][type] += 1;
	CurrentGiftsForMap[client][type] += 1;
	CurrentGiftsTotalForRound[client] += 1;
	CurrentGiftsTotalForMap[client] += 1;
}

void GetColor(const char[] str_color, int color[3])
{
	char sColors[3][4];
	ExplodeString(str_color, " ", sColors, 3, 4);

	color[0] = StringToInt(sColors[0]);
	color[1] = StringToInt(sColors[1]);
	color[2] = StringToInt(sColors[2]);
}