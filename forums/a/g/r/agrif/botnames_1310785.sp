// botnames.sp - give names to bots when they're created
// Written and maintained by Aaron Griffith <aargri@gmail.com>
// for more information, see <http://gamma-level.com/teamfortress2/botnames>

// This file is in the public domain. Do with it what you will.

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma unused cvarVersion

#define PLUGIN_VERSION "1.2"
#define PLUGIN_DESCRIPTION "Gives automatic names to bots on creation."
#define BOT_NAME_FILE "configs/botnames.txt"

// how long to wait to setup bot names, after they join a team
// used to work around TF2 bots changing names after joining a team
#define BOTSETUP_WAIT 10.0

// maximum players to be expected, ever
#define MAX_PLAYERS 256

// the shortest possible name length -- as a sanity check
#define MIN_NAME_LENGTH 2

// this array will store the names loaded
new Handle:bot_names;

// this array will have a list of indexes to
// bot_names, use these in order
new Handle:name_redirects;

// this is the next index to use into name_redirects
// update this each time you use a name
new next_index;

// an array to hold all our name change timers, so we can suppress
// any other name changes until it's done
new Handle:bot_timers[MAX_PLAYERS + 1];

// various convars
new Handle:cvarVersion; // version cvar!
new Handle:cvarEnabled; // are we enabled?
// (note - name list still reloaded on map load even when disabled)

// name list source settings
new Handle:cvarDatabaseName; // name from databases.cfg, or "" to use file
new Handle:cvarDatabaseTable; // what table to use
new Handle:cvarDatabaseColumn; // what column to use

// general settings
new Handle:cvarPrefix; // bot name prefix
new Handle:cvarRandom; // use random-order names?
new Handle:cvarAnnounce; // announce new bots?
new Handle:cvarSuppress; // supress join/team/namechange messages?

public Plugin:myinfo =
{
	name = "Bot Names",
	author = "Rakeri",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = ""
}

// a function to generate name_redirects
GenerateRedirects()
{
	new loaded_names = GetArraySize(bot_names);

	if (name_redirects != INVALID_HANDLE)
	{
		ResizeArray(name_redirects, loaded_names);
	} else {
		name_redirects = CreateArray(1, loaded_names);
	}

	for (new i = 0; i < loaded_names; i++)
	{
		SetArrayCell(name_redirects, i, i);
		
		// nothing to do random-wise if i == 0
		if (i == 0)
		{
			continue;
		}

		// now to introduce some chaos
		if (GetConVarBool(cvarRandom))
		{
			SwapArrayItems(name_redirects, GetRandomInt(0, i - 1), i);
		}
	}
}

// a function to load data into bot_names from BOT_NAME_FILE
ReloadNamesFromFile()
{
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), BOT_NAME_FILE);
	
	new Handle:file = OpenFile(path, "r");
	if (file == INVALID_HANDLE)
	{
		PrintToServer("[botnames] could not open file \"%s\"", path);
		return;
	}
	
	// this LENGTH*3 is sort of a hack
	// don't make long lines, people!
	decl String:newname[MAX_NAME_LENGTH*3];
	decl String:formedname[MAX_NAME_LENGTH];
	decl String:prefix[MAX_NAME_LENGTH];

	GetConVarString(cvarPrefix, prefix, sizeof(prefix));

	while (IsEndOfFile(file) == false)
	{
		if (ReadFileLine(file, newname, sizeof(newname)) == false)
		{
			break;
		}
		
		// trim off comments starting with // or #
		new commentstart;
		commentstart = StrContains(newname, "//");
		if (commentstart != -1)
		{
			newname[commentstart] = 0;
		}
		commentstart = StrContains(newname, "#");
		if (commentstart != -1)
		{
			newname[commentstart] = 0;
		}
		
		new length = strlen(newname);
		if (length < MIN_NAME_LENGTH)
		{
			// we loaded a bum name
			// (that is, blank line or 1 char == bad)
			continue;
		}

		// get rid of pesky whitespace
		TrimString(newname);
		
		Format(formedname, sizeof(formedname), "%s%s", prefix, newname);
		PushArrayString(bot_names, formedname);
	}
	
	CloseHandle(file);
}

// as above, but loads from the database
ReloadNamesFromDatabase()
{
	decl String:dbname[128];
	GetConVarString(cvarDatabaseName, dbname, sizeof(dbname));
	
	// error storage
	decl String:error[256];
	
	new Handle:db = SQL_Connect(dbname, true, error, sizeof(error));
	if (db == INVALID_HANDLE)
	{
		PrintToServer("[botnames] error: could not connect to database \"%s\"", dbname);
		PrintToServer("[botnames] %s", error);
		return;
	}
	
	// get info about our query-to-be
	decl String:dbtable[128];
	GetConVarString(cvarDatabaseTable, dbtable, sizeof(dbtable));
	decl String:dbcolumn[128];
	GetConVarString(cvarDatabaseColumn, dbcolumn, sizeof(dbcolumn));
	
	// construct our query
	decl String:dbquery[512];
	Format(dbquery, sizeof(dbquery), "SELECT %s FROM %s", dbcolumn, dbtable);
	
	// get the data
	new Handle:query = SQL_Query(db, dbquery);
	if (query == INVALID_HANDLE)
	{
		PrintToServer("[botnames] error: could not query database \"%s\"", dbname);
		if (SQL_GetError(db, error, sizeof(error)))
			PrintToServer("[botnames] %s", error);
		
		CloseHandle(db);
		return;
	}
	
	// set up name processing vars
	decl String:newname[MAX_NAME_LENGTH];
	decl String:formedname[MAX_NAME_LENGTH];
	decl String:prefix[MAX_NAME_LENGTH];

	GetConVarString(cvarPrefix, prefix, sizeof(prefix));
	
	// process names
	while (SQL_FetchRow(query))
	{
		SQL_FetchString(query, 0, newname, sizeof(newname));
		
		if (strlen(newname) < MIN_NAME_LENGTH)
		{
			// bum name -- invalid
			continue;
		}
		
		// prefix the name, and add it to our list
		Format(formedname, sizeof(formedname), "%s%s", prefix, newname);
		PushArrayString(bot_names, formedname);
	}
	
	// clean up
	CloseHandle(query);
	CloseHandle(db);
}

// reloads names from file, or database -- whatever's appropriate
ReloadNames()
{
	// reset name list position
	next_index = 0;

	// create -- or clear -- the name array
	if (bot_names != INVALID_HANDLE)
	{
		ClearArray(bot_names);
	} else {
		bot_names = CreateArray(MAX_NAME_LENGTH);
	}
	
	decl String:dbname[128];
	GetConVarString(cvarDatabaseName, dbname, sizeof(dbname));
	
	if (strlen(dbname) == 0)
	{
		// no valid database setup, load from file
		ReloadNamesFromFile();
	} else {
		// valid database (probably), load from there
		ReloadNamesFromDatabase();
	}
}

// load the next name into a string
LoadNextName(String:name[], maxlen)
{
	new loaded_names = GetArraySize(bot_names);

	GetArrayString(bot_names, GetArrayCell(name_redirects, next_index), name, maxlen);

	next_index++;
	if (next_index > loaded_names - 1)
	{
		next_index = 0;
	}
}

// actually set the client name
DoBotName(client, announce)
{
	// if we have no names, just stop right there
	new loaded_names = GetArraySize(bot_names);
	if (loaded_names <= 0)
	{
		return;
	}

	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, MAX_NAME_LENGTH);
	if (FindStringInArray(bot_names, name) != -1)
	{
		// this bot has been named appropriately, skip
		return;
	}
	
	LoadNextName(name, MAX_NAME_LENGTH);	
	SetClientInfo(client, "name", name);
	
	if (GetConVarBool(cvarAnnounce) && announce)
	{
		PrintToChatAll("[botnames] Bot created.");
		PrintToServer("[botnames] Bot created.");
	}
}

// called when the plugin loads
public OnPluginStart()
{
	// cvars!
	cvarVersion = CreateConVar("sm_botnames_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("sm_botnames_enabled", "1", "sets whether bot naming is enabled", FCVAR_NOTIFY | FCVAR_PLUGIN);
	
	cvarDatabaseName = CreateConVar("sm_botnames_db_name", "", "a named database to load bot names from, or \"\" to load from file", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarDatabaseTable = CreateConVar("sm_botnames_db_table", "botnames", "the table to load names from, if loading from a database", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarDatabaseColumn = CreateConVar("sm_botnames_db_column", "name", "the name of the column that contains the bot names, if loading from a database", FCVAR_NOTIFY | FCVAR_PLUGIN);
	
	cvarPrefix = CreateConVar("sm_botnames_prefix", "", "sets a prefix for bot names (include a trailing space, if needed!)", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarRandom = CreateConVar("sm_botnames_random", "1", "sets whether to randomize names used", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarAnnounce = CreateConVar("sm_botnames_announce", "0", "sets whether to announce bots when added", FCVAR_NOTIFY | FCVAR_PLUGIN);
	cvarSuppress = CreateConVar("sm_botnames_suppress", "1", "sets whether to supress join/team change/name change bot messages", FCVAR_NOTIFY | FCVAR_PLUGIN);
	
	// hook team change, connect to supress messages
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);

	// trickier... name changes are user messages, so...
	HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true);

	// register our commands
	RegServerCmd("sm_botnames_reload", Command_Reload);
	
	// fill up bot_timers with INVALID_HANDLEs
	for (new i = 1; i <= MAX_PLAYERS; i++)
	{
		bot_timers[i] = INVALID_HANDLE;
	}

	AutoExecConfig();
}

// handle disconnects: remove bot timers
public OnClientDisconnect(client)
{
	if (bot_timers[client] != INVALID_HANDLE)
	{
		KillTimer(bot_timers[client]);
		bot_timers[client] = INVALID_HANDLE;
	}
}


public OnMapStart()
{
	// note that we should change this so name reload only happens
	// when the plugin is enabled, but for now...
	ReloadNames();
	GenerateRedirects();
}

// reload bot name, via console
public Action:Command_Reload(args)
{
	ReloadNames();
	GenerateRedirects();
	PrintToServer("[botnames] Loaded %i names.", GetArraySize(bot_names));
}

// handle "SayText2" usermessages, including name change notifies!
public Action:UserMessage_SayText2(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (!(GetConVarBool(cvarEnabled) && GetConVarBool(cvarSuppress)))
	{
		return Plugin_Continue;
	}

	decl String:message[256];

	BfReadShort(bf); // team color

	BfReadString(bf, message, sizeof(message));
	// check for Name_Change, not #TF_Name_Change (compatibility?)
	if (StrContains(message, "Name_Change") != -1)
	{
		BfReadString(bf, message, sizeof(message)); // original
		
		// find the clientid of this name
		new maxplayers, client = -1;
		maxplayers = GetMaxClients();
		for (new i = 1; i <= maxplayers; i++)
		{
			if (!IsClientConnected(i) || !IsFakeClient(i))
			{
				// we don't care about disconnects and real people
				continue;
			}
			
			decl String:testname[MAX_NAME_LENGTH];
			GetClientName(i, testname, sizeof(testname));
			if (StrEqual(message, testname))
			{
				client = i;
			}
		}

		// for reference, the newname string is here
		//BfReadString(bf, message, sizeof(message)); // new
		
		// if we didn't find it to be a bot, stop trying to block it
		if (client == -1)
			return Plugin_Continue;
		
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// called *just* after a bot joins a team. set up name and announce here
// this is a WORKAROUND for TF2, but it works fine everywhere else
public Action:Timer_BotSetup(Handle:timer, any:client)
{
	// remove ourselves, first
	bot_timers[client] = INVALID_HANDLE;

	// timer was called, so we're definately enabled, and client is a bot
	// no announce, in case the first rename worked
	DoBotName(client, false);
}

// handle player team change, to supress bot messages
// and set up name change timer
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarEnabled))
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0)
	{
		// weird error, ignore
		return Plugin_Continue;
	}
	
	if (IsFakeClient(client))
	{
		// fake client == bot
		
		// change the name RIGHT NOW in case we can
		DoBotName(client, true);
		
		// set up name change timer
		// skip it if there is already a timer
		if (bot_timers[client] == INVALID_HANDLE)
		{
			bot_timers[client] = CreateTimer(BOTSETUP_WAIT, Timer_BotSetup, client);
		}
		
		// suppress if we have to
		if (GetConVarBool(cvarSuppress))
		{
			SetEventBool(event, "silent", true);
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

// handle player connect, to supress bot messages
public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!(GetConVarBool(cvarEnabled) && GetConVarBool(cvarSuppress)))
	{
		return Plugin_Continue;
	}

	decl String:networkID[32];
	GetEventString(event, "networkid", networkID, sizeof(networkID));

	if(!dontBroadcast && StrEqual(networkID, "BOT"))
	{
		// we got a bot connectin', resend event as no-broadcast
		decl String:clientName[MAX_NAME_LENGTH], String:address[32];
		GetEventString(event, "name", clientName, sizeof(clientName));
		GetEventString(event, "address", address, sizeof(address));

		new Handle:newEvent = CreateEvent("player_connect", true);
		SetEventString(newEvent, "name", clientName);
		SetEventInt(newEvent, "index", GetEventInt(event, "index"));
		SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
		SetEventString(newEvent, "networkid", networkID);
		SetEventString(newEvent, "address", address);

		FireEvent(newEvent, true);

		return Plugin_Handled;
	}

	return Plugin_Continue;
}
