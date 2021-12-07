
//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

//Terminate:
#pragma semicolon		1
#pragma compress		0

//Definitions:
#define SQLVERSION		"1.2"
#define PLUGINVERSION		"1.04.25"

//Set Debugging/Fail State:
//#define DEBUG
//#define FAIL

//ConVars:
enum XHandles
{
	Handle:DeathForward,
	Handle:RoundForward,
};

//Cvar Handle:
static Handle:CV_SQLMANAGE = INVALID_HANDLE;

//Forward Handle:
static Handle:g_Forward[XHandles] = {INVALID_HANDLE,...};

//Database Sql:
static bool:InQuery;
static String:Query[3036];
static bool:DBConnected = false;
static bool:Loaded[MAXPLAYERS + 1];
static Handle:hSQL = INVALID_HANDLE;
static Handle:hQuery = INVALID_HANDLE;
static bool:IsDisconnect[MAXPLAYERS + 1];

//Global Variables:
static g_Points[MAXPLAYERS + 1] = {0,...};
static g_HeadShots[MAXPLAYERS + 1] = {0,...};
static g_Infections[MAXPLAYERS + 1] = {0,...};
static g_IsInfected[MAXPLAYERS + 1] = {0,...};
static g_MenuSelected[MAXPLAYERS + 1] = {0,...};

//Human Upgrades:
static g_HumanKills[MAXPLAYERS + 1] = {0,...};
static g_HumanDeaths[MAXPLAYERS + 1] = {0,...};
static g_HumanScore[MAXPLAYERS + 1] = {0,...};
static g_HumanDamageRecieved[MAXPLAYERS + 1] = {0,...};
static g_HumanDamageDone[MAXPLAYERS + 1] = {0,...};

//Zombie Upgrades:
static g_ZombieKills[MAXPLAYERS + 1] = {0,...};
static g_ZombieDeaths[MAXPLAYERS + 1] = {0,...};
static g_ZombieScore[MAXPLAYERS + 1] = {0,...};
static g_ZombieDamageRecieved[MAXPLAYERS + 1] = {0,...};
static g_ZombieDamageDone[MAXPLAYERS + 1] = {0,...};

//Session:
static g_SessionHeadShots[MAXPLAYERS + 1] = {0,...};
static g_SessionInfections[MAXPLAYERS + 1] = {0,...};
static g_SessionPoints[MAXPLAYERS + 1] = {0,...};
static g_SessionZombieScore[MAXPLAYERS + 1] = {0,...};
static g_SessionZombieKills[MAXPLAYERS + 1] = {0,...};
static g_SessionZombieDeaths[MAXPLAYERS + 1] = {0,...};
static g_SessionHumanScore[MAXPLAYERS + 1] = {0,...};
static g_SessionHumanKills[MAXPLAYERS + 1] = {0,...};
static g_SessionHumanDeaths[MAXPLAYERS + 1] = {0,...};

//SQL Strings:
static String:g_SQL_PlayerRank[] = "SELECT COUNT(*) FROM `PlayerRank` WHERE Points > %d;";
static String:g_SQL_RankCount[] = "SELECT COUNT(*) FROM `PlayerRank`;";
static String:g_SQL_SavePlayerRound[] = "UPDATE PlayerRank SET Points = %d WHERE STEAMID = %d;";
static String:g_SQL_SavePlayerZDamageR[] = "UPDATE PlayerRank SET ZombieDamageRecieved = %d WHERE STEAMID = %d;";
static String:g_SQL_SavePlayerHDamageR[] = "UPDATE PlayerRank SET HumanDamageRecieved = %d WHERE STEAMID = %d;";
static String:g_SQL_SavePlayerZDamageD[] = "UPDATE PlayerRank SET HumanDamageDone = %d WHERE STEAMID = %d;";
static String:g_SQL_SavePlayerHDamageD[] = "UPDATE PlayerRank SET ZombieDamageDone = %d WHERE STEAMID = %d";
static String:g_SQL_SavePlayerInfections[] = "UPDATE PlayerRank SET Infections = %d WHERE STEAMID = %d;";
static String:g_SQL_SavePlayerZDied[] = "UPDATE PlayerRank SET ZombieDeaths = %d, ZombieScore = %d WHERE STEAMID = '%d;";
static String:g_SQL_SavePlayerHDied[] = "UPDATE PlayerRank SET HumanDeaths = %d, HumanScore = %d WHERE STEAMID = %d;";
static String:g_SQL_SavePlayerHKill[] = "UPDATE PlayerRank SET HumanKills = %d, HumanScore = %d, HeadShots = %d, Points = %d WHERE STEAMID = %d;";
static String:g_SQL_SavePlayerZKill[] = "UPDATE PlayerRank SET ZombieKills = %d, ZombieScore = %d, Points = %d WHERE STEAMID = %d;";
static String:g_SQL_SelectTopRanked[] = "SELECT * FROM `PlayerRank` ORDER BY Points DESC LIMIT %d;";
static String:g_SQL_SelectPlayerRank[] = "SELECT * FROM `PlayerRank` WHERE STEAMID = %d;";
static String:g_SQL_CreateNewPlayer[] = "INSERT INTO `PlayerRank` (`STEAMID`) VALUES (%d);";
static String:g_SQL_UpdatePlayTime[] = "UPDATE PlayerRank SET NAME = '%s', PlayTime = PlayTime + 1 WHERE STEAMID = %d;";
static String:g_SQL_UpdatePlayerName[] = "UPDATE PlayerRank SET NAME = '%s' WHERE STEAMID = %d;";
static String:g_SQL_CreatePlayerRankTables[] = "CREATE TABLE IF NOT EXISTS `PlayerRank` (`STEAMID` INTIGER NOT NULL DEFAULT 0, `NAME` VARCHAR(32) NOT NULL, `LASTONTIME` FLOAT(24) NOT NULL DEFAULT 0.0, `Points` INTIGER NOT NULL DEFAULT 0, `ZombieKills` INTIGER NOT NULL DEFAULT 0, `ZombieDeaths` INTIGER NOT NULL DEFAULT 0, `ZombieScore` INTIGER NOT NULL DEFAULT 0, `ZombieDamageDone` INTIGER NOT NULL DEFAULT 0, `ZombieDamageRecieved` INTIGER NOT NULL DEFAULT 0, `HumanKills` INTIGER NOT NULL DEFAULT 0, `HumanDeaths` INTIGER NOT NULL DEFAULT 0, `HumanScore` INTIGER NOT NULL DEFAULT 0, `HumanDamageDone` INTIGER NOT NULL DEFAULT 0, `HumanDamageRecieved` INTIGER NOT NULL DEFAULT 0, `HeadShots` INTIGER NOT NULL DEFAULT 0, `Infections` INTIGER NOT NULL DEFAULT 0, `PlayTime` INTIGER NOT NULL DEFAULT 0, PRIMARY KEY (`STEAMID`));";

//Plugin Info:
public Plugin:myinfo =
{

	name = "Zombie Panic Official Rank",
	author = "Master(D)",
	description = "Zombie panic sounds Game mod",
	version = PLUGINVERSION,
	url = ""
}

