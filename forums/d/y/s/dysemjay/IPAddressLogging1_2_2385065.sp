#include <sourcemod>

/* For format: xxx.xxx.xxx.xxx:xxxxx\0 */
#define IP_ADDRESS_STRL 22
#define STEAM_AUTH_STRL 34

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "IP Address Logging",
	author = "emjay",
	description = "Log client IP Address during connection, and create the \"cinfo\" command.",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?p=2385065"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	/* Register Cinfo command. */
	RegAdminCmd("cinfo", Command_Cinfo, ADMFLAG_BAN, "cinfo <#userid|name>");
}

/* Action for Cinfo command. */
public Action Command_Cinfo(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: cinfo <#userid|name>");
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArgString( arg, sizeof(arg) );
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	target_count = ProcessTargetString(arg, 
									   client, 
									   target_list, 
									   MAXPLAYERS, 
									   COMMAND_FILTER_CONNECTED,
									   target_name,
									   sizeof(target_name),
									   tn_is_ml);

	if(target_count <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	char name[MAX_NAME_LENGTH], address[IP_ADDRESS_STRL], steamid[STEAM_AUTH_STRL];
	
	for (int i = 0; i < target_count; i++)
	{
		GetClientName( target_list[i], name, sizeof(name) );
		GetClientIP(target_list[i], address, sizeof(address), false);
		
		if( GetClientAuthId( target_list[i], AuthId_Steam2, steamid, sizeof(steamid) ) )
		{
			ReplyToCommand(client, 
						   "Client ID: %d Name: %s IP Address: %s Steam ID: %s", 
						   target_list[i], 
						   name, 
						   address, 
						   steamid);
		}
		else
		{
			ReplyToCommand(client, 
						   "Client ID: %d Name: %s IP Address: %s Steam ID: STEAM_ID_PENDING",
						   target_list[i],
						   name,
						   address);
		}
	}
	
	return Plugin_Handled;
}


/* Callback to log successful connection. */
public void OnClientConnected(int client)
{
	/* Do not log connections from the server, or from fake clients. */
	if(client < 1 || IsFakeClient(client))
	{
		return;
	}

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	char address[IP_ADDRESS_STRL];
	GetClientIP(client, address, sizeof(address), false);
	
	/**
	 * There can be situations where the steamid is already known OnClientConnected,
	 * if the steamid can be successfully determined, then include it in the log entry.
	 */
	char steamid[STEAM_AUTH_STRL];
	if( GetClientAuthId( client, AuthId_Steam2, steamid, sizeof(steamid) ) )
	{
		LogToGame("\"%s<%d><%s><>\" connected, address \"%s\"", name, GetClientUserId(client), steamid, address);
	}
	else
	{
		LogToGame("\"%s<%d><STEAM_ID_PENDING><>\" connected, address \"%s\"", name, GetClientUserId(client), address);
	}
}