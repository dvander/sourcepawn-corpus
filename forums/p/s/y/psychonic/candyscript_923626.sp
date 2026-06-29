#include <sourcemod>

/* defines */
#define PLUGIN_VERSION "0.6.0"
//#define DEBUG "1"
#define NULLNAME "$$NULL##"

public Plugin:myinfo = 
{
	name = "TF2 Game Credits",
	author = "GachL",
	description = "Give some candy to your users",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

/* Global variables */
new Handle:cvCreditPerTick;
new Handle:cvCreditPerKill;
new Handle:cvCreditLossPerSuicide;
new Handle:cvCfgTickSpeed;
new Handle:cvCfgDatabaseToUse;
new Handle:cvCfgTablePrefix;
new Handle:cvCfgChatTag;
new Handle:cvCfgTickOnlyAlive;
new Handle:cvCfgNoiseLevel;
new Handle:cvCreditLossPerDeath;
new Handle:cvKillsForCredit;
new Handle:cvCustomChatTriggerBuyMenu1;
new Handle:cvCustomChatTriggerBuyMenu2;
new Handle:cvCustomChatTriggerPlayerStats1;
new Handle:cvCustomChatTriggerPlayerStats2;

new Handle:dbConnection = INVALID_HANDLE;

new String:sChatTag[32];
new String:sTablePrefix[32];
new String:sCurrentDB[64];

new iKills[MAXPLAYERS];

new String:sConnectingClients[34][128]; // Store SteamId for sql callbacks
new iPushArray[34];

new iBuyCount = 0;
new Function:fCallbacks[512][2];
new String:sNames[512][128];
new iCosts[512];
new Float:iStopTimes[512];

public OnPluginStart()
{
	PrintDebug("Creating convars");
	/* Create convars */
	InitializeConvars();
	
	PrintDebug("Creating admin commands");
	/* Create admin commands */
	InitializeAdminCommands();
	
	HookEvent("player_connect", ePlayerConnect);
	HookEvent("player_death", ePlayerDeath);

	for (new i = 0; i < sizeof(sNames); i++)
		sNames[i] = NULLNAME;
}

public OnConfigsExecuted()
{
	InitializeTimersAndCValues();
	InitializeDatabase();
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("RegisterCandy", RegisterCandy);
	CreateNative("DeregisterCandy", DeregisterCandy);
	return true;
}

/**
 * If debug is enabled print a debug message
 */
public PrintDebug(String:sMessage[])
{
#if defined DEBUG
	PrintToServer("[CDBG] %s", sMessage);
#endif
}

public PrintNoise(String:sMessage[], level, target)
{
	PrintDebug("Printing noise");
	new iNoiseLevel = GetConVarInt(cvCfgNoiseLevel);
	if (level <= iNoiseLevel)
	{
		if (target == 0)
		{
			PrintDebug("Print noise to all");
			PrintToChatAll(sMessage);
		}
		else
		{
			PrintDebug("Print noise to [target]");
			if (!FullCheckClient(target))
			{
				PrintDebug("Invalid target!");
				return;
			}
			PrintToChat(target, sMessage);
		}
	}
}

/**
 * Create all convars
 */
public InitializeConvars()
{
	cvCreditPerKill = CreateConVar("sm_candy_credit_per_kill", "1", "Credits a user gets for killing someone", FCVAR_PLUGIN);
	cvCreditPerTick = CreateConVar("sm_candy_credit_per_tick", "1", "Credits a user gets each tick", FCVAR_PLUGIN);
	cvCreditLossPerSuicide = CreateConVar("sm_candy_loss_per_suicide", "0", "Credits a user loses if he kills himself", FCVAR_PLUGIN);
	cvCfgTickSpeed = CreateConVar("sm_candy_tick_speed", "60", "Time between two ticks in seconds", FCVAR_PLUGIN);
	cvCfgDatabaseToUse = CreateConVar("sm_candy_database", "default", "Database to use (from databases.cfg)", FCVAR_PLUGIN);
	cvCfgTablePrefix = CreateConVar("sm_candy_table_prefix", "cndy_", "Prefix for the table to store data in", FCVAR_PLUGIN);
	cvCfgChatTag = CreateConVar("sm_candy_chat_tag", "candy", "Tag for messages printed to the chat ([value] text)", FCVAR_PLUGIN);
	cvCfgTickOnlyAlive = CreateConVar("sm_candy_tick_only_alive", "0", "Give only alive players credit on tick", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvCfgNoiseLevel = CreateConVar("sm_candy_noise_level", "2", "Set the noise level 1-3", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	cvCreditLossPerDeath = CreateConVar("sm_candy_loss_per_death", "1", "Credits a user loses if he gets killed", FCVAR_PLUGIN);
	cvKillsForCredit = CreateConVar("sm_candy_kills_for_credit", "1", "Kills required to receive sm_candy_credit_per_kill", FCVAR_PLUGIN);
	cvCustomChatTriggerBuyMenu1 = CreateConVar("sm_candy_chat_buy1", "", "Custom chat trigger for the buy menu", FCVAR_PLUGIN);
	cvCustomChatTriggerBuyMenu2 = CreateConVar("sm_candy_chat_buy2", "", "Custom chat trigger for the buy menu", FCVAR_PLUGIN);
	cvCustomChatTriggerPlayerStats1 = CreateConVar("sm_candy_chat_stats1", "", "Custom chat trigger for the player stats", FCVAR_PLUGIN);
	cvCustomChatTriggerPlayerStats2 = CreateConVar("sm_candy_chat_stats2", "", "Custom chat trigger for the player stats", FCVAR_PLUGIN);
	
	PrintDebug("AutoExecConfig");
	AutoExecConfig();
	
	CreateConVar("sm_candy_version", PLUGIN_VERSION, "Candy plugin version", FCVAR_PLUGIN | FCVAR_PROTECTED| FCVAR_NOTIFY);
	
	PrintDebug("Getting new chat tag");
	GetConVarString(cvCfgChatTag, sChatTag, sizeof(sChatTag));
}

/**
 * Create all admin commands
 */
public InitializeAdminCommands()
{
	RegAdminCmd("sm_candy_add", cAddCandy, ADMFLAG_BAN, "Give an user some credits (sm_candy_add userid amount)");
	RegAdminCmd("sm_candy_remove", cRemoveCandy, ADMFLAG_BAN, "Remove some credits (sm_candy_remove userid amount)");
	RegAdminCmd("sm_candy_get", cGetCandy, ADMFLAG_BAN, "Get the amount of candy (sm_candy_get userid)");
	RegAdminCmd("sm_candy_reset", cResetCandy, ADMFLAG_BAN, "Reset the amount of candy of every player to a certain amount (sm_candy_reset amount)");
	RegAdminCmd("sm_candy_resetdb", cResetDB, ADMFLAG_BAN, "Reset the database (sm_candy_resetdb)");
}

/**
 * Initialize or renew database connection
 */
public InitializeDatabase()
{
	/**
	 * I wanted to check if there is
	 * already a connection to close
	 * it first to prevent db connection
	 * stream spamming on the server but
	 * the api says there is no function
	 * to close a database connection
	 * (which is stupid imo)
	 */
	 
	 /**
	  * Oh wait. CloseHandle?
	  */
	
	// Check if db connection is the same
	new String:sDBHndlName[128];
	GetConVarString(cvCfgDatabaseToUse, sDBHndlName, sizeof(sDBHndlName));
	if (strcmp(sCurrentDB, sDBHndlName) == 0)
	{
		PrintDebug("No change in db connection detected.");
		return;
	}
	
	// Check if db connection exist
	if (dbConnection != INVALID_HANDLE)
	{
		PrintDebug("Closing existing DB handle!");
		CloseHandle(dbConnection);
	}
	
	if (!SQL_CheckConfig(sDBHndlName))
	{
		PrintToServer("[%s] I wasn't able to find your database configuration %s", sChatTag, sDBHndlName);
		return;
	}
	SQL_TConnect(cDatabaseEstablished, sDBHndlName);
}

/**
 * Callback for threaded database connection
 */
public cDatabaseEstablished(Handle:owner, Handle:db, String:error[], any:data)
{
	PrintDebug("Database connection established");
	if (db == INVALID_HANDLE)
	{
		PrintToServer("[%s] Failed to connect: %s", sChatTag, error);
		dbConnection = INVALID_HANDLE;
		return;
	}
	else
	{
		PrintDebug("Success! Create tables if not exist!");
		new String:sDBHndlName[128];
		GetConVarString(cvCfgDatabaseToUse, sDBHndlName, sizeof(sDBHndlName));
		strcopy(sCurrentDB, sizeof(sCurrentDB), sDBHndlName);
		dbConnection = db;
		new String:qCreateTable[255];
		Format(qCreateTable, sizeof(qCreateTable), "DESCRIBE %scandydata;", sTablePrefix);
		new Handle:qCheckTableVersion = SQL_Query(dbConnection, qCreateTable)
		if (qCheckTableVersion != INVALID_HANDLE)
		{
			if (SQL_GetRowCount(qCheckTableVersion) == 2)
			{
				Format(qCreateTable, sizeof(qCreateTable), "ALTER TABLE %scandydata ADD lifetimecandy INT UNSIGNED;", sTablePrefix);
				SQL_FastQuery(dbConnection, qCreateTable);
				PrintDebug("Update database!");
			}
			else if (SQL_GetRowCount(qCheckTableVersion) == 3)
			{
				SQL_FetchRow(qCheckTableVersion);
				SQL_FetchRow(qCheckTableVersion);
				SQL_FetchRow(qCheckTableVersion); // lifetime candy
				new String:sLifeTimeCandy[255];
				SQL_FetchString(qCheckTableVersion, 4, sLifeTimeCandy, sizeof(sLifeTimeCandy));
				Format(qCreateTable, sizeof(qCreateTable), "ltc: '%s'", sLifeTimeCandy);
				PrintDebug(qCreateTable);
				if (strcmp(sLifeTimeCandy, "", false) == 0)
				{
					Format(qCreateTable, sizeof(qCreateTable), "ALTER TABLE %scandydata CHANGE candy candy INT NOT NULL DEFAULT '0', CHANGE lifetimecandy lifetimecandy INT UNSIGNED NOT NULL DEFAULT '0';", sTablePrefix);
					SQL_FastQuery(dbConnection, qCreateTable);
					PrintDebug("Updating database!");
				}
				else
				{
					PrintDebug("Latest db version!");
				}
			}
			CloseHandle(qCheckTableVersion)
		} else {
			Format(qCreateTable, sizeof(qCreateTable), "CREATE TABLE IF NOT EXISTS %scandydata (steamid VARCHAR(32) NOT NULL PRIMARY KEY, candy INT, lifetimecandy INT UNSIGNED);", sTablePrefix);
			SQL_FastQuery(dbConnection, qCreateTable);
		}
		PrintDebug("Prechecking all users");
		PrecheckAllUsers();
	}
}

/**
 * Initialize timers and cvar values
 */
public InitializeTimersAndCValues()
{
	RegConsoleCmd("say", cSay);
	
	GetConVarString(cvCfgChatTag, sChatTag, sizeof(sChatTag));
	GetConVarString(cvCfgTablePrefix, sTablePrefix, sizeof(sTablePrefix));
	
	PrintDebug("Updating tick speed");
	new iTickSpeed = GetConVarInt(cvCfgTickSpeed);
	new iCreditEarn = GetConVarInt(cvCreditPerTick);
	if ((iTickSpeed > 0) && (iCreditEarn > 0))
	{
		CreateTimer(float(iTickSpeed), tTick, _, TIMER_REPEAT);
	}
	
	for (new i = 0; i < sizeof(sConnectingClients); i++)
	{
		sConnectingClients[i] = "";
	}
}

/**
 * A new player connected!
 */
public ePlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return;
	new String:sSteamId[128], iUserId, hUserHimself;
	GetEventString(event, "networkid", sSteamId, sizeof(sSteamId));
	iUserId = GetEventInt(event, "userid");
	hUserHimself = GetClientOfUserId(iUserId);
	iKills[hUserHimself] = 0;
	
	PrintDebug("Prechecking connecting user");
	PrecheckUser(AddToConnecters(sSteamId));
}

/**
 * Someone got killed! Call 911!
 */
public ePlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintDebug("Eew, blood! player_death called!");
	InitializeDatabase();
	new attackerId = GetEventInt(event, "attacker");
	new victimId = GetEventInt(event, "userid");
	new attacker = GetClientOfUserId(attackerId);
	new victim = GetClientOfUserId(victimId);
	
	if (!FullCheckClient(attacker) || !FullCheckClient(victim))
	{
		PrintDebug("The target or the attacker are invalid clients!");
		return;
	}
	
	if (attacker == victim)
	{
		PrintDebug("Someone killed himself (suicide)");
		// suicide :(
		new iLosePoints = GetConVarInt(cvCreditLossPerSuicide);
		if (iLosePoints == 0)
			return;
		new String:sNoise[128];
		Format(sNoise, sizeof(sNoise), "[%s] You lost %i credits.", sChatTag, iLosePoints);
		PrintNoise(sNoise, 3, victim);
		RemoveCandy(victim, iLosePoints);
		return;
	}
	
	// He killed someone!
	PrintDebug("Someone got killed");
	new iCreditGain = GetConVarInt(cvCreditPerKill);
	new iCreditLoss = GetConVarInt(cvCreditLossPerDeath);
	new iKillsForCredit = GetConVarInt(cvKillsForCredit);
	new bool:bUserGetsCredits = iKillsForCredit < 2;
	
	if (!bUserGetsCredits)
	{
		if (iKills[attacker] >= iKillsForCredit)
			bUserGetsCredits = true;
		else
			iKills[attacker]++;
	}
	
	if (bUserGetsCredits)
	{
		PrintDebug("User gets credits!");
		if (iCreditGain != 0)
			AddCandy(attacker, iCreditGain);
		
		new String:sNoiseAttacker[128];
		Format(sNoiseAttacker, sizeof(sNoiseAttacker), "[%s] You got %i credits.", sChatTag, iCreditGain);
		if (iCreditGain != 0)
			PrintNoise(sNoiseAttacker, 2, attacker);
	}
	
	if (iCreditLoss != 0)
		RemoveCandy(victim, iCreditLoss);
	new String:sNoiseVictim[128];
	Format(sNoiseVictim, sizeof(sNoiseVictim), "[%s] You lost %i credits.", sChatTag, iCreditLoss);
	if (iCreditLoss != 0)
		RemoveCandy(victim, iCreditLoss);
}

public Action:cSay(client, args)
{
	PrintDebug("Say event has been fired!");
	PrintDebug("Reinitializing DB (if needed)");
	InitializeDatabase();
	PrintDebug("Checking DB connection");
	if (dbConnection == INVALID_HANDLE)
	{
		PrintDebug("Nope, no DB connection. Aborting say command");
		return Plugin_Continue;
	}
	PrintDebug("Validating client");
	if (!FullCheckClient(client))
	{
		PrintDebug("Nope, client invalid. Aborting say command");
		return Plugin_Continue;
	}
	PrintDebug("Seems to be a health client/db. Checking for commands");
	new String:text[512], String:sCustChatTriggerBuy1[128], String:sCustChatTriggerBuy2[128], String:sCustChatTriggerStats1[128], String:sCustChatTriggerStats2[128];
	GetConVarString(cvCustomChatTriggerBuyMenu1, sCustChatTriggerBuy1, sizeof(sCustChatTriggerBuy1));
	GetConVarString(cvCustomChatTriggerBuyMenu2, sCustChatTriggerBuy2, sizeof(sCustChatTriggerBuy2));
	GetConVarString(cvCustomChatTriggerPlayerStats1, sCustChatTriggerStats1, sizeof(sCustChatTriggerStats1));
	GetConVarString(cvCustomChatTriggerPlayerStats2, sCustChatTriggerStats2, sizeof(sCustChatTriggerStats2));
	GetCmdArg(1, text, sizeof(text));
	if (   (strcmp(text, "!buy", false) == 0)
		|| (strcmp(text, "!buymenu", false) == 0)
		|| (strcmp(text, "buymenu", false) == 0)
		|| (strcmp(text, "buy", false) == 0)
		|| ((strcmp(sCustChatTriggerBuy1, "", false) != 0) && (strcmp(text, sCustChatTriggerBuy1, false) == 0))
		|| ((strcmp(sCustChatTriggerBuy2, "", false) != 0) && (strcmp(text, sCustChatTriggerBuy2, false) == 0)))
	{
		PrintDebug("Someone wants to buy something");
		new String:qGetUsersCandy[255], String:sSteamId[32];
		GetClientAuthString(client, sSteamId, sizeof(sSteamId));
		Format(qGetUsersCandy, sizeof(qGetUsersCandy), "SELECT candy FROM %scandydata WHERE steamid = '%s';", sTablePrefix, sSteamId);
		SQL_TQuery(dbConnection, cBuyMenuSQLCallback, qGetUsersCandy, client);
		
		return Plugin_Handled;
	}
	else if ((strcmp(text, "!cstats", false) == 0)
		|| (strcmp(text, "!candy", false) == 0)
		|| (strcmp(text, "candy", false) == 0)
		|| (strcmp(text, "cstats", false) == 0)
		|| ((strcmp(sCustChatTriggerStats1, "", false) == 0) && (strcmp(text, sCustChatTriggerStats1, false) == 0))
		|| ((strcmp(sCustChatTriggerStats2, "", false) == 0) && (strcmp(text, sCustChatTriggerStats2, false) == 0)))
	{
		PrintDebug("Someone wants his stats");
		new String:qGetUsersCandy[255], String:sSteamId[32];
		GetClientAuthString(client, sSteamId, sizeof(sSteamId));
		Format(qGetUsersCandy, sizeof(qGetUsersCandy), "SELECT candy, lifetimecandy FROM %scandydata WHERE steamid = '%s';", sTablePrefix, sSteamId);
		SQL_TQuery(dbConnection, cStatsSQLCallback, qGetUsersCandy, client);
		
		return Plugin_Handled;
	}
	PrintDebug("Nope, no command found. Aborting say command");
	return Plugin_Continue;
}

/**
 * Precheck every user
 */
public PrecheckAllUsers()
{
	InitializeDatabase();
	new iConnectedPlayers = GetClientCount();
	for (new i = 1; i <= iConnectedPlayers; i++)
	{
		if (!FullCheckClient(i))
			continue;
		new String:sSteamId[128];
		GetClientAuthString(i, sSteamId, sizeof(sSteamId));
		PrecheckUser(AddToConnecters(sSteamId));
	}
}

/**
 * Add SteamId to steamid list
 */
public AddToConnecters(String:sSteamId[128])
{
	// Check if already in list
	for (new i = 0; i < sizeof(sConnectingClients); i++)
	{
		if (strcmp(sConnectingClients[i], sSteamId) == 0)
			return i;
	}
	
	new iNext = 0;
	for (new i = 0; i < sizeof(sConnectingClients); i++)
	{
		iNext = i;
		if (strcmp(sConnectingClients[i], "") == 0)
			break;
	}
	sConnectingClients[iNext] = sSteamId;
	PrintDebug("Adding a value to the connectors");
	return iNext;
}

/**
 * Remove SteamId from steamid list
 */
public RemoveFromConnecters(position)
{
	sConnectingClients[position] = "";
	PrintDebug("Removing a value from the connectors");
}

/**
 * Tick!
 */
public Action:tTick(Handle:timer)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return;
	
	new String:err[255];
	SQL_GetError(dbConnection, err, sizeof(err));
	PrintDebug(err);
	
	PrintDebug("Tick!");
	
	new iCreditEarn = GetConVarInt(cvCreditPerTick);
	new iConnectedPlayers = GetClientCount();
	for (new i = 1; i <= iConnectedPlayers; i++)
	{
		if (!FullCheckClient(i))
			continue;
		
		PrintDebug("Processing a client in tick!");
		
		new iOnlyAlive = GetConVarInt(cvCfgTickOnlyAlive);
		if ((iOnlyAlive == 1) && !IsPlayerAlive(i))
		{
			PrintDebug("Client is dead and dead clients don't get points!");
			continue;
		}
		
		/**
		 * This client is now free to
		 * get his candy
		 */
		PrintDebug("He's got candy!");
		AddCandy(i, iCreditEarn);
		new String:sTickNoise[128];
		if (iCreditEarn == 1)
			Format(sTickNoise, sizeof(sTickNoise), "[%s] You received 1 credit!", sChatTag);
		else if (iCreditEarn > 1)
			Format(sTickNoise, sizeof(sTickNoise), "[%s] You received %i credits!", sChatTag, iCreditEarn);
		PrintNoise(sTickNoise, 3, i);
	}
}

