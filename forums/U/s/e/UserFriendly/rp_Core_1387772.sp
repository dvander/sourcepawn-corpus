
//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <StockRP>
#include <colors>

//Terminate:
#pragma semicolon		1
#pragma compress		0

#define PLUGINVERSION		"1.0"
#define SQLVERSION		"1.4b"

//Point Log File:
#define LOGFILE "addons/sourcemod/logs/ZombieMod_Logging/ZM_Logging.log"

//ConVars:
enum XCVar
{
	Handle:CV_FALLDAMAGE,
	Handle:CV_FRIENDLYFIRE,
	Handle:CV_CONNECTANNONCE,
	Handle:CV_GAMENAME,
	Handle:CV_SHOCKTIME,
	Handle:CV_ARMORFALLDAMAGE,
	Handle:CV_SQLMANAGE
};

//Database Sql:
static Handle:hSQL;
static bool:InQuery;
static bool:SQLLite = false;
static bool:DBConnected = false;
static bool:Loaded[MAXPLAYERS + 1];
static bool:IsDisconnect[MAXPLAYERS + 1];

//Global Forwards:
static bool:MapRunning = false;

//Cvar Handle:
static Handle:CVAR[XCVar] = INVALID_HANDLE;

//Global Event Handles:
static Handle:g_TeamForward;
static Handle:g_DeathForward;
static Handle:g_SpawnForward;

//Global Variables:
//static IsDonator[MAXPLAYERS + 1] = {0,...};
//static IsCuffed[MAXPLAYERS + 1] = {0,...};
//static IsCop[MAXPLAYERS + 1] = {0,...};

//Miscs
static UserMsg:FadeID;
static UserMsg:ShakeID;

//Plugin Info:
public Plugin:myinfo =
{
	name = "Role Play Core",
	author = "Master(D)",
	description = "Role Play Game",
	version = PLUGINVERSION,
	url = ""
}

