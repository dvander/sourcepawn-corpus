#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
new Handle:db = INVALID_HANDLE;
new Handle:ImmuneType = INVALID_HANDLE;
new Handle:ImmuneFlag = INVALID_HANDLE;
new Handle:ImmuneGroup = INVALID_HANDLE;
new Handle:IgnoreBots = INVALID_HANDLE;
new AdminFlag:Immune_Flag;
new String:steamid[255];
new Immune[MAXPLAYERS+1] = 0;
new const String:MESS[] = "\x04[SteamID Restrict] \x01";

// Plugin Info
public Plugin:myinfo = 
{
	name = "SteamID Restrict",
	author = "johan123jo",
	description = "Kicks steamids not in a MySql database (sort of whitelist).",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("sm_steamid_restrict_version", 			PLUGIN_VERSION, "SteamID Restrict Version (unchangeable).", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ImmuneType 	= CreateConVar("sm_steamid_restrict_type", 	"0", 			"Should groups or admins with a flag be immune to being kicked (0 = disabled, 1 = Group and 2 = flag).");
	ImmuneGroup = CreateConVar("sm_steamid_restrict_group", "", 			"What is the group name of the admins that should be immune (sm_steamid_restrict_type needs to be 1 for this).");
	ImmuneFlag	= CreateConVar("sm_steamid_restrict_flag",	"root", 		"What flag should a admin need to be immune to being kicked, look in admin_levels.cfg for flags (sm_steamid_restrict_type needs to be 2 for this).");
	IgnoreBots	= CreateConVar("sm_steamid_restrict_bots",	"1", 			"Should bots be allowed to join the server (0 = no, 1 = yes).");
	AutoExecConfig(true, "sm_steamid_restrict");
	
	RegAdminCmd("sm_steamid_restrict_add", 		Command_Add, 	ADMFLAG_ROOT, 		"Add a steamid to the database.");
	RegAdminCmd("sm_steamid_restrict_delete", 	Command_Delete, ADMFLAG_ROOT, 		"Deletes a steamid from the database.");
	RegAdminCmd("sm_steamid_restrict_list", 	Command_List, 	ADMFLAG_GENERIC, 	"List all SteamIDs in the database.");
	
	decl String:error[256];
	db = SQL_Connect("restrict", false, error, sizeof(error));
	
	if(db == INVALID_HANDLE)
	{
		PrintToServer("[SteamID Restrict] Unable to connect to database (%s)", error);
		LogError("[SteamID Restrict] Unable to connect to database (%s)", error);
		return;
	}
	else
		PrintToServer("[SteamID Restrict] Successfully connected to database!");
}

// When a client connects it will check what ImmuneType is, if it's 1 it will check if the user is in the group.
// It it's 2 it will check if the player has the flag. The user has one of these things, Immune will be set to 1.
// If Immune still is 0 it will check if the user still is in the database, if not. The player will get kicked.
public OnClientPostAdminCheck(client)
{
	new bots = GetConVarInt(IgnoreBots);
	new type = GetConVarInt(ImmuneType);
	
	if(bots != 1)
	{
		if(IsFakeClient(client))
			ServerCommand("bot_kick");
		
		return;
	}
	else if(bots == 1 && IsFakeClient(client))
		return;
	
	if(type == 1)
	{
		new AdminId:admin = GetUserAdmin(client);
		
		if (admin != INVALID_ADMIN_ID)
		{
			new count = GetAdminGroupCount(admin);

			for (new i = 0; i < count; i++)
			{
				decl String:buffer[64], String:group_immune[64];
				GetAdminGroup(admin, i, buffer, sizeof(buffer));
				GetConVarString(ImmuneGroup, group_immune, sizeof(group_immune));
				
				if(StrEqual(buffer, group_immune, false))
					Immune[client] = 1;
			}
		}
	}
	else if(type == 2)
	{
		decl String:flag_immune[16];
		GetConVarString(ImmuneFlag, flag_immune, sizeof(flag_immune));
		
		FindFlagByName(flag_immune, Immune_Flag);
		
		if(GetAdminFlag(GetUserAdmin(client), Immune_Flag))
			Immune[client] = 1;
	}

	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	if(Immune[client] == 0)
		CheckSteamID(client, auth);
}

// Send a check query to the database to see if the user is in the database.
CheckSteamID(userid, const String:auth[])
{
	decl String:query[255];
	Format(query, sizeof(query), "SELECT steamid FROM steamid_restrict WHERE steamid = '%s'", auth);
	SQL_TQuery(db, SQL_CheckSteamID, query, userid);
}

// Checks if the SteamID is in the database, if not the player will get kicked.
public SQL_CheckSteamID(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!IsClientConnected(client))
	{
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		LogError("[SteamID Restrict] Query failed! %s", error);
		KickClient(client, "Authorization failed, please try again later.");
	}
	else if (!SQL_GetRowCount(hndl))
	{
		KickClient(client, "You are not allowed to join this server");
	}
}

// Command to list all the SteamIDs in the database, and other stuff the command needs for it to work.
public Action:Command_List(client, args)
{
	decl String:query[255];
	Format(query, sizeof(query), "SELECT * FROM steamid_restrict");
	SQL_TQuery(db, SQL_ListSteamids, query, client);
	
	return Plugin_Handled;
}