/**
 * Admin command to add candy
 * to an user
 */
public Action:cAddCandy(client, args)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return Plugin_Handled;
	new String:sTarget[32], String:sAmount[32];
	new iTarget, iAmount;
	
	if (!GetCmdArg(1, sTarget, sizeof(sTarget)))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] Usage: sm_candy_add userid amount", sChatTag);
		else
			PrintToServer("[%s] Usage: sm_candy_add userid amount", sChatTag);
		return Plugin_Handled;
	}
	
	if (!GetCmdArg(2, sAmount, sizeof(sAmount)))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] Usage: sm_candy_add userid amount", sChatTag);
		else
			PrintToServer("[%s] Usage: sm_candy_add userid amount", sChatTag);
		return Plugin_Handled;
	}
	
	iTarget = GetClientOfUserId(StringToInt(sTarget));
	iAmount = StringToInt(sAmount);
	
	if (!FullCheckClient(iTarget))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] No such user (%s)", sChatTag, sTarget);
		else
			PrintToServer("[%s] No such user (%s)", sChatTag, sTarget);
		return Plugin_Handled;
	}
	
	if (iAmount != 0)
	{
		AddCandy(iTarget, iAmount);
	}
	
	new String:sCandyNoise[255];
	Format(sCandyNoise, sizeof(sCandyNoise), "[%s] A nice admin gave you %i credits.", sChatTag, iAmount);
	PrintNoise(sCandyNoise, 2, iTarget);
	
	return Plugin_Handled;
}

