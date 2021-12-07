#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0vL4D"

#include <sdktools>

#include <filesmanagementinterface>

new Handle:g_hEnable;
new bool:g_bCanPlaySounds;
new Handle:g_hSoundFolder;
new String:g_szSoundFolderPath[ 256 ];

public Plugin:myinfo =
{
	name = "Random Join Sound",
	author = "RedSword / Bob Le Ponge",
	description = "Play a random sound to clients that connect",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	//CVARs
	CreateConVar("randomjoinsoundversion", PLUGIN_VERSION, "Random Join Sound version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT);
	
	g_hEnable = CreateConVar("sm_join_sound_enable", "1.0", "If the join sound plugin is enabled. 1=Yes", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hSoundFolder = CreateConVar("sm_join_sound", "sound/joinsounds", "The sound folder where to take a sound to play", FCVAR_PLUGIN);
	
	if ( !LibraryExists( "filesmanagement.core" ) )
	{
		SetFailState( "Could not find Files Management Interface" );
	}
}

public OnConfigsExecuted()
{
	if ( !GetConVarBool( g_hEnable ) )
		return;
	
	GetConVarString( g_hSoundFolder, g_szSoundFolderPath, sizeof(g_szSoundFolderPath) );
	
	new nbPrecached = FMI_PrecacheSoundsFolder( g_szSoundFolderPath );
	
	PrintToServer("[Random Join Sound] Precached a total of %d sounds", nbPrecached);
	
	g_bCanPlaySounds = false;
	
	if ( nbPrecached > 0 )
	{
		strcopy( g_szSoundFolderPath, sizeof(g_szSoundFolderPath), g_szSoundFolderPath[ 6 ] ); //remove 'sound/'
		g_bCanPlaySounds = true;
	}
}

public OnClientPutInServer(client)
{
	if ( !g_bCanPlaySounds )
		return;
	
	decl String:szBuffer[ 256 ];
	
	FMI_GetRandomSound( g_szSoundFolderPath, szBuffer, sizeof(szBuffer) );
	
	ClientCommand( client, "play %s", szBuffer );
}