//Initation:
public OnPluginStart()
{

	//Declare:
	decl String:GameName[128], String:Map[128];

	//Initialize:
	GetCurrentMap(Map, 128);
	GetGameFolderName(GameName, sizeof(GameName));

	//Not Map:
	if(!StrEqual(GameName, "hl2mp"))
	{

		//Fail State:
		SetFailState("|ZM| This Plugin Only Sopports 'HL2DM'");
	}

	//Not SDKHooks:
	if(GetExtensionFileStatus("sdkhooks.ext") < 1)
	{

		//Fail State:
		SetFailState("|ZM| This Plugin Needs 'SDKHooks 1.3 Or Latter'");
	}

	//Print Server If Plugin Start:
	PrintToConsole(0, "|RolePlay| Successfully Loaded (v%s)!", PLUGINVERSION);

	//Handle:
	new Handle:ENABLETEAMPLAY = FindConVar("mp_teamplay");

	//Not Teamplay:
	if(GetConVarInt(ENABLETEAMPLAY) != 1)
	{

		//Command:
		ServerCommand("sm_cvar \"mp_teamplay\" \"1\"");

		ServerCommand("sm_cvar \"mp_flashlight\" \"1\"");

		ServerCommand("sm_map \"%s\"", Map);
	}

	//Global Hooks:
	g_DeathForward = CreateGlobalForward("OnClientDied", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell);

	g_TeamForward = CreateGlobalForward("OnClientTeam", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

	g_SpawnForward = CreateGlobalForward("OnClientSpawn", ET_Event, Param_Cell, Param_Cell);

	//User Messages:
	FadeID = GetUserMessageId("Fade");

	ShakeID = GetUserMessageId("Shake");

	//ConVar Hooks:
	CVAR[CV_CONNECTANNONCE] = CreateConVar("sm_connect_announce", "1", "enable/disable player connet announce default (1)", FCVAR_PLUGIN);

	CVAR[CV_FRIENDLYFIRE] = CreateConVar("sm_friendlyfire", "1", "enable dynamic zm friendly fire default (1)", FCVAR_PLUGIN);

	CVAR[CV_FALLDAMAGE] = CreateConVar("sm_disable_falldamage", "1","Enables fall damage default (1)", FCVAR_PLUGIN);

	CVAR[CV_GAMENAME] = CreateConVar("sm_gamename", "Roleplay New", "Game Description Override", FCVAR_PLUGIN);

	CVAR[CV_SHOCKTIME] = CreateConVar("s,_shocktime", "5.0", "Set the ammont of time a player is in shick default (5.0)", FCVAR_PLUGIN);

	CVAR[CV_ARMORFALLDAMAGE] = CreateConVar("sm_disable_armorfalldamage", "1", "Enables Armor damage on fall default (1)", FCVAR_PLUGIN);

	CVAR[CV_SQLMANAGE] = CreateConVar("sm_sqltype", "1", "1 use sql noconfig needed/ 2 use mysql need mconfig default (1)", FCVAR_PLUGIN);

	//Connect To Sql Database:
	InitMySQL();

}

//Map Start:
public OnMapStart()
{

	//Event Hooking:
	if(!HookEventEx("player_death", EventDeath_Forward))
	{

		//Print:
		SetFailState("Source Hook 'Player_Death' Not Found");
	}

	//Event Hooking:
	if(!HookEventEx("player_spawn", Eventspawn_Forward))
	{

		//Print:
		SetFailState("Source Hook 'Player_spawn' Not Found");
	}

	//Event Hooking:
	if(!HookEventEx("player_team", EventTeam_Forward, EventHookMode_Pre))
	{

		//Print:
		SetFailState("Source Hook 'Player_Team' Not Found");
	}

	//Event Hooking:
	if(!HookEventEx("player_connect", EventConnect_Forward, EventHookMode_Pre))
	{

		//Print:
		SetFailState("Source Hook 'Player_Connect' Not Found");
	}

	//Event Hooking:
	if(!HookEventEx("player_disconnect", EventDisconnect_Forward, EventHookMode_Pre))
	{

		//Print:
		SetFailState("Source Hook 'Player_Disconnect' Not Found");
	}

	//Not Fall Damage:
	if(GetConVarInt(CVAR[CV_FALLDAMAGE]) == 1)
	{

		//Command:
		ServerCommand("sm_cvar \"mp_falldamage\" \"1\"");
	}

	//Not Friendly Fire
	if(GetConVarInt(CVAR[CV_FRIENDLYFIRE]) == 1)
	{

		//Command:
		ServerCommand("sm_cvar \"mp_friendlyfire\" \"1\"");
	}

	//Map Running:
	MapRunning = true;
}

//Map End:
public OnMapEnd()
{

	//Map Not Running:
	MapRunning = false;
}

//Is Extension Loaded:
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{

	//Point Out Extension:
	MarkNativeAsOptional("SDKHook");

	MarkNativeAsOptional("SDKUnhook");

	//Close:
	CloseHandle(myself);

	//Return:
	return APLRes_Success;
}
//Sdkhooks:
public OnAllPluginsLoaded()
{

	//Is Extension Is Loaded:
	if(GetExtensionFileStatus("sdkhooks.ext") != 1)
	{

		//Print Fail State:
		SDKHooksFail();
	}
}

//SdkHooks:
public OnLibraryRemoved(const String:name[])
{

	//Is Extension Is Loaded:
	if(strcmp(name, "sdkhooks.ext") == 0)
	{

		//Print Fail State:
		SDKHooksFail();
	}
}

SDKHooksFail()
{

	//Print:
	SetFailState("SDKHooks is required for RolePlay");
}

//public OnClientPutInServer(Client)
public OnClientPostAdminCheck(Client)
{

	//Client Hooking:
	if(!SDKHookEx(Client, SDKHook_OnTakeDamage, OnClientDamage))
	{
		//Fail State Print:
		SetFailState("SDK Hooks was unable to load 'SDKHook_OnTakeDamage'");
	}

	//Timer:
	CreateTimer(0.5, CreateSQLAccount, Client);
}

//Disconnect:
public OnClientDisconnect(Client)
{

	//Client Hook:
	if(SDKHookEx(Client, SDKHook_OnTakeDamage, OnClientDamage))
	{

		//Client Unhooking:
		SDKUnhook(Client, SDKHook_OnTakeDamage, OnClientDamage);
	}

	//Save:
	DBSave(Client);

	//Initialize:
	Loaded[Client] = false;
}

//Client Steam Id Valid:
public OnClientAuthorized(Client,const String:auth[])
{

	//Convar:
	if(GetConVarInt(CVAR[CV_CONNECTANNONCE]) == 1)
	{

		//Declare:
		decl String:ClientName[32];

		//Initialize:
		GetClientName(Client, ClientName, 32);

		//Print:
		CPrintToChatAll("\x05Player %s has joined the game (%s)", ClientName, auth);
	}

}


/////////////////////////////////////////////////////////////////////
/////			  Game Name Override:			/////
/////////////////////////////////////////////////////////////////////

//Game Info Changer:
public Action:OnGetGameDescription(String:gameDesc[64])
{

	//Not Map:
	if(MapRunning)
	{

		//Declare:
		decl String:Override[32];

		//Get String:
		GetConVarString(CVAR[CV_GAMENAME], Override, 32);

		//Format:
		Format(gameDesc, sizeof(gameDesc), "%s", Override);

		//Return:
		return Plugin_Changed;
	}

	//Return
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
/////			  Hook Forwards:			/////
/////////////////////////////////////////////////////////////////////

//EventDeath Farward:
public Action:EventDeath_Forward(Handle:Event, const String:name[], bool:dontBroadcast)
{

	//Declare:
	decl String:weapon[64], Action:result;

	//Start Forward:
	Call_StartForward(g_DeathForward);

	//Get String:
	GetEventString(Event, "weapon", weapon, sizeof(weapon));

	//Get Users:
	Call_PushCell(GetClientOfUserId(GetEventInt(Event, "userid")));
	Call_PushCell(GetClientOfUserId(GetEventInt(Event, "attacker")));

	//Get Weapon:
	Call_PushString(weapon);

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
public Action:EventTeam_Forward(Handle:Event, const String:name[], bool:dontBroadcast)
{

	//Declare:
	decl Action:result;

	//Start Forward:
	Call_StartForward(g_TeamForward);

	//Get Users:
	Call_PushCell(GetClientOfUserId(GetEventInt(Event, "userid")));
	Call_PushCell(GetEventInt(Event, "team"));
	Call_PushCell(GetEventInt(Event, "oldteam"));

	//Finnish Forward:
	Call_Finish(_:result);

	//Set Broadcast:
	SetEventBroadcast(Handle:Event, true);

	//Close:
	CloseHandle(Event);

	//Return:
	return result;
}

//EventDeath Farward:
public Action:Eventspawn_Forward(Handle:Event, const String:name[], bool:dontBroadcast)
{

	//Declare:
	decl Action:result;

	//Start Forward:
	Call_StartForward(g_SpawnForward);

	//Get Users:
	Call_PushCell(GetClientOfUserId(GetEventInt(Event, "userid")));

	//Finnish Forward:
	Call_Finish(_:result);

	//Set Broadcast:
	SetEventBroadcast(Handle:Event, true);

	//Close:
	CloseHandle(Event);

	//Return:
	return result;
}

/////////////////////////////////////////////////////////////////////
/////			  Event Suppressers:			/////
/////////////////////////////////////////////////////////////////////

//Event Player Disconnect:
public Action:EventConnect_Forward(Handle:event, const String:name[], bool:dontBroadcast)
{

	//Dont Broardcast:
	if(!dontBroadcast)
	{

		//Declare:
		decl String:clientName[33], String:networkID[22], String:address[32];

		//Get Event Strings:
		GetEventString(event, "name", clientName, sizeof(clientName));
		GetEventString(event, "networkid", networkID, sizeof(networkID));
		GetEventString(event, "address", address, sizeof(address));

		//Handle:
		new Handle:newEvent = CreateEvent("player_connect", true);

		//Set Event Strings:
		SetEventString(newEvent, "name", clientName);

		//Set Event Intiger:
		SetEventInt(newEvent, "index", GetEventInt(event, "index"));
		SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));

		//Set Event Strings:
		SetEventString(newEvent, "networkid", networkID);
		SetEventString(newEvent, "address", address);

		//Start Event:
		FireEvent(newEvent, true);

		//Return:
		return Plugin_Handled;
	}

	//Return:
	return Plugin_Continue;
}

//Event Player Connect:
public Action:EventDisconnect_Forward(Handle:event, const String:name[], bool:dontBroadcast)
{

	//Dont Broardcast:
	if(!dontBroadcast)
	{

		//Declare:
		decl String:clientName[33], String:networkID[22], String:reason[65];

		//Get Event Strings:
		GetEventString(event, "name", clientName, sizeof(clientName));
		GetEventString(event, "networkid", networkID, sizeof(networkID));
		GetEventString(event, "reason", reason, sizeof(reason));

		//Handle:
		new Handle:newEvent = CreateEvent("player_disconnect", true);

		//Set Event Intiger:
		SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));

		//Set Event Strings:
		SetEventString(newEvent, "reason", reason);
		SetEventString(newEvent, "name", clientName);        
		SetEventString(newEvent, "networkid", networkID);

		//Start Event:
		FireEvent(newEvent, true);

		//Return:
		return Plugin_Handled;
	}

	//Return:
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
/////			     Game Events:			/////
/////////////////////////////////////////////////////////////////////