/**
 * Admin command to remove candy
 * from an user
 */
public Action:cRemoveCandy(client, args)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return Plugin_Handled;
	new String:sTarget[32], String:sAmount[32];
	new iTarget, iAmount;
	
	if (!GetCmdArg(1, sTarget, sizeof(sTarget)))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] Usage: sm_candy_remove userid amount", sChatTag);
		else
			PrintToServer("[%s] Usage: sm_candy_remove userid amount", sChatTag);
		return Plugin_Handled;
	}
	
	if (!GetCmdArg(2, sAmount, sizeof(sAmount)))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] Usage: sm_candy_remove userid amount", sChatTag);
		else
			PrintToServer("[%s] Usage: sm_candy_remove userid amount", sChatTag);
		return Plugin_Handled;
	}
	
	iTarget = GetClientOfUserId(StringToInt(sTarget));
	iAmount = StringToInt(sAmount);
	
	if (!FullCheckClient(iTarget))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] No such user (%s)", sChatTag, sTarget);
		else
			PrintToServer("[%s] No such user (%s)", sChatTag, sTarget);
		return Plugin_Handled;
	}
	
	if (iAmount != 0)
	{
		RemoveCandy(iTarget, iAmount);
	}
	
	new String:sCandyNoise[255];
	Format(sCandyNoise, sizeof(sCandyNoise), "[%s] An evil admin stole %i credits from you.", sChatTag, iAmount);
	PrintNoise(sCandyNoise, 2, iTarget);
	
	return Plugin_Handled;
}

