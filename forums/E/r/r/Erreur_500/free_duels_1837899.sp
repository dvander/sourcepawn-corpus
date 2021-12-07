#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <free_duels>


#define PLUGIN_NAME         "Free duels"
#define PLUGIN_AUTHOR       "Erreur 500"
#define PLUGIN_DESCRIPTION	"Challenge other players"
#define PLUGIN_VERSION      "2.05"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"
#define WEBSITE 			"http://adf.ly/qVkzU"
#define MAX_LINE_WIDTH 		60
#define CHECK_DELAY 		0.1


enum DuelData
{
    Challenger,
	bool:Enabled,
	Type,
    Score,
	PlayedTime,
	kills,
	Deads,
	ClassRestrict,
	GodMod,
	bool:HeadShot,
	TimeLeft,
	CSprite,
	SpriteParent,
	bool:HideSprite,
}

new g_Duel[MAXPLAYERS+1][DuelData];

new	victories[MAXPLAYERS+1]			= {0, ...};
new death[MAXPLAYERS+1]				= {0, ...};
new	killsNbr[MAXPLAYERS+1]			= {0, ...};
new total[MAXPLAYERS+1]				= {0, ...};
new Float:points[MAXPLAYERS+1]		= {0.0, ...};

new bool:Abandon[MAXPLAYERS+1]		= {false, ...};
new bool:Equality[MAXPLAYERS+1]		= {false, ...};
new bool:Winner[MAXPLAYERS+1]		= {false, ...};
new bool:SQLite 					= false;

new Handle:c_EnableType[4]			= {INVALID_HANDLE, ...};
new Handle:cvarEnabled				= INVALID_HANDLE;
new Handle:c_Tag					= INVALID_HANDLE;
new Handle:c_EnableClass			= INVALID_HANDLE;
new Handle:c_EnableGodMod			= INVALID_HANDLE;
new Handle:c_EnableHeadShot			= INVALID_HANDLE;
new Handle:c_HeadShotFlag			= INVALID_HANDLE;
new Handle:c_Immunity				= INVALID_HANDLE;
new Handle:c_ClassRestriction		= INVALID_HANDLE;
new Handle:c_GodModFlag				= INVALID_HANDLE;
new Handle:db 						= INVALID_HANDLE;

new String:ClientSteamID[MAXPLAYERS+1][24];
new String:ClientName[MAXPLAYERS+1][MAX_LINE_WIDTH];

