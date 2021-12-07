
#pragma semicolon 1
#include <sourcemod>

#define MAX_TEXT_LENGTH		33
#define PLUGIN_VERSION		"0.1.0"

public Plugin:myinfo = 
{
	name = "Admin Slash",
	author = "DruX",
	description = "Allows executing admin commands through chat.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
}

public OnPluginStart( )
{
	RegConsoleCmd( "say", HookSayCommand );
	RegConsoleCmd( "say_team", HookSayCommand );
	CreateConVar( "sm_admin_slash", PLUGIN_VERSION, "SM Admin Slash Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
}

public Action:HookSayCommand( iClient, iArgs )
{
	if ( GetUserAdmin( iClient ) )
	{
		decl String:szText[ MAX_TEXT_LENGTH ];
		GetCmdArgString( szText, sizeof( szText ) - 1 );
		
		if ( szText[ 0 ] == '/' || szText[ 0 ] == '!' )
		{
			decl String:szCharacters[ ] = { "/", "!" };
			
			for ( new i = 0; i < sizeof( szCharacters ); i++ )
			{
				ReplaceString( szText, sizeof( szText ) - 1, szCharacters[ i ], "" );
			}
			
			ClientCommand( iClient, "sm_%s", szText );
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