//Initation:
public OnPluginStart()
{

	//Declare:
	decl String:GameName[32];

	//Initialize:
	GetGameFolderName(GameName, sizeof(GameName));

	//Not Map:
	if(!StrEqual(GameName, "zps"))
	{
#if defined FAIL
		//Fail State:
		SetFailState("|RolePlay| This Plugin Only Sopports 'Zombie Panic: Source'");
#endif
	}

	RegConsoleCmd("sm_rank", Command_Rank);

	RegConsoleCmd("sm_top", Command_Top);

	RegConsoleCmd("sm_top5", Command_Top5);

	RegConsoleCmd("sm_top10", Command_Top10);

	RegConsoleCmd("sm_session", Command_Session);

	RegConsoleCmd("sm_rankinfo", Command_RankInfo);

	RegConsoleCmd("sm_players", Command_Players);

	RegConsoleCmd("sm_playerList", Command_Players);

	//Print Server If Plugin Start:
	PrintToServer("|ZombieRank| Core Successfully Loaded (v%s)!", PLUGINVERSION);

	//ConVar Hooks:
	CV_SQLMANAGE = CreateConVar("sm_sqltype", "1", "1 use sql noconfig needed/ 2 use mysql need mconfig default (1)");

	//Server Version:
	CreateConVar("sm_ZombieRank_version", PLUGINVERSION, "show the version of the ranking system", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//Create Auto Configurate File:
	AutoExecConfig(true, "ZombieRank");

	//Global Hooks:
	g_Forward[DeathForward] = CreateGlobalForward("OnClientDied", ET_Event, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell, Param_Cell);

	g_Forward[RoundForward] = CreateGlobalForward("OnRoundNew", ET_Event, Param_Cell);

	//Timer:
	CreateTimer(60.0, Handle_UpdatePlayers, TIMER_REPEAT);

	//Event Hooking:
	HookEvent("player_death", EventDeath_Forward);

	//Loop:
	for(new Client = 1; Client <= GetMaxClients(); Client++)
	{

		//Connected:
		if(IsClientConnected(Client))
		{

			//Client Hook:
			if(!SDKHookEx(Client, SDKHook_OnTakeDamagePost, OnClientDamage))
			{
#if defined FAIL
				//Fail State Print:
				SetFailState("SDK Hooks was unable to load 'SDKHook_OnTakeDamagePost'");
#endif
			}
		}
	}

	//Load Language:
	LoadTranslations("common.phrases");

	//Start SQL Connection:
	InitSQL();
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
#endif
{
	//Point Out Extension:
	MarkNativeAsOptional("SDKHook");

	MarkNativeAsOptional("SDKUnhook");

	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
		return APLRes_Success;
	#else
#if defined FAIL
		return true;
#endif
	#endif
}

//Setup Sql Connection:
public InitSQL()
{

	//Declare:
	decl String:error[512];

	//Not MYSQL
	if(GetConVarInt(CV_SQLMANAGE) == 2)
	{

		//find Configeration:
		if(SQL_CheckConfig("ZombieRank"))
		{

			//Declare:
			decl String:SQLDriver[32];

			///Sql Connect:
			hSQL = SQL_Connect("ZombieRank", true, error, sizeof(error));

			//Not Conntected:
			if(hSQL == INVALID_HANDLE)
			{
#if defined DEBUG
				//Logging:
				LogMessage("|DataBase| Error %s", error);
#endif
			}

			//Read SQL Driver
			SQL_ReadDriver(hSQL, SQLDriver, sizeof(SQLDriver));

			//Sqlite
			if(strcmp(SQLDriver, "sqlite", false)==0)
			{
#if defined DEBUG
				//Logging:
				LogMessage("|DataBase| Connected to SQLite Database I.e External Config. Version %s.",SQLVERSION);
#endif

				//Initialize:
				DBConnected = true;
			}

			//MYSQL
			if(strcmp(SQLDriver, "mysql", false)==0)
			{
#if defined DEBUG
				//Logging:
				LogMessage("|DataBase| Connected to MySQL Database. Version %s.",SQLVERSION);
#endif

				//Initialize:
				DBConnected = true;

				//character Set:
				if(!SQL_FastQuery(hSQL, "SET NAMES 'utf8'"))
				{
#if defined DEBUG
					//Logging
					LogMessage("|DataBase| SQL: Could not set up database character set (utf8).");
#endif
				}
			}
		}

		//Override:
		else
		{
#if defined DEBUG
			//Logging:
			LogMessage("|DataBase| No MySQL/SQLite Configeration Found In database.cfg");
#endif
		}
	}

	//Backup Database:
	if(GetConVarInt(CV_SQLMANAGE) == 1 || !DBConnected)
	{

		//Handle:
		new Handle:kv = CreateKeyValues("");

		//Set String:
		KvSetString(kv, "driver", "sqlite"); 
		KvSetString(kv, "database", "ZombieRank");

		//Sql Connect:
		hSQL = SQL_ConnectCustom(kv, error, sizeof(error), true);

		//Not Connected:
		if(hSQL == INVALID_HANDLE)
		{
#if defined DEBUG
			//Logging:
			LogMessage("|DataBase| Error %s.", error);
#endif
		}

		//Override
		else
		{
#if defined DEBUG
			//Logging:
			LogMessage("|DataBase| Connected to SQLite Database. Version %s.", SQLVERSION);
#endif

			//Initialize:
			DBConnected = true;
		}

		//Close:
		CloseHandle(kv);
	}

	//Timer:
	CreateTimer(0.5, CreateSQLdbplayer);
}

//EventDeath Farward:
public Action:EventDeath_Forward(Handle:Event, const String:name[], bool:dontBroadcast)
{

	//Declare:
	decl String:Clientweapon[32], String:Playerweapon[32], Action:result;

	new Client = GetClientOfUserId(GetEventInt(Event, "userid"));

	new Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));

	//Start Forward:
	Call_StartForward(g_Forward[DeathForward]);

	//Get String:
	GetEventString(Event, "weapon", Playerweapon, sizeof(Playerweapon));

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client))
	{

		//Get Client Weapon:
		GetClientWeapon(Client, Clientweapon, sizeof(Clientweapon));
	}

	//Get Users:
	Call_PushCell(Client);

	Call_PushCell(Attacker);

	//Get Weapon:
	Call_PushString(Clientweapon);

	Call_PushString(Playerweapon);

	//Get Headshot:
	Call_PushCell(GetEventInt(Event, "headshot"));

	//Finnish Forward:
	Call_Finish(_:result);

	//Close:
	CloseHandle(Event);

	//Return:
	return result;
}

//EventDeath Farward:
public Action:EventAmbientPlay_Forward(Handle:Event, const String:name[], bool:dontBroadcast)
{

	//Declare:
	decl String:ASound[64];

	//Initialize:
	GetEventString(Event, "sound", ASound, sizeof(ASound));

	//Is End Round Sound:
	if(StrContains(ASound, ".Win", true) > -1)
	{

		//Declare:
		decl Action:result;

		//Start Forward:
		Call_StartForward(g_Forward[RoundForward]);

		//Finnish Forward:
		Call_Finish(_:result);

		//Set Broadcast:
		SetEventBroadcast(Handle:Event, true);

		//Close:
		CloseHandle(Event);

		//Return:
		return result;
	}

	//Return:
	return Plugin_Continue;
}

//public OnClientPutInServer(Client)
public OnClientPostAdminCheck(Client)
{

	//Client Hooking:
	if(!SDKHookEx(Client, SDKHook_OnTakeDamagePost, OnClientDamage))
	{
#if defined FAIL
		//Fail State Print:
		SetFailState("SDK Hooks was unable to load 'SDKHook_OnTakeDamagePost'");
#endif
	}

	g_SessionHeadShots[Client] = 0;

	g_SessionInfections[Client] = 0;

	g_SessionPoints[Client] = 0;

	g_SessionZombieScore[Client] = 0;

	g_SessionZombieKills[Client] = 0;

	g_SessionZombieDeaths[Client] = 0;

	g_SessionHumanScore[Client] = 0;

	g_SessionHumanKills[Client] = 0;

	g_SessionHumanDeaths[Client] = 0;

	g_MenuSelected[Client] = 0;

	//Timer:
	CreateTimer(0.5, CreateSQLAccount, Client);
}

//Disconnect:
public OnClientDisconnect(Client)
{

	//Client Hook:
	if(SDKHookEx(Client, SDKHook_OnTakeDamagePost, OnClientDamage))
	{

		//Fail State Print:
		SDKUnhook(Client, SDKHook_OnTakeDamagePost, OnClientDamage);
	}
}

