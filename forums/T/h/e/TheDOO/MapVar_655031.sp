/**
 * =======================================
 * MapVar
 * Map-based convar/plugin configuration
 *
 * Author: ChOmP[C7]
 * =======================================
 *
 * Based on MistaGee's Map CFG plugin for AMXX
 *
 *
 * Credits: MistaGee
 */
 
#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "MapVar",
	author = "ChOmP[C7]",
	description = "Map-based convar/plugin configuration",
	version = PLUGIN_VERSION,
	url = "www.coz-world.com"
};

//Global variables
new Handle:g_hMapFileCvar;
new String:g_sCurrentMap[128];

public OnPluginStart()
{
	CreateConVar( "sm_mapvar_version", PLUGIN_VERSION, "Version # for MapVar", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	
	g_hMapFileCvar = CreateConVar( "sm_mapvar_file", "mapvar.cfg", "File that contains the map-based configurations" );
	
}

public OnMapStart()
{
	//Get the current map name
	GetCurrentMap( g_sCurrentMap, sizeof( g_sCurrentMap ) );
}

public OnAutoConfigsBuffered()
{
	LogMessage( "Loading map configuration...." );
	ParseMapConfig();
}

ParseMapConfig()
{
	decl String:sPath[256], String:sFile[256];
	
	//Get name of map config file from cvar
	GetConVarString( g_hMapFileCvar, sFile, sizeof( sFile ) );
	
	//Build path to the map config file, check if it exists
	BuildPath( Path_SM, sPath, sizeof( sPath ), "configs/%s", sFile );
	if( !FileExists( sPath ) )
	{
		LogError( "%s not found", sPath );
	}
	
	//Open map config file, check if it opened
	new Handle:hMapFile = OpenFile( sPath, "rt" );
	if( hMapFile == INVALID_HANDLE )
	{
		LogError( "Could not open file: %s", sPath );
	}
	
	//Begin parsing the file
	while( !IsEndOfFile( hMapFile ) )
	{
		decl String:sLine[256], String:sMapName[256], intWildcard;
		
		ReadFileLine( hMapFile, sLine, sizeof( sLine ) );
		
		//Get length of string
		new intTxtlen = strlen( sLine );
		
		if( ( sLine[0] != '/' ) && ( sLine[1] != '/' ) && ( sLine[0] != '\0' ) && ( intTxtlen > 1 ) )
		{
			TrimString( sLine );
			
			//Map name
			if( sLine[0] == '[' )
			{
				//Check for closed map name
				new endChar = FindCharInString( sLine, ']' );
				if( endChar != -1 )
				{
					sLine[endChar] = '\0';
						
					intWildcard = 0;
					
					strcopy( sMapName, sizeof( sMapName ), sLine[1] );
				}
				
				//Map name is open then..
				else
				{
					intWildcard = 1;
					
					strcopy( sMapName, sizeof( sMapName ), sLine[1] );
				}
			}
			
			//Command
			else
			{
				//Closed map command
				if( ( intWildcard == 0 ) && ( StrEqual( g_sCurrentMap, sMapName, false ) ) )
				{
					ServerCommand( sLine );
				}
				
				
				//Open map command
				if( ( intWildcard == 1 ) && ( StrContains( g_sCurrentMap, sMapName, false ) != -1 ) )
				{
					ServerCommand( sLine );
				}
				
			}
		}
	}
	
	//Close map file handle
	CloseHandle( hMapFile );
	hMapFile = INVALID_HANDLE;
}
		