//Event Death:
public Action:OnClientSpawn(Client)
{

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client))
	{

		//Timer:
		CreateTimer(0.1, OnSpawnSetup, Client);
	}
}

//Event Death:
public Action:OnClientTeam(Client, NewTeam, OldTeam)
{

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client))
	{

	}
}

//Event Death:
public Action:OnClientDied(Client, Attacker, const String:weapon[], bool:headshot)
{

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client))
	{

	}
}

//Event Damage:
public Action:OnClientDamage(Client, &attacker, &inflictor, &Float:damage, &damageType)
{

	//Not Fall Damage:
	if(damageType == DMG_FALL && GetConVarFloat(CVAR[CV_ARMORFALLDAMAGE]) != 0)
	{

		//Initialize:
		damage *= 1.5;

		//Declare:
		new Float:Armor = float(GetClientArmor(Client));

		//Has No Armor:
		if(Armor == 0.0)
		{

			//Initialize:
			damage = FloatMul(damage, GetRandomFloat(0.50, 1.50));
		}

		//Has Armor :
		else if((Armor - damage) < 1 && (Armor != 0.0))
		{

			//Set Armor:
			SetEntityArmor(Client, 0);

			//Initialize:
			damage = FloatMul(damage, GetRandomFloat(0.25, 0.75));
		}

		//Has Armor With Right Damage to armor value:
		else if(FloatDiv(Armor, damage) > 1.0)
		{

			//Set Armor:
			SetEntityArmor(Client, RoundToNearest(FloatDiv(Armor, damage)));

			//Initialize:
			damage = FloatMul(damage, GetRandomFloat(0.25, 0.75));
		}

		//Override:
		else
		{
			//Set Armor:
			SetEntityArmor(Client, 0);
		}

		//Shake Client:
		ShakeClient(Client, GetConVarFloat(CVAR[CV_SHOCKTIME])/2.0, 5.0);

		//Return:
		return Plugin_Changed;
	}

	//Return:
	return Plugin_Continue;
}

