#include <sourcemod>

new Handle:DB = INVALID_HANDLE;

public OnPluginStart()
{
	//Setup say command hooks
	RegConsoleCmd("say", Command_ChatHook_Say);
	RegConsoleCmd("say_team", Command_ChatHook_Say);

	
}




public StartDB()
{
	new String:Error[70];
	new String:query[300];
	
	DB = SQL_Connect("MMR", true, Error, sizeof(Error));
	
	if(DB == INVALID_HANDLE)
	{
		PrintToServer("MySQL Error - %s", Error);
		CloseHandle(DB);
	}
	else
	{
		
		new Handle:queryC = SQL_Query(DB, query);
		
		if(queryC == INVALID_HANDLE)
		{
			SQL_GetError(DB, Error, sizeof(Error));
			PrintToServer("MySQL Error - %s", Error);
		}
	}
}

public OnClientConnected(client)
{
	new String:Error[70];
	new String:steamid[32];
	new String:query[300];
	
	
	GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
	}

public Action:Command_ChatHook_Say(client, args)
{
	//Vars
	new String:steamid[32];
	new String:Error[70];
	new String:query[300];
	decl String:text[200];
	decl String:message[200];
	
	//Read the args into text
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
	    //No chat message, Ignore
		return Plugin_Continue;
	}

	//Get the chat message in ""
	BreakString(text,message,sizeof(message));
	
	//Check for the !rank
	if (strcmp(message, "!rank", false) == 0)
	{
		decl String:steamID[100];
		GetClientAuthString(client, steamID, sizeof(steamID));
		Format(query, sizeof(query), "SELECT score = '%a' FROM ranking WHERE steamid = '%s'))", steamid);
	
		PrintToChat(client, %s);
		return Plugin_Handled;
	}
	
	//Was not a reset rank message, continue
	return Plugin_Continue;
}