static String:DuelNames[4][16] 					= {"Disabled", "Normal", "Time left", "Amount of kills"};
static String:ClassNames[TFClassType][] 		= {"ANY", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer" };
static String:ClassRestricNames[TFClassType][] 	= {"", "scouts", "snipers", "soldiers", "demomen", "medics", "heavies", "pyros", "spies", "engineers" };
static String:TF_ClassNames[TFClassType][] 		= {"", "scout", "sniper", "soldier", "demoman", "medic", "heavyweapons", "pyro", "spy", "engineer" };
static TimeLeftOptions[10] 			= {1, 2, 5, 10, 15, 20, 30, 45, 60, 120};
static AmountOfKillOptions[12] 		= {1, 2, 3, 4, 5, 10, 15, 20, 50, 75, 100, 150};

new LimitPerClass[4][10];
new RankTotal;
new Countdown = 600;


public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{	
	CreateConVar("duel_version", PLUGIN_VERSION, "Duel version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled 		= CreateConVar("duel_enabled", 			"1", 	"Enable or disable Free Duels ?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_Tag		 		= CreateConVar("duel_tag", 				"1", 	"Add 'duels' tags", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_Immunity			= CreateConVar("duel_immunity", 		"0", 	"a or b or o or p or q or r or s or t or z for flag needed, 0 = no flag needed");	
	c_ClassRestriction	= CreateConVar("duel_classrestrict", 	"0", 	"1 = classrestrict by DJ Tsunami, 2 = Max Class (Class Limit) by Nican , 0 = none");
	c_EnableClass		= CreateConVar("duel_class", 			"1", 	"0 = disable class restriction duel, 1 = enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_EnableType[1]		= CreateConVar("duel_type1", 			"1",	"0 = disable `normal` duel, 1 = enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_EnableType[2]		= CreateConVar("duel_type2", 			"1", 	"0 = disable `time left` duel, 1 = enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_EnableType[3]		= CreateConVar("duel_type3", 			"1",	"0 = disable `amount of kills` duel, 1 = enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_EnableGodMod		= CreateConVar("duel_godmod", 			"1", 	"0 = disable challenger godmod, 1 = enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_GodModFlag		= CreateConVar("duel_godmod_flag", 		"a", 	"Flag needed to create godmod duel : a or b or o or p or q or r or s or t or z, 0 = no flag");	
	c_EnableHeadShot	= CreateConVar("duel_headshot", 		"1", 	"0 = disable head shot only (sniper), 1 = enable", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_HeadShotFlag		= CreateConVar("duel_headshot_flag", 	"a", 	"Flag needed to create head shot duel : a or b or o or p or q or r or s or t or z, 0 = no flag");	
		
	if(GetConVarBool(cvarEnabled))
	{
		LogMessage("[0/5] Loading : Enabled");
		RegConsoleCmd("duel", loadDuel, "Challenge player");
		RegConsoleCmd("abort", AbortDuel, "Stop duel");
		RegConsoleCmd("myduels", MyDuelStats, "Show your duels stats");
		RegConsoleCmd("topduel", TopDuel, "Show top dueler");

		LogMessage("[1/5] Loading : Initialisation");
		Initialisation();
		AutoExecConfig(true, "free_duels");
		Connect();
		LoadTranslations("free_duels.phrases");
		
		HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
		HookEvent("player_death", EventPlayerDeath);
		HookEvent("player_team", EventPlayerTeam, EventHookMode_Pre);
		HookEvent("player_changeclass", EventPlayerchangeclass, EventHookMode_Pre);
		HookEvent("player_hurt", Eventplayerhurt, EventHookMode_Pre);
		HookEvent("player_builtobject", EventBuiltObject);
		HookEvent("teamplay_round_win", EventRoundEnd);
		HookEvent("teamplay_flag_event", EventFlag);
		HookEvent("controlpoint_starttouch", EventCPStartTouch);
		HookEvent("controlpoint_endtouch", EventCPEndTouch);
		
		
		CreateTimer(1.0, Timer, INVALID_HANDLE, TIMER_REPEAT);
	}
	else
		LogMessage("Loading : Free Duels disabled by CVar");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IsPlayerInDuel", Native_IsPlayerInDuel);
	CreateNative("IsDuelRestrictionClass", Native_IsDuelRestrictionClass);
	CreateNative("GetDuelerID", Native_GetDuelerID);
	
	return APLRes_Success;
}

Initialisation()
{
	for(new i=0; i<MAXPLAYERS+1; i++)
	{
		g_Duel[i][Enabled]		= false;
		g_Duel[i][SpriteParent]	= -1;
		g_Duel[i][CSprite]		= -1;
	}
}


public OnConfigsExecuted()
{
	LogMessage("[4/5] Loading : Configs Executed");
	if(GetConVarInt(c_Tag))
		TagsCheck("Duels");
		
	LogMessage("[5/5] Loading : Finished");
}

TagsCheck(const String:tag[])
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (!(StrContains(tags, tag, false)>-1))
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	CloseHandle(hTags);
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/free_duel/RED_Target.vmt");
	AddFileToDownloadsTable("materials/free_duel/RED_Target.vtf");
	AddFileToDownloadsTable("materials/free_duel/BLU_Target.vmt");
	AddFileToDownloadsTable("materials/free_duel/BLU_Target.vtf");
	
	PrecacheModel("models/player/medic_animations.mdl");
	PrecacheDecal("materials/free_duel/RED_Target.vmt", true);
	PrecacheDecal("materials/free_duel/BLU_Target.vmt", true);
}

Connect()
{
	if (SQL_CheckConfig("duel"))
	{
		SQL_TConnect(Connected, "duel");
	}
	else
	{
		new String:error[255];
		SQLite = true;
		
		new Handle:kv;
		kv = CreateKeyValues("");
		KvSetString(kv, "driver", "sqlite");
		KvSetString(kv, "database", "duel");
		db = SQL_ConnectCustom(kv, error, sizeof(error), false);
		CloseHandle(kv);		
		
		if (db == INVALID_HANDLE)
			LogMessage("Loading : Failed to connect: %s", error);
		else
		{
			LogMessage("[2/5] Loading : Connected to SQLite Database");
			CreateDbSQLite();
		}
	}
}

public Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Failed to connect! Error: %s", error);
		LogMessage("Loading : Failed to connect! Error: %s", error);
		SetFailState("SQL Error.  See error logs for details.");
		return;
	}

	LogMessage("Loading : Connected to MySQLite Database[2/5]");
	SQL_TQuery(hndl, SQLErrorCheckCallback, "SET NAMES 'utf8'");
	db = hndl;
	SQL_CreateTables();
}

SQL_CreateTables()
{
	new len = 0;
	decl String:query[1000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Duels_Stats` (");
	len += Format(query[len], sizeof(query)-len, "`Players` VARCHAR(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`SteamID` VARCHAR(25) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`Points` float(16,9) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Victories` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Duels` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Kills` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Deads` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`PlayTime` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Abandoned` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Equalities` int(25) NOT NULL default '0',");
	len += Format(query[len], sizeof(query)-len, "`Last_dueler` VARCHAR(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`Last_dueler_SteamID` VARCHAR(25) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "`Etat` VARCHAR(25) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "PRIMARY KEY  (`SteamID`)");
	len += Format(query[len], sizeof(query)-len, ") ENGINE=MyISAM DEFAULT CHARSET=utf8;");
	if (SQL_FastQuery(db, query)) 
		LogMessage("[3/5] Loading : Tables Created");
}

CreateDbSQLite()
{
	new len = 0;
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `Duels_Stats`");
	len += Format(query[len], sizeof(query)-len, " (`Players` TEXT, `SteamID` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `Points` REAL DEFAULT 0,`Victories` INTEGER DEFAULT 0, `Duels` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `Kills` INTEGER DEFAULT 0, `Deads` INTEGER DEFAULT 0, `PlayTime` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `Abandoned` INTEGER DEFAULT 0, `Equalities` INTEGER DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `Last_dueler` TEXT, `Last_dueler_SteamID` TEXT, `Etat` TEXT");
	
	len += Format(query[len], sizeof(query)-len, ");");
	if(SQL_FastQuery(db, query))
		LogMessage("[3/5] Loading : Tables Created");
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!StrEqual("", error))
	{
		LogError("Loading : SQL Error: %s", error);
		LogMessage("Loading : SQL Error: %s", error);
	}
}

public Action:loadDuel(iClient, Args)
{	
	decl String:FlagNeeded[2];
	GetConVarString(c_Immunity, FlagNeeded, sizeof(FlagNeeded));
	
	if(!isAdmin(iClient, FlagNeeded))
		return;
	
	decl String:Argument1[256];
	GetCmdArgString(Argument1, sizeof(Argument1));
	
	if(StrEqual ("",Argument1)) 	// No Args
		CallPanel(iClient);
	else
	{	
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		if((target_count = ProcessTargetString(
			Argument1,
			iClient,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
			{
				ReplyToTargetError(iClient, target_count);
				CallPanel(iClient);
				return;
			}
				
		for (new i = 0; i < target_count; i++)
		{	
			if(isGoodSituation(iClient, target_list[i]))
			{
				if(!g_Duel[iClient][Type])
				{
					LogAction(iClient, target_list[i], "%L challenged %L", iClient, target_list[i]);
					CreateDuel(iClient, target_list[i]);
				}
				else
					CPrintToChat(iClient,"%t", "WaitAnwser");
			}
		}
	}	
}

public bool:isAdmin(iClient, String:FlagNeeded[2])
{	
	if(StrEqual(FlagNeeded, "0"))
		return true;
	else
	{
		new flags = GetUserFlagBits(iClient);
		if(flags == 0)
		{
			//PrintToChatAll("Flag : %s + %s", FlagNeeded[0], FlagNeeded[1]);
			CPrintToChat(iClient,"%t", "NoFlag");
			return false;
		}
		else if((flags & ADMFLAG_ROOT) && StrEqual(FlagNeeded, "z"))
			return true;
		else if((flags & ADMFLAG_RESERVATION) && StrEqual(FlagNeeded, "a"))
			return true;
		else if((flags & ADMFLAG_GENERIC) && StrEqual(FlagNeeded, "b"))
			return true;
		else if((flags & ADMFLAG_CUSTOM1) && StrEqual(FlagNeeded, "o"))
			return true;
		else if((flags & ADMFLAG_CUSTOM2) && StrEqual(FlagNeeded, "p"))
			return true;
		else if((flags & ADMFLAG_CUSTOM3) && StrEqual(FlagNeeded, "q"))
			return true;
		else if((flags & ADMFLAG_CUSTOM4) && StrEqual(FlagNeeded, "r"))
			return true;
		else if((flags & ADMFLAG_CUSTOM5) && StrEqual(FlagNeeded, "s"))
			return true;
		else if((flags & ADMFLAG_CUSTOM6) && StrEqual(FlagNeeded, "t"))
			return true;
		else
		{
			//PrintToChatAll("FlagNO : %s + %s", FlagNeeded[0], FlagNeeded[1]);
			CPrintToChat(iClient,"%t", "NoFlag");
			return false;
		}
	}
}

RemovePlayerBuilding(iClient)
{
	new ObjEnt;
	
	while((ObjEnt = FindEntityByClassname(ObjEnt, "obj_sentrygun")) != -1)
	{
		if(GetEntPropEnt(ObjEnt, Prop_Send, "m_hBuilder") == iClient)
		{
			SetVariantInt(1000);
			AcceptEntityInput(ObjEnt, "RemoveHealth");
		}
	}
	
	while((ObjEnt = FindEntityByClassname(ObjEnt, "obj_dispenser")) != -1)
	{
		if(GetEntPropEnt(ObjEnt, Prop_Send, "m_hBuilder") == iClient)
		{
			SetVariantInt(1000);
			AcceptEntityInput(ObjEnt, "RemoveHealth");
		}
	}
	
	while((ObjEnt = FindEntityByClassname(ObjEnt, "obj_teleporter")) != -1)
	{
		if(GetEntPropEnt(ObjEnt, Prop_Send, "m_hBuilder") == iClient)
		{
			SetVariantInt(1000);
			AcceptEntityInput(ObjEnt, "RemoveHealth");
		}
	}
}


//------------------------------------------------------------------------------------------------------------------------
//							Event Zone
//------------------------------------------------------------------------------------------------------------------------


public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(g_Duel[iClient][Enabled] && g_Duel[iClient][ClassRestrict] != 0 && TF2_GetPlayerClass(iClient) != TFClassType:g_Duel[iClient][ClassRestrict])
	{
		TF2_SetPlayerClass(iClient, TFClassType:g_Duel[iClient][ClassRestrict], false);
		TF2_RespawnPlayer(iClient);
		CPrintToChat(iClient, "%t", "ChangeClass");
		CPrintToChat(iClient, "%t", "Abort");
	}
	
	if(g_Duel[iClient][Enabled] && g_Duel[iClient][GodMod] == 1)
		SetGodModColor(iClient);
}

public Action:EventPlayerDeath(Handle:hEvent, const String:strName[], bool:bHidden)
{

	new iClient 	= GetClientOfUserId(GetEventInt(hEvent, "userid"));    
	new iKiller 	= GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new iAssister 	= GetClientOfUserId(GetEventInt(hEvent, "assister"));
	
	if( GetEventInt( hEvent, "death_flags" ) & TF_DEATHFLAG_DEADRINGER )
        return;

	if( GetConVarBool(c_EnableHeadShot) == true && g_Duel[iClient][HeadShot] == true)
	{
		new customkill = GetEventInt(hEvent, "customkill");
		new bool:headshot = (customkill == 1);
		if(headshot == false) return;
	}
	
	if (g_Duel[iKiller][Challenger] == iClient && g_Duel[iKiller][Enabled])
	{
		g_Duel[iKiller][kills] += 1;
		g_Duel[iClient][Deads] += 1;
		
		if(g_Duel[iKiller][Enabled] &&  g_Duel[iKiller][Type] != 3 )
		{
			g_Duel[iKiller][Score] += 1;
			CPrintToChat(iKiller, "%t", "Score", iKiller, g_Duel[iKiller][Score], iClient, g_Duel[iClient][Score]);
			CPrintToChat(iClient, "%t", "Score", iClient, g_Duel[iClient], iKiller, g_Duel[iKiller][Score]);
		}
		else if(g_Duel[iKiller][Enabled] &&  g_Duel[iKiller][Type] == 3)
		{
			g_Duel[iKiller][Score] -= 1;
			CPrintToChat(iKiller, "%t", "Score", iKiller, g_Duel[iKiller][Score], iClient, g_Duel[iClient][Score]);
			CPrintToChat(iClient, "%t", "Score", iClient, g_Duel[iClient][Score], iKiller, g_Duel[iKiller][Score]);
			
			if(g_Duel[iKiller][Score] == 0) EndDuel(iKiller, g_Duel[iKiller][Type]);
		}
	}
	else if(g_Duel[iAssister][Challenger] == iClient && g_Duel[iAssister][Enabled])
	{
		g_Duel[iAssister][kills] += 1;
		g_Duel[iClient][Deads] += 1;
		if(g_Duel[iAssister][Enabled] &&  g_Duel[iAssister][Type] != 3 )
		{
			g_Duel[iAssister][Score] += 1;
			CPrintToChat(iAssister, "%t", "Score", iAssister, g_Duel[iAssister][Score], iClient, g_Duel[iClient][Score]);
			CPrintToChat(iClient, "%t", "Score", iClient, g_Duel[iClient][Score], iAssister, g_Duel[iAssister][Score]);
		}
		else if(g_Duel[iAssister][Enabled] &&  g_Duel[iAssister][Type] == 3)
		{
			g_Duel[iAssister][Score] -= 1;
			CPrintToChat(iAssister, "%t", "Score", iAssister, g_Duel[iAssister][Score], iClient, g_Duel[iClient][Score]);
			CPrintToChat(iClient, "%t", "Score", iClient, g_Duel[iClient][Score], iAssister, g_Duel[iAssister][Score]);
			
			if(g_Duel[iAssister][Score] == 0) EndDuel(iAssister, g_Duel[iAssister][Type]);
		}
	}
}

public Action:EventPlayerTeam(Handle:hEvent, const String:strName[], bool:bHidden)
{	
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(g_Duel[iClient][Enabled])
	{
		CPrintToChatAll("%t", "Victory", g_Duel[iClient][Challenger], iClient, "(Player changed team)");
		
		Abandon[g_Duel[iClient][Challenger]] 	= false;
		Abandon[iClient]						= true;
		Winner[g_Duel[iClient][Challenger]] 	= true;
		Winner[iClient] 						= false;
		
		if(g_Duel[iClient][Challenger] !=0)
			ClientCommand(g_Duel[iClient][Challenger], "playgamesound ui/duel_event.wav");

		if(iClient != 0)
			ClientCommand(iClient, "playgamesound ui/duel_event.wav");
		
		InitializeClientonDB(g_Duel[iClient][Challenger]);
		InitializeClientonDB(iClient);
	}
}

public Action:EventPlayerchangeclass(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(g_Duel[iClient][Enabled] && g_Duel[iClient][ClassRestrict] != 0 && TF2_GetPlayerClass(iClient) != TFClassType:g_Duel[iClient][ClassRestrict])
	{
		TF2_SetPlayerClass(iClient, TFClassType:g_Duel[iClient][ClassRestrict], false);
		TF2_RespawnPlayer(iClient);
		CPrintToChat(iClient, "%t", "ChangeClass");
		CPrintToChat(iClient, "%t", "Abort");
	}
}

public Action:EventRoundEnd(Handle:hEvent, const String:strName[], bool:bHidden)
{
	for(new i = 1; i < MaxClients ; i++)
	{
		if(g_Duel[i][Enabled])
		{
			EndDuel(i, g_Duel[i][Type]);
			g_Duel[i][Enabled] = false;
			g_Duel[g_Duel[i][Challenger]][Enabled] = false;
		}
	}
}

public Action:Eventplayerhurt(Handle:hEvent, const String:strName[], bool:bHidden)
{	
	if(GetConVarBool(c_EnableGodMod))
	{
		new iClient 		= GetClientOfUserId(GetEventInt(hEvent, "userid"));
		new DamageAmount 	= GetEventInt(hEvent, "damageamount");
		new Attacker 		= GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
		if( ((g_Duel[iClient][Challenger] != Attacker) || (g_Duel[Attacker][Challenger] != iClient))  && ((g_Duel[iClient][Enabled] && g_Duel[iClient][GodMod] == 1 ) || (g_Duel[Attacker][Enabled] && g_Duel[Attacker][GodMod] == 1)))
			SetEntityHealth(iClient, GetClientHealth(iClient) + DamageAmount);
	}
}

public Action:EventCPStartTouch(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetEventInt(hEvent, "player");
	if(g_Duel[iClient][Enabled] && g_Duel[iClient][GodMod] == 1)
	{
		g_Duel[iClient][GodMod] = 2;	// It's not because you are on GodMod you can take CP!
		SetEntityRenderColor(iClient, 255, 255, 255, 0);
	}
}

public Action:EventCPEndTouch(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetEventInt(hEvent, "player");
	if(!IsValidClient(iClient)) return;
	
	if(g_Duel[iClient][Enabled] && g_Duel[iClient][GodMod] == 2)
	{
		g_Duel[iClient][GodMod] = 1;	// You're a good guy!
		SetGodModColor(iClient);
	}
}

public Action:EventFlag(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetEventInt(hEvent, "player");
	new EventType = GetEventInt(hEvent, "eventtype");
	
	if(!IsValidClient(iClient)) return;
	
	if(g_Duel[iClient][Enabled] && g_Duel[iClient][GodMod] == 1 && (EventType == 1 || EventType == 3) )	
	{
		g_Duel[iClient][GodMod] = 2;	// It's not because you are on GodMod you can take Flag!
		SetEntityRenderColor(iClient, 255, 255, 255, 0);
	}
	else if(g_Duel[iClient][Enabled] && g_Duel[iClient][GodMod] == 2 && (EventType == 2 || EventType == 4) )	
	{
		g_Duel[iClient][GodMod] = 1;	// You're a good guy!
		SetGodModColor(iClient);
	}
}

public Action:EventBuiltObject(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new ObjEnt = GetEventInt(hEvent, "index");
	
	if(!IsValidClient(iClient)) return Plugin_Handled;
	if(!g_Duel[iClient][Enabled]) return Plugin_Handled;
	if(!g_Duel[iClient][GodMod]) return Plugin_Handled;
	
	CPrintToChat(iClient, "%t", "Don'tBuilt");
	SetVariantInt(1000);
	AcceptEntityInput(ObjEnt, "RemoveHealth");
	return Plugin_Handled;
}

public OnGameFrame()
{
	new Float:vecOrigin[3];
	
	for(new iClient = 1; iClient <= MaxClients; iClient++ )
		if(IsValidClient(iClient) && g_Duel[iClient][Enabled])
		{
			if(TF2_GetPlayerClass(iClient) == TFClass_Spy && TF2_IsPlayerInCondition(iClient, TFCond_Cloaked))
			{
				if(!g_Duel[iClient][HideSprite])
					g_Duel[iClient][HideSprite] = true;
			}
			else
			{
				if(g_Duel[iClient][HideSprite])
					g_Duel[iClient][HideSprite] = false;
			}
			
			GetClientEyePosition( iClient, vecOrigin );
			vecOrigin[2] += 25.0;
			
			if(EntRefToEntIndex(g_Duel[iClient][SpriteParent]) != -1)
				TeleportEntity(EntRefToEntIndex(g_Duel[iClient][SpriteParent]), vecOrigin, NULL_VECTOR, NULL_VECTOR);
		}
}


//------------------------------------------------------------------------------------------------------------------------
//							!DUEL Menu
//------------------------------------------------------------------------------------------------------------------------


public CallPanel(iClient)
{	
	if(!g_Duel[iClient][Enabled])
	{
		if(!g_Duel[iClient][Type])
		{
			new iteam;
			new Player[40];
			
			if(GetClientTeam(iClient) == 2)	iteam = 3;
			else if(GetClientTeam(iClient) == 3) iteam = 2;
			
			if(iteam == 2 || iteam == 3)
			{
				new nbr = 0;
				for(new i = 1; i < MaxClients ; i++)	// Create an array if valid players (players + bots)
				{	
					Player[i-1] = 0;
					if(IsValidClient(i) && GetClientTeam(i) == iteam && !g_Duel[i][Enabled] && g_Duel[i][Challenger] == 0)
					{
						Player[nbr] = i;
						nbr += 1;
					}
				}

				if(nbr >= 1) // Player found, open menu
				{
					decl String:Playername[MAX_LINE_WIDTH];
					decl String:str_PlayerID[8];
					new Handle:menuPlayer = CreateMenu(DuelPanel1);
					SetMenuTitle(menuPlayer, "Who challenge ?");

					for(new i = 0; i < nbr; i++)
					{
						GetClientName(Player[i], Playername, sizeof(Playername));
						IntToString(Player[i], str_PlayerID, sizeof(str_PlayerID));
						AddMenuItem(menuPlayer, str_PlayerID, Playername);
					}

					SetMenuExitButton(menuPlayer, true);
					DisplayMenu(menuPlayer, iClient, MENU_TIME_FOREVER);
					
				}
				else
					CPrintToChat(iClient,"%t", "NoFound");
			}
			else
				CPrintToChat(iClient,"%t", "Spectator");
		}
		else
			CPrintToChat(iClient,"%t", "WaitAnwser");
	}
	else
		CPrintToChat(iClient,"%t", "InDuel");
	return ;
}

public DuelPanel1(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		decl String:str_PlayerID[8];
		GetMenuItem(menu, args, str_PlayerID, sizeof(str_PlayerID));
		
		CreateDuel(iClient, StringToInt(str_PlayerID));	
	}
}

CreateDuel(Player1, Player2)
{
	if(isGoodSituation(Player1, Player2))
	{
		g_Duel[Player1][Challenger] 	= Player2;
		
		GetSafeClientData(Player1);
		GetSafeClientData(Player2);
		
		if(StrEqual(ClientSteamID[Player1], "INVALID"))
		{
			CPrintToChat(Player1, "Your SteamID isn't valid!");
			ResetPlayer(Player1);
			ResetPlayer(Player2);
		}
		else if(StrEqual(ClientSteamID[Player2], "INVALID"))
		{
			CPrintToChat(Player1, "%N SteamID isn't valid!", Player2);
			ResetPlayer(Player1);
			ResetPlayer(Player2);
		}
		else
		{
			g_Duel[Player1][Type] 		= 1;
			g_Duel[Player1][TimeLeft] 	= 1;
			g_Duel[Player1][Score] 		= 1;
			
			DuelOption(Player1);
		}
	}
}

public DuelOption(Player1)
{
	new String:MenuItem[100];
	new Handle:menu = CreatePanel();
	
	SetPanelTitle(menu, "Duel Options:");
	Format(MenuItem, sizeof(MenuItem), "Duel                        [%s]", DuelNames[g_Duel[Player1][Type]]);
	DrawPanelItem(menu, MenuItem);
	
	if(g_Duel[Player1][Type] == 2)
	{
		Format(MenuItem, sizeof(MenuItem), "Time                        [%i %s]", g_Duel[Player1][TimeLeft], g_Duel[Player1][TimeLeft] >1 ? "mins":"min");
		DrawPanelItem(menu, MenuItem);
	}
	else if(g_Duel[Player1][Type] == 3)
	{
		Format(MenuItem, sizeof(MenuItem), "Amount                   [%i %s]", g_Duel[Player1][Score], g_Duel[Player1][Score] >1 ? "kills":"kill");
		DrawPanelItem(menu, MenuItem);
	}
	else
		DrawPanelText(menu, " ");
	
	Format(MenuItem, sizeof(MenuItem), "Class restriction                [%s]", ClassNames[g_Duel[Player1][ClassRestrict]]);
	DrawPanelItem(menu, MenuItem);
	Format(MenuItem, sizeof(MenuItem), "Challenger protection       [%s]", g_Duel[Player1][GodMod] ? "ON":"OFF");
	DrawPanelItem(menu, MenuItem);
	Format(MenuItem, sizeof(MenuItem), "Head shot only                  [%s]", g_Duel[Player1][HeadShot] ? "ON":"OFF");
	DrawPanelItem(menu, MenuItem);
	DrawPanelText(menu, " ");
	DrawPanelItem(menu, "Rules");
	DrawPanelItem(menu, "Send duel");
	DrawPanelItem(menu, "Exit");


	SendPanelToClient(menu, Player1, DuelOptionAnswer, MENU_TIME_FOREVER);
}

public DuelOptionAnswer(Handle:menu, MenuAction:action, Player1, args)
{
	if (action == MenuAction_Cancel)
	{
		ResetPlayer(g_Duel[Player1][Challenger]);
		ResetPlayer(Player1);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		new bool:AvailableClass[10] = {true,...};
		
		// IF Class restriction Enable
		if(GetConVarInt(c_ClassRestriction) > 0)
		{	
			new PlayerPerClass[2][10];
			new String:CVARClassRed[35];
			new String:CVARClassBlue[35];
			
			// Get Plugin restriction limit
			if(GetConVarInt(c_ClassRestriction) == 2)		//MaxClass Plugin
			{
				if(!StartReadingFromTable()) //error while reding file
				{
					SetConVarInt(c_ClassRestriction, 0);
					LogMessage("[Duel] Error while reading MaxClass config file. Now duel_classrestrict = 0 ");
				}
			}
			else
			{
				for(new i=1;i<=9;i++)
				{
					if(GetConVarInt(c_ClassRestriction) == 1)	//Class Restrict Plugin
					{
						Format(CVARClassRed, sizeof(CVARClassRed), "sm_classrestrict_red_%s", ClassRestricNames[i]);
						Format(CVARClassBlue, sizeof(CVARClassBlue), "sm_classrestrict_blu_%s", ClassRestricNames[i]);
						LimitPerClass[2][i] = GetConVarInt(FindConVar(CVARClassRed));
						LimitPerClass[3][i] = GetConVarInt(FindConVar(CVARClassBlue));
					}
					else 											//Error in Cvar
					{
						LimitPerClass[2][i] = -1;
						LimitPerClass[3][i] = -1;
					}
				}
			}
			
			// Get current players class
			for(new i=1;i<=9;i++)
			{
				PlayerPerClass[0][i] = 0;
				PlayerPerClass[1][i] = 0;
			}
			for(new i = 1; i < MaxClients; i++)
				if(IsClientInGame(i))
					PlayerPerClass[GetClientTeam(i)%2][TF2_GetPlayerClass(i)] ++;
					
			if(IsClientInGame(Player1))
				PlayerPerClass[GetClientTeam(Player1)%2][TF2_GetPlayerClass(Player1)] --;
			if(IsClientInGame(g_Duel[Player1][Challenger]))
				PlayerPerClass[GetClientTeam(g_Duel[Player1][Challenger])%2][TF2_GetPlayerClass(g_Duel[Player1][Challenger])] --;
			
			// Check Class full and available
			for( new i=1;i<=9;i++)
			{
				if( (LimitPerClass[2][i] < 0 && LimitPerClass[3][i] < 0) || (LimitPerClass[2][i] > PlayerPerClass[0][i] && LimitPerClass[3][i] > PlayerPerClass[1][i]) )
					AvailableClass[i] = true;
				else
					AvailableClass[i] = false;
			}
		}
	
	
		// Process the information
		
		decl String:FlagNeeded1[2];
		decl String:FlagNeeded2[2];
		GetConVarString(c_GodModFlag, FlagNeeded1, sizeof(FlagNeeded1));
		GetConVarString(c_HeadShotFlag, FlagNeeded2, sizeof(FlagNeeded2));
		
		
		
		if(args == 1)		// Duel type
		{
			g_Duel[Player1][Type]++;
			
			if(g_Duel[Player1][Type] > 3)
				g_Duel[Player1][Type] = 1;
		}
		else if(args == 2 && g_Duel[Player1][Type] == 2)		// Time
		{
			new i;
			while(TimeLeftOptions[i] != g_Duel[Player1][TimeLeft] && i < 10) i++;
			
			if(i == 9) i = 0;
			else i++;
			
			g_Duel[Player1][TimeLeft] = TimeLeftOptions[i];
		}
		else if(args == 2 && g_Duel[Player1][Type] == 3)		// Amount
		{	
			new i;
			while(AmountOfKillOptions[i] != g_Duel[Player1][Score] && i < 12) i++;
			
			if(i == 11) i = 0;
			else i++;
			
			g_Duel[Player1][Score] = AmountOfKillOptions[i];
		}
		else if(args >= 2  && args < 8)
		{
			if(g_Duel[Player1][Type] == 1)
				args++;
		
			if(args == 3)		// Class Restriction
			{
				if(GetConVarBool(c_EnableClass))
				{
					do
					{
						if(g_Duel[Player1][ClassRestrict] == 2)	// Only for sniper
							g_Duel[Player1][HeadShot] = false;
						
						g_Duel[Player1][ClassRestrict] ++;
							
						if(g_Duel[Player1][ClassRestrict] >= 10)	// Modulo 10 classes
							g_Duel[Player1][ClassRestrict] = 0;

					}
					while(!AvailableClass[g_Duel[Player1][ClassRestrict]]);
				}
				else
					g_Duel[Player1][ClassRestrict] = 0;
			}
			else if(args == 4)		// Challenger protection
			{
				if(GetConVarBool(c_EnableGodMod) && isAdmin(Player1, FlagNeeded1))
					g_Duel[Player1][GodMod] = g_Duel[Player1][GodMod] ? 0 : 1;
				else
					g_Duel[Player1][GodMod] = 0;
			}
			else if(args == 5) // Head shot only
			{
				if(GetConVarBool(c_EnableHeadShot) && g_Duel[Player1][ClassRestrict] == 2 && isAdmin(Player1, FlagNeeded2))
					g_Duel[Player1][HeadShot] = g_Duel[Player1][HeadShot] ? false : true;
				else
					g_Duel[Player1][HeadShot] = false;
			}
			else if(args == 6)	// Click on rules
			{
				ShowMOTDPanel(Player1, "Free-Duels rules", WEBSITE, MOTDPANEL_TYPE_URL );
			}
			else if(args == 7)	// Click on send duel
			{
				if(!isGoodSituation(Player1, g_Duel[Player1][Challenger]))
					return;
					
				if(IsClientInGame(g_Duel[Player1][Challenger]))
				{
					g_Duel[g_Duel[Player1][Challenger]][Challenger] 	= Player1;
					g_Duel[g_Duel[Player1][Challenger]][Type]			= g_Duel[Player1][Type];
					g_Duel[g_Duel[Player1][Challenger]][Score]			= g_Duel[Player1][Score] = g_Duel[Player1][Type] < 3 ? 0:g_Duel[Player1][Score]; 
					g_Duel[g_Duel[Player1][Challenger]][ClassRestrict]	= g_Duel[Player1][ClassRestrict];
					g_Duel[g_Duel[Player1][Challenger]][GodMod]			= g_Duel[Player1][GodMod];
					g_Duel[g_Duel[Player1][Challenger]][HeadShot]		= g_Duel[Player1][HeadShot];
					g_Duel[g_Duel[Player1][Challenger]][TimeLeft]		= g_Duel[Player1][TimeLeft] *= 60;
					
				
					if(IsFakeClient(g_Duel[Player1][Challenger])) // Against BOT
						LoadDuel(g_Duel[Player1][Challenger]);
					else	
						ChallengerMenu(Player1, g_Duel[Player1][Challenger]); // Against Player
				}
				else
				{
					ResetPlayer(g_Duel[Player1][Challenger]);
					ResetPlayer(Player1);
					CPrintToChat(Player1, "%t", "NotInGame");
				}
				return;
			}
			else if(args == 8)	// Click on exit
			{
				ResetPlayer(g_Duel[Player1][Challenger]);
				ResetPlayer(Player1);
				return;
			}
		}
		
		if(IsValidClient(Player1))
			DuelOption(Player1);
	}	
}

bool:StartReadingFromTable()
{
	decl String:file[PLATFORM_MAX_PATH];
	decl String:config[PLATFORM_MAX_PATH];
	decl String:mapname[32];
	new MaxClass[MAXPLAYERS][TFTeam + TFTeam:1][TFClassType + TFClassType:1];
	
	GetConVarString(FindConVar("sm_maxclass_config"), config, sizeof(config));
	BuildPath(Path_SM, file, sizeof(file),"configs/%s", config);

	if (!FileExists(file))
	  BuildPath(Path_SM, file, sizeof(file),"configs/%s", "MaxClass.txt");

	if (!FileExists(file))
		return false;

	new Handle:kv = CreateKeyValues("MaxClassPlayers");
	FileToKeyValues(kv, file);

	//Get in the first sub-key, first look for the map, then look for default
	GetCurrentMap(mapname, sizeof(mapname));
	if (!KvJumpToKey(kv, mapname))
	{
		// Check for map type!
		SplitString(mapname, "_", mapname, sizeof(mapname));
		
		if (!KvJumpToKey(kv, mapname))
		{
			if (!KvJumpToKey(kv, "default"))
			{
				CloseHandle(kv);
				return false;
			}
		}
	}

	new MaxPlayers[TFClassType + TFClassType:1], breakpoint, iStart, iEnd, i, TFTeam:a;
	decl String:buffer[64],String:start[32], String:end[32];
	new redblue[TFTeam];

	//Reset all numbers to -1
	for (i=0; i<10; i++)
		MaxPlayers[i] = -1;

	for (i=0; i<=GetMaxClients(); i++)
		for (a=TFTeam_Unassigned; a <= TFTeam_Blue; a++)
			MaxClass[i][a] = MaxPlayers;

	if (!KvGotoFirstSubKey(kv))
	{
		CloseHandle(kv);
		return false;
	}

	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));

		//Collect all data
		MaxPlayers[TFClass_Scout] =	KvGetNum(kv, TF_ClassNames[TFClass_Scout], -1);
		MaxPlayers[TFClass_Sniper] =   KvGetNum(kv, TF_ClassNames[TFClass_Sniper], -1);
		MaxPlayers[TFClass_Soldier] =  KvGetNum(kv, TF_ClassNames[TFClass_Soldier], -1);
		MaxPlayers[TFClass_DemoMan] =  KvGetNum(kv, TF_ClassNames[TFClass_DemoMan], -1);
		MaxPlayers[TFClass_Medic] =	KvGetNum(kv, TF_ClassNames[TFClass_Medic], -1);
		MaxPlayers[TFClass_Heavy] =	KvGetNum(kv, TF_ClassNames[TFClass_Heavy], -1);
		MaxPlayers[TFClass_Pyro] =	 KvGetNum(kv, TF_ClassNames[TFClass_Pyro], -1);
		MaxPlayers[TFClass_Spy] =	  KvGetNum(kv, TF_ClassNames[TFClass_Spy], -1);
		MaxPlayers[TFClass_Engineer] = KvGetNum(kv, TF_ClassNames[TFClass_Engineer], -1);

		if (MaxPlayers[TFClass_Engineer] == -1)
			MaxPlayers[TFClass_Engineer] = KvGetNum(kv, "engenner", -1);

		redblue[TFTeam_Red] =  KvGetNum(kv, "team2", 1);
		redblue[TFTeam_Blue] =  KvGetNum(kv, "team3", 1);

		if (redblue[TFTeam_Red] == 1)
			redblue[TFTeam_Red] =  KvGetNum(kv, "red", 1);

		if (redblue[TFTeam_Blue] == 1)
			redblue[TFTeam_Blue] =  KvGetNum(kv, "blue", 1);

		if ((redblue[TFTeam_Red] + redblue[TFTeam_Blue]) == 0)
			continue;

		//Just 1 number
		if (StrContains(buffer,"-") == -1)
		{	
			iStart = CheckBoundries(StringToInt(buffer));

			for (a=TFTeam_Unassigned; a<= TFTeam_Blue; a++)
			{
				if (redblue[a] == 1)
					MaxClass[iStart][a] = MaxPlayers;			
			}
			//A range, like 1-5
		}
		else
		{
			//Break the "1-5" into "1" and "5"
			breakpoint = SplitString(buffer,"-",start,sizeof(buffer));
			strcopy(end,sizeof(end),buffer[breakpoint]);
			TrimString(start);
			TrimString(end);

			//make "1" and "5" into integers
			//Check boundries, see if does not go out of the array limits
			iStart = CheckBoundries(StringToInt(start));
			iEnd = CheckBoundries(StringToInt(end));

			//Copy data to the global array for each one in the range
			for (i= iStart; i<= iEnd;i++)
			{
				for (a=TFTeam_Unassigned; a<= TFTeam_Blue; a++)
				{
					if (redblue[a] == 1)
						MaxClass[i][a] = MaxPlayers;			
				}
			}
		}	
		for(i = 1; i<10; i++)
		{
			LimitPerClass[2][i] = MaxClass[GetClientCount(true)][2][i];
			LimitPerClass[3][i] = MaxClass[GetClientCount(true)][1][i];
		}
	} while (KvGotoNextKey(kv));
	

	CloseHandle(kv);
	return true;
}

CheckBoundries(i)
{
	if (i < 0)
		return 0;
	else if (i > MAXPLAYERS)
		return MAXPLAYERS;
	else
		return i;
}


//------------------------------------------------------------------------------------------------------------------------
//							Challenger Menu Answer
//------------------------------------------------------------------------------------------------------------------------


public ChallengerMenu(Player1, Player2)
{
	if(g_Duel[Player1][Type] == 1)
	{
		ClientCommand(Player1, "playgamesound ui/duel_challenge.wav");
		ClientCommand(g_Duel[Player1][Challenger], "playgamesound ui/duel_challenge.wav");
		
	}
	else if(g_Duel[Player1][Type] == 2 || g_Duel[Player1][Type] == 3)
	{
		ClientCommand(Player1, "playgamesound ui/duel_challenge_with_restriction.wav");
		ClientCommand(g_Duel[Player1][Challenger], "playgamesound ui/duel_challenge_with_restriction.wav");
	}
	else
	{
		ResetPlayer(Player1);
		ResetPlayer(Player2);
		return;
	}
	
	for(new i; i<MaxClients; i++)
		if(IsValidClient(i) && i != g_Duel[Player1][Challenger])
			CPrintToChat(i, "%t", "Challenged", Player1, g_Duel[Player1][Challenger]);
			
	CPrintToChat(Player2, "%t", "You!", Player1, g_Duel[Player1][Type]);
	
	
	new String:MenuItem[100];
	new String:MenuTitle[100];
	new Handle:menu = CreatePanel();
	
	Format(MenuTitle, sizeof(MenuTitle), "%N challenged you!", Player1);
	SetPanelTitle(menu, MenuTitle);
	if(g_Duel[Player1][Type] == 1)
		Format(MenuItem, sizeof(MenuItem), "Type: Normal");
	else if(g_Duel[Player1][Type] == 2)
		Format(MenuItem, sizeof(MenuItem), "Type: Time left         [%i %s]", g_Duel[Player1][TimeLeft], g_Duel[Player1][TimeLeft] >1 ? "mins":"min");
	else if(g_Duel[Player1][Type] == 3)
		Format(MenuItem, sizeof(MenuItem), "Type: Amount of kills   [%i %s]", g_Duel[Player1][Score], g_Duel[Player1][Score] >1 ? "kills":"kill");
	DrawPanelText(menu, MenuItem);
	DrawPanelText(menu, " ");
	Format(MenuItem, sizeof(MenuItem), "Class restriction                [%s]", ClassNames[g_Duel[Player1][ClassRestrict]]);
	DrawPanelText(menu, MenuItem);
	Format(MenuItem, sizeof(MenuItem), "Challenger protection       [%s]", g_Duel[Player1][GodMod] ? "ON":"OFF");
	DrawPanelText(menu, MenuItem);
	Format(MenuItem, sizeof(MenuItem), "Head shot only                  [%s]", g_Duel[Player1][HeadShot] ? "ON":"OFF");
	DrawPanelText(menu, MenuItem);
	Format(MenuItem, sizeof(MenuItem), "                                ");
	DrawPanelText(menu, MenuItem);

	DrawPanelItem(menu, "Yes, I challenge");
	DrawPanelItem(menu, "No, I refuse");
	

	SendPanelToClient(menu, Player2, ChallengerMenuAnswer, 20);
}

public ChallengerMenuAnswer(Handle:menu, MenuAction:action, Player2, args)
{
	if (action == MenuAction_Cancel)
	{
		CPrintToChatAll("%t", "TooAfraid", Player2, g_Duel[Player2][Challenger]);
		ResetPlayer(g_Duel[Player2][Challenger]);
		ResetPlayer(Player2);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(args == 1)	// ACCEPT THE DUEL
		{
			if(!isGoodSituation(Player2, g_Duel[Player2][Challenger]))
				return;
			
			LoadDuel(Player2); // Load Duel
			
		}
		else if(args == 2)	// REFUSE THE DUEL
		{
			new Player1 = g_Duel[Player2][Challenger];
			new D_Type	= g_Duel[Player2][Type];
			
			ResetPlayer(Player1);
			ResetPlayer(Player2);
			
			CPrintToChatAll("%t", "Refused", Player2, Player1);
			
			if(D_Type == 1)
			{
				ClientCommand(Player2, "playgamesound ui/duel_challenge_rejected.wav");
				ClientCommand(Player1, "playgamesound ui/duel_challenge_rejected.wav");
			}
			else if(D_Type == 2 || D_Type == 3)
			{
				ClientCommand(Player2, "playgamesound ui/duel_challenge_rejected_with_restriction.wav");
				ClientCommand(Player1, "playgamesound ui/duel_challenge_rejected_with_restriction.wav");
			}
		}
	}
}


LoadDuel(Player2)
{
	if(!isGoodSituation(g_Duel[Player2][Challenger], Player2)) return;
	
	g_Duel[Player2][Enabled] = true;
	g_Duel[g_Duel[Player2][Challenger]][Enabled] = true;
	
	if(g_Duel[Player2][ClassRestrict] != 0) // Load Classrestriction
	{
		if(TFClassType:g_Duel[Player2][ClassRestrict] != TFClassType:TF2_GetPlayerClass(Player2)) // Player2
		{
			TF2_SetPlayerClass(Player2, TFClassType:g_Duel[Player2][ClassRestrict], false);
			TF2_RespawnPlayer(Player2);
		}
		
		if(TFClassType:g_Duel[Player2][ClassRestrict] != TFClassType:TF2_GetPlayerClass(g_Duel[Player2][Challenger])) // Player1
		{
			TF2_SetPlayerClass(g_Duel[Player2][Challenger], TFClassType:g_Duel[Player2][ClassRestrict], false);
			TF2_RespawnPlayer(g_Duel[Player2][Challenger]);
		}	
	}
	
	if(g_Duel[Player2][GodMod])	// Load Godmod
	{	
		if(TF2_GetPlayerClass(Player2) == TFClass_Engineer)
			RemovePlayerBuilding(Player2);
		if(TF2_GetPlayerClass(g_Duel[Player2][Challenger]) == TFClass_Engineer)	
			RemovePlayerBuilding(g_Duel[Player2][Challenger]);
			
		SetGodModColor(Player2);
		SetGodModColor(g_Duel[Player2][Challenger]);
	}
	
	CreateChallengerParticle(Player2);
	CreateChallengerParticle(g_Duel[Player2][Challenger]);
	
	if(g_Duel[Player2][Type] == 1) // Play Sound
	{
		ClientCommand(Player2, "playgamesound ui/duel_challenge_accepted.wav");
		ClientCommand(g_Duel[Player2][Challenger], "playgamesound ui/duel_challenge_accepted.wav");
	}
	else if(g_Duel[Player2][Type] == 2 || g_Duel[Player2][Type] == 3)
	{
		ClientCommand(Player2, "playgamesound ui/duel_challenge_accepted_with_restriction.wav");
		ClientCommand(g_Duel[Player2][Challenger], "playgamesound ui/duel_challenge_accepted_with_restriction.wav");
	}
	
	CPrintToChatAll("%t", "Accepts", Player2, g_Duel[Player2][Challenger]);
	CPrintToChat(Player2,"%t", "Abort");
	CPrintToChat(g_Duel[Player2][Challenger],"%t", "Abort");
}


//------------------------------------------------------------------------------------------------------------------------
//							Option Functions
//------------------------------------------------------------------------------------------------------------------------


SetGodModColor(iClient)
{
	if(GetClientTeam(iClient) == 2)
		SetEntityRenderColor(iClient, 200, 0, 0, 0);
	else
		SetEntityRenderColor(iClient, 0, 0, 200, 0);
}


CreateChallengerParticle(iClient)
{
	new Float:vOrigin[3]; 
	GetClientAbsOrigin(iClient, vOrigin); 
	vOrigin[2] += 25; 

	new parent = CreateEntityByName("prop_dynamic");
	new String:strParent[64];
	Format(strParent, sizeof(strParent), "prop%i", parent);
	DispatchKeyValue(parent, "targetname", strParent);
	DispatchKeyValue(parent, "renderfx","0");
	DispatchKeyValue(parent, "damagetoenablemotion","0");
	DispatchKeyValue(parent, "forcetoenablemotion","0");
	DispatchKeyValue(parent, "Damagetype","0");
	DispatchKeyValue(parent, "disablereceiveshadows","1");
	DispatchKeyValue(parent, "massScale","0");
	DispatchKeyValue(parent, "nodamageforces","0");
	DispatchKeyValue(parent, "shadowcastdist","0");
	DispatchKeyValue(parent, "disableshadows","1");
	DispatchKeyValue(parent, "spawnflags","1670");
	DispatchKeyValue(parent, "model","models/player/medic_animations.mdl");
	DispatchKeyValue(parent, "PerformanceMode","1");
	DispatchKeyValue(parent, "rendermode","10");
	DispatchKeyValue(parent, "physdamagescale","0");
	DispatchKeyValue(parent, "physicsmode","2");

	DispatchSpawn(parent);
	TeleportEntity(parent, vOrigin, NULL_VECTOR, NULL_VECTOR);

	new ent = CreateEntityByName("env_sprite");
	if(ent)
	{
		new String:StrEntityName[64];
		Format(StrEntityName, sizeof(StrEntityName), "ent_sprite_oriented_%i", ent);

		if(GetClientTeam(iClient) == 2)
			DispatchKeyValue(ent, "model", "free_duel/RED_Target.vmt");
		else
			DispatchKeyValue(ent, "model", "free_duel/BLU_Target.vmt");
		DispatchKeyValue(ent, "classname", "env_sprite");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		//DispatchKeyValue(ent, "targetname", StrEntityName);
		DispatchKeyValue(ent, "parentname", strParent);

		DispatchSpawn(ent);
		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);

		SetVariantString(strParent);
		AcceptEntityInput(ent, "SetParent");

		g_Duel[iClient][CSprite] = EntIndexToEntRef(ent);
		g_Duel[iClient][SpriteParent] = EntIndexToEntRef(parent);
		SDKHook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
	}
}

public Action:Hook_SetTransmit(entity, iClient) 
{
	if(EntRefToEntIndex(g_Duel[iClient][CSprite]) == entity && !g_Duel[iClient][HideSprite])	// Can see
		return Plugin_Continue;

	if(EntRefToEntIndex(g_Duel[g_Duel[iClient][Challenger]][CSprite]) == entity && !g_Duel[g_Duel[iClient][Challenger]][HideSprite]) // Can see
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action:Timer(Handle:timer)
{	
	decl String:FlagNeeded[2];
	GetConVarString(c_Immunity, FlagNeeded, sizeof(FlagNeeded));
	Countdown--;
	for(new t=1; t<=MaxClients; t++)
	{
		if(IsClientInGame(t) && IsClientConnected(t) && !IsClientReplay(t) && !IsClientSourceTV(t) && g_Duel[t][Enabled])
		{
			HudMessageTime(t);
			
			g_Duel[t][PlayedTime] += 1;
			
			if(g_Duel[t][Type] == 2)
			{
				g_Duel[t][TimeLeft] -= 1;
				if(g_Duel[t][TimeLeft] <= 0)
				{
					g_Duel[g_Duel[t][Challenger]][Enabled] = false;
					EndDuel(t, g_Duel[t][Type]);
				}
			}
			
			if(Countdown <= 0 && isAdmin(t, FlagNeeded))
				CPrintToChat(t, "%t","!myduels");
			else if(Countdown == 450 && isAdmin(t, FlagNeeded))
				CPrintToChat(t, "%t","!topduel");
		}
	}
	if(Countdown <= 0)
		Countdown = 900;
}

HudMessageTime(iClient)
{
	SetHudTextParams(0.85, 0.0, 1.0, 39, 148, 0, 255, 1, 0.0, 0.0, 0.0);
	
	if(g_Duel[iClient][Type] == 1 || g_Duel[iClient][Type] == 3)	ShowHudText(iClient, -1, "You : %i - Him: %i", g_Duel[iClient][Score], g_Duel[g_Duel[iClient][Challenger]][Score]);
	else if(g_Duel[iClient][Type] == 2)	ShowHudText(iClient, -1, "Time left : %i | You : %i - Him: %i", g_Duel[iClient][TimeLeft], g_Duel[iClient][Score], g_Duel[g_Duel[iClient][Challenger]][Score]);
}

public OnClientDisconnect(iClient)
{
	if(!IsValidClient(iClient)) return;
	
	if(g_Duel[iClient][Enabled]) 
	{
		CPrintToChatAll("%t","Victory", g_Duel[iClient][Challenger], iClient, "(Player disconnected)");
		
		if(IsValidClient(g_Duel[iClient][Challenger]))
			ClientCommand(g_Duel[iClient][Challenger], "playgamesound ui/duel_event.wav");
		
		Winner[g_Duel[iClient][Challenger]]		= true;
		Winner[iClient]				= false;
		Abandon[iClient] 			= true;
		Abandon[g_Duel[iClient][Challenger]] 		= false;
		
		InitializeClientonDB(g_Duel[iClient][Challenger]);
		InitializeClientonDB(iClient);
	}
}

public Action:AbortDuel(iClient, Args)
{
	if(!IsValidClient(iClient)) return;
	
	if(g_Duel[iClient][Enabled])
	{
		new String:reason[64];
		Format(reason, sizeof(reason), "(%N aborted)", iClient);
		CPrintToChatAll("%t","Victory", g_Duel[iClient][Challenger], iClient, reason);
		
		Winner[g_Duel[iClient][Challenger]]		= true;
		Winner[iClient]				= false;
		Abandon[iClient] 			= true;
		Abandon[g_Duel[iClient][Challenger]] 		= false;
		
		InitializeClientonDB(g_Duel[iClient][Challenger]);
		InitializeClientonDB(iClient);
		
		if(g_Duel[iClient][Challenger] != 0)
		{
			ClientCommand(g_Duel[iClient][Challenger], "playgamesound ui/duel_event.wav");
		}
		if(iClient != 0)
		{
			ClientCommand(iClient, "playgamesound ui/duel_event.wav");
		}
	}
	else
		CPrintToChat(iClient,"%t", "NotInDuel");
}


//------------------------------------------------------------------------------------------------------------------------
//							Security functions
//------------------------------------------------------------------------------------------------------------------------


stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}

public bool:isGoodSituation(iClient, Player2)
{
	if(!IsValidClient(iClient) || !IsValidClient(Player2))
	{
		ResetPlayer(Player2);
		ResetPlayer(iClient);
		return false;
	}
	
	if(g_Duel[Player2][Enabled])  		// too late ! iClient Player2 already in duel ...
	{
		CPrintToChat(iClient,"%t", "IsInDuel", Player2);	
		ResetPlayer(iClient);
		return false;
	}
	else if(g_Duel[iClient][Enabled])  			// you are already in duel ...
	{
		CPrintToChat(iClient,"%t", "InDuel");
		ResetPlayer(iClient);
		return false;
	}
	else if(GetClientTeam(iClient) != 2 && GetClientTeam(iClient) != 3)
	{
		CPrintToChat(iClient,"%t", "TeamError");
		ResetPlayer(iClient);
		return false;
	}
	else if(GetClientTeam(Player2) != 2 && GetClientTeam(Player2) != 3)
	{
		CPrintToChat(iClient,"%t", "TeamError");
		ResetPlayer(Player2);
		return false;
	}
	else if(GetClientTeam(iClient) == GetClientTeam(Player2))
	{
		CPrintToChat(iClient,"%t", "TeamError");
		ResetPlayer(iClient);
		ResetPlayer(Player2);
		return false;
	}
	else
		return true;
}

GetSafeClientData(iClient)
{
	new String:PlayerInfo[MAX_LINE_WIDTH];
	
	//Client Name	
	GetClientName(iClient, PlayerInfo, sizeof(PlayerInfo));	
	
	ReplaceString(PlayerInfo, sizeof(PlayerInfo), "'", "");		// Fix player name for DB
	ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?PHP", "");
	ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?php", "");
	ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?", "");
	ReplaceString(PlayerInfo, sizeof(PlayerInfo), "?>", "");
	ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<", "[");
	ReplaceString(PlayerInfo, sizeof(PlayerInfo), ">", "]");
	ReplaceString(PlayerInfo, sizeof(PlayerInfo), ",", ".");

	strcopy(ClientName[iClient], MAX_LINE_WIDTH, PlayerInfo); 
	
	
	//Client SteamID
	if(IsFakeClient(iClient))
		strcopy(PlayerInfo, MAX_LINE_WIDTH, "BOT"); 
	else
	{
		GetClientAuthString(iClient, PlayerInfo, sizeof(PlayerInfo));
		if(StrEqual(PlayerInfo,""))		// O.o It's Possible !? yes ...
			strcopy(PlayerInfo, MAX_LINE_WIDTH, "INVALID"); 
	}
	strcopy(ClientSteamID[iClient], 24, PlayerInfo); 
}


//------------------------------------------------------------------------------------------------------------------------
//							Duel Stats
//------------------------------------------------------------------------------------------------------------------------


public Action:MyDuelStats(iClient, Args)
{	
	if (iClient == 0) return;
	
	new String:buffer[255];
	
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Duels_Stats`");
	SQL_TQuery(db, T_Rank1, buffer, iClient);
}

public T_Rank1(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if (hndl == INVALID_HANDLE)
		LogError("Query failed! %s", error);
	else
	{
		if(!IsValidClient(iClient))	return;
		new String:buffer[255];
		
		while (SQL_FetchRow(hndl))
		{
			RankTotal = SQL_FetchInt(hndl,0);
			Format(buffer, sizeof(buffer), "SELECT `Points`, `Victories`, `Duels`, `Kills`, `Deads` FROM `Duels_Stats` WHERE SteamID = '%s'", ClientSteamID[iClient]);
			SQL_TQuery(db, T_Rank2, buffer, iClient);
		}
	}	
}

public T_Rank2(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if (hndl == INVALID_HANDLE)
		LogError("Query failed! %s", error);
	else
	{
		new String:buffer[255];
		while (SQL_FetchRow(hndl))
		{
			points[iClient]	 	= SQL_FetchFloat(hndl,0);
			victories[iClient]	= SQL_FetchInt(hndl,1);
			total[iClient]		= SQL_FetchInt(hndl,2);
			killsNbr[iClient]		= SQL_FetchInt(hndl,3);
			death[iClient]		= SQL_FetchInt(hndl,4);
			
			Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `Duels_Stats` WHERE `Points` > %i", victories);
			SQL_TQuery(db, T_Rank3, buffer, iClient);
		}
	}	
}

public T_Rank3(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if (hndl == INVALID_HANDLE)
		LogError("Query failed! %s", error);
	else
		while (SQL_FetchRow(hndl))
			RankPanel(iClient, SQL_FetchInt(hndl,0));
}

RankPanel(iClient, Rank)
{	
	new String:value[MAX_LINE_WIDTH];
	new String:ClientID[MAX_LINE_WIDTH];
	new Handle:rnkpanel = CreatePanel();
	
	GetClientName(iClient, ClientID, sizeof(ClientID) );
	SetPanelTitle(rnkpanel, "Your duels' stats:");
	Format(value, sizeof(value), "Name: %s", ClientID);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "Rank: %i out of %i", Rank , RankTotal);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "Points: %f" , points[iClient]);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "Victories: %i" , victories[iClient]);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "Duels total: %i" , total[iClient]);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "Kills: %i" , killsNbr[iClient]);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "Deaths: %i" , death[iClient]);
	DrawPanelText(rnkpanel, value);
	DrawPanelItem(rnkpanel, "Close");
	SendPanelToClient(rnkpanel, iClient, RankPanelHandler, 15);
}

