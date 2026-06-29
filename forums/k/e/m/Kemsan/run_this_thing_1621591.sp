//===== [ INCLUDES ] ==============
#include <sourcemod>

#pragma semicolon 1

//===== [ CONSTANTS ] ==============
#define PLUGIN_VERSION "1.0"
#define MAX_COMMANDS 150
#define MAX_FILE_LEN 512
#define MAX_DISPLAY_LENGTH 512

//===== [ VARIABLES ] ==============
new String:g_strHours[ MAX_COMMANDS ][ 512 ];
new String:g_strCommands[ MAX_COMMANDS][ 512 ];
new g_iCommands;

new Handle:hRunThing;

//===== [ PLUGIN INFO ] ==============
public Plugin:myinfo = 
{
	name = "Run this thing",
	author = "Kemsan",
	description = "Run command on defined day/month/year/hour/minute/second",
	version = PLUGIN_VERSION,
	url = "http://kemsan.com.pl"
};

public OnPluginStart()
{	
	CreateConVar( "sm_run_thing_version", PLUGIN_VERSION, "Plugin version",  FCVAR_REPLICATED | FCVAR_NOTIFY );
	hRunThing = CreateConVar( "sm_run_thing", "1", "Enable/Disable(1/0) plugin", FCVAR_PLUGIN );
	
	StartTimer( );
}

stock StartTimer( )
{
	if( GetConVarBool( hRunThing ) )
	{
		LoadCommands();
		CreateTimer( 1.0, Timer_Functions, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
	}
}

public Action:Timer_Functions( Handle:hTimer )
{
	if( GetConVarBool( hRunThing ) )
	{
		decl String:strDate[ 512 ];
		decl String:strBuffers[ 2 ][ 512 ];
		
		for( new i = 0; i < g_iCommands; i++ )
		{
			ExplodeString( g_strHours[ i ], "|", strBuffers, sizeof( strBuffers ), sizeof( strBuffers[ ] ) );
			FormatTime( strDate, sizeof( strDate ), strBuffers[ 0 ], GetTime( ) );
			
			if( StrEqual( strDate, strBuffers[ 1 ] ) )
			{
				ReplaceString( g_strCommands[ i ], sizeof( g_strCommands ), "'", "\"", true );
				
				ServerCommand( "%s", g_strCommands[ i ] );
				PrintToServer( "Command %s executed", g_strCommands[ i ] );
			}
		}
		
	}
}

//===== [ COMMANDS ] ==============
public LoadCommands()
{
	if( GetConVarBool( hRunThing ) )
	{
		decl String:filename[ MAX_FILE_LEN ];
		BuildPath( Path_SM, filename, MAX_FILE_LEN, "configs/things_commands.txt" );
		new Handle:hFile = OpenFile( filename, "r" );
		
		if( hFile == INVALID_HANDLE )
		{
			SetFailState( "addons/sourcemod/configs/things_commands.txt not found" );
			return;
		}
		
		g_iCommands = 0;
		
		while ( !IsEndOfFile( hFile ) )
		{
			decl String:line[255];
			if ( !ReadFileLine( hFile, line, sizeof( line ) ) )
			{
				break;
			}
			
			/* Trim comments */
			new len = strlen( line );
			new bool:ignoring = false;
			for ( new i = 0; i < len; i++ )
			{
				if ( ignoring )
				{
					if ( line[ i ] == '"' )
					{
						ignoring = false;
					}
				} 
				else 
				{
					if ( line[ i ] == '"' )
					{
						ignoring = true;
					} 
					else if ( line[ i ] == ';' ) 
					{
						line[ i ] = '\0';
						break;
					} 
					else if ( line[ i ] == '/' && i != len - 1 && line[ i + 1 ] == '/')
					{
						line[ i ] = '\0';
						break;
					}
				}
			}
		
			TrimString( line );
			
			if ( ( line[ 0 ] == '/' && line[ 1 ] == '/' ) || (line[ 0 ] == ';' || line[ 0 ] == '\0' ) )
			{
				continue;
			}
			
			g_strCommands[ g_iCommands ][ 0 ] = 0;
			g_strHours[ g_iCommands ][ 0 ] = 0;
			
			new String:file_name[ MAX_DISPLAY_LENGTH ];
			new String:file_sound[ MAX_FILE_LEN ];	
			new cur_idx, idx;
			
			cur_idx = BreakString( line, file_name, sizeof( file_name ) );
			strcopy( g_strHours[ g_iCommands ], sizeof( g_strHours[ ] ), file_name );
			
			idx = cur_idx;
			cur_idx = BreakString( line[ idx ], file_sound, sizeof( file_sound ) );
			strcopy( g_strCommands[ g_iCommands ], sizeof( g_strCommands[ ] ), file_sound );
			
			g_iCommands++;
		}
	
		CloseHandle( hFile );
	}
}