/**
 * Admin command to set the
 * amount of every users
 * candy to a specific value
 */
public Action:cResetCandy(client, args)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return Plugin_Handled;
	new String:sAmount[32];
	
	if (!GetCmdArg(1, sAmount, sizeof(sAmount)))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] Usage: sm_candy_reset amount", sChatTag);
		else
			PrintToServer("[%s] Usage: sm_candy_reset amount", sChatTag);
		return Plugin_Handled;
	}
	
	new iAmount = StringToInt(sAmount);
	if (iAmount < 0)
		return Plugin_Handled;
	
	if (!FullCheckClient(client))
	{
		// run as console -> execute it without asking. :(
		new String:qReset[255];
		Format(qReset, sizeof(qReset), "UPDATE %scandydata SET candy = %s;", sTablePrefix, sAmount);
		SQL_TQuery(dbConnection, cIgnoreQueryCallback, qReset);
		PrintToServer("Reset all clients candy to %s", sAmount);
		return Plugin_Handled;
	}
	
	new Handle:mAskForSure = CreateMenu(cResetCandyMenuCallback);
	SetMenuTitle(mAskForSure, "Reset candy to %s?", sAmount);
	AddMenuItem(mAskForSure, "no", "No");
	AddMenuItem(mAskForSure, sAmount, "Yes");
	DisplayMenu(mAskForSure, client, 20);
	return Plugin_Handled;
}