//Event Spawn:
public Action:OnRoundNew()
{

	//Declare:
	decl String:SteamId[64], iSteamId;

	//Initialize:
	InQuery = true;

	//Loop:
	for(new Client = 1; Client <= GetMaxClients(); Client++)
	{

		//Connected:
		if(IsClientConnected(Client) && GetClientTeam(Client) != 1 && GetClientTeam(Client) != 4)
		{

			//Initialize:
			g_Points[Client] += 2;

			g_SessionPoints[Client] += 2;

			//Initialize:
			GetClientAuthString(Client, SteamId, sizeof(SteamId));

			iSteamId = SteamIdToInt(SteamId);

			//Sql Strings:
			Format(Query, sizeof(Query), g_SQL_SavePlayerRound, g_Points[Client], iSteamId);

			//Not Created Tables:
			if(!SQL_FastQuery(hSQL, Query))
			{
#if defined DEBUG
				//Logging
				LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
			}

			//Not Connected:
			if(IsDisconnect[Client])
			{

				//Initialize:
				Loaded[Client] = false;

				IsDisconnect[Client] = false;
			}
		}
	}

	//Initialize:
	InQuery = false;
}

//Event Damage:
public OnClientDamage(Client, Attacker, Inflictor, Float:damage, damagetype)
{

	//Initialize:
	InQuery = true;

	//Declare:
	decl String:SteamId[64];

	//Initialize:
	GetClientAuthString(Client, SteamId, sizeof(SteamId));

	//Declare:
	new iSteamId = SteamIdToInt(SteamId);

	//Is Client Zombie:
	if(GetClientTeam(Client) == 3)
	{

		//Initialize:
		g_ZombieDamageRecieved[Client] += RoundToNearest(damage);

		//Sql Strings:
		Format(Query, sizeof(Query), g_SQL_SavePlayerZDamageR, g_ZombieDamageRecieved[Client], iSteamId);

		//Not Created Tables:
		if(!SQL_FastQuery(hSQL, Query))
		{
#if defined DEBUG
			//Logging
			LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
		}

		//Not Connected:
		if(IsDisconnect[Client])
		{

			//Initialize:
			Loaded[Client] = false;

			IsDisconnect[Client] = false;
		}
	}

	//Is Client Human:
	if(GetClientTeam(Client) == 2)
	{

		//Initialize:
		g_HumanDamageRecieved[Client] += RoundToNearest(damage);

		//Sql Strings:
		Format(Query, sizeof(Query), g_SQL_SavePlayerHDamageR, g_HumanDamageRecieved[Client], iSteamId);

		//Not Created Tables:
		if(!SQL_FastQuery(hSQL, Query))
		{
#if defined DEBUG
			//Logging
			LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
		}

		//Not Connected:
		if(IsDisconnect[Client])
		{

			//Initialize:
			Loaded[Client] = false;

			IsDisconnect[Client] = false;
		}
	}

	//Is Player:
	if(Attacker != Client && Client != 0 && Attacker != 0 && Client > 0 && Client < MaxClients && Attacker > 0 && Attacker < MaxClients)
	{

		//Initialize:
		GetClientAuthString(Attacker, SteamId, sizeof(SteamId));

		iSteamId = SteamIdToInt(SteamId);

		//Is Client Zombie and Is Attacker Human:
		if(GetClientTeam(Client) == 3 && GetClientTeam(Attacker) == 2)
		{

			//Initialize:
			g_HumanDamageDone[Attacker] += RoundToNearest(damage);

			//Sql Strings:
			Format(Query, sizeof(Query), g_SQL_SavePlayerHDamageD, g_HumanDamageDone[Attacker], iSteamId);

			//Not Created Tables:
			if(!SQL_FastQuery(hSQL, Query))
			{
#if defined DEBUG
				//Logging
				LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
			}

			//Not Connected:
			if(IsDisconnect[Attacker])
			{

				//Initialize:
				Loaded[Attacker] = false;

				IsDisconnect[Attacker] = false;
			}
		}

		//Is Client Human and Is Attacker Zombie:
		if(GetClientTeam(Client) == 3 && GetClientTeam(Attacker) == 2)
		{

			//Initialize:
			g_ZombieDamageDone[Attacker] += RoundToNearest(damage);

			//Sql Strings:
			Format(Query, sizeof(Query), g_SQL_SavePlayerZDamageD, g_ZombieDamageDone[Attacker], iSteamId);

			//Not Created Tables:
			if(!SQL_FastQuery(hSQL, Query))
			{
#if defined DEBUG
				//Logging
				LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
			}

			//Is Infected:
			if(g_IsInfected[Client] == 0 && GetEntProp(Client, Prop_Data, "m_IsInfected") == 1)
			{

				//Initialize:
				g_IsInfected[Client] = 1;

				//Initialize:
				g_Infections[Attacker] += 1;

				g_SessionInfections[Attacker] += 1;

				//Sql Strings:
				Format(Query, sizeof(Query), g_SQL_SavePlayerInfections, g_Infections[Attacker], iSteamId);

				//Not Created Tables:
				if(!SQL_FastQuery(hSQL, Query))
				{
#if defined DEBUG
					//Logging
					LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
				}
			}

			//Not Infected:
			if(g_IsInfected[Client] == 1 && GetEntProp(Client, Prop_Data, "m_IsInfected") == 0)
			{

				//Initialize:
				g_IsInfected[Client] = 0;
			}

			//Not Connected:
			if(IsDisconnect[Attacker])
			{

				//Initialize:
				Loaded[Attacker] = false;

				IsDisconnect[Attacker] = false;
			}
		}
	}
}
//Event Death:
public Action:OnClientDied(Client, Attacker, const String:ClientWeapon[32], const String:AttackerWeapon[32], bool:headshot)
{

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client))
	{

		//Initialize:
		InQuery = true;

		//Declare:
		decl String:SteamId[64];

		//Initialize:
		GetClientAuthString(Client, SteamId, sizeof(SteamId));

		//Declare:
		new iSteamId = SteamIdToInt(SteamId);

		//Is Zombie:
		if(GetClientTeam(Client) == 3)
		{

			//Initialize:
			g_ZombieDeaths[Client] += 1;

			g_ZombieScore[Client] -= 1;

			g_SessionZombieDeaths[Client] += 1;

			g_SessionZombieScore[Client] -= 1;

			//Sql Strings:
			Format(Query, sizeof(Query), g_SQL_SavePlayerZDied, g_ZombieDeaths[Client], g_ZombieScore[Client], iSteamId);

			//Not Created Tables:
			if(!SQL_FastQuery(hSQL, Query))
			{
#if defined DEBUG
				//Logging
				LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
			}

			//Not Connected:
			if(IsDisconnect[Client])
			{

				//Initialize:
				Loaded[Client] = false;

				IsDisconnect[Client] = false;
			}
		}

		//Is Human:
		if(GetClientTeam(Client) == 2)
		{

			//Initialize:
			g_HumanDeaths[Client] += 1;

			g_HumanScore[Client] -= 3;

			g_SessionHumanDeaths[Client] += 1;

			g_SessionHumanScore[Client] -= 3;

			//Sql Strings:
			Format(Query, sizeof(Query), g_SQL_SavePlayerHDied, g_HumanDeaths[Client], g_HumanScore[Client], iSteamId);

			//Not Created Tables:
			if(!SQL_FastQuery(hSQL, Query))
			{
#if defined DEBUG
				//Logging
				LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
			}

			//Not Connected:
			if(IsDisconnect[Client])
			{

				//Initialize:
				Loaded[Client] = false;

				IsDisconnect[Client] = false;
			}
		}

		//Is Client:
		if(Attacker != Client && Attacker != 0 && Attacker < GetMaxClients())
		{

			//Initialize:
			GetClientAuthString(Attacker, SteamId, sizeof(SteamId));

			iSteamId = SteamIdToInt(SteamId);

			//Initialize:
			Query = "";

			//Is Zombie and Is Human:
			if(GetClientTeam(Client) == 3 && GetClientTeam(Attacker) == 2)
			{

				//HeadShot:
				if(headshot)
				{

					//Initialize:
					g_HeadShots[Attacker] += 1;

					g_Points[Attacker] += 2;

					g_SessionHeadShots[Attacker] += 1;

					g_SessionPoints[Attacker] += 2;

				}

				//Initialize:
				g_HumanKills[Attacker] += 1;

				g_HumanScore[Attacker] += 1;

				g_Points[Attacker] += 2;

				g_SessionHumanKills[Attacker] += 1;

				g_SessionHumanScore[Attacker] += 1;

				g_SessionPoints[Attacker] += 2;

				//Sql Strings:
				Format(Query, sizeof(Query), g_SQL_SavePlayerHKill, g_HumanKills[Client], g_HumanScore[Client], g_HeadShots[Client], g_Points[Client], iSteamId);

				//Not Created Tables:
				if(!SQL_FastQuery(hSQL, Query))
				{
#if defined DEBUG
					//Logging
					LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
				}

				//Not Connected:
				if(IsDisconnect[Attacker])
				{

					//Initialize:
					Loaded[Attacker] = false;

					IsDisconnect[Attacker] = false;
				}
			}

			//Is Zombie and Is Human:
			if(GetClientTeam(Client) == 2 && GetClientTeam(Attacker) == 3)
			{

				//Initialize:
				g_ZombieKills[Attacker] += 1;

				g_ZombieScore[Attacker] += 3;

				g_SessionZombieKills[Attacker] += 1;

				g_SessionZombieScore[Attacker] += 3;

				//Is Carrier:
				if(StrEqual(AttackerWeapon, "weapon_carrierarms"))
				{

					//Initialize:
					g_Points[Attacker] += 3;

					g_SessionPoints[Attacker] += 3;
				}

				//Override:
				else
				{

					//Initialize:
					g_Points[Attacker] += 4;

					g_SessionPoints[Attacker] += 4;
				}

				//Sql Strings:
				Format(Query, sizeof(Query), g_SQL_SavePlayerZKill, g_ZombieKills[Client], g_ZombieScore[Client], g_Points[Client], iSteamId);

				//Not Created Tables:
				if(!SQL_FastQuery(hSQL, Query))
				{
#if defined DEBUG
					//Logging
					LogMessage("|DataBase| SQL: Could not update players Stats (%s)", SteamId);
#endif
				}

				//Not Connected:
				if(IsDisconnect[Attacker])
				{

					//Initialize:
					Loaded[Attacker] = false;

					IsDisconnect[Attacker] = false;
				}
			}
		}

		//Initialize:
		InQuery = false;
	}
}