/////////////////////////////////////////////////////////////////////
/////			       Timers:				/////
/////////////////////////////////////////////////////////////////////

//Spawn Timer:
public Action:OnSpawnSetup(Handle:Timer, any:Client)
{

	//Connected:
	if(Client > 0 && IsClientConnected(Client) && IsClientInGame(Client))
	{

		//Set Hud:
		HideHud(Client, 64);
	}
}


/////////////////////////////////////////////////////////////////////
/////			     Local Stocks:			/////
/////////////////////////////////////////////////////////////////////

//shake effect
stock ShakeClient(Client, Float:Length, Float:Severity)
{

	//Conntected:
	if(IsClientConnected(Client) && IsClientInGame(Client))
	{

		//Declare:
		new SendClient[2];
		SendClient[0] = Client;

		//Handle:
		new Handle:ViewMessage = StartMessageEx(ShakeID, SendClient, 1);

		//Write Handle:
		BfWriteByte(ViewMessage, 0);
		BfWriteFloat(ViewMessage, Severity);
		BfWriteFloat(ViewMessage, 10.0);
		BfWriteFloat(ViewMessage, Length);

		//Close:
		EndMessage();
	}
}

//Fade Effect:
public FadeClient(Client, bool:out)
{

	//Conntected:
	if(IsClientConnected(Client) && IsClientInGame(Client))
	{

		//Declare
		new SendClient[2];
		SendClient[0] = Client;

		//Handle:
		new Handle:ViewMessage = StartMessageEx(FadeID, SendClient, 1);

		//Write Handle:
		BfWriteShort(ViewMessage, 3000); //fade time
		BfWriteShort(ViewMessage, 0); //hold time
		if (out)
		{

			//Out and Stayout
			BfWriteShort(ViewMessage, 0x0002|0x0008);
		}

		//Override:
		else
		{

			//In Ignore Other Fades
			BfWriteShort(ViewMessage, 0x0001|0x0010);
		}

		//Red
		BfWriteByte(ViewMessage, 25);

		//Green
		BfWriteByte(ViewMessage, 0);

		//Blue
		BfWriteByte(ViewMessage, 0);

		//Alpha
		BfWriteByte(ViewMessage, 250);

		//Cloose:
		EndMessage();
	}
}

