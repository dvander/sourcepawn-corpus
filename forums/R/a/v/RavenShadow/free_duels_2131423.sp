#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <free_duels>


#define PLUGIN_NAME         "Free duels"
#define PLUGIN_AUTHOR       "Erreur 500 fixed/edited by RavenShadow"
#define PLUGIN_DESCRIPTION	"Challenging other players"
#define PLUGIN_VERSION      "2.02C"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"
#define MAX_LINE_WIDTH 		60



new Duel[MAXPLAYERS+1] 				= {0, ...};
new Score[MAXPLAYERS+1]				= {0, ...};
new TimeLeft[MAXPLAYERS+1] 			= {0, ...};
new iTimer[MAXPLAYERS+1] 			= {0, ...};
new DuelEnable[MAXPLAYERS+1] 		= {0, ...};
new ClassRestric[MAXPLAYERS+1] 		= {0, ...};
new iKills[MAXPLAYERS+1]			= {0, ...};
new iDeads[MAXPLAYERS+1]			= {0, ...};
new Winner[MAXPLAYERS+1]			= {0, ...};
new Abandon[MAXPLAYERS+1]			= {0, ...};
new Equality[MAXPLAYERS+1]			= {0, ...};
new	victories[MAXPLAYERS+1]			= {0, ...};
new death[MAXPLAYERS+1]				= {0, ...};
new	kills[MAXPLAYERS+1]				= {0, ...};
new Float:points[MAXPLAYERS+1]		= {0.0, ...};
new total[MAXPLAYERS+1]				= {0, ...};

new bool:GodMod[MAXPLAYERS+1] 		= {false, ...};
new bool:HeadShot[MAXPLAYERS+1] 	= {false, ...};
new bool:SQLite 					= false;

new Handle:c_EnableType[4]			= {INVALID_HANDLE , ...};
new Handle:cvarEnabled				= INVALID_HANDLE;
new Handle:c_EnableClass			= INVALID_HANDLE;
new Handle:c_EnableGodMod			= INVALID_HANDLE;
new Handle:c_EnableHeadShot			= INVALID_HANDLE;
new Handle:c_HeadShotFlag			= INVALID_HANDLE;
new Handle:c_Immunity				= INVALID_HANDLE;
new Handle:c_ClassRestriction		= INVALID_HANDLE;
new Handle:c_GodModFlag				= INVALID_HANDLE;
new Handle:db 						= INVALID_HANDLE;

new String:ClientSteamID[MAXPLAYERS+1][MAX_LINE_WIDTH];
new String:ClientName[MAXPLAYERS+1][MAX_LINE_WIDTH];

static String:strModes[4][16] 					= {"Disabled","Normal","Time left","Amount of kills"};
static String:ClassNames[TFClassType][] 		= {"ANY", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer" };
static String:ClassRestricNames[TFClassType][] 	= {"", "scouts", "snipers", "soldiers", "demomen", "medics", "heavies", "pyros", "spies", "engineers" };
static String:TF_ClassNames[TFClassType][] 		= {"", "scout", "sniper", "soldier", "demoman", "medic", "heavyweapons", "pyro", "spy", "engineer" };

new Player[40];
new LimitPerClass[4][10];
new RankTotal;
new Countdown = 300;


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
	c_Immunity			= CreateConVar("duel_immunity", 		"0", 	"a or b or o or p or q or r or s or t or z for flag needed, 0 = no flag needed");	
	c_ClassRestriction	= CreateConVar("duel_classrestrict", 	"0", 	"1 = classrestrict by DJ Tsunami, 2 = Max Class (Class Limit) by Nican , 0 = none");
	c_EnableClass		= CreateConVar("duel_class", 			"1", 	"0 = disable class restriction duel, 1 = enable");
	c_EnableType[1]		= CreateConVar("duel_type1", 			"1",	"0 = disable `normal` duel, 1 = enable");
	c_EnableType[2]		= CreateConVar("duel_type2", 			"1", 	"0 = disable `time left` duel, 1 = enable");
	c_EnableType[3]		= CreateConVar("duel_type3", 			"1",	"0 = disable `amount of kills` duel, 1 = enable");
	c_EnableGodMod		= CreateConVar("duel_godmod", 			"1", 	"0 = disable challenger godmod, 1 = enable");
	c_GodModFlag		= CreateConVar("duel_godmod_flag", 		"a", 	"Flag needed to create godmod duel : a or b or o or p or q or r or s or t or z, 0 = no flag");	
	c_EnableHeadShot	= CreateConVar("duel_headshot", 		"1", 	"0 = disable head shot only (sniper), 1 = enable");
	c_HeadShotFlag		= CreateConVar("duel_headshot_flag", 	"a", 	"Flag needed to create head shot duel : a or b or o or p or q or r or s or t or z, 0 = no flag");	
		
	if(GetConVarBool(cvarEnabled))
	{
		LogMessage("Loading : Enabled		 			[0/5]");
		RegConsoleCmd("duel", loadDuel, "Challenge player");
		RegConsoleCmd("abort", AbortDuel, "Stop duel");
		RegConsoleCmd("myduels", MyDuelStats, "Show your duels stats");
		RegConsoleCmd("topduel", TopDuel, "Show top dueler");

		LogMessage("Loading : Initialisation 				[1/5]");
		AutoExecConfig(true, "Free_duels");
		Connect();
		LoadTranslations("free_duels.phrases");
		LoadTranslations("common.phrases");
		
		HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
		HookEvent("player_death", EventPlayerDeath);
		HookEvent("teamplay_round_win", EventRoundEnd);
		HookEvent("player_team", EventPlayerTeam, EventHookMode_Pre);
		HookEvent("player_changeclass", EventPlayerchangeclass, EventHookMode_Pre);
		HookEvent("player_hurt", Eventplayerhurt, EventHookMode_Pre);
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


public OnConfigsExecuted()
{
	LogMessage("Loading : Configs Executed 				[4/5]");
	TagsCheck("Duels");
	LogMessage("Loading : Finished 					[5/5]");
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
			LogMessage("Loading : Connected to SQLite Database		[2/5]");
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
		LogMessage("Loading : Tables Created 				[3/5]");
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
		LogMessage("Loading : Tables Created 				[3/5]");
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
				LogAction(iClient, target_list[i], "%L challenged %L", iClient, target_list[i]);
				CreateDuel(iClient, target_list[i]);
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
			CPrintToChat(iClient,"%t", "Duel5");
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
			CPrintToChat(iClient,"%t", "Duel5");
			return false;
		}
	}
}