//Upgrade Menu:
public Action:Command_Rank(Client, args)
{

	//Handle:
	new Handle:Menu;

	//Is Valid:
	if(args != 1)
	{

		//Show Menu:
		ShowRankMenu(Client, Menu, Client);

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl String:arg1[32];

	//Initialize:
	GetCmdArg(1, arg1, sizeof(arg1));

	//Declare:
	decl String:target_name[MAX_TARGET_LENGTH];

	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			Client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(Client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{

		//Declare:
		new Player = target_list[i];

		//Valid Player:
		if(Player < 1)
		{

			//Close:
			CloseHandle(Menu);

			//Return:
			return Plugin_Handled;
		}

		//Show:
		ShowRankMenu(Client, Menu, Player);
	}

	//Return:
	return Plugin_Handled;
}

//Upgrade Menu:
public Action:Command_Top(Client, args)
{

	//Handle:
	new Handle:Menu;

	//Show Menu:
	ShowTopMenu(Client, Menu, 1);

	//Return:
	return Plugin_Handled;
}

//Upgrade Menu:
public Action:Command_Top5(Client, args)
{

	//Handle:
	new Handle:Menu;

	//Show Menu:
	ShowTopMenu(Client, Menu, 5);

	//Return:
	return Plugin_Handled;
}

//Upgrade Menu:
public Action:Command_Top10(Client, args)
{

	//Handle:
	new Handle:Menu;

	//Show Menu:
	ShowTopMenu(Client, Menu, 10);

	//Return:
	return Plugin_Handled;
}

//Upgrade Menu:
public Action:Command_RankInfo(Client, args)
{

	//Handle:
	new Handle:Menu;

	//Show Menu:
	ShowRankInfoMenu(Client, Menu);

	//Return:
	return Plugin_Handled;
}

//Upgrade Menu:
public Action:Command_Session(Client, args)
{

	//Handle:
	new Handle:Menu;

	//Is Valid:
	if(args != 1)
	{

		//Show Menu:
		ShowSessionMenu(Client, Menu, Client);

		//Return:
		return Plugin_Handled;
	}

	//Declare:
	decl String:arg1[32];

	//Initialize:
	GetCmdArg(1, arg1, sizeof(arg1));

	//Declare:
	decl String:target_name[MAX_TARGET_LENGTH];

	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			Client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(Client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{

		//Declare:
		new Player = target_list[i];

		//Valid Player:
		if(Player < 1)
		{

			//Close:
			CloseHandle(Menu);

			//Return:
			return Plugin_Handled;
		}

		//Show:
		ShowSessionMenu(Client, Menu, Player);
	}

	//Return:
	return Plugin_Handled;
}

//Upgrade Menu:
public Action:Command_Players(Client, args)
{

	//Handle:
	new Handle:Menu;

	//Show Menu:
	ShowPlayersMenu(Client, Menu);

	//Return:
	return Plugin_Handled;
}

//Show Menu:
public Action:ShowRankMenu(Client, &Handle: Menu, Player)
{

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, g_Points[Player]);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Declare:
	decl String:bAllFormat[128], String:PlayerName[64], String:iAllFormat[5];

	//Initulize:
	GetClientName(Player, PlayerName, sizeof(PlayerName));

	//Handle:
	Menu = CreateMenu(Handle_Rank_Menu);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s STATS!\nTHARE Rank IS CURRENTLY %d (OF %d).\n    ", PlayerName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "OVERALL STATS\n\nPOINTS: %d\nKILLS: %d\nDEATHS: %d\nHEADSHOTS: %d\nINFECTIONS: %d\n    ", g_Points[Player], (g_ZombieKills[Player] + g_HumanKills[Player]), (g_ZombieDeaths[Player] + g_HumanDeaths[Player]), g_HeadShots[Player], g_Infections[Player]);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW HUMAN STATS\nKILLS: %d\nDeaths: %d\n    ", g_HumanKills[Player], g_HumanDeaths[Player]);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW ZOMBIE STATS\nKILLS: %d\nDeaths: %d\n    ", g_ZombieKills[Player], g_ZombieDeaths[Player]);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "3 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Caclculate Headshot Ratio:
	new Float:HeadShotRatio = g_HeadShots[Player] == 0 ? 0.00 : FloatDiv(float(g_HeadShots[Player]), float((g_ZombieKills[Player] + g_HumanKills[Player])))*100;

	//Caclculate Kill Death Ratio:
	new Float:KillDeathRatio = (g_ZombieDeaths[Player] + g_HumanDeaths[Player]) == 0 ? 1.0:float((g_ZombieKills[Player] + g_HumanKills[Player]) / (g_ZombieDeaths[Player] + g_HumanDeaths[Player]));

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW OTHER STATS\nKILL/DEATH RATIO: %.2f\nHEADSHOT RATIO: %.2f \%\n    ", KillDeathRatio, HeadShotRatio);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "4 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "5 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowRankHumanMenu(Client, &Handle: Menu, Player)
{

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, g_Points[Player]);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Declare:
	decl String:bAllFormat[128], String:PlayerName[64], String:iAllFormat[5];

	//Initulize:
	GetClientName(Player, PlayerName, sizeof(PlayerName));

	//Handle:
	Menu = CreateMenu(Handle_RankHuman_Menu);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s STATS!\nTHEIR Rank IS CURRENTLY %d (OF %d).\n    ", PlayerName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW HUMAN STATS\nSCORE: %d\nKILLS: %d\nDeaths: %d\nHEADSHOTS: %d\nDAMAGE DONE: %d\nDAMAGE RECEIVED: %d\n    ", g_HumanScore[Player], g_HumanKills[Player], g_HumanDeaths[Player], g_HeadShots[Player], g_HumanDamageDone[Player], g_HumanDamageRecieved[Player]);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "Back");

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "3 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowRankZombieMenu(Client, &Handle: Menu, Player)
{

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, g_Points[Player]);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Declare:
	decl String:bAllFormat[128], String:PlayerName[64], String:iAllFormat[5];

	//Initulize:
	GetClientName(Player, PlayerName, sizeof(PlayerName));

	//Handle:
	Menu = CreateMenu(Handle_RankZombie_Menu);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s STATS!\nTHEIR Rank IS CURRENTLY %d (OF %d).\n    ", PlayerName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW ZOMBIE STATS\nSCORE: %d\nKILLS: %d\nDeaths: %d\nINFECTIONS: %d\nDAMAGE DONE: %d\nDAMAGE RECEIVED: %d\n    ", g_ZombieScore[Player], g_ZombieKills[Player], g_ZombieDeaths[Player], g_Infections[Player], g_ZombieDamageDone[Player], g_ZombieDamageRecieved[Player]);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "Back");

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "3 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowRankOtherMenu(Client, &Handle: Menu, Player)
{

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, g_Points[Player]);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Declare:
	decl String:SteamId[256];

	//Initialize:
	GetClientAuthString(Player, SteamId, sizeof(SteamId));

	//Declare:
	new iSteamId = SteamIdToInt(SteamId);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_SelectPlayerRank, iSteamId);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new PlayTime = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		PlayTime = SQL_FetchInt(hQuery, 13);
	}

	if(PlayTime / 60 >= 1) PlayTime = PlayTime / 60;
	else PlayTime = 1;

	//Close:
	CloseHandle(hQuery);

	//Declare:
	decl String:bAllFormat[128], String:PlayerName[64], String:iAllFormat[5];

	//Initulize:
	GetClientName(Player, PlayerName, sizeof(PlayerName));

	//Handle:
	Menu = CreateMenu(Handle_RankOther_Menu);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s STATS!\nTHEIR Rank IS CURRENTLY %d (OF %d).\n    ", PlayerName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Caclculate Headshot Ratio:
	new Float:IfectionRatio = g_Infections[Player] == 0 ? 0.00 : FloatDiv(float(g_Infections[Player]), float(g_ZombieKills[Player]))*100;

	//Caclculate Headshot Ratio:
	new Float:HeadShotRatio = g_HeadShots[Player] == 0 ? 0.00 : FloatDiv(float(g_HeadShots[Player]), float((g_ZombieKills[Player] + g_HumanKills[Player])))*100;

	//Caclculate Kill Death Ratio:
	new Float:KillDeathRatio = (g_ZombieDeaths[Player] + g_HumanDeaths[Player]) == 0 ? 1.0:float((g_ZombieKills[Player] + g_HumanKills[Player]) / (g_ZombieDeaths[Player] + g_HumanDeaths[Player]));

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW OTEHR STATS\nKILL/DEATH RATIO: %.2f\nHEADSHOT RATIO: %.2f \%\nINFECTION RATIO: %.2f \%\nONLINE TIME: %d HOURS\n    ", KillDeathRatio, HeadShotRatio, IfectionRatio, PlayTime);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "Back");

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "3 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowTopMenu(Client, &Handle: Menu, Filter)
{

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, g_Points[Client]);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Declare:
	new i = 0;

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_SelectTopRanked, Filter);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	decl String:iAllFormat[256], String:bAllFormat[256], TopPoints[Filter], TopSteamId[Filter], String:TopName[Filter][32];

	//Handle:
	Menu = CreateMenu(Handle_Top_Menu);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "TOP CATEGORY SELECTION!\nYOUR Rank IS CURRENTLY %d (OF %d).\n    ", Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		TopSteamId[i] = SQL_FetchInt(hQuery, 0);

		//Database Field Loading String:
		SQL_FetchString(hQuery, 1, TopName[i], 32);

		//Database Field Loading Intiger:
		TopPoints[i] = SQL_FetchInt(hQuery, 3);

		//Format:
		Format(bAllFormat, sizeof(bAllFormat), "%s (%d)",TopName[i], TopPoints[i]);

		//Format:
		Format(iAllFormat, sizeof(iAllFormat), "%d", TopSteamId[i]);

		//Menu Buttons:
		AddMenuItem(Menu, iAllFormat, bAllFormat);

		i++;
	}

	//Set Menu Buttons:
	SetMenuPagination(Menu, 10);

	//Set Exit Button:
	SetMenuExitButton(Menu, true);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);

	//Close:
	CloseHandle(hQuery);
}