//Setup Sql Connection:
public InitMySQL()
{

	//Declare:
	decl String:error[512];

	//Not SQLite:
	if(GetConVarInt(CVAR[CV_SQLMANAGE]) == 1)
	{

		//Handle:
		new Handle:kv = INVALID_HANDLE;

		//Initialize:
		kv = CreateKeyValues("");

		//Set String:
		KvSetString(kv, "driver", "sqlite"); 
		KvSetString(kv, "database", "RolePlayDB");

		//Sql Connect:
		hSQL = SQL_ConnectCustom(kv, error, sizeof(error), true);

		//Not Connected:
		if(hSQL==INVALID_HANDLE)
		{

			//Logging:
			LogToFileEx(LOGFILE,"|DataBase| Error %s", error);
		}

		//Override
		else
		{

			//Logging:
			LogToFileEx(LOGFILE,"|DataBase| Connected to Sqlite Database. Version %s",SQLVERSION);

			//Initialize:
			DBConnected = true;
		}

		//Close:
		CloseHandle(kv);

		//Initialize:
		SQLLite = true;
	}

	//Not MYSQL
	if(GetConVarInt(CVAR[CV_SQLMANAGE]) == 2)
	{

		//Declare:
		decl String:SQLDriver[32];

		//find Configeration:
		if(SQL_CheckConfig("RoleplayDB"))
		{

			///Sql Connect:
			hSQL = SQL_Connect("RoleplayDB",true,error, sizeof(error));

			//Not Conntected:
			if(hSQL==INVALID_HANDLE)
			{

				//Logging:
				LogToFileEx(LOGFILE,"|DataBase| Error %s", error);
			}

			//Read SQL Driver
			SQL_ReadDriver(hSQL, SQLDriver, sizeof(SQLDriver));

			//Sqlite
			if(strcmp(SQLDriver, "sqlite", false)==0)
			{

				//Logging:
				LogToFileEx(LOGFILE,"|DataBase| Connected to Sqlite Database I.e External Config. Version %s",SQLVERSION);

				//Initialize:
				DBConnected = true;
				SQLLite = true;
			}

			//MYSQL
			if(strcmp(SQLDriver, "mysql", false)==0)
			{

				//Logging:
				LogToFileEx(LOGFILE,"|DataBase| Connected to MySql Database. Version %s",SQLVERSION);

				//Initialize:
				DBConnected = true;
				SQLLite = false;
			}
		}

		//Override:
		else
		{

			//Logging:
			LogToFileEx(LOGFILE,"|DataBase| No MySql Configeration Found In database.cfg");
			SQLLite = false;
		}
	}

	//No Database Connection:
	if(!DBConnected)
	{

		//Logging:
		LogToFileEx(LOGFILE,"|DataBase| Could not Connect to a DataBase.");

		//Initialize:
		SQLLite = false;
	}

	//Return:
	return;
}

//Create Tables:
public createdb()
{

	//MYSQL:
	if(!SQLLite)
	{

		//Timer:
		CreateTimer(0.2,CreateMySQLdbplayer);
	}

	//Override:
	else
	{

		//Timer:
		CreateTimer(0.2,CreateSQLitedbplayer);
	}
}

//Create MYSQL Database:
public Action:CreateMySQLdbplayer(Handle:Timer)
{

	//Declare:
	new len = 0;
	decl String:query[2000];

	//Sql String:
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "  `LASTONTIME` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, "  PRIMARY KEY  (`STEAMID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE = MyISAM DEFAULT CHARSET = utf8;");



	//Not Created Tables:
	if(!SQL_FastQuery(hSQL, query))
	{

		//Fail State:
		SetFailState("|DataBase| MySQL: Could not create (Player) Database tables");

		//Logging
		LogToFileEx(LOGFILE,"|DataBase| MySQL: Could not create (Player) Database tables");
	}

	//Override
	else
	{

		//Logging
		LogToFileEx(LOGFILE,"|DataBase| MySQL: Creating (Player) Database tables");

		//Created Tables:
		SQL_FastQuery(hSQL, query);
	}
}

//Create SQLite Database:
public Action:CreateSQLitedbplayer(Handle:Timer)
{

	//Declare:
	new len = 0;
	decl String:query[2000];

	//Sql String:
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Player`");
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `NAME` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `LASTONTIME` INTEGER,");
	len += Format(query[len], sizeof(query)-len, "  PRIMARY KEY (`STEAMID`));");

	//Not Created Tables:
	if(!SQL_FastQuery(hSQL, query))
	{

		//Fail State:
		SetFailState("|DataBase| SQLite: Could not create (Player) Database tables");

		//Logging
		LogToFileEx(LOGFILE,"|DataBase| SQLite: Could not create (Player) Database tables");
	}

	//Override:
	else
	{

		//Logging
		LogToFileEx(LOGFILE,"|DataBase| SQLite: Creating (Player) Database tables");

		//Created Tables:
		SQL_FastQuery(hSQL, query);
	}
}

//Reset Timer:
public Action:DBSave_Restart(Handle:Timer, any:Client)
{

	//Save:
	DBSave(Client);

	//ReturnL
	return Plugin_Handled;
}

stock InsertPlayer(Client)
{

	//Declare:
	decl String:ClientName[255], String:buffer[255];

	//Initialize:
	GetClientName(Client, ClientName, sizeof(ClientName));

	//Remove Harmfull Strings:
	SQL_EscapeString(hSQL, ClientName, ClientName, sizeof(ClientName));

	//Declare:
	decl String:SteamId[255];

	//Unlock DB:
	SQL_LockDatabase(hSQL);

	//Initialize:
	GetClientAuthString(Client, SteamId, sizeof(SteamId));

	//Sql String:
	Format(buffer, sizeof(buffer), "INSERT INTO Player (`NAME`,`STEAMID`,`LASTONTIME`) VALUES ('%s','%s',%i);", ClientName, SteamId, GetTime());	

	//Created Tables:
	SQL_FastQuery(hSQL,buffer);

	//Lock DB:
	SQL_UnlockDatabase(hSQL);
}

//Save:
stock DBSave(Client)
{

	//Connected:
	if(!IsClientConnected(Client))
	{

		//Return:
		return true;
	}

	//Reset Timer:
	if(InQuery)
	{

		//Timer:
		CreateTimer(1.0, DBSave_Restart, Client);

		//Return:
		return true;
	}

	//Not Loaded:
	if(Loaded[Client])
	{

		//Initialize:
		InQuery = true;

		//Unlocl DB:
		SQL_LockDatabase(hSQL);

		//Declare:
		decl String:ClientName[64],String:SteamId[32],String:query[2000];

		//Initialize:
		GetClientAuthString(Client, SteamId, 32);
		GetClientName(Client, ClientName, 64);

		//Remove Harmfull Strings:
		SQL_EscapeString(hSQL, ClientName, ClientName, sizeof(ClientName));
		SQL_EscapeString(hSQL, SteamId, SteamId, sizeof(SteamId));

		//Declare:
		new len = 0;

		//Sql Strings:
		len += Format(query[len], sizeof(query)-len, "UPDATE Player SET NAME = '%s',", ClientName);
		len += Format(query[len], sizeof(query)-len, "LASTONTIME = %f WHERE STEAMID = '%s';", GetGameTime(), SteamId);

		//Handle:
		SQL_FastQuery(hSQL, query);

		//Not Connected:
		if(IsDisconnect[Client])
		{

			//Initialize:
			Loaded[Client] = false;
			IsDisconnect[Client] = false;
		}

		//Initialize:
		InQuery = false;
		
		//Lock DB:
		SQL_UnlockDatabase(hSQL);
	}

	//Return:
	return true;
}

//Load:
stock DBLoad(Client)
{

	//Connected:
	if(!IsClientConnected(Client))
	{

		//Return:
		return true;
	}

	//Declare:
	decl String:SteamId[255], String:buffer[255];

	//Initialize:
	GetClientAuthString(Client, SteamId, sizeof(SteamId));

	//Sql String:
	Format(buffer, sizeof(buffer),"SELECT * FROM Player WHERE STEAMID = '%s';",SteamId);

	//Handle:
	new Handle:query = SQL_Query(hSQL,buffer);

	//Not Connected:
	if(query)
	{

		//Refresh DB:
		SQL_Rewind(query);

		//Fetch Data:
		new bool:fetch=SQL_FetchRow(query);

		//Not Player:
		if(!fetch)
		{

			//Insert Player:
			InsertPlayer(Client);
		}

		//Override:
		else
		{

		}
	}

	//Close:
	CloseHandle(query);

	//Initialize:
	IsDisconnect[Client] = false;
	Loaded[Client] = true;
	InQuery = false;

	//Return:
	return true;
}

public Action:CreateSQLAccount(Handle:Timer, any:Client)
{

	//Declare:
	decl String:SteamId[64];

	//Initialize:
	GetClientAuthString(Client, SteamId, 64);

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