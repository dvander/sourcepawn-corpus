	
	#pragma semicolon 1
	#include <sourcemod>
	
	#define PLUGIN_VERSION		"0.2.1b"
	
	#define MAX_AUTHID_LENGTH	20
	#define MAX_TEXT_LENGTH	191
	
	new String:g_szSteamID[MAXPLAYERS+1][MAX_AUTHID_LENGTH];
	new String:g_szName[MAXPLAYERS+1][MAX_NAME_LENGTH];
	
	public Plugin:myinfo =
	{
		name = "Say SteamID",
		author = "fezh",
		description = "This plugin provides your steam id to everyone when you write something in chat",
		version = PLUGIN_VERSION,
		url = "http://forums.alliedmods.net/"
	}
	
	public OnPluginStart()
	{
		RegConsoleCmd("say", HookSayCommand);
		RegConsoleCmd("say_team", HookSayTeamCommand);

		CreateConVar("say_steamid_version", PLUGIN_VERSION, "Say SteamID version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	}
	
	public OnClientAuthorized(Client, const String:szAuth[])
	{
		GetClientAuthString(Client, g_szSteamID[Client], MAX_AUTHID_LENGTH-1);
	}
	
	public OnClientPutInServer(Client)
	{
		GetClientName(Client, g_szName[Client], MAX_NAME_LENGTH-1);
	}
	
	public OnClientSettingsChanged(Client)
	{
		GetClientName(Client, g_szName[Client], MAX_NAME_LENGTH-1);
	}
	
	public Action:HookSayCommand(Client, Args)
	{
		new String:szText[MAX_TEXT_LENGTH];
		GetCmdArgString(szText, MAX_TEXT_LENGTH-1);
		StripQuotes(szText);
		Format(szText, MAX_TEXT_LENGTH-1, "\x01%s \x03%s \x04(%s)\x01: %s", IsPlayerAlive(Client) ? "" : "*DEAD*", g_szName[Client], g_szSteamID[Client], szText);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			PrintToChatColor(i, Client, szText);
			break;
		}
		return Plugin_Handled;
	}
	
	public Action:HookSayTeamCommand(Client, Args)
	{
		new String:szText[MAX_TEXT_LENGTH];
		GetCmdArgString(szText, MAX_TEXT_LENGTH-1);
		StripQuotes(szText);
		Format(szText, MAX_TEXT_LENGTH-1, "\x01%s (TEAM) \x03%s \x04(%s)\x01: %s", IsPlayerAlive(Client) ? "" : "*DEAD*", g_szName[Client], g_szSteamID[Client], szText);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (GetClientTeam(Client) == GetClientTeam(i))
			{
				PrintToChatColor(i, Client, szText);
				break;
			}
		}
		return Plugin_Handled;
	}
	
	stock PrintToChatColor(client_index, author_index, const String:message[])
	{ 
		new Handle:buffer = StartMessageOne("SayText2", client_index);
		if (buffer != INVALID_HANDLE)
		{ 
			BfWriteByte(buffer, author_index); 
			BfWriteByte(buffer, true); 
			BfWriteString(buffer, message); 
			EndMessage(); 
		} 
	}
	