//Show Menu:
public Action:ShowTopRankMenu(Client, &Handle: Menu, iSteamId)
{

	//Initulize:
	iSteamId = g_MenuSelected[Client];

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_SelectPlayerRank, iSteamId);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	decl String:TopName[32];

	new Points = 0, HumanKills = 0, HumanDeaths = 0, ZombieKills = 0, ZombieDeaths = 0, Headshots = 0, Infections = 0;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading String:
		SQL_FetchString(hQuery, 1, TopName, 32);

		//Database Field Loading Intiger:
		Points = SQL_FetchInt(hQuery, 3);

		//Database Field Loading Intiger:
		ZombieKills = SQL_FetchInt(hQuery, 4);

		//Database Field Loading Intiger:
		ZombieDeaths = SQL_FetchInt(hQuery, 5);

		//Database Field Loading Intiger:
		HumanKills = SQL_FetchInt(hQuery, 9);

		//Database Field Loading Intiger:
		HumanDeaths = SQL_FetchInt(hQuery, 10);

		//Database Field Loading Intiger:
		Headshots = SQL_FetchInt(hQuery, 14);

		//Database Field Loading Intiger:
		Infections = SQL_FetchInt(hQuery, 15);
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, g_Points[Client]);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Handle:
	Menu = CreateMenu(Handle_TopRank_Menu);

	//Declare:
	decl String:bAllFormat[256], String:iAllFormat[256];

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s STATS!\nTHEIR Rank IS CURRENTLY %d (OF %d).\n    ", TopName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "OVERALL STATS\n\nPOINTS: %d\nKILLS: %d\nDEATHS: %d\nHEADSHOTS: %d\nINFECTIONS: %d\n    ", Points, (ZombieKills + HumanKills), (ZombieDeaths + HumanDeaths), Headshots, Infections);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW HUMAN STATS\nKILLS: %d\nDeaths: %d\n    ", HumanKills, HumanDeaths);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW ZOMBIE STATS\nKILLS: %d\nDeaths: %d\n    ", ZombieKills, g_ZombieDeaths);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "3 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Caclculate Headshot Ratio:
	new Float:HeadShotRatio = Headshots == 0 ? 0.00 : FloatDiv(float(Headshots), float((ZombieKills + HumanKills)))*100;

	//Caclculate Kill Death Ratio:
	new Float:KillDeathRatio = (ZombieDeaths + HumanDeaths) == 0 ? 1.0:float((ZombieKills + HumanKills) / (ZombieDeaths + HumanDeaths));

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW OTEHR STATS\nKILL/DEATH RATIO: %.2f\nHEADSHOT RATIO: %.2f \%\n    ", KillDeathRatio, HeadShotRatio);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "4 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "5 null");

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowTopHumanMenu(Client, &Handle: Menu, iSteamId)
{

	//Initulize:
	iSteamId = g_MenuSelected[Client];

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_SelectPlayerRank, iSteamId);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	decl String:TopName[32];

	new Points = 0, HumanScore = 0, HumanKills = 0, HumanDeaths = 0, Headshots = 0, HumanDamageDone = 0, HumanDamageRecieved = 0;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading String:
		SQL_FetchString(hQuery, 1, TopName, 32);

		//Database Field Loading Intiger:
		Points = SQL_FetchInt(hQuery, 3);

		//Database Field Loading Intiger:
		HumanScore = SQL_FetchInt(hQuery, 11);

		//Database Field Loading Intiger:
		HumanKills = SQL_FetchInt(hQuery, 9);

		//Database Field Loading Intiger:
		HumanDeaths = SQL_FetchInt(hQuery, 10);

		//Database Field Loading Intiger:
		Headshots = SQL_FetchInt(hQuery, 14);

		//Database Field Loading Intiger:
		HumanDamageDone = SQL_FetchInt(hQuery, 12);

		//Database Field Loading Intiger:
		HumanDamageRecieved = SQL_FetchInt(hQuery, 13);

	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, Points);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Handle:
	Menu = CreateMenu(Handle_TopHuman_Menu);

	//Declare:
	decl String:bAllFormat[128], String:iAllFormat[5];

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s STATS!\nTHEIR Rank IS CURRENTLY %d (OF %d).\n    ", TopName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW HUMAN STATS\nSCORE: %d\nKILLS: %d\nDeaths: %d\nHEADSHOTS: %d\nDAMAGE DONE: %d\nDAMAGE RECEIVED: %d\n    ", HumanScore, HumanKills, HumanDeaths, Headshots, HumanDamageDone, HumanDamageRecieved);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "Back");

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "3 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowTopZombieMenu(Client, &Handle: Menu, iSteamId)
{

	//Initulize:
	iSteamId = g_MenuSelected[Client];

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_SelectPlayerRank, iSteamId);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	decl String:TopName[32];

	new Points = 0, ZombieScore = 0, ZombieKills = 0, ZombieDeaths = 0, Infections = 0, ZombieDamageDone = 0, ZombieDamageReceived = 0;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading String:
		SQL_FetchString(hQuery, 1, TopName, 32);

		//Database Field Loading Intiger:
		Points = SQL_FetchInt(hQuery, 3);

		//Database Field Loading Intiger:
		ZombieScore = SQL_FetchInt(hQuery, 6);

		//Database Field Loading Intiger:
		ZombieKills = SQL_FetchInt(hQuery, 4);

		//Database Field Loading Intiger:
		ZombieDeaths = SQL_FetchInt(hQuery, 5);

		//Database Field Loading Intiger:
		Infections = SQL_FetchInt(hQuery, 15);

		//Database Field Loading Intiger:
		ZombieDamageDone = SQL_FetchInt(hQuery, 7);

		//Database Field Loading Intiger:
		ZombieDamageReceived = SQL_FetchInt(hQuery, 8);
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, Points);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Handle:
	Menu = CreateMenu(Handle_TopZombie_Menu);

	//Declare:
	decl String:bAllFormat[128], String:iAllFormat[5];

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s STATS!\nTHEIR Rank IS CURRENTLY %d (OF %d).\n    ", TopName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW ZOMBIE STATS\nSCORE: %d\nKILLS: %d\nDeaths: %d\nInfections: %d\nDAMAGE DONE: %d\nDAMAGE RECEIVED: %d\n    ", ZombieScore, ZombieKills, ZombieDeaths, Infections, ZombieDamageDone, ZombieDamageReceived);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "Back");

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "3 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowTopOtherMenu(Client, &Handle: Menu, iSteamId)
{

	//Initulize:
	iSteamId = g_MenuSelected[Client];

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_SelectPlayerRank, iSteamId);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	decl String:TopName[32];

	new Points = 0, HumanKills = 0, HumanDeaths = 0, ZombieKills = 0, ZombieDeaths = 0, Infections = 0, Headshots = 0;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading String:
		SQL_FetchString(hQuery, 1, TopName, 32);

		//Database Field Loading Intiger:
		Points = SQL_FetchInt(hQuery, 3);

		//Database Field Loading Intiger:
		ZombieKills = SQL_FetchInt(hQuery, 4);

		//Database Field Loading Intiger:
		ZombieDeaths = SQL_FetchInt(hQuery, 5);

		//Database Field Loading Intiger:
		HumanKills = SQL_FetchInt(hQuery, 9);

		//Database Field Loading Intiger:
		HumanDeaths = SQL_FetchInt(hQuery, 10);

		//Database Field Loading Intiger:
		Headshots = SQL_FetchInt(hQuery, 14);

		//Database Field Loading Intiger:
		Infections = SQL_FetchInt(hQuery, 15);
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, Points);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_SelectPlayerRank, iSteamId);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new PlayTime = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		PlayTime = SQL_FetchInt(hQuery, 13);
	}

	if(PlayTime / 60 >= 1) PlayTime = PlayTime / 60;
	else PlayTime = 1;

	//Close:
	CloseHandle(hQuery);

	//Declare:
	decl String:bAllFormat[128], String:iAllFormat[5];

	//Handle:
	Menu = CreateMenu(Handle_TopOther_Menu);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s STATS!\nTHEIR Rank IS CURRENTLY %d (OF %d).\n    ", TopName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Caclculate Headshot Ratio:
	new Float:IfectionRatio = Infections == 0 ? 0.00 : FloatDiv(float(Infections), float(ZombieKills))*100;

	//Caclculate Headshot Ratio:
	new Float:HeadShotRatio = Headshots == 0 ? 0.00 : FloatDiv(float(Headshots), float((HumanKills)))*100;

	//Caclculate Kill Death Ratio:
	new Float:KillDeathRatio = (ZombieDeaths + HumanDeaths) == 0 ? 1.0:float((ZombieKills + HumanKills) / (ZombieDeaths + HumanDeaths));

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEW OTEHR STATS\nKILL/DEATH RATIO: %.2f\nHEADSHOT RATIO: %.2f \%\nINFECTION RATIO: %.2f \%\nONLINE TIME: %d HOURS\n    ", KillDeathRatio, HeadShotRatio, IfectionRatio, PlayTime);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "Back");

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "3 %d", iSteamId);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowRankInfoMenu(Client, &Handle: Menu)
{

	//Handle:
	Menu = CreateMenu(Handle_RankInfo_Menu);

	//Declare:
	decl String:bAllFormat[512];

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING PLUGIN INFOMATION!\n    ");

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Is SQLITE
	if(GetConVarInt(CV_SQLMANAGE) == 1)
	{

		//Format:
		Format(bAllFormat, sizeof(bAllFormat), "ABOUT RANK:\nPLUGIN CODED BY 'MASTER(D)'\nVISIT 'http://mojomsrp.go-networks.net/Test/'\n    \nCONTACT ME FOR:\nFEATURE REQUESTS OR BUG REPORTS\nPLUGIN VERSION %s\nE-MAIL ME AT Master@MnM-Gaming.com\nDB VERSION %s, TYPE SQLITE\nPOWERD BY mnm-gaming.com/\n    ", PLUGINVERSION, SQLVERSION);
	}

	//Is SQLITE
	if(GetConVarInt(CV_SQLMANAGE) == 2)
	{

		//Format:
		Format(bAllFormat, sizeof(bAllFormat), "ABOUT RANK:\nPLUGIN CODED BY 'MASTER(D)'\nVISIT 'http://mojomsrp.go-networks.net/Test/'\n    \nCONTACT ME FOR:\nFEATURE REQUESTS OR BUG REPORTS\nPLUGIN VERSION %s\nE-MAIL ME AT dj_jonezy@live.co.uk\nDB VERSION %s, TYPE MYSQL\n    ", PLUGINVERSION, SQLVERSION);
	}

	//Menu Buttons:
	AddMenuItem(Menu, "1", bAllFormat);

	//Menu Buttons:
	AddMenuItem(Menu, "2", "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowPlayersMenu(Client, &Handle: Menu)
{

	//Declare:
	decl String:PlayerName[64], String:iAllFormat[32], String:bAllFormat[32];

	//Initulize:
	new Ranking = 1;

	//Handle:
	Menu = CreateMenu(Handle_Players_Menu);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING PLAYER LIST!\n    ");

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Loop:
	for(new i = 1; i <= GetMaxClients(); i++)
	{

		//Connected:
		if(!IsClientInGame(i))
		{

			//Return:
			continue;
		}

		//Sql String:
		Format(Query, sizeof(Query), g_SQL_PlayerRank, g_Points[i]);

		//Handle:
		hQuery = SQL_Query(hSQL, Query);

		//Initulize:
		Ranking = 1;

		//Not Player:
		while (SQL_FetchRow(hQuery))
		{

			//Database Field Loading Intiger:
			Ranking = SQL_FetchInt(hQuery, 0) + 1;
		}

		//Close:
		CloseHandle(hQuery);

		//Format:
		Format(iAllFormat, sizeof(iAllFormat), "%d", i);

		//Initulize:
		GetClientName(i, PlayerName, sizeof(PlayerName));

		//Format:
		Format(bAllFormat, sizeof(bAllFormat), "%s (%d)", PlayerName, Ranking);

		//Menu Buttons:
		AddMenuItem(Menu, iAllFormat, PlayerName);
	}

	//Set Exit Button:
	SetMenuExitButton(Menu, true);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Show Menu:
public Action:ShowSessionMenu(Client, &Handle: Menu, Player)
{

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_PlayerRank, g_Points[Player]);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Declare:
	new Ranking = 1, MaxRanking = 1;

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		Ranking = SQL_FetchInt(hQuery, 0) + 1;
	}

	//Close:
	CloseHandle(hQuery);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_RankCount);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Not Player:
	while (SQL_FetchRow(hQuery))
	{

		//Database Field Loading Intiger:
		MaxRanking = SQL_FetchInt(hQuery, 0);
	}

	//Close:
	CloseHandle(hQuery);

	//Declare:
	decl String:bAllFormat[128], String:PlayerName[64], String:iAllFormat[5];

	//Initulize:
	GetClientName(Player, PlayerName, sizeof(PlayerName));

	//Handle:
	Menu = CreateMenu(Handle_Session_Menu);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "VIEWING %s SESSION!\nTHEIR Rank IS CURRENTLY %d (OF %d).\n    ", PlayerName, Ranking, MaxRanking);

	//Title:
	SetMenuTitle(Menu, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "OVERALL SESSION\nPOINTS: %d\nKILLS: %d\nDEATHS: %d\nHEADSHOTS: %d\nINFECTIONS: %d\n    ", g_SessionHeadShots[Player], (g_SessionZombieKills[Player] + g_SessionHumanKills[Player]), (g_SessionZombieDeaths[Player] + g_SessionHumanDeaths[Player]), g_SessionHeadShots[Player], g_SessionInfections[Player]);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "HUMAN SESSION\nSCORE: %d\nKILLS: %d\nDEATHS: %d\n    ", g_SessionHumanScore[Player], g_SessionHumanKills[Player], g_SessionHumanDeaths[Player]);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(bAllFormat, sizeof(bAllFormat), "ZOMBIE SESSION\nSCORE: %d\nKILLS: %d\nDEATHS: %d\n    ", g_SessionZombieScore[Player], g_SessionZombieKills[Player], g_SessionZombieDeaths[Player]);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "1 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, bAllFormat);

	//Format:
	Format(iAllFormat, sizeof(iAllFormat), "2 %d", Player);

	//Menu Buttons:
	AddMenuItem(Menu, iAllFormat, "EXIT", ITEMDRAW_CONTROL);

	//Set Exit Button:
	SetMenuExitButton(Menu, false);

	//Show Menu:
	DisplayMenu(Menu, Client, 60);
}