public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(DuelEnable[iClient] != 0 && ClassRestric[iClient] != 0 && TF2_GetPlayerClass(iClient) != TFClassType:ClassRestric[iClient])
	{
		TF2_SetPlayerClass(iClient, TFClassType:ClassRestric[iClient], false);
		TF2_RespawnPlayer(iClient);
		CPrintToChat(iClient, "%t", "Duel1");
		CPrintToChat(iClient, "%t", "Duel2");
	}
}

public Action:EventPlayerDeath(Handle:hEvent, const String:strName[], bool:bHidden)
{

	new iClient 	= GetClientOfUserId(GetEventInt(hEvent, "userid"));    
	new iKiller 	= GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	new iAssister 	= GetClientOfUserId(GetEventInt(hEvent, "assister"));
	
	if( GetEventInt( hEvent, "death_flags" ) & TF_DEATHFLAG_DEADRINGER )
        return;

	if( GetConVarBool(c_EnableHeadShot) == true && HeadShot[iClient] == true)
	{
		new customkill = GetEventInt(hEvent, "customkill");
		new bool:headshot = (customkill == 1);
		if(headshot == false) return;
	}
	
	if (Duel[iKiller] == iClient && DuelEnable[iKiller] != 0)
	{
		iKills[iKiller] += 1;
		iDeads[iClient] += 1;
		
		if(DuelEnable[iKiller] != 3 )
		{
			Score[iKiller] += 1;
			CPrintToChat(iKiller, "%t", "Duel10", iKiller, Score[iKiller], iClient, Score[iClient]);
			CPrintToChat(iClient, "%t", "Duel10", iClient, Score[iClient], iKiller, Score[iKiller]);
		}
		else if(DuelEnable[iKiller] == 3)
		{
			Score[iKiller] -= 1;
			CPrintToChat(iKiller, "%t", "Duel10", iKiller, Score[iKiller], iClient, Score[iClient]);
			CPrintToChat(iClient, "%t", "Duel10", iClient, Score[iClient], iKiller, Score[iKiller]);
			
			if(Score[iKiller] == 0) EndDuel(iKiller);
		}
	}
	else if(Duel[iAssister] == iClient && DuelEnable[iAssister] != 0)
	{
		iKills[iAssister] += 1;
		iDeads[iClient] += 1;
		if(DuelEnable[iAssister] != 3 )
		{
			Score[iAssister] += 1;
			CPrintToChat(iAssister, "%t", "Duel10", iAssister, Score[iAssister], iClient, Score[iClient]);
			CPrintToChat(iClient, "%t", "Duel10", iClient, Score[iClient], iAssister, Score[iAssister]);
		}
		else if(DuelEnable[iAssister] == 3)
		{
			Score[iAssister] -= 1;
			CPrintToChat(iAssister, "%t", "Duel10", iAssister, Score[iAssister], iClient, Score[iClient]);
			CPrintToChat(iClient, "%t", "Duel10", iClient, Score[iClient], iAssister, Score[iAssister]);
			
			if(Score[iAssister] == 0) EndDuel(iAssister);
		}
	}
}

public Action:EventPlayerTeam(Handle:hEvent, const String:strName[], bool:bHidden)
{	
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient))
	{
		if(DuelEnable[iClient] != 0)
		{
			CPrintToChatAll("%t", "Duel11", Duel[iClient], iClient, "(Player changed team)");
			
			Abandon[Duel[iClient]] 		= 0;
			Abandon[iClient]			= 1;
			Winner[Duel[iClient]] 		= 1;
			Winner[iClient] 			= 0;
		
			if(Duel[iClient] !=0)
				ClientCommand(Duel[iClient], "playgamesound ui/duel_event.wav");

			if(iClient != 0)
				ClientCommand(iClient, "playgamesound ui/duel_event.wav");
		
			InitializeClientonDB(iClient);
			InitializeClientonDB(Duel[iClient]);
		}
	}
}

public Action:EventPlayerchangeclass(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(DuelEnable[iClient] != 0 && ClassRestric[iClient] != 0 && TF2_GetPlayerClass(iClient) != TFClassType:ClassRestric[iClient])
	{
		TF2_SetPlayerClass(iClient, TFClassType:ClassRestric[iClient], false);
		TF2_RespawnPlayer(iClient);
		CPrintToChat(iClient, "%t", "Duel1");
		CPrintToChat(iClient, "%t", "Duel2");
	}
}