/**
 * Admin command to reset the
 * database (deletes everything)
 */
public Action:cResetDB(client, args)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return Plugin_Handled;
	
	if (!FullCheckClient(client))
	{
		// run as console -> execute it without asking. :(
		new String:qReset[255];
		Format(qReset, sizeof(qReset), "DROP TABLE %scandydata;", sTablePrefix);
		SQL_TQuery(dbConnection, cIgnoreQueryCallback, qReset);
		PrintToServer("Reset db, dropping EVERYTHING!");
		CloseHandle(dbConnection);
		dbConnection = INVALID_HANDLE;
		sCurrentDB = "INVALID_DATABASE";
		InitializeDatabase();
		return Plugin_Handled;
	}
	
	new Handle:mAskForSure = CreateMenu(cResetDBMenuCallback);
	SetMenuTitle(mAskForSure, "Reset database?");
	AddMenuItem(mAskForSure, "no", "No");
	AddMenuItem(mAskForSure, "yes", "Yes");
	DisplayMenu(mAskForSure, client, 20);
	return Plugin_Handled;
}

/**
 * Admin command to show how
 * much candy the user owns
 */
public Action:cGetCandy(client, args)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return Plugin_Handled;
	new String:sTarget[32];
	new iTarget;
	
	if (!GetCmdArg(1, sTarget, sizeof(sTarget)))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] Usage: sm_candy_get userid", sChatTag);
		else
			PrintToServer("[%s] Usage: sm_candy_get userid", sChatTag);
		return Plugin_Handled;
	}
	
	iTarget = GetClientOfUserId(StringToInt(sTarget));
	
	if (!FullCheckClient(iTarget))
	{
		if (FullCheckClient(client))
			PrintToChat(client, "[%s] No such user (%s)", sChatTag, sTarget);
		else
			PrintToServer("[%s] No such user (%s)", sChatTag, sTarget);
		return Plugin_Handled;
	}
	
	new String:qGetUsersCandy[255], String:sSteamId[32];
	GetClientAuthString(iTarget, sSteamId, sizeof(sSteamId));
	Format(qGetUsersCandy, sizeof(qGetUsersCandy), "SELECT candy FROM %scandydata WHERE steamid = '%s';", sTablePrefix, sSteamId);
	SQL_TQuery(dbConnection, cGetUsersCandy, qGetUsersCandy, client);
	PrintDebug(qGetUsersCandy);
	PrintDebug(qGetUsersCandy);
	
	return Plugin_Handled;
}

/**
 * Callback of cGetCandy
 */
public cGetUsersCandy(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[%s] Error while executing cGetCandy query: %s", sChatTag, error);
		return;
	}
	
	if (SQL_GetRowCount(hndl) == 1)
	{
		SQL_FetchRow(hndl);
		new iHisCandy = SQL_FetchInt(hndl, 0);
		if (FullCheckClient(data))
			PrintToChat(data, "[%s] This user has got \x03%i\x01 credits.", sChatTag, iHisCandy);
		else
			PrintToServer("[%s] This user has got \x03%i\x01 credits.", sChatTag, iHisCandy);
	}
	else
	{
		if (FullCheckClient(data))
			PrintToChat(data, "[%s] This user does not exist in the database.", sChatTag);
		else
			PrintToServer("[%s] This user does not exist in the database.", sChatTag);
	}
}

/**
 * Check if this user exists in
 * the database
 */
public PrecheckUser(position)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return;
	new String:sSteamId[32];
	strcopy(sSteamId, sizeof(sSteamId), sConnectingClients[position]);
	new String:qCheckForUser[255];
	Format(qCheckForUser, sizeof(qCheckForUser), "SELECT * FROM %scandydata WHERE steamid = '%s';", sTablePrefix, sSteamId);
	SQL_TQuery(dbConnection, cPrecheckUser, qCheckForUser, position);
}

