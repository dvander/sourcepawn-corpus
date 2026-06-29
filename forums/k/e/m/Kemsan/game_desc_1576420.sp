#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_NAME "Game Description Override"
#define PLUGIN_AUTHOR "Orginal psychonic Quickfix by Kemsan"
#define PLUGIN_DESC "Allows changing of displayed game type in server browser"
#define PLUGIN_VERSION "1.2.5"
#define PLUGIN_URL "http://www.nicholashastings.com"

new Handle:g_hCvarGameDesc = INVALID_HANDLE;

public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	CreateConVar( "gamedesc_override_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_DONTRECORD | FCVAR_SPONLY | FCVAR_NOTIFY );
	
	g_hCvarGameDesc = CreateConVar( "gamedesc_override", "", "Game Description Override (set blank \"\" for default no override)", FCVAR_PLUGIN );
}

public OnAllPluginsLoaded()
{
	if ( GetExtensionFileStatus("sdkhooks.ext") != 1 )
	{
		SDKHooksFail( );
	}
}

public OnLibraryRemoved( const String:strName[] ) 
{
	if ( strcmp( strName, "sdkhooks.ext" ) == 0 )
	{
		SDKHooksFail( );
	}
}

SDKHooksFail( )
{
	SetFailState( "SDKHooks is required for Game Description Override" );
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	decl String:g_strGameDesc[ 64 ] = "";
	GetConVarString( g_hCvarGameDesc, g_strGameDesc, sizeof( g_strGameDesc ) );
	
	Format( gameDesc, sizeof( gameDesc ), "%s", g_strGameDesc );
	return Plugin_Changed;
}
	