//Handle Prompting:
public Handle_Rank_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[5], String:hbuffer[2][5];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 5); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Initialize:
		new Player = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowRankMenu(Client, Menu, Player);
		}

		if(Result == 2)
		{

			//Show Menu:
			ShowRankHumanMenu(Client, Menu, Player);
		}

		if(Result == 3)
		{

			//Show Menu:
			ShowRankZombieMenu(Client, Menu, Player);
		}

		if(Result == 4)
		{

			//Show Menu:
			ShowRankOtherMenu(Client, Menu, Player);
		}

		if(Result == 5)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_RankHuman_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[5], String:hbuffer[2][5];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 5); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Initialize:
		new Player = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowRankHumanMenu(Client, Menu, Player);
		}

		if(Result == 2)
		{

			//Show Menu:
			ShowRankMenu(Client, Menu, Player);
		}

		if(Result == 3)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_RankZombie_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[5], String:hbuffer[2][5];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 5); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Initialize:
		new Player = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowRankZombieMenu(Client, Menu, Player);
		}

		if(Result == 2)
		{

			//Show Menu:
			ShowRankMenu(Client, Menu, Player);
		}

		if(Result == 3)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_RankOther_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[5], String:hbuffer[2][5];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 5); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Initialize:
		new Player = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowRankOtherMenu(Client, Menu, Player);
		}

		if(Result == 2)
		{

			//Show Menu:
			ShowRankMenu(Client, Menu, Player);
		}

		if(Result == 3)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_Top_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[32];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Declare:
		new iSteamId = StringToInt(info);

		//Initulize:
		g_MenuSelected[Client] = iSteamId;


		//Show Menu:
		ShowTopRankMenu(Client, Menu, iSteamId);
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_TopRank_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[32], String:hbuffer[2][32];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 32); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Declare:
		new iSteamId = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowTopRankMenu(Client, Menu, iSteamId);
		}

		if(Result == 2)
		{

			//Show Menu:
			ShowTopHumanMenu(Client, Menu, iSteamId);
		}

		if(Result == 3)
		{

			//Show Menu:
			ShowTopZombieMenu(Client, Menu, iSteamId);
		}

		if(Result == 4)
		{

			//Show Menu:
			ShowTopOtherMenu(Client, Menu, iSteamId);
		}

		if(Result == 5)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_TopHuman_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[32], String:hbuffer[2][32];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 32); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Declare:
		new iSteamId = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowTopHumanMenu(Client, Menu, iSteamId);
		}

		if(Result == 2)
		{

			//Show Menu:
			ShowTopRankMenu(Client, Menu, iSteamId);
		}

		if(Result == 3)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_TopZombie_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[32], String:hbuffer[2][32];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 32); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Declare:
		new iSteamId = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowTopZombieMenu(Client, Menu, iSteamId);
		}

		if(Result == 2)
		{

			//Show Menu:
			ShowTopRankMenu(Client, Menu, iSteamId);
		}

		if(Result == 3)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_TopOther_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[32], String:hbuffer[2][32];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 32); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Declare:
		new iSteamId = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowTopOtherMenu(Client, Menu, iSteamId);
		}

		if(Result == 2)
		{

			//Show Menu:
			ShowTopRankMenu(Client, Menu, iSteamId);
		}

		if(Result == 3)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_RankInfo_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[5];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Initialize:
		new Result = StringToInt(info);

		if(Result == 1)
		{

			//Show Menu:
			ShowRankInfoMenu(Client, Menu);
		}

		if(Result == 2)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_Players_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[32];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Get Player:
		new Player = StringToInt(info);

		//Show Menu:
		ShowRankMenu(Client, Menu, Player);
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Handle Prompting:
public Handle_Session_Menu(Handle:Menu, MenuAction:HandleAction, Client, Parameter)
{

	//Selected:
	if(HandleAction == MenuAction_Select)
	{

		//Declare:
		decl String:info[5], String:hbuffer[2][5];

		//Get Menu Info:
		GetMenuItem(Menu, Parameter, info, sizeof(info));

		//Explode:
		ExplodeString(info, " ", hbuffer, 2, 5); 

		//Initialize:
		new Result = StringToInt(hbuffer[0]);

		//Initialize:
		new Player = StringToInt(hbuffer[1]);

		if(Result == 1)
		{

			//Show Menu:
			ShowSessionMenu(Client, Menu, Player);
		}

		if(Result == 2)
		{

			//Initulize:
			HandleAction = MenuAction_End;
		}
	}

	//Selected:
	else if(HandleAction == MenuAction_End)
	{

		//Close:
		CloseHandle(Menu);
	}

	//Return:
	return true;
}