// Used by Command_List to query database for info.
public SQL_ListSteamids(Handle:owner, Handle:hndl, const String:error[], any:client)
{

	if (hndl == INVALID_HANDLE)
	{
		LogError("[SteamID Restrict] Query failed! %s", error);
		PrintToChat(client, "%sQuery failed, please try again later.", MESS);
	}
	else
	{
		new String:steamid_f[255];
		PrintToConsole(client, "SteamIDs in database:");
		
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, steamid_f, sizeof(steamid_f));
			PrintToConsole(client, "%s", steamid_f);
		}
	}
}

// Command to add a steamID to the database, and other stuff it needs to work.
public Action:Command_Add(client, args)
{
	if(args < 5)
	{
		ReplyToCommand(client, "Usage: sm_steamid_restrict_add <steamid>");
		return Plugin_Handled;
	}
	
	new String:part3[2], String:part5[30], String:fsteam[255];
	GetCmdArg(3, part3, sizeof(part3));
	GetCmdArg(5, part5, sizeof(part5));
	
	Format(fsteam, sizeof(fsteam), "STEAM_0:%s:%s", part3, part5);
	
	AddSteamid(client, fsteam);
	
	return Plugin_Handled;
}

// Command_Add uses this to send a check query to see if the SteamID is already in the database.
AddSteamid(client, const String:auth[255])
{
	steamid = auth;
	decl String:query[255];
	Format(query, sizeof(query), "SELECT steamid FROM steamid_restrict WHERE steamid = '%s'", auth);
	SQL_TQuery(db, SQL_AddSteamid_Check, query, client);
}

// Checks if the SteamID it has is already in the database.
public SQL_AddSteamid_Check(Handle:owner, Handle:hndl, const String:error[], any:client)
{

	if (hndl == INVALID_HANDLE)
	{
		LogError("[SteamID Restrict] Query failed! %s", error);
		PrintToChat(client, "%sQuery failed, please try again later.", MESS);
	}
	else if (!SQL_GetRowCount(hndl))
	{
		decl String:query[255];
		Format(query, sizeof(query), "INSERT INTO steamid_restrict (steamid) VALUES ('%s')", steamid);
		SQL_TQuery(db, SQL_AddSteamid_Add, query, client);
	}
	else
		PrintToChat(client, "%sThe SteamID is already in the database.", MESS);
}

// If SQL_AddSteamid_Check did not find a SteamID in the database it will add it to the database.
public SQL_AddSteamid_Add(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[SteamID Restrict] Query failed! %s", error);
		PrintToChat(client, "%sQuery failed, please try again later.", MESS);
	}
	else
		PrintToChat(client, "%sThe SteamID has been added to the database.", MESS);
}

// Command to delete a steamID from the database.
public Action:Command_Delete(client, args)
{
	if(args < 5)
	{
		ReplyToCommand(client, "Usage: sm_steamid_restrict_delete <steamid>");
		return Plugin_Handled;
	}
	
	new String:part3[2], String:part5[30], String:fsteam[255];
	GetCmdArg(3, part3, sizeof(part3));
	GetCmdArg(5, part5, sizeof(part5));
	
	Format(fsteam, sizeof(fsteam), "STEAM_0:%s:%s", part3, part5);
	
	DeleteSteamid(client, fsteam);
	
	return Plugin_Handled;
}

// Querys the database and checks if the SteamID entered exists.
DeleteSteamid(client, const String:auth[255])
{
	steamid = auth;
	decl String:query[255];
	Format(query, sizeof(query), "SELECT steamid FROM steamid_restrict WHERE steamid = '%s'", auth);
	SQL_TQuery(db, SQL_DeleteSteamid_Check, query, client);
}

// Querys the database to see if a SteamID exists, if it exists in the database it will delete the SteamID from the database.
public SQL_DeleteSteamid_Check(Handle:owner, Handle:hndl, const String:error[], any:client)
{

	if (hndl == INVALID_HANDLE)
	{
		LogError("[SteamID Restrict] Query failed! %s", error);
		PrintToChat(client, "%sQuery failed, please try again later.", MESS);
	}
	else if (SQL_GetRowCount(hndl))
	{
		decl String:query[255];
		Format(query, sizeof(query), "DELETE FROM steamid_restrict WHERE steamid = '%s'", steamid);
		SQL_TQuery(db, SQL_DeleteSteamid_Delete, query, client);
	}
	else
		PrintToChat(client, "%sThe SteamID is not in the database.", MESS);
}

// Deletes the SteamID from the database, and kicks the client if on the server, and the player is not in a immune group or have a immune flag.
public SQL_DeleteSteamid_Delete(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[SteamID Restrict] Query failed! %s", error);
		PrintToChat(client, "%sQuery failed, please try again later.", MESS);
	}
	else
	{
		decl String:auth[255];
	
		for(new x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x))
			{
				GetClientAuthString(x, auth, sizeof(auth));
				
				if(StrEqual(auth, steamid))
				{
					if(Immune[x] != 1)
						KickClient(x, "You are not allowed to be on this server");
					else
						PrintToChat(client, "%sThe user is also immune because of a group or because he has a immune flag", MESS);
				}
			}
		}
		
		PrintToChat(client, "%sThe SteamID has been deleted from the database.", MESS);
		
	}
}