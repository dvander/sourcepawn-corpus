#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1.1"

public Plugin myinfo =
{
	name = "Status GREP - Partial SteamID Search",
	author = "RedSword",
	description = "Allow to search for partial steamIDs and easily get someone's ID.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//defines for color code
#define COLOR_NORMAL	"\x01"
#define COLOR_USERID	"\x04"
#define COLOR_CLIENT	"\x05"
#define COLOR_STEAMID	"\x03"

//Cvars
Handle g_enabled;

#define MAX_CLIENT_CHECK	3

public void OnPluginStart()
{
	//CVARs
	CreateConVar( "statusgrepversion", PLUGIN_VERSION, "Partial SteamID Search's version", 
		FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_enabled = CreateConVar( "sgrep", "1", "Is the plugin enabled ? 0 = no, 1 = yes. Def. 1", 
		FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	
	//Commands
	RegAdminCmd( "sm_findname", Cmd_GetInfoFromPlayerName, ADMFLAG_BAN, "sm_findname" );
	RegAdminCmd( "sm_steamid", Cmd_GetInfoFromSteamID, ADMFLAG_BAN, "sm_steamid" );
	RegAdminCmd( "sm_sgrep", Cmd_StatusGrep, ADMFLAG_BAN, "sm_sgrep" );
	
	//Translation file
	LoadTranslations( "statusgrep.phrases" );
}

//===== Admin CMD

public Action Cmd_GetInfoFromPlayerName(int iClient, int args)
{
	if ( GetConVarInt( g_enabled ) == 1 )
	{
		char szBuffer[ MAX_NAME_LENGTH ];
		
		if (args != 1)
		{
			ReplyToCommand( iClient, "\x04[SM] \x01Usage: <sm_findname|say !findname> <partial name>" );
		}
		else
		{
			GetCmdArg( 1, szBuffer, sizeof(szBuffer) );
			
			dealWithClients( iClient, szBuffer, true, false );
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Cmd_GetInfoFromSteamID(int client, int args)
{
	if ( GetConVarInt( g_enabled ) == 1 )
	{
		char szBuffer[ MAX_NAME_LENGTH ];
		
		if (args != 1)
		{
			ReplyToCommand( client, "\x04[SM] \x01Usage: <sm_steamid|say !steamid> <partial steamID>" );
		}
		else
		{
			GetCmdArg( 1, szBuffer, sizeof(szBuffer) );
			
			dealWithClients( client, szBuffer, false, true );
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Cmd_StatusGrep(int client, int args)
{
	if ( GetConVarInt( g_enabled ) == 1 )
	{
		char szBuffer[ MAX_NAME_LENGTH ];
		
		if (args != 1)
		{
			ReplyToCommand( client, "\x04[SM] \x01Usage: <sm_sgrep|say !sgrep> <string>" );
		}
		else
		{
			GetCmdArg( 1, szBuffer, sizeof(szBuffer) );
			
			dealWithClients( client, szBuffer, true, true );
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

//===== Privates

//We have the string we will be looking for; now lets loop throught clients
void dealWithClients( int avoidedClient, char[] soughtStr, bool checkName, bool checkSteamID )
{
	int clients[ MAX_CLIENT_CHECK ]; //Get a max of 3 clients
	int numberClients;
	
	char szBuffer[ MAX_NAME_LENGTH ];
	
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame( i ) && i != avoidedClient )
		{
			if ( checkSteamID )
			{
				GetClientAuthId( i, AuthId_Engine, szBuffer, sizeof(szBuffer) );
			
				if ( StrContains( szBuffer, soughtStr ) >= 0 )
				{
					if ( numberClients < MAX_CLIENT_CHECK )
					{
						clients[ numberClients ] = i;
					}
					numberClients++;
					continue;
				}
			}
			
			if ( checkName )
			{
				GetClientName( i, szBuffer, sizeof(szBuffer) );
				
				if ( StrContains( szBuffer, soughtStr ) >= 0 )
				{
					if ( numberClients < MAX_CLIENT_CHECK )
					{
						clients[ numberClients ] = i;
					}
					numberClients++;
					//continue;
				}
			}
		}
	}
	
	verboseToAdmin( avoidedClient, clients, numberClients );
}

//Doing another fct to look clearner
//We have all the clients sought; reply to the client after having build the string
void verboseToAdmin( int iClient, int[] clients, int numberClients )
{
	if ( numberClients == 0 )
	{
		ReplyToCommand( iClient, "\x04[SM] \x01%t", "No client" );
		return;
	}
	
	char szVerboseBuffer[ 256 ];
	
	if ( numberClients > MAX_CLIENT_CHECK )
		FormatEx( szVerboseBuffer, sizeof(szVerboseBuffer), "\x04[SM] \x01%t", "Many clients", "\x04", numberClients, COLOR_NORMAL );
	else
		FormatEx( szVerboseBuffer, sizeof(szVerboseBuffer), "\x04[SM] \x01%t", "Few clients" );
	
	char szMiniBuffer[ MAX_NAME_LENGTH ];
	
	for ( int i; i < MAX_CLIENT_CHECK && i < numberClients; ++i )
	{
		IntToString( GetClientUserId( clients[ i ] ), szMiniBuffer, sizeof(szMiniBuffer) );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), "#" );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), COLOR_USERID );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), szMiniBuffer );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), COLOR_NORMAL );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), " " );
		
		GetClientName( clients[ i ], szMiniBuffer, sizeof(szMiniBuffer) );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), "\"" );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), COLOR_CLIENT );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), szMiniBuffer );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), COLOR_NORMAL );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), "\" " );
		
		GetClientAuthId( clients[ i ], AuthId_Engine, szMiniBuffer, sizeof(szMiniBuffer) );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), "[" );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), COLOR_STEAMID );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), szMiniBuffer );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), COLOR_NORMAL );
		StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), "]" );
		
		if ( i != MAX_CLIENT_CHECK - 1 && i != numberClients - 1 )
			StrCat( szVerboseBuffer, sizeof(szVerboseBuffer), ", " );
	}
	
	ReplyToCommand( iClient, "%s.", szVerboseBuffer );
}