//Covert To String:
stock SteamIdToInt(const String:SteamId[], nBase = 10)
{

	//Declare:
	decl String:subinfo[3][16];

	//Explode:
	ExplodeString(SteamId, ":", subinfo, sizeof(subinfo), sizeof(subinfo[]));

	//Initulize:
	new Int = StringToInt(subinfo[2], nBase);

	if(StrEqual(subinfo[1], "1"))
	{

		//Initulize:
		Int *= -1;
	}

	//Return:
	return Int;
}

//Fetch Client Details:
public Action:CreateSQLAccount(Handle:Timer, any:Client)
{

	//Connected:
	if(IsClientConnected(Client))
	{

		//Declare:
		decl String:SteamId[64];

		//Initialize:
		GetClientAuthString(Client, SteamId, sizeof(SteamId));

		//No SteamId:
		if(StrEqual(SteamId, "") || InQuery)
		{

			//Timer:
			CreateTimer(1.0, CreateSQLAccount, Client);
		}

		//Override
		else
		{

			//Initialize:
			InQuery = true;

			//Load:
			DBLoad(Client);
		}	
	}
}

//Create Database:
public Action:CreateSQLdbplayer(Handle:Timer)
{

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_CreatePlayerRankTables);

	//Lock Database Threading:
	SQL_LockDatabase(hSQL);

	//Lock Created Tables:
	if(!SQL_FastQuery(hSQL, Query))
	{
#if defined FAIL
		//Fail State:
		SetFailState("|DataBase| SQL: Could not create (PlayerRank) Database tables");
#endif
#if defined DEBUG
		//Logging
		LogMessage("|DataBase| SQL: Could not create (PlayerRank) Database tables");
#endif
	}

	//Override
	else
	{
#if defined DEBUG
		//Logging
		LogMessage("|DataBase| SQL: Creating (PlayerRank) Database tables");
#endif
	}

	//UnLock Created Tables:
	SQL_UnlockDatabase(hSQL);

	//Update Database:
	UpdateSQL();
}