/**
 * Callback of PrecheckUser
 */
public cPrecheckUser(Handle:owner, Handle:hndl, String:error[], any:data)
{
	new String:sSteamId[32];
	strcopy(sSteamId, sizeof(sSteamId), sConnectingClients[data]);
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[%s] Error while executing PrecheckUser query: %s", sChatTag, error);
		return;
	}
	
	if (SQL_GetRowCount(hndl) != 1)
	{
		// Create new user
		new String:qCreateNewUser[255];
		Format(qCreateNewUser, sizeof(qCreateNewUser), "INSERT INTO %scandydata (steamid, candy, lifetimecandy) VALUES ('%s', 0, 0);", sTablePrefix, sSteamId);
		SQL_TQuery(dbConnection, cIgnoreQueryCallback, qCreateNewUser);
	}
	
	RemoveFromConnecters(data);
}

/**
 * Give a player candy
 */
public AddCandy(client, amount)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return;
	if (!FullCheckClient(client))
		return;
	new String:sSteamId[32];
	GetClientAuthString(client, sSteamId, sizeof(sSteamId));
	new String:qAddCandy[255];
	Format(qAddCandy, sizeof(qAddCandy), "UPDATE %scandydata SET candy = candy + %i, lifetimecandy = lifetimecandy + %i WHERE steamid = '%s';", sTablePrefix, amount, amount, sSteamId);
	PrintDebug(qAddCandy);
	SQL_TQuery(dbConnection, cIgnoreQueryCallback, qAddCandy);
}

/**
 * You suck, so no candy for you!
 */
public RemoveCandy(client, amount)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return;
	if (!FullCheckClient(client))
		return;
	new String:sSteamId[32];
	GetClientAuthString(client, sSteamId, sizeof(sSteamId));
	new String:qAddCandy[255];
	Format(qAddCandy, sizeof(qAddCandy), "SELECT candy, '%s' FROM %scandydata WHERE steamid = '%s';", sSteamId, sTablePrefix, sSteamId);
	SQL_TQuery(dbConnection, cCheckForNegativeAmount, qAddCandy, amount);
}

public cCheckForNegativeAmount(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[%s] Error in remove candy query: %s", sChatTag, error);
		return;
	}
	
	SQL_FetchRow(hndl);
	if (SQL_FetchInt(hndl, 0) - data < 0)
		return;
	new String:sSteamId[32];
	SQL_FetchString(hndl, 1, sSteamId, sizeof(sSteamId));

	new String:qAddCandy[255];
	Format(qAddCandy, sizeof(qAddCandy), "UPDATE %scandydata SET candy = candy - %i WHERE steamid = '%s';", sTablePrefix, data, sSteamId);
	SQL_TQuery(dbConnection, cIgnoreQueryCallback, qAddCandy);
}

/**
 * Set a specific amount of candy
 */
public SetCandy(client, amount)
{
	InitializeDatabase();
	if (dbConnection == INVALID_HANDLE)
		return;
	if (!FullCheckClient(client))
		return;
	new String:sSteamId[32];
	GetClientAuthString(client, sSteamId, sizeof(sSteamId));
	new String:qAddCandy[255];
	Format(qAddCandy, sizeof(qAddCandy), "UPDATE %scandydata SET candy = %i WHERE steamid = '%s';", sTablePrefix, amount, sSteamId);
	SQL_TQuery(dbConnection, cIgnoreQueryCallback, qAddCandy);
}

/**
 * Discard query callback
 */
public cIgnoreQueryCallback(Handle:owner, Handle:hndl, String:error[], any:data)
{
	return;
}

/**
 * Perform a full check if
 * the client is valid
 */
public bool:FullCheckClient(client)
{
	if (client < 1) {
		PrintDebug("Client < 0");
		return false;
	}
	
	if (!IsClientConnected(client)) {
		PrintDebug("Client not connected");
		return false;
	}
	
	if (!IsClientInGame(client)) {
		PrintDebug("Client not ingame");
		return false;
	}
	
	if (IsFakeClient(client)) {
		PrintDebug("Client is fake");
		return false;
	}
	
	return true;
}

/**
 * Candy stats SQL callback
 */
public cStatsSQLCallback(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[%s] Error in buy menu query: %s", sChatTag, error);
		return;
	}
	
	SQL_FetchRow(hndl);
	new iCurrentMoney = SQL_FetchInt(hndl, 0);
	new iLifetimeMoney = SQL_FetchInt(hndl, 1);
	
	PrintToChat(data, "[%s] You currently own \x04%i\x01 credits. You totally earned \x04%i\x01!", sChatTag, iCurrentMoney, iLifetimeMoney);
}

/**
 * Buy menu SQL callback
 */