public Action:EventRoundEnd(Handle:hEvent, const String:strName[], bool:bHidden)
{
	for(new i = 1; i < MaxClients ; i++)
	{
		if(DuelEnable[i] != 0)
		{
			EndDuel(i);
			DuelEnable[Duel[i]] = 0;
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
	
		if( ((Duel[iClient] != Attacker) || (Duel[Attacker] != iClient))  && ((DuelEnable[iClient] != 0 && GodMod[iClient] == true ) || (DuelEnable[Attacker] != 0 && GodMod[Attacker] == true)))
			SetEntityHealth(iClient, GetClientHealth(iClient) + DamageAmount);
	}
}

public CallPanel(iClient)
{	
	if(DuelEnable[iClient] == 0)
	{
		new iteam;
		if(GetClientTeam(iClient) == 2)	iteam = 3;
		else if(GetClientTeam(iClient) == 3) iteam = 2;
		if(iteam == 2 || iteam == 3)
		{
			new nbr = 0;
			for(new i = 1; i < MaxClients ; i++)
			{	
				Player[i-1] = 0;
				if(IsClientInGame(i) && GetClientTeam(i) == iteam && DuelEnable[i] == 0)
				{
					Player[nbr] = i;
					nbr += 1;
				}
			}
			CPrintToChat(iClient,"%t", "Duel3");
			if (nbr >=1)
				DuelPanel(iClient, nbr);
			else
				CPrintToChat(iClient,"%t", "Duel4");
		}
		else
			CPrintToChat(iClient,"%t", "Duel6");
	}
	else
		CPrintToChat(iClient,"%t", "Duel7");
	return ;
}

public DuelPanel(iClient, nbr)
{
	new String:Playername[MAX_LINE_WIDTH];
	new Handle:menuPlayer = CreateMenu(DuelPanel1);
	SetMenuTitle(menuPlayer, "Who challenge ?");

	for(new i = 0; i < nbr; i++)
	{
		GetClientName(Player[i], Playername, sizeof(Playername) );
		AddMenuItem(menuPlayer, "i", Playername);
	}

	SetMenuExitButton(menuPlayer, true);
	DisplayMenu(menuPlayer, iClient, MENU_TIME_FOREVER);
}

public DuelPanel1(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		new Player2 = Player[args];
		CreateDuel(iClient, Player2);	
	}
}

public ChoiceDuelPanel(iClient)
{
	new Handle:menuNext = CreateMenu(ChoiceDuelPanel1);
	SetMenuTitle(menuNext, "Choice duel type :");

	for(new i=1; i<4; i++)
	{
		if(GetConVarBool(c_EnableType[i]))
			AddMenuItem(menuNext, strModes[i], strModes[i]);
		else 
			AddMenuItem(menuNext, strModes[0], strModes[0]);
	}

	SetMenuExitButton(menuNext, true);
	DisplayMenu(menuNext, iClient, MENU_TIME_FOREVER);
}

public ChoiceDuelPanel1(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_Cancel)
	{
		ResetPlayer(iClient);
		ResetPlayer(Duel[iClient]);
	}	
	else if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		decl String:strPoints[32];
		GetMenuItem(menu, args, strPoints, sizeof(strPoints));
		if(StrEqual (strModes[0], strPoints))
			ChoiceDuelPanel(iClient);
		
		else if(StrEqual (strModes[1], strPoints))
		{
			if(IsClientInGame(Duel[iClient]))
			{
				ClientCommand(iClient, "playgamesound ui/duel_challenge.wav");
				ClientCommand(Duel[iClient], "playgamesound ui/duel_challenge.wav");
				CPrintToChatAll("%t", "Duel12",iClient,Duel[iClient]);
				DuelAnswer(iClient, Duel[iClient], 1);
			}
			else
				CPrintToChat(iClient,"%t", "Duel8");
		}
		else if(StrEqual (strModes[2], strPoints))
			ChoiceDuelPanel2(iClient);
		else if(StrEqual (strModes[3], strPoints))
			ChoiceDuelPanel3(iClient);
	}	
}

public ChoiceDuelPanel2(iClient)
{
	new Handle:menuTime = CreateMenu(ChoiceDuelPanel2_1);
	SetMenuTitle(menuTime, "Choice Time :");

	AddMenuItem(menuTime, "60", "1 min");
	AddMenuItem(menuTime, "120", "2 mins");
	AddMenuItem(menuTime, "300", "5 mins");
	AddMenuItem(menuTime, "600", "10 mins");
	AddMenuItem(menuTime, "900", "15 mins");
	AddMenuItem(menuTime, "1200", "20 mins");
	AddMenuItem(menuTime, "1800", "30 mins");
	AddMenuItem(menuTime, "2700", "45 mins");
	AddMenuItem(menuTime, "3600", "60 mins");
	AddMenuItem(menuTime, "7200", "120 mins");

	SetMenuExitButton(menuTime, true);
	DisplayMenu(menuTime, iClient, MENU_TIME_FOREVER);
}

public ChoiceDuelPanel2_1(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_Cancel)
	{
		ResetPlayer(iClient);
		ResetPlayer(Duel[iClient]);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		decl String:strValeur[32];
		new Valeur;
		
		GetMenuItem(menu, args, strValeur, sizeof(strValeur));
		Valeur = StringToInt(strValeur);
		TimeLeft[iClient] 		= Valeur;
		TimeLeft[Duel[iClient]] = Valeur;
		CreateDuel2_1(iClient);

	}	
}

public ChoiceDuelPanel3(iClient)
{
	new Handle:menuKill = CreateMenu(ChoiceDuelPanel3_1);
	SetMenuTitle(menuKill, "Choice amount of kill :");

	AddMenuItem(menuKill, "1", "1 kill");
	AddMenuItem(menuKill, "2", "2 kills");
	AddMenuItem(menuKill, "3", "3 kills");
	AddMenuItem(menuKill, "4", "4 kills");
	AddMenuItem(menuKill, "5", "5 kills");
	AddMenuItem(menuKill, "10", "10 kills");
	AddMenuItem(menuKill, "15", "15 kills");
	AddMenuItem(menuKill, "20", "20 kills");
	AddMenuItem(menuKill, "50", "50 kills");
	AddMenuItem(menuKill, "75", "75 kills");
	AddMenuItem(menuKill, "100", "100 kills");
	AddMenuItem(menuKill, "150", "150 kills");

	SetMenuExitButton(menuKill, true);
	DisplayMenu(menuKill, iClient, MENU_TIME_FOREVER);
}

public ChoiceDuelPanel3_1(Handle:menu, MenuAction:action, Player1, args)
{
	if (action == MenuAction_Cancel)
	{
		ResetPlayer(Player1);
		ResetPlayer(Duel[Player1]);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:strValeur[32];
		new Valeur;
		
		GetMenuItem(menu, args, strValeur, sizeof(strValeur));
		Valeur = StringToInt(strValeur);		
		Score[Duel[Player1]] 		= Valeur;
		Score[Player1] 				= Valeur;
		CreateDuel3_1(Player1);
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

		//Why am I doing the 4 teams if there are only 2?
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

public ClassOption(iClient)
{
	new Handle:menuClass = CreateMenu(ClassOption_1);
	SetMenuTitle(menuClass, "Enable Class restriction ?");

	AddMenuItem(menuClass, "1", "No");
	
	if(GetConVarInt(c_ClassRestriction) > 0)
	{	
		new PlayerPerClass[2][10];
		new String:Line[17];
		new String:CVARClassRed[35];
		new String:CVARClassBlue[35];
		new String:Full[] = {"(Full)"};
		
		
		if(GetConVarInt(c_ClassRestriction) == 2)		//MaxClass Plugin
		{
			if(!StartReadingFromTable()) //error while reding file
			{
				SetConVarInt(c_ClassRestriction, 0);
				LogMessage("[Duel] Error while reading MaxClass config file. set duel_classrestrict = 0 ");
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
		for(new i=1;i<=9;i++)
		{
			PlayerPerClass[0][i] = 0;
			PlayerPerClass[1][i] = 0;
		}
		for(new i = 1; i < MaxClients; i++)
			if(IsClientInGame(i))
				PlayerPerClass[GetClientTeam(i)%2][TF2_GetPlayerClass(i)] ++;
		if(IsClientInGame(iClient))
			PlayerPerClass[GetClientTeam(iClient)%2][TF2_GetPlayerClass(iClient)] --;
		if(IsClientInGame(Duel[iClient]))
			PlayerPerClass[GetClientTeam(Duel[iClient])%2][TF2_GetPlayerClass(Duel[iClient])] --;
			
		for( new i=1;i<=9;i++)
		{
			if( (LimitPerClass[2][i] < 0 && LimitPerClass[3][i] < 0) || (LimitPerClass[2][i] > PlayerPerClass[0][i] && LimitPerClass[3][i] > PlayerPerClass[1][i]) )
			{
				Format(Line, sizeof(Line), "%s", ClassNames[i]);
				AddMenuItem(menuClass,  "i+1", Line);
			}
			else
			{
				Format(Line, sizeof(Line), "%s %s", ClassNames[i], Full);
				AddMenuItem(menuClass,  Full, Line);
			}
		}
	}
	else
	{
		AddMenuItem(menuClass, "2", "Scout");
		AddMenuItem(menuClass, "3", "Sniper");
		AddMenuItem(menuClass, "4", "Soldier");
		AddMenuItem(menuClass, "5", "Demoman");
		AddMenuItem(menuClass, "6", "Medic");
		AddMenuItem(menuClass, "7", "Heavy");
		AddMenuItem(menuClass, "8", "Pyro");
		AddMenuItem(menuClass, "9", "Spy");
		AddMenuItem(menuClass, "10", "Engineer");
	}

	SetMenuExitButton(menuClass, true);
	DisplayMenu(menuClass, iClient, MENU_TIME_FOREVER);
}

public ClassOption_1(Handle:menu, MenuAction:action, Player1, args)
{
	if (action == MenuAction_Cancel)
	{
		ResetPlayer(Player1);
		ResetPlayer(Duel[Player1]);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		decl String:FlagNeeded1[2];
		decl String:FlagNeeded2[2];
		GetConVarString(c_GodModFlag, FlagNeeded1, sizeof(FlagNeeded1));
		GetConVarString(c_HeadShotFlag, FlagNeeded2, sizeof(FlagNeeded2));
		
		if(args == 0)
		{
			ClassRestric[Duel[Player1]] = 0;
			ClassRestric[Player1] 		= 0;
		}
		else
		{
			decl String:strArgs[32];
			GetMenuItem(menu, args, strArgs, sizeof(strArgs));
			if(StrEqual ("(Full)", strArgs))
				ClassOption(Player1);
			else
			{
				ClassRestric[Duel[Player1]] = args;
				ClassRestric[Player1] 		= args;
			}
		}
		if(GetConVarBool(c_EnableGodMod) && isAdmin(Player1, FlagNeeded1))
			GodModMenu(Player1);
		else if(GetConVarBool(c_EnableHeadShot) && ClassRestric[Player1] == 2 && isAdmin(Player1, FlagNeeded2))
			HeadShotMenu(Player1);
		else
			ChoiceDuelPanel(Player1);
	}	
}

public GodModMenu(Player1)
{
	new Handle:menuClass = CreateMenu(GodModMenu_1);
	SetMenuTitle(menuClass, "Enable challenger protection ?");

	AddMenuItem(menuClass, "1", "No");
	AddMenuItem(menuClass, "2", "Yes");
	
	SetMenuExitButton(menuClass, true);
	DisplayMenu(menuClass, Player1, MENU_TIME_FOREVER);
}

public GodModMenu_1(Handle:menu, MenuAction:action, Player1, args)
{
	if (action == MenuAction_Cancel)
	{
		ResetPlayer(Player1);
		ResetPlayer(Duel[Player1]);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		decl String:FlagNeeded[2];
		GetConVarString(c_HeadShotFlag, FlagNeeded, sizeof(FlagNeeded));
		if(args == 1)
		{
			GodMod[Player1] 		= true;
			GodMod[Duel[Player1]] 	= true;
		}
		else
		{
			GodMod[Player1]			= false;
			GodMod[Duel[Player1]]	= false;
		}
		
		if(GetConVarBool(c_EnableHeadShot) && ClassRestric[Player1] == 2 && isAdmin(Player1, FlagNeeded))
			HeadShotMenu(Player1);
		else
			ChoiceDuelPanel(Player1);
	}
}

public HeadShotMenu(Player1)
{
	new Handle:menuClass = CreateMenu(HeadShotMenu_1);
	SetMenuTitle(menuClass, "Only head shot ?");

	AddMenuItem(menuClass, "1", "No");
	AddMenuItem(menuClass, "2", "Yes");
	
	SetMenuExitButton(menuClass, true);
	DisplayMenu(menuClass, Player1, MENU_TIME_FOREVER);
}

public HeadShotMenu_1(Handle:menu, MenuAction:action, Player1, args)
{
	if (action == MenuAction_Cancel)
	{
		ResetPlayer(Player1);
		ResetPlayer(Duel[Player1]);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		if(args == 1)
		{
			HeadShot[Player1] 		= true;
			HeadShot[Duel[Player1]] = true;
		}
		else
		{
			HeadShot[Player1] 		= false;
			HeadShot[Duel[Player1]] = false;
		}
		ChoiceDuelPanel(Player1);
	}
}

public DuelAnswer(Player1, Player2, Type)
{
	new Handle:menuAnswer;
	new String:etat1[4];
	new String:etat2[4];
	
	if(!isGoodSituation(Player1, Player2))
		return;
		
	if(HeadShot[Player1] == true)
		Format(etat1, sizeof(etat1), "Yes");
	else
		Format(etat1, sizeof(etat1), "NO");
		
	if(GodMod[Player1] == true)
		Format(etat2, sizeof(etat2), "Yes");
	else
		Format(etat2, sizeof(etat2), "NO");
	
	CPrintToChat(Player2,"%t", "Duel13", Duel[Player2], Type);
	CPrintToChat(Player2,"%t", "Duel24", ClassNames[ClassRestric[Player2]], etat1, etat2 );
	if(Type == 1)
		menuAnswer = CreateMenu(DuelPanelAnswer1);
	else if(Type == 2)
		menuAnswer = CreateMenu(DuelPanelAnswer2);
	else if(Type == 3)
		menuAnswer = CreateMenu(DuelPanelAnswer3);
	
	SetMenuTitle(menuAnswer, "%N challenged you!", Player1);

	AddMenuItem(menuAnswer, "1", "Yes, I challenge");
	AddMenuItem(menuAnswer, "2", "No, I refuse");

	SetMenuExitButton(menuAnswer, true);
	DisplayMenu(menuAnswer, Player2, 15);
}

public DuelPanelAnswer1(Handle:menu, MenuAction:action, Player2, args)
{
	if (action == MenuAction_Cancel)
	{
		CPrintToChatAll("%t", "Duel17", Player2, Duel[Player2]);
		ResetPlayer(Player2);
		ResetPlayer(Duel[Player2]);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select && isGoodSituation(Player2, Duel[Player2]))
	{
		if(args == 0)
		{
			CreateDuel1_2(Player2);
		}
		else if(args == 1)
		{
			CPrintToChatAll("%t", "Duel14", Player2, Duel[Player2]);
			ClientCommand(Player2, "playgamesound ui/duel_challenge_rejected.wav");
			ClientCommand(Duel[Player2], "playgamesound ui/duel_challenge_rejected.wav");
		}
	}
}

public DuelPanelAnswer2(Handle:menu, MenuAction:action, Player2, args)
{
	if (action == MenuAction_Cancel)
	{
		CPrintToChatAll("%t", "Duel17", Player2, Duel[Player2]);
		ResetPlayer(Player2);
		ResetPlayer(Duel[Player2]);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select && isGoodSituation(Player2, Duel[Player2]))
	{
		if(args == 0)
		{
			CreateDuel2_2(Player2);
		}
		else if(args == 1)
		{
			CPrintToChatAll("%t", "Duel14", Player2, Duel[Player2]);
			ClientCommand(Player2, "playgamesound ui/duel_challenge_rejected_with_restriction.wav");
			ClientCommand(Duel[Player2], "playgamesound ui/duel_challenge_rejected_with_restriction.wav");
		}
	}	
}

public DuelPanelAnswer3(Handle:menu, MenuAction:action, Player2, args)
{
	if (action == MenuAction_Cancel)
	{
		CPrintToChatAll("%t", "Duel17", Player2, Duel[Player2]);
		ResetPlayer(Player2);
		ResetPlayer(Duel[Player2]);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select && isGoodSituation(Player2, Duel[Player2]))
	{
		if(args == 0)
		{
			CreateDuel3_2(Player2);
		}
		else if(args == 1)
		{
			CPrintToChatAll("%t", "Duel14", Player2, Duel[Player2]);
			ClientCommand(Player2, "playgamesound ui/duel_challenge_rejected_with_restriction.wav");
			ClientCommand(Duel[Player2], "playgamesound ui/duel_challenge_rejected_with_restriction.wav");
		}
	}
}
CreateDuel(Player1, Player2)
{
	
	DuelEnable[Player1] = 0;		//Duel disable
	DuelEnable[Player2] = 0;		//Duel disable
	Duel[Player2] 		= Player1;
	Duel[Player1] 		= Player2;
	
	if(IsClientInGame(Player2) && IsClientConnected(Player2))
	{
		new String:PlayerInfo[MAX_LINE_WIDTH];
		
		GetClientName(Player1, PlayerInfo, sizeof(PlayerInfo) );
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "'", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?PHP", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?php", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "?>", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<", "[");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), ">", "]");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), ",", ".");
	
		strcopy(ClientName[Player1], MAX_LINE_WIDTH, PlayerInfo); 
		
		GetClientName(Player2, PlayerInfo, sizeof(PlayerInfo) );
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "'", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?PHP", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?php", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<?", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "?>", "");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), "<", "[");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), ">", "]");
		ReplaceString(PlayerInfo, sizeof(PlayerInfo), ",", ".");

		strcopy(ClientName[Player2], MAX_LINE_WIDTH, PlayerInfo); 
		
		if(IsFakeClient(Player2))
			strcopy(PlayerInfo, MAX_LINE_WIDTH, "BOT"); 
		else
			GetClientAuthString(Player2, PlayerInfo, sizeof(PlayerInfo));
		strcopy(ClientSteamID[Player2], MAX_LINE_WIDTH, PlayerInfo); 
		
		if(IsFakeClient(Player1))
			strcopy(PlayerInfo, MAX_LINE_WIDTH, "BOT"); 
		else
			GetClientAuthString(Player1, PlayerInfo, sizeof(PlayerInfo));
		strcopy(ClientSteamID[Player1], MAX_LINE_WIDTH, PlayerInfo); 

		
		if(GetConVarBool(c_EnableClass))
			ClassOption(Player1);
		else
			ChoiceDuelPanel(Player1);
	}
	else
	{
		CPrintToChat(Player1,"%t", "Duel8");
	}
}

// - - - - - - - - - - DUEL TYPE 1 - - - - - - - - - - 

CreateDuel1_2(Player2)
{
	Score[Duel[Player2]] 		= 0;
	Score[Player2] 				= 0;
	DuelEnable[Duel[Player2]] 	= 1;		//Duel type 1 enable
	DuelEnable[Player2] 		= 1;		//Duel type 1 enable
	
	if(ClassRestric[Player2] != 0)
	{
		if(TFClassType:ClassRestric[Player2] != TFClassType:TF2_GetPlayerClass(Player2))
		{
			TF2_SetPlayerClass(Player2, TFClassType:ClassRestric[Player2], false);
			TF2_RespawnPlayer(Player2);
		}
		if(TFClassType:ClassRestric[Duel[Player2]] != TFClassType:TF2_GetPlayerClass(Duel[Player2]))
		{
			TF2_SetPlayerClass(Duel[Player2], TFClassType:ClassRestric[Duel[Player2]], false);
			TF2_RespawnPlayer(Duel[Player2]);
		}
	}
	
	ClientCommand(Player2, "playgamesound ui/duel_challenge_accepted.wav");
	ClientCommand(Duel[Player2], "playgamesound ui/duel_challenge_accepted.wav");
	
	CPrintToChatAll("%t", "Duel15", Player2, Duel[Player2]);
	CPrintToChat(Player2,"%t", "Duel2");
	CPrintToChat(Duel[Player2],"%t", "Duel2");
	
	return 1;
}

// - - - - - - - - - - DUEL TYPE 2 - - - - - - - - - - 

CreateDuel2_1(Player1)
{
	if(IsClientInGame(Duel[Player1]))
	{
		DuelAnswer(Player1, Duel[Player1], 2);
		ClientCommand(Player1, "playgamesound ui/duel_challenge_with_restriction.wav");
		ClientCommand(Duel[Player1], "playgamesound ui/duel_challenge_with_restriction.wav");
		CPrintToChatAll("%t", "Duel16",Player1,Duel[Player1],TimeLeft[Player1]/60);
	}
	else
	{
		CPrintToChat(Player1,"%t", "Duel8");
	}
	
}
	
CreateDuel2_2(Player2)
{
	Score[Duel[Player2]]		= 0;
	Score[Player2] 				= 0;
	DuelEnable[Duel[Player2]] 	= 2;		//Duel type 2 enable
	DuelEnable[Player2] 		= 2;		//Duel type 2 enable
	
	if(ClassRestric[Player2] != 0)
	{
		if(TFClassType:ClassRestric[Player2]!= TFClassType:TF2_GetPlayerClass(Player2))
		{
			TF2_SetPlayerClass(Player2, TFClassType:ClassRestric[Player2], false);
			TF2_RespawnPlayer(Player2);
		}
		if(TFClassType:ClassRestric[Duel[Player2]]!= TFClassType:TF2_GetPlayerClass(Duel[Player2]))
		{
			TF2_SetPlayerClass(Duel[Player2], TFClassType:ClassRestric[Duel[Player2]], false);
			TF2_RespawnPlayer(Duel[Player2]);
		}
	}
	
	ClientCommand(Player2, "playgamesound ui/duel_challenge_accepted_with_restriction.wav");
	ClientCommand(Duel[Player2], "playgamesound ui/duel_challenge_accepted_with_restriction.wav");
	
	CPrintToChatAll("%t", "Duel15",Player2, Duel[Player2]);
	CPrintToChat(Player2,"%t", "Duel2");
	CPrintToChat(Duel[Player2],"%t", "Duel2");
	
	return 1;
}

// - - - - - - - - - - DUEL TYPE 3 - - - - - - - - - - 

CreateDuel3_1(Player1)
{
	if(IsClientInGame(Duel[Player1]) && Duel[Player1] > 0 && Duel[Player1] <= MaxClients)
	{
		DuelAnswer(Player1, Duel[Player1], 3);
		ClientCommand(Player1, "playgamesound ui/duel_challenge_with_restriction.wav");
		ClientCommand(Duel[Player1], "playgamesound ui/duel_challenge_with_restriction.wav");
		CPrintToChatAll("%t", "Duel12",Player1,Duel[Player1]);
	}
	else
	{
		CPrintToChat(Player1,"%t", "Duel8");
	}
}

CreateDuel3_2(Player2)
{
	DuelEnable[Duel[Player2]] 	= 3;		//Duel type 3 enable
	DuelEnable[Player2] 		= 3;		//Duel type 3 enable
	
	if(ClassRestric[Player2] != 0)
	{
		if(TFClassType:ClassRestric[Player2]!= TFClassType:TF2_GetPlayerClass(Player2))
		{
			TF2_SetPlayerClass(Player2, TFClassType:ClassRestric[Player2], false);
			TF2_RespawnPlayer(Player2);
		}
		if(TFClassType:ClassRestric[Duel[Player2]]!= TFClassType:TF2_GetPlayerClass(Duel[Player2]))
		{
			TF2_SetPlayerClass(Duel[Player2], TFClassType:ClassRestric[Duel[Player2]], false);
			TF2_RespawnPlayer(Duel[Player2]);
		}
	}
	
	ClientCommand(Player2, "playgamesound ui/duel_challenge_accepted_with_restriction.wav");
	ClientCommand(Duel[Player2], "playgamesound ui/duel_challenge_accepted_with_restriction.wav");
	
	CPrintToChatAll("%t", "Duel15",Player2, Duel[Player2]);
	CPrintToChat(Player2,"%t", "Duel2");
	CPrintToChat(Duel[Player2],"%t", "Duel2");
}

public bool:isGoodSituation(Player1, Player2)	
{
	if(Player1 < 0 || Player1 > MaxClients)
	{
		return false;
	}
	if(Player2 < 0 || Player2 > MaxClients)
	{
		return false;
	}
	if(DuelEnable[Player1] != 0)  		// too late ! Player1 is already in duel ...
	{
		CPrintToChat(Player2,"%t", "Duel18", Duel[Player2]);	
		ResetPlayer(Player2);
		ResetPlayer(Player1);
		return false;
	}
	else if(DuelEnable[Player2] != 0)  			// Player2(you) is (are) already in duel ...
	{
		CPrintToChat(Player2,"%t", "Duel7");
		ResetPlayer(Player2);
		ResetPlayer(Player1);
		return false;
	}
	else if((GetClientTeam(Player1) != 2 && GetClientTeam(Player1) != 3) && (GetClientTeam(Player2) != 2 && GetClientTeam(Player2) != 3))
	{
		CPrintToChat(Player1,"%t", "Duel19");
		ResetPlayer(Player2);
		ResetPlayer(Player1);
		return false;
	}
	else if(GetClientTeam(Player1) == GetClientTeam(Player2))
	{
		CPrintToChat(Player1,"%t", "Duel19");
		ResetPlayer(Player2);
		ResetPlayer(Player1);
		return false;
	}
	else
		return true;
}

public Action:Timer(Handle:timer)
{	
	decl String:FlagNeeded[2];
	GetConVarString(c_Immunity, FlagNeeded, sizeof(FlagNeeded));
	Countdown--;
	for(new t=1; t<=MaxClients; t++)
	{
		if(IsClientInGame(t) && IsClientConnected(t) && !IsClientReplay(t) && !IsClientSourceTV(t) && DuelEnable[t] != 0)
		{
			HudMessageTime(t);
			HudMessageTime(Duel[t]);
			
			iTimer[t] += 1;
			
			if(DuelEnable[t] == 2)
			{
				TimeLeft[t] -= 1;
				if(TimeLeft[t] == 0)
				{
					DuelEnable[Duel[t]] = 0;
					EndDuel(t);
				}
			}
			
			if(Countdown == 0 && isAdmin(t, FlagNeeded))
				CPrintToChatAll("%t","Duel20");
			else if(Countdown == 450 && isAdmin(t, FlagNeeded))
				CPrintToChatAll("%t","Duel21");
		}
	}
	if(Countdown == 0)
		Countdown = 900;
}

HudMessageTime(iClient)
{
	SetHudTextParams(0.85, 0.0, 1.0, 39, 148, 0, 255, 1, 0.0, 0.0, 0.0);
	
	if(DuelEnable[iClient] == 1 || DuelEnable[iClient] == 3)	ShowHudText(iClient, -1, "You : %i - Him: %i", Score[iClient], Score[Duel[iClient]]);
	else if(DuelEnable[iClient] == 2)	ShowHudText(iClient, -1, "Time left : %i | You : %i - Him: %i", TimeLeft[iClient], Score[iClient], Score[Duel[iClient]]);
}

public OnClientDisconnect(iClient)
{
	if(DuelEnable[iClient] != 0) 
	{
		CPrintToChatAll("%t","Duel11", Duel[iClient], iClient, "(Player disconnected)");
		
		if(Duel[iClient] != 0)
			ClientCommand(Duel[iClient], "playgamesound ui/duel_event.wav");
		
		Winner[Duel[iClient]]		= 1;
		Winner[iClient]				= 0;
		Abandon[iClient] 			= 1;
		Abandon[Duel[iClient]] 		= 0;
		
		InitializeClientonDB(iClient);
		InitializeClientonDB(Duel[iClient]);
	}
}

public Action:AbortDuel(iClient, Args)
{
	if(DuelEnable[iClient] != 0)
	{
		new String:reason[64];
		Format(reason, sizeof(reason), "(%N aborted)", iClient);
		CPrintToChatAll("%t","Duel11", Duel[iClient], iClient, reason);
		
		Winner[Duel[iClient]]		= 1;
		Winner[iClient]				= 0;
		Abandon[iClient] 			= 1;
		Abandon[Duel[iClient]] 		= 0;
		
		InitializeClientonDB(iClient);
		InitializeClientonDB(Duel[iClient]);
		
		if(Duel[iClient] != 0)
		{
			ClientCommand(Duel[iClient], "playgamesound ui/duel_event.wav");
		}
		if(iClient != 0)
		{
			ClientCommand(iClient, "playgamesound ui/duel_event.wav");
		}
	}
	else
		CPrintToChat(iClient,"%t", "Duel9");
}

 

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
		new String:buffer[255];
		new String:iClientSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(iClient, iClientSteamID, sizeof(iClientSteamID));
		
		while (SQL_FetchRow(hndl))
		{
			RankTotal = SQL_FetchInt(hndl,0);
			Format(buffer, sizeof(buffer), "SELECT `Points`, `Victories`, `Duels`, `Kills`, `Deads` FROM `Duels_Stats` WHERE SteamID = '%s'", iClientSteamID);
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
			kills[iClient]		= SQL_FetchInt(hndl,3);
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
	{
		while (SQL_FetchRow(hndl))
		{
			RankPanel(iClient, SQL_FetchInt(hndl,0));
		}
	}	
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
	Format(value, sizeof(value), "Kills: %i" , kills[iClient]);
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

bool:EndDuel(iClient)
{
	if(DuelEnable[iClient] != 0)
	{
		if(DuelEnable[iClient] == 1 || DuelEnable[iClient] == 2)
		{
			if(Score[iClient] > Score[Duel[iClient]])
			{
				CPrintToChatAll("%t", "Duel11", iClient, Duel[iClient],"");
				Winner[iClient] 		= 1;
				Winner[Duel[iClient]] 	= 0;
			}
			else if (Score[iClient] < Score[Duel[iClient]])
			{
				CPrintToChatAll("%t", "Duel11", Duel[iClient], iClient,"");
				Winner[iClient] 		= 0;
				Winner[Duel[iClient]] 	= 1;
			}
			else
			{
				CPrintToChatAll("%t", "Duel22", Duel[iClient], iClient);
				Equality[iClient] 		= 1;
				Winner[iClient] 		= 1;
				Equality[Duel[iClient]] = 1;
				Winner[Duel[iClient]] 	= 1;
			}
		}
		else if(DuelEnable[iClient] == 3)
		{
			if(Score[iClient] > Score[Duel[iClient]])
			{
				CPrintToChatAll("%t", "Duel11", Duel[iClient], iClient,"");
				Winner[iClient] 		= 0;
				Winner[Duel[iClient]] 	= 1;
			}
			else if (Score[iClient] < Score[Duel[iClient]])
			{
				CPrintToChatAll("%t", "Duel11", iClient, Duel[iClient],"");
				Winner[iClient] 		= 1;
				Winner[Duel[iClient]] 	= 0;
			}
			else
			{
				CPrintToChatAll("%t", "Duel22", Duel[iClient], iClient);
				Equality[iClient] 		= 1;
				Winner[iClient] 		= 1;
				Equality[Duel[iClient]] = 1;
				Winner[Duel[iClient]] 	= 1;
			}
		}
				
		if(Duel[iClient] !=0)
			ClientCommand(Duel[iClient], "playgamesound ui/duel_event.wav");
			
		if(iClient != 0)
			ClientCommand(iClient, "playgamesound ui/duel_event.wav");
		
		InitializeClientonDB(iClient);
		InitializeClientonDB(Duel[iClient]);
		
		return true;
	}
	return false;
}


public InitializeClientonDB(iClient)
{
	if (iClient == 0)
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
		
	if(Equality[iClient] == 1)
	{
		Format(etat, sizeof(etat), "Equality");
		CltPoint 	= 1;
	}
	else if(Winner[iClient] == 1)
	{
		Format(etat, sizeof(etat), "Winner");
		CltPoint 	= 2;
	}
	else
	{
		Format(etat, sizeof(etat), "Loser");
		CltPoint 	= 0;
	}	
	
	if (!SQL_GetRowCount(hndl))
	{
		new String:buffer[1500];
		if(!SQLite)
		{
			Format(buffer, sizeof(buffer), "INSERT INTO Duels_Stats (`Players`,`SteamID`,`Points`,`Victories`,`Duels`,`Kills`,`Deads`,`PlayTime`,`Abandoned`,`Equalities`,`Last_dueler`,`Last_dueler_SteamID`,`Etat`) VALUES ('%s','%s','%i','%i','1','%i','%i','%i','%i','%i','%s','%s','%s')", ClientName[iClient], ClientSteamID[iClient], CltPoint, Winner[iClient], iKills[iClient], iDeads[iClient], iTimer[iClient], Abandon[iClient], Equality[iClient], ClientName[Duel[iClient]], ClientSteamID[Duel[iClient]], etat);
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			LogMessage("MySQL => %N First victory, and add on database.", iClient);
		}
		else
		{
			Format(buffer, sizeof(buffer), "INSERT INTO Duels_Stats VALUES('%s','%s','%i','%i','1','%i','%i','%i','%i','%i','%s','%s','%s');", ClientName[iClient], ClientSteamID[iClient], CltPoint, Winner[iClient], iKills[iClient], iDeads[iClient], iTimer[iClient], Abandon[iClient], Equality[iClient], ClientName[Duel[iClient]], ClientSteamID[Duel[iClient]], etat );
			SQL_TQuery(db, SQLErrorCheckCallback, buffer);
			LogMessage("SQLite => %N First victory, and add on database.", iClient);
		}
		CPrintToChatAll("%t", "Duel23", ClientName[iClient], Winner[iClient]);
	}
	else
	{
		new String:buffer[1500];
		
		while (SQL_FetchRow(hndl))
		{
			new clientvictories 	= SQL_FetchInt(hndl,0);
			new clientduels			= SQL_FetchInt(hndl,1);
			if(Winner[iClient] == 1)
				clientvictories += 1;
			new Float:clientpoints 	= ((clientvictories*1.0)/(clientduels+1)) + clientvictories;
			
			Format(buffer, sizeof(buffer), "UPDATE Duels_Stats SET Players = '%s', Points = %f, Victories = Victories +%i, Duels = Duels +1, Kills = Kills +%i, Deads = Deads +%i, PlayTime = PlayTime +%i, Abandoned = Abandoned +%i, Equalities = Equalities +%i, Last_dueler = '%s', Last_dueler_SteamID = '%s', Etat = '%s' WHERE SteamID = '%s'",ClientName[iClient], clientpoints, Winner[iClient], iKills[iClient], iDeads[iClient], iTimer[iClient], Abandon[iClient], Equality[iClient], ClientName[Duel[iClient]], ClientSteamID[Duel[iClient]], etat, ClientSteamID[iClient]);
			SQL_TQuery(db,SQLErrorCheckCallback, buffer);
	
			CPrintToChatAll("%t", "Duel23", ClientName[iClient], clientvictories);
			LogMessage("MySQL => %s %d victory, and updated on database.", ClientName[iClient], clientvictories);
		}
	}
	ResetPlayer(iClient);
}

ResetPlayer(iClient)
{
	DuelEnable[iClient] 		= 0;
	ClassRestric[iClient] 		= 0;
	iKills[iClient]				= 0;
	iDeads[iClient]				= 0;
	TimeLeft[iClient]			= 0;
	Score[iClient]				= 0;
	Duel[iClient] 				= 0;
	Winner[iClient]				= 0;
	iTimer[iClient]				= 0;
	Abandon[iClient]			= 0;
	Equality[iClient]			= 0;
	GodMod[iClient]				= false;
	HeadShot[iClient]			= false;
}



public Native_IsPlayerInDuel(Handle:plugin, numParams)
{	
	new iClient = GetNativeCell(1); 
	
	if(DuelEnable[iClient] != 0)
		return true;
	else
		return false;
}

public Native_IsDuelRestrictionClass(Handle:plugin, numParams)
{	
	new iClient = GetNativeCell(1); 
	
	if(ClassRestric[iClient] != 0)
		return true;
	else
		return false;
}

public Native_GetDuelerID(Handle:plugin, numParams)
{
	return Duel[GetNativeCell(1)];
}