public UpdateSQL()
{

	//Declare:
	decl String:SteamId[64];

	//Loop:
	for(new i = 1; i <= GetMaxClients(); i++)
	{

		//Connected:
		if(IsClientConnected(i)) 
		{

			//Initulize
			GetClientAuthString(i, SteamId, sizeof(SteamId));

			//Load Player:
			DBLoad(i);
		}
	}
}

public Action:Handle_UpdatePlayers(Handle:timer)
{

	//Loop:
	for (new i = 1; i <= GetMaxClients(); i++)
	{

		//Connected:
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{

			//Update:
			UpdatePlayer(i);
		}
	}
}

public UpdatePlayer(Client)
{

	//Declare:
	decl String:SteamId[256];

	//Initialize:
	GetClientAuthString(Client, SteamId, sizeof(SteamId));

	//Declare:
	new iSteamId = SteamIdToInt(SteamId);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_SelectPlayerRank, iSteamId);

	//Handle:
	hQuery = SQL_Query(hSQL, Query);

	//Refresh DB:
	SQL_Rewind(hQuery);

	//Not Player:
	if(!SQL_FetchRow(hQuery))
	{

		//Sql String:
		Format(Query, sizeof(Query), g_SQL_CreateNewPlayer, iSteamId);

		//Not Created Tables:
		if(!SQL_FastQuery(hSQL, Query))
		{
#if defined DEBUG
			//Logging
			LogMessage("|DataBase| SQL: Could not insert Player into database (%s) (%s)", SteamId);
#endif
		}

		//Override:
		else
		{
#if defined DEBUG
			//Logging
			LogMessage("|DataBase| SQL: Inserted new Player into the database (%s) (%s)", SteamId);
#endif
		}
	}

	//Close:
	CloseHandle(hQuery);

	//Declare:
	decl String:ClientName[64], String:CNameQuery[64];

	//Initialize:
	GetClientName(Client, ClientName, sizeof(ClientName));

	//Remove Harmfull Strings:
	SQL_EscapeString(hSQL, ClientName, CNameQuery, sizeof(CNameQuery));

	//Sql Strings:
	Format(Query, sizeof(Query), g_SQL_UpdatePlayTime, CNameQuery, iSteamId);

	//Not Created Tables:
	if(!SQL_FastQuery(hSQL, Query))
	{
#if defined DEBUG
		//Logging
		LogMessage("|DataBase| SQL: Could not insert Player into database (%s)", SteamId);
#endif
	}

	//Override:
	else
	{
#if defined DEBUG
		//Logging
		LogMessage("|DataBase| SQL: Inserted new Player into the database (%s)", SteamId);
#endif
	}
}

public InsertPlayer(Client)
{

	//Declare:
	decl String:SteamId[256];

	//Initialize:
	GetClientAuthString(Client, SteamId, sizeof(SteamId));

	//Declare:
	new iSteamId = SteamIdToInt(SteamId);

	//Sql String:
	Format(Query, sizeof(Query), g_SQL_CreateNewPlayer, iSteamId);

	//Not Created Tables:
	if(!SQL_FastQuery(hSQL, Query))
	{
#if defined DEBUG
		//Logging
		LogMessage("|DataBase| SQL: Could not insert Player into database (%s)", SteamId);
#endif
	}

	//Override:
	else
	{
#if defined DEBUG
		//Logging
		LogMessage("|DataBase| SQL: Inserted new Player into the database (%s)", SteamId);
#endif
	}
}

//Load:
public DBLoad(Client)
{

	//Connected:
	if(IsClientConnected(Client))
	{

		//Declare:
		decl String:SteamId[256];

		//Initialize:
		GetClientAuthString(Client, SteamId, sizeof(SteamId));

		//Declare:
		new iSteamId = SteamIdToInt(SteamId);

		//Sql String:
		Format(Query, sizeof(Query), g_SQL_SelectPlayerRank, iSteamId);

		//Handle:
		hQuery = SQL_Query(hSQL, Query);

		//Refresh DB:
		SQL_Rewind(hQuery);

		//Not Player:
		if(!SQL_FetchRow(hQuery))
		{

			//Insert Player:
			InsertPlayer(Client);
		}

		//Override:
		else
		{

			//Database Field Loading Intiger:
			g_Points[Client] = SQL_FetchInt(hQuery, 3);

			//Database Field Loading Intiger:
			g_ZombieKills[Client] = SQL_FetchInt(hQuery, 4);

			//Database Field Loading Intiger:
			g_ZombieDeaths[Client] = SQL_FetchInt(hQuery, 5);

			//Database Field Loading Intiger:
			g_ZombieScore[Client] = SQL_FetchInt(hQuery, 6);

			//Database Field Loading Intiger:
			g_ZombieDamageDone[Client] = SQL_FetchInt(hQuery, 7);

			//Database Field Loading Intiger:
			g_ZombieDamageRecieved[Client] = SQL_FetchInt(hQuery, 8);

			//Database Field Loading Intiger:
			g_HumanKills[Client] = SQL_FetchInt(hQuery, 9);

			//Database Field Loading Intiger:
			g_HumanDeaths[Client] = SQL_FetchInt(hQuery, 10);

			//Database Field Loading Intiger:
			g_HumanScore[Client] = SQL_FetchInt(hQuery, 11);

			//Database Field Loading Intiger:
			g_HumanDamageDone[Client] = SQL_FetchInt(hQuery, 12);

			//Database Field Loading Intiger:
			g_HumanDamageRecieved[Client] = SQL_FetchInt(hQuery, 13);

			//Database Field Loading Intiger:
			g_HeadShots[Client] = SQL_FetchInt(hQuery, 14);

			//Database Field Loading Intiger:
			g_Infections[Client] = SQL_FetchInt(hQuery, 15);
		}

		//Close:
		CloseHandle(hQuery);

		//Declare:
		decl String:ClientName[64], String:CNameQuery[64];

		//Initialize:
		GetClientName(Client, ClientName, sizeof(ClientName));

		//Remove Harmfull Strings:
		SQL_EscapeString(hSQL, ClientName, CNameQuery, sizeof(CNameQuery));

		//Format:
		Format(Query, sizeof(Query), g_SQL_UpdatePlayerName, CNameQuery, iSteamId);

		//Not Created Tables:
		if(!SQL_FastQuery(hSQL, Query))
		{
#if defined DEBUG
			//Logging
			LogMessage("|DataBase| SQL: Could not update Player name (%s) (%s)", CNameQuery, SteamId);
#endif
		}

		//Initialize:
		IsDisconnect[Client] = false;

		Loaded[Client] = true;

		InQuery = false;

		//Handle:
		new Handle:Menu;

		//Show Menu:
		ShowRankMenu(Client, Menu, Client);
	}

	//Return:
	return;
}