public cBuyMenuSQLCallback(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[%s] Error in buy menu query: %s", sChatTag, error);
		return;
	}
	
	SQL_FetchRow(hndl);
	new iCurrentMoney = SQL_FetchInt(hndl, 0);
	
	/**
	 * Thanks to the allied mods wiki!
	 */
	new String:sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath),"configs/buymenu.txt");

	if (!FileExists(sFilePath))
    {
        PrintToServer("[%s] buymenu.txt not found in configs folder!", sChatTag);
        return;
    }
	new Handle:kv = CreateKeyValues("Buymenu");
	FileToKeyValues(kv, sFilePath);
 
	if (!KvGotoFirstSubKey(kv))
	{
		PrintToServer("[%s] Failed to read the buymenu.txt", sChatTag);
		return;
	}
	
	new Handle:mBuyMenu = CreateMenu(cBuyMenu);
	SetMenuTitle(mBuyMenu, "Your credits: %i", iCurrentMoney);
 
	for (new i = 0; i < sizeof(sNames); i++)
	{
		if (strcmp(sNames[i], NULLNAME) == 0)
			continue;
		new String:sInfo[128];
		IntToString(i+1024, sInfo, sizeof(sInfo));
		AddMenuItem(mBuyMenu, sInfo, sNames[i], (iCurrentMoney >= iCosts[i] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
	}
 
	/**
	 * I know the following code is
	 * totally stupid and chaos
	 * but I'm too lazy to clean
	 * up. Huh? *looking around*
	 * True.. true...
	 */
	decl String:buffer[255];
	do
	{
		new String:sTitle[32], String:sCosts[32], String:sText[64];
		KvGetSectionName(kv, buffer, sizeof(buffer));
		KvGetString(kv, "title", sTitle, sizeof(sTitle));
		KvGetString(kv, "price", sCosts, sizeof(sCosts));
		Format(sText, sizeof(sText), "%s (%s)", sTitle, sCosts);
		AddMenuItem(mBuyMenu, buffer, sText, (iCurrentMoney >= StringToInt(sCosts) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED));
	} while (KvGotoNextKey(kv));
 
	CloseHandle(kv)
	DisplayMenu(mBuyMenu, data, 20);
}

/**
 * Buy menu callback
 */
public cBuyMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, param2, info, sizeof(info))
		
		new String:qGetUsersCandy[255], String:sSteamId[32];
		GetClientAuthString(param1, sSteamId, sizeof(sSteamId));
		Format(qGetUsersCandy, sizeof(qGetUsersCandy), "SELECT candy, '%s' FROM %scandydata WHERE steamid = '%s';", info, sTablePrefix, sSteamId);
		SQL_TQuery(dbConnection, cBuyMenuCallbackSQLCallback, qGetUsersCandy, param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/**
 * [Buy menu callback] [SQL callback] (lol)
 */
public cBuyMenuCallbackSQLCallback(Handle:owner, Handle:hndl, String:error[], any:data)
{
	PrintDebug("MenuCallback!");
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[%s] Error in buy menu query: %s", sChatTag, error);
		return;
	}
	
	PrintDebug("Get all data");
	SQL_FetchRow(hndl);
	new iCurrentMoney = SQL_FetchInt(hndl, 0);
	new String:sBuyEntry[32];
	SQL_FetchString(hndl, 1, sBuyEntry, sizeof(sBuyEntry));
	new iBuyEntry = StringToInt(sBuyEntry);
	
	if (iBuyEntry < 1024)
	{
		new String:sTitle[32], String:sPrice[32], String:sOnCmd[256], String:sOffCmd[256], String:sTime[32];
		new String:sFilePath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sFilePath, sizeof(sFilePath),"configs/buymenu.txt");

		if (!FileExists(sFilePath))
		{
		PrintToServer("[%s] buymenu.txt not found in configs folder!", sChatTag);
		return;
		}
		new Handle:kv = CreateKeyValues("Buymenu");
		FileToKeyValues(kv, sFilePath);
		if (!KvJumpToKey(kv, sBuyEntry))
		{
			return;
		}
		
		KvGetString(kv, "title", sTitle, sizeof(sTitle));
		KvGetString(kv, "price", sPrice, sizeof(sPrice));
		KvGetString(kv, "oncmd", sOnCmd, sizeof(sOnCmd));
		KvGetString(kv, "offcmd", sOffCmd, sizeof(sOffCmd));
		KvGetString(kv, "time", sTime, sizeof(sTime));
		new iPrice, Float:iTime;
		iPrice = StringToInt(sPrice);
		iTime = StringToFloat(sTime);
		CloseHandle(kv);
		if (iCurrentMoney < iPrice)
		{
			// U faild n00b!!
			PrintDebug("Insufficient funds!");
			PrintToChat(data, "[%s] You don't have enough credits to buy that! (Required: %i)", sChatTag, iPrice);
			return;
		}

		PrintDebug("Parsing ?$#~|");
		new String:sUserId[8], String:sName[128], String:sIndex[4], String:sSteamId[32], String:sQuotedName[128];
		IntToString(GetClientUserId(data), sUserId, sizeof(sUserId));
		GetClientName(data, sName, sizeof(sName));
		GetClientAuthString(data, sSteamId, sizeof(sSteamId));
		IntToString(data, sIndex, sizeof(sIndex));
		Format(sQuotedName, sizeof(sQuotedName), "\"%s\"", sName);
		ReplaceChar("?", sUserId, sOnCmd);
		ReplaceChar("$", sName, sOnCmd);
		ReplaceChar("#", sIndex, sOnCmd);
		ReplaceChar("~", sSteamId, sOnCmd);
		ReplaceChar("|", sQuotedName, sOnCmd);
		
		RemoveCandy(data, iPrice);
		PrintDebug("Running OnCmd");
		ServerCommand(sOnCmd);
		
		if (iTime > 0)
		{
			PrintDebug("Command has off time");
			ReplaceChar("?", sUserId, sOffCmd);
			ReplaceChar("$", sName, sOffCmd);
			ReplaceChar("#", sIndex, sOffCmd);
			ReplaceChar("~", sSteamId, sOffCmd);
			ReplaceChar("|", sQuotedName, sOffCmd);

			PrintDebug("Creating off timer");
			new String:sSmallOffCmd[128];
			strcopy(sSmallOffCmd, sizeof(sSmallOffCmd), sOffCmd);
			new iDataStore = AddToConnecters(sSmallOffCmd); // abuse of the AddToConnecters, but who cares?
			CreateTimer(iTime, tStopCommand, iDataStore);
		}
	}
	else
	{
		iBuyEntry -= 1024;
		if (strcmp(sNames[iBuyEntry], NULLNAME) == 0)
			return;
		if (iCurrentMoney < iCosts[iBuyEntry])
		{
			// U faild n00b!!
			PrintDebug("Insufficient funds!");
			PrintToChat(data, "[%s] You don't have enough credits to buy that! (Required: %i)", sChatTag, iCosts[iBuyEntry]);
			return;
		}
		Call_StartFunction(INVALID_HANDLE, fCallbacks[iBuyEntry][0]);
		Call_PushCell(data);
		Call_PushCell(iCurrentMoney);
		new Float:iResult;
		if (Call_Finish(iResult) == SP_ERROR_NONE)
		{
			if (iResult > 0)
			{
				new iRemoveMoney = RoundToNearest(iCosts[iBuyEntry]*iResult);
				if (iRemoveMoney > iCurrentMoney)
					return;
				RemoveCandy(data, iRemoveMoney);
			}
		}
		
		if ((iStopTimes[iBuyEntry] > 0) && (fCallbacks[iBuyEntry][1] != INVALID_FUNCTION))
		{
			new String:sFitBuyEntry[128];
			strcopy(sFitBuyEntry, sizeof(sFitBuyEntry), sBuyEntry);
			new iStore = AddToConnecters(sFitBuyEntry);
			iPushArray[iStore] = data;
			CreateTimer(iStopTimes[iBuyEntry], tStopCommand, iStore);
		}
	}
}

public ReplaceChar(String:sSplitChar[], String:sReplace[], String:sString[256])
{
	StrCat(sString, sizeof(sString), " ");
	new String:sBuffer[16][256];
	ExplodeString(sString, sSplitChar, sBuffer, sizeof(sBuffer), sizeof(sBuffer[]));
	strcopy(sString, sizeof(sString), "");
	for (new i = 0; i < sizeof(sBuffer); i++)
	{
		if (strcmp(sBuffer[i], "") == 0)
			continue;
		if (i != 0)
		{
			new String:sTmpStr[256];
			Format(sTmpStr, sizeof(sTmpStr), "%s%s", sReplace, sBuffer[i]);
			StrCat(sString, sizeof(sString), sTmpStr);
		}
		else
		{
			StrCat(sString, sizeof(sString), sBuffer[i]);
		}
	}
}

/**
 * Reset candy menu callback
 */
public cResetCandyMenuCallback(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, item, info, sizeof(info))
		
		if (strcmp(info, "no", false) == 0)
			return;
		
		new String:qResetCandy[255];
		Format(qResetCandy, sizeof(qResetCandy), "UPDATE %scandydata SET candy = '%s';", sTablePrefix, info);
		SQL_TQuery(dbConnection, cIgnoreQueryCallback, qResetCandy);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/**
 * Reset database menu callback
 */
public cResetDBMenuCallback(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Select)
	{
		new String:info[32]
		GetMenuItem(menu, item, info, sizeof(info))
		
		if (strcmp(info, "no", false) == 0)
			return;
		
		new String:qReset[255];
		Format(qReset, sizeof(qReset), "DROP TABLE %scandydata;", sTablePrefix);
		SQL_TQuery(dbConnection, cIgnoreQueryCallback, qReset);
		PrintToServer("Reset db, dropping EVERYTHING!");
		CloseHandle(dbConnection);
		dbConnection = INVALID_HANDLE;
		sCurrentDB = "INVALID_DATABASE";
		InitializeDatabase();
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
}

/**
 * STOP the MADNESS!!
 */
public Action:tStopCommand(Handle:timer, any:data)
{
	new iEntry = StringToInt(sConnectingClients[data]);
	if (iEntry >= 1024)
	{
		iEntry -= 1024;
		if (fCallbacks[iEntry][1] == INVALID_FUNCTION)
			return;
		new client = iPushArray[data];
		Call_StartFunction(INVALID_HANDLE, fCallbacks[iEntry][1]);
		Call_PushCell(client);
		Call_Finish(_);
		iPushArray[data] = 0;
	}
	else
	{
		PrintDebug("Off timer called with this command:");
		PrintDebug(sConnectingClients[data]);
		ServerCommand(sConnectingClients[data]);
	}
	RemoveFromConnecters(data);
}

/**
 * API
 */
public RegisterCandy(Handle:hPlugin, iNumParams)
{
	new String:sName[256], iBuyCosts, Float:iStopTime, Function:fStart, Function:fStop
	GetNativeString(1, sName, sizeof(sName));
	iBuyCosts = GetNativeCell(2);
	iStopTime = GetNativeCell(3);
	fStart = GetNativeCell(4);
	fStop = GetNativeCell(5);
	
	if (strlen(sName) == 0)
	{
		LogError("Error: Candy name not given!");
		return -1;
	}
	if (iBuyCosts <= 0)
	{
		LogError("Error: Buy costs <= 0!");
		return -1;
	}
	new iClicks = 0;
	new bool:run = true; // warning, constant expression blah blah ow shut up!
	while (run)
	{
		if (strcmp(sNames[iBuyCount], NULLNAME) == 0)
			break;
		iBuyCount++;
		if (iBuyCount >= sizeof(sNames))
		{
			iBuyCount = 0;
			iClicks++;
		}
		if (iClicks >= 2)
		{
			LogError("Error: Too much candy (max. %i)", sizeof(sNames));
			return -1; // No free spots left
		}
	}
	strcopy(sNames[iBuyCount], sizeof(sNames[]), sName);
	iCosts[iBuyCount] = iBuyCosts;
	fCallbacks[iBuyCount][0] = fStart;
	fCallbacks[iBuyCount][1] = fStop;
	if (iStopTime > 0)
		iStopTimes[iBuyCount] = iStopTime;
	return iBuyCount;
}

public DeregisterCandy(Handle:hPlugin, iNumParams)
{
	new iCandyId = GetNativeCell(1);
	fCallbacks[iCandyId][0] = INVALID_FUNCTION;
	fCallbacks[iCandyId][1] = INVALID_FUNCTION;
	iCosts[iCandyId] = 0;
	sNames[iCandyId] = NULLNAME;
	iStopTimes[iCandyId] = 0.0;
}
