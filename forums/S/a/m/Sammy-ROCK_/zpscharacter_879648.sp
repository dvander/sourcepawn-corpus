#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <sdktools>
#define ZPSMAXPLAYERS 24
#define Version "1.1"
#define CVarFlags FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
new MaxPlayers = -1;
new String:SteamID[ZPSMAXPLAYERS+1][32];
new Char[ZPSMAXPLAYERS+1] = {1, ...};
new bool:Created[ZPSMAXPLAYERS+1] = {false, ...};
new Handle:DatabaseHndl = INVALID_HANDLE;
new Handle:DatabaseCVar = INVALID_HANDLE;
new Handle:VersionCVar = INVALID_HANDLE;
new Handle:hTopMenu = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "ZPS Character",
	author = "NBK - Sammy-ROCK!",
	description = "Saves client's character and always make him be like that.",
	version = Version,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	DatabaseCVar = CreateConVar("zpscharacter_database", "storage-local", "SourceMod MySQL Database's name from \"sourcemod/configs/databases.cfg\".", FCVAR_PLUGIN);
	VersionCVar = CreateConVar("zpscharacter_version", Version, "Version of ZPS Character plugin.", CVarFlags);
	ConnectToDB();
	HookEvent("player_spawn", PlayerSpawnEvent);
	RegConsoleCmd("choosechar", PickChar, "Let's you choose the character that you'll be.");
	RegAdminCmd("sm_chars_fixdoubles", Command_FixDoubles, ADMFLAG_ROOT, "Fix doubled players at database.");
	RegAdminCmd("sm_chars_reset", Command_Reset, ADMFLAG_ROOT, "Resets a player's character.");
	RegAdminCmd("sm_chars_reset_all", Command_ResetAll, ADMFLAG_ROOT, "Recreates the entire character database.");
	RegAdminCmd("sm_chars_reset_steamid", Command_ResetSteamId, ADMFLAG_ROOT, "Resets a player's character using his Steam Id.");
	AutoExecConfig(true, "zpscharacter"); // Loads default settings
	{
		decl String:DataVersion[8];
		GetConVarString(VersionCVar, DataVersion, sizeof(DataVersion));
		if(!StrEqual(DataVersion, Version))
		{
			DeleteFile("cfg\\sourcemod\\zpscharacter.cfg")
			AutoExecConfig(true, "zpscharacter"); // Recreates plugin's config file
			AutoExecConfig(true, "zpscharacter"); // Runs updated convars' value
			LogMessage("Newer Version Detected (From \"%s\" to \"%s\"): cfg\\sourcemod\\zpscharacter.cfg was remade.", DataVersion, Version);
		}
	}
	decl Handle:topmenu;
	if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);
}

public Action:PickChar(client, args)
{
	ReplyToCommand(client, "Choose your character!");
	ShowPickCharMenu(client);
	return Plugin_Handled;
}

public ShowPickCharMenu(const client)
{
	new Handle:menu = CreateMenu(PickCharHndl);
	SetMenuTitle(menu, "Choose your character: (Current: %d)", Char[client])
	AddMenuItem(menu, "1", "Eugene   (Detective)");
	AddMenuItem(menu, "2", "Marcus   (Cop)");
	AddMenuItem(menu, "3", "Paul     (Punker)");
	AddMenuItem(menu, "4", "Jennifer (Unknown)");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public PickCharHndl(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[4];
		GetMenuItem(menu, param2, info, sizeof(info));
		Char[param1] = StringToInt(info);
		UpdateClientModel(param1);
		SavePlayer(param1);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public OnMapStart()
{
	MaxPlayers = GetMaxClients();
}

public OnClientAuthorized(client, const String:steamid[])
{
	Created[client] = false;
	Char[client] = 1;
	Format(SteamID[client], sizeof(SteamID[]), steamid);
	LoadPlayer(client);
}

public Action:PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientTeam(client) == 4 && Created[client])
	{
		ShowPickCharMenu(client);
		Created[client] = false;
	}
	UpdateClientModel(client);
}

public UpdateClientModel(const client)
{
	if(!IsClientInGame(client))
		return;
	new String:Model[256];
	new team = GetClientTeam(client);
	if(team == 2 || team == 4)
		Format(Model, sizeof(Model), "models\\survivors\\survivor%d\\survivor%d.mdl", Char[client], Char[client]);
	else if(team == 3)
	{
		if(GetClientHealth(client) == 200)
			Format(Model, sizeof(Model), "models\\zombies\\zombie%d\\zombie%d.mdl", Char[client], Char[client]);
		else if(GetClientHealth(client) == 250)
			Format(Model, sizeof(Model), "models\\zombies\\zombie0\\zombie0.mdl");
		else
			return;
	}
	else
		return;
	if(!FileExists(Model, true))
		return;
	if(!IsModelPrecached(Model))
		PrecacheModel(Model);
	SetEntityModel(client, Model);
}

public ConnectToDB()
{
	decl String:Database[128];
	GetConVarString(DatabaseCVar, Database, sizeof(Database));
	SQL_TConnect(OnDatabaseConnect, Database);
}

public OnDatabaseConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Database failure: %s", error);
	} else {
		DatabaseHndl = hndl;
		SQL_LockDatabase(DatabaseHndl);
		if(!SQL_FastQuery(DatabaseHndl, "CREATE TABLE IF NOT EXISTS zpscharacters(steam_id varchar(32) NOT NULL, char int(1) NOT NULL default 1, PRIMARY KEY (steam_id ASC));"))
		{
			LogError("[ZPSCharacter] Could not create players table.");
			return;
		}
		SQL_UnlockDatabase(DatabaseHndl);
		UpdateSQL();
	}
}

public UpdateSQL()
{
	for(new player=1; player<=MaxPlayers; player++)
	{
		if(IsClientInGame(player)) 
		{
			GetClientAuthString(player, SteamID[player], sizeof(SteamID[]));
			LoadPlayer(player);
		}
	}
}

public SavePlayer(const client)
{
	if(Char[client] < 1)
		Char[client] = 1;
	else if(Char[client] > 4)
		Char[client] = 4;
	decl String:query[128];
	Format(query, sizeof(query), "UPDATE zpscharacters SET char = %d WHERE steam_id = '%s';", Char[client], SteamID[client]);
	SQL_TQuery(DatabaseHndl, T_NoActions, query);
}

public CreatePlayer(const client)
{
	decl String:query[128];
	Format(query, sizeof(query), "INSERT INTO zpscharacters (steam_id) VALUES ('%s');", SteamID[client]);
	SQL_TQuery(DatabaseHndl, T_NoActions, query);
	Created[client] = true;
}

public T_NoActions(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
		LogError("Query failed! %s", error);
}

public LoadPlayer(const client)
{
	decl String:query[128];
	Format(query, sizeof(query), "SELECT char FROM zpscharacters WHERE steam_id = '%s';", SteamID[client]);
	SQL_TQuery(DatabaseHndl, T_LoadPlayer, query, client);
}

public T_LoadPlayer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = data;
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		return;
	}
	else if(SQL_FetchRow(hndl))
		Char[client]	= SQL_FetchInt(hndl, 0);
	else
		CreatePlayer(client);
	UpdateClientModel(client);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	hTopMenu = topmenu;
	
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu,
			"sm_chars_reset",
			TopMenuObject_Item,
			AdminMenu_Reset,
			player_commands,
			"sm_chars_reset",
			ADMFLAG_ROOT);

		AddToTopMenu(hTopMenu,
			"sm_chars_reset_all",
			TopMenuObject_Item,
			AdminMenu_ResetAll,
			server_commands,
			"sm_chars_reset_all",
			ADMFLAG_ROOT);
	}
}

public AdminMenu_Reset(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Resets Player Character", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		new client = param;
		Char[client] = 1;
		SavePlayer(client);
		UpdateClientModel(client);
	}
}

public AdminMenu_ResetAll(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Delete Everyone's Characters", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		SQL_TQuery(DatabaseHndl, T_NoActions, "DROP TABLE IF EXISTS zpscharacters; CREATE TABLE IF NOT EXISTS zpscharacters(steam_id varchar(32) NOT NULL, char int(1) NOT NULL default 1, PRIMARY KEY (steam_id ASC));");
	}
}

public Action:Command_FixDoubles(client, args)
{
	SQL_TQuery(DatabaseHndl, T_NoActions, "CREATE TABLE IF NOT EXISTS zpscharacters_fixed(steam_id varchar(32) NOT NULL, char int(1) NOT NULL default 1, PRIMARY KEY (steam_id ASC));INSERT INTO zpscharacters_fixed SELECT DISTINCT * FROM zpscharacters;DROP TABLE IF EXISTS zpscharacters;RENAME TABLE zpscharacters_fixed TO zpscharacters;");
	ReplyToCommand(client, "Doubled rows fixed.");
	return Plugin_Handled;
}

public Action:Command_Reset(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_reset <target>");
		return Plugin_Handled;
	}
	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new target = target_list[i];
		Char[target] = 1;
		SavePlayer(target);
		ReplyToCommand(client, "%N's character have been resetted.", target);
	}
	return Plugin_Handled;
}

public Action:Command_ResetAll(client, args)
{
	SQL_TQuery(DatabaseHndl, T_NoActions, "DROP TABLE IF EXISTS zpscharacters; CREATE TABLE IF NOT EXISTS zpscharacters(steam_id varchar(32) NOT NULL, char int(1) NOT NULL default 1, PRIMARY KEY (steam_id ASC));");
	ReplyToCommand(client, "Rankings Database reseted.");
	return Plugin_Handled;
}

public Action:Command_ResetSteamId(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_reset_steamid \"<steam id>\"");
		return Plugin_Continue;
	}
	decl String:SteamId[32], String:query[128];
	GetCmdArg(1, SteamId, sizeof(SteamId));
	Format(query, sizeof(query), "UPDATE zpscharacters SET char = 1 WHERE steam_id = '%s';", SteamId);
	SQL_TQuery(DatabaseHndl, T_NoActions, query);
	ReplyToCommand(client, "\"%s\"'s ranking has been reseted.", SteamId);
	return Plugin_Handled;
}