public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public Action:TopDuel(iClient, Args)
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT `Players`, `Points` FROM `Duels_Stats` ORDER BY `Points` DESC LIMIT 0,100");
	SQL_TQuery(db, T_ShowTopDuel, buffer, iClient);
}

public T_ShowTopDuel(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	if (hndl == INVALID_HANDLE)
		LogError("Query failed! %s", error);
	else
	{
		new Handle:menu = CreateMenu(TopDuelPanel);
		SetMenuTitle(menu, "Top Duel Menu:");

		new i  = 1;
		while (SQL_FetchRow(hndl))
		{
			new String:PlayerName[MAX_LINE_WIDTH];
			new String:line[MAX_LINE_WIDTH];
			SQL_FetchString(hndl,0, PlayerName , MAX_LINE_WIDTH);
			
			Format(line, sizeof(line), "%i : %s %f points", i, PlayerName, SQL_FetchFloat(hndl,1));
			AddMenuItem(menu, "i" , line);
			i++;
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, iClient, MENU_TIME_FOREVER);

		return;
	}
	return;
}

public TopDuelPanel(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
}


//------------------------------------------------------------------------------------------------------------------------
//							When duel end
//------------------------------------------------------------------------------------------------------------------------


bool:EndDuel(iClient, DuelType)
{
	if(DuelType != 0)
	{
		if(DuelType == 1 || DuelType == 2)
		{
			if(g_Duel[iClient][Score] > g_Duel[g_Duel[iClient][Challenger]][Score])
			{
				CPrintToChatAll("%t", "Victory", iClient, g_Duel[iClient][Challenger],"");
				Winner[iClient] 		= true;
				Winner[g_Duel[iClient][Challenger]] 	= false;
			}
			else if (g_Duel[iClient][Score] < g_Duel[g_Duel[iClient][Challenger]][Score])
			{
				CPrintToChatAll("%t", "Victory", g_Duel[iClient][Challenger], iClient,"");
				Winner[iClient] 		= false;
				Winner[g_Duel[iClient][Challenger]] 	= true;
			}
			else
			{
				CPrintToChatAll("%t", "Equality", g_Duel[iClient][Challenger], iClient);
				Equality[iClient] 		= true;
				Winner[iClient] 		= true;
				Equality[g_Duel[iClient][Challenger]] = true;
				Winner[g_Duel[iClient][Challenger]] 	= true;
			}
		}
		else if(DuelType == 3)
		{
			if(g_Duel[iClient][Score] > g_Duel[g_Duel[iClient][Challenger]][Score])
			{
				CPrintToChatAll("%t", "Victory", g_Duel[iClient][Challenger], iClient,"");
				Winner[iClient] 		= false;
				Winner[g_Duel[iClient][Challenger]] 	= true;
			}
			else if (g_Duel[iClient][Score] < g_Duel[g_Duel[iClient][Challenger]][Score])
			{
				CPrintToChatAll("%t", "Victory", iClient, g_Duel[iClient][Challenger],"");
				Winner[iClient] 		= true;
				Winner[g_Duel[iClient][Challenger]] 	= false;
			}
			else
			{
				CPrintToChatAll("%t", "Equality", g_Duel[iClient][Challenger], iClient);
				Equality[iClient] 		= true;
				Winner[iClient] 		= true;
				Equality[g_Duel[iClient][Challenger]] = true;
				Winner[g_Duel[iClient][Challenger]] 	= true;
			}
		}
		
		if(IsValidClient(g_Duel[iClient][Challenger]))
			ClientCommand(g_Duel[iClient][Challenger], "playgamesound ui/duel_event.wav");
			
		if(IsValidClient(iClient))
			ClientCommand(iClient, "playgamesound ui/duel_event.wav");
		
		InitializeClientonDB(g_Duel[iClient][Challenger]);
		InitializeClientonDB(iClient);
		
		return true;
	}
	return false;
}


public InitializeClientonDB(iClient)
{
	if(iClient == 0)
	{
		ResetPlayer(iClient);
		return;
	}
	new String:buffer[255];

	Format(buffer, sizeof(buffer), "SELECT `Victories`,`Duels` FROM Duels_Stats WHERE STEAMID = '%s'", ClientSteamID[iClient]);
	SQL_TQuery(db, T_UpdateClient, buffer, iClient);
}

public T_UpdateClient(Handle:owner, Handle:hndl, const String:error[], any:iClient)
{
	new String:etat[512];
	new CltPoint;
	new Victory;
	new Equal;
	new Kill = g_Duel[iClient][kills];
	new Dead = g_Duel[iClient][Deads];
	new Abort = Abandon[iClient];
	new Tmer = g_Duel[iClient][PlayedTime];
	new Dueller = g_Duel[iClient][Challenger];
		
	if(Equality[iClient])
	{
		Format(etat, sizeof(etat), "Equality");
		CltPoint 	= 1;
		Victory 	= 1;
		Equal		= 1;
	}
	else if(Winner[iClient])
	{
		Format(etat, sizeof(etat), "Winner");
		CltPoint 	= 2;
		Victory 	= 1;
		Equal		= 0;
	}
	else
	{
		Format(etat, sizeof(etat), "Loser");
		CltPoint 	= 0;
		Victory 	= 0;
		Equal		= 0;
	}	
	
	
	ResetPlayer(iClient);
	
	if (!SQL_GetRowCount(hndl))
	{
		new String:buffer[1500];
		if(!SQLite)
		{
			Format(buffer, sizeof(buffer), "INSERT INTO Duels_Stats (`Players`,`SteamID`,`Points`,`Victories`,`Duels`,`Kills`,`Deads`,`PlayTime`,`Abandoned`,`Equalities`,`Last_dueler`,`Last_dueler_SteamID`,`Etat`) VALUES ('%s','%s','%i','%i','1','%i','%i','%i','%i','%i','%s','%s','%s')", ClientName[iClient], ClientSteamID[iClient], CltPoint, Victory, Kill, Dead, Tmer, Abort, Equal, ClientName[Dueller], ClientSteamID[Dueller], etat);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			LogMessage("MySQL => %s First victory, and add on database.", ClientName[iClient]);
		}
		else
		{
			Format(buffer, sizeof(buffer), "INSERT INTO Duels_Stats VALUES('%s','%s','%i','%i','1','%i','%i','%i','%i','%i','%s','%s','%s');", ClientName[iClient], ClientSteamID[iClient], CltPoint, Victory, Kill, Dead, Tmer, Abort, Equal, ClientName[Dueller], ClientSteamID[Dueller], etat );
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			LogMessage("SQLite => %s First victory, and add on database.", ClientName[iClient]);
		}
		CPrintToChatAll("%t", Victory >1 ? "Victories" : "VictoryNbr", ClientName[iClient], Victory);
	}
	else
	{
		new String:buffer[1500];
		
		while (SQL_FetchRow(hndl))
		{
			new clientvictories 	= SQL_FetchInt(hndl,0);
			new clientduels			= SQL_FetchInt(hndl,1);
			if(Victory == 1)
				clientvictories += 1;
			new Float:clientpoints 	= ((clientvictories*1.0)/(clientduels+1)) + clientvictories;
			
			Format(buffer, sizeof(buffer), "UPDATE Duels_Stats SET Players = '%s', Points = %f, Victories = Victories +%i, Duels = Duels +1, Kills = Kills +%i, Deads = Deads +%i, PlayTime = PlayTime +%i, Abandoned = Abandoned +%i, Equalities = Equalities +%i, Last_dueler = '%s', Last_dueler_SteamID = '%s', Etat = '%s' WHERE SteamID = '%s'",ClientName[iClient], clientpoints, Victory, Kill, Dead, Tmer, Abort, Equal, ClientName[Dueller], ClientSteamID[Dueller], etat, ClientSteamID[iClient]);
			SQL_TQuery(db,SQLErrorCheckCallback, buffer);
	
			CPrintToChatAll("%t", clientvictories >1 ? "Victories" : "VictoryNbr", ClientName[iClient], clientvictories);
			LogMessage("MySQL => %s %d victories, and updated on database.", ClientName[iClient], clientvictories);
		}
	}
}

ResetPlayer(iClient)
{
	if(IsValidClient(iClient) && g_Duel[iClient][GodMod])
		SetEntityRenderColor(iClient, 255, 255, 255, 0);
	
	g_Duel[iClient][Enabled] 		= false;
	g_Duel[iClient][HeadShot]		= false;
	g_Duel[iClient][ClassRestrict] 	= 0;
	g_Duel[iClient][kills]			= 0;
	g_Duel[iClient][Deads]			= 0;
	g_Duel[iClient][TimeLeft]		= 0;
	g_Duel[iClient][Score]			= 0;
	g_Duel[iClient][Challenger] 	= 0;
	g_Duel[iClient][PlayedTime]		= 0;
	g_Duel[iClient][GodMod]			= 0;
	g_Duel[iClient][Type]			= 0;
	
	Winner[iClient]				= false;
	Abandon[iClient]			= false;
	Equality[iClient]			= false;
	
	if(IsValidEdict(EntRefToEntIndex(g_Duel[iClient][SpriteParent])))
	{
		RemoveEdict(EntRefToEntIndex(g_Duel[iClient][SpriteParent]));
		g_Duel[iClient][SpriteParent] = -1;
	}
	
	if(IsValidEdict(EntRefToEntIndex(g_Duel[iClient][CSprite])))
	{
		RemoveEdict(EntRefToEntIndex(g_Duel[iClient][CSprite]));
		g_Duel[iClient][CSprite] = -1;
	}
}


//------------------------------------------------------------------------------------------------------------------------
//							Native Functions
//------------------------------------------------------------------------------------------------------------------------


public Native_IsPlayerInDuel(Handle:plugin, numParams)
{	
	new iClient = GetNativeCell(1); 
	
	if(!IsValidClient(iClient)) return false;
	
	if(g_Duel[iClient][Enabled])
		return true;
	else
		return false;
}

public Native_IsDuelRestrictionClass(Handle:plugin, numParams)
{	
	new iClient = GetNativeCell(1); 
	
	if(!IsValidClient(iClient)) return false;
	
	if(g_Duel[iClient][ClassRestrict] != 0)
		return true;
	else
		return false;
}

public Native_GetDuelerID(Handle:plugin, numParams)
{
	if(!IsValidClient(GetNativeCell(1))) return -1;
	return g_Duel[GetNativeCell(1)][Challenger];
}
