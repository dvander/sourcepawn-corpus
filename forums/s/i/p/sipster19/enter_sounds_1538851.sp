#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5"
#define MAX_FILE_LEN 150
#define MAX_SOUNDS 50
#define MAX_DISPLAY_LENGTH 150

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Enter server sound",
	author = "Kemsan, Troy",
	description = "Play sounds after player connect server",
	version = PLUGIN_VERSION,
	url = "http://kemsan.pl"
};

new String:g_displayNames[ MAX_SOUNDS][ MAX_FILE_LEN ];
new String:g_soundNames[ MAX_SOUNDS ][ MAX_DISPLAY_LENGTH ];
new g_numSounds;

new Handle:hEnterSound;
new Handle:hEnterSoundNotify;
new Handle:hEnterSoundNotifyMsg;
new Handle:hEnterSoundDelay;
new Handle:hEnterSoundNotifyDelay;
new Handle:hEnterSoundPlayType;

public OnPluginStart()
{
	CreateConVar("sm_enter_sounds_version", PLUGIN_VERSION, "Plugin version",  FCVAR_REPLICATED|FCVAR_NOTIFY);
	hEnterSound = CreateConVar( "sm_enter_sound", "1", "Enable/Disable(1/0) enter sounds", FCVAR_PLUGIN );
	hEnterSoundNotify = CreateConVar( "sm_enter_sound_notify", "1", "Enable/Disable(1/0) notify in enter sounds", FCVAR_PLUGIN );
	hEnterSoundNotifyMsg = CreateConVar( "sm_enter_sound_notify_msg", "Sound Clip: {SOUND_NAME}", "Sound notify msg", FCVAR_PLUGIN );
	hEnterSoundDelay = CreateConVar( "sm_enter_sound_delay", "0.1", "Sound play delay", FCVAR_PLUGIN, true, 0.1 );
	hEnterSoundNotifyDelay = CreateConVar( "sm_enter_sound_notify_delay", "0.1", "Sound notify delay", FCVAR_PLUGIN, true, 0.1 );
	hEnterSoundPlayType = CreateConVar( "sm_enter_sound_play_type", "0", "0 - play client command (play), 1 - play from sdk sound command", FCVAR_PLUGIN );
	
	AutoExecConfig( true, "enter_sounds" );
	
	LoadSounds();
}

public OnMapStart()
{
	if( GetConVarBool( hEnterSound ) )
	{
		decl String:buffer[ MAX_FILE_LEN ];
		for( new i = 0; i < g_numSounds; i++ )
		{
			Format( buffer, MAX_FILE_LEN, "sound/%s", g_soundNames[ i ] );
			AddFileToDownloadsTable( buffer);
			PrecacheSound( g_soundNames[ i ], true );
		}
	}
}

public OnClientPostAdminCheck( iClient )
{
	if( GetConVarBool( hEnterSound ) )
	{
		new iRandomSound = GetRandomInt( 0, g_numSounds - 1 ), Handle:hPack, Handle:hPackNotify;
		CreateDataTimer( GetConVarFloat( hEnterSoundDelay ), Timer_PlaySound, hPack );
		WritePackCell( hPack, iClient );
		WritePackCell( hPack, iRandomSound );
		
		if( GetConVarBool( hEnterSoundNotify ) )
		{
			CreateDataTimer( GetConVarFloat( hEnterSoundNotifyDelay ), Timer_ShowNotify, hPackNotify );
			WritePackCell( hPackNotify, iClient );
			WritePackCell( hPackNotify, iRandomSound );
		}
	}
}

public Action:Timer_PlaySound(Handle:hTimer, Handle:hPack)
{
	new iClient, iSound;
	
	/* Set to the beginning and unpack it */
	ResetPack( hPack );
	iClient = ReadPackCell( hPack );
	iSound = ReadPackCell( hPack );
	
	if( GetConVarInt( hEnterSoundPlayType ) == 0 )
		ClientCommand( iClient, "play %s", g_soundNames[ iSound ] );
	else
	EmitSoundToClient( iClient, g_soundNames[ iSound ] );
	
	return Plugin_Continue;
}

public Action:Timer_ShowNotify(Handle:hTimer, Handle:hPack)
{
	new iClient, iSound;
	
	/* Set to the beginning and unpack it */
	ResetPack( hPack );
	iClient = ReadPackCell( hPack );
	iSound = ReadPackCell( hPack );
	
	decl String:strBuffer[ 512 ];
	GetConVarString( hEnterSoundNotifyMsg, strBuffer, sizeof( strBuffer ) );
	
	ReplaceString( strBuffer, sizeof( strBuffer ), "{SOUND_NAME}", g_displayNames[ iSound ] );
	
	PrintToChat( iClient, strBuffer );
	
	return Plugin_Continue;
}



public LoadSounds()
{
	if( GetConVarBool( hEnterSound ) )
	{
		decl String:filename[ MAX_FILE_LEN ];
		BuildPath( Path_SM, filename, MAX_FILE_LEN, "configs/enter_sounds.txt" );
		new Handle:hFile = OpenFile( filename, "r" );
		
		if( hFile == INVALID_HANDLE )
		{
			SetFailState( "addons/sourcemod/configs/enter_sounds.txt not found" );
			return;
		}
		
		g_numSounds = 0;
		
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
					else if ( line[ i ] == ';' ) {
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
			
			g_displayNames[ g_numSounds ][ 0 ] = 0;
			g_soundNames[ g_numSounds ][ 0 ] = 0;
			
			new String:file_name[ MAX_DISPLAY_LENGTH ];
			new String:file_sound[ MAX_FILE_LEN ];	
			new cur_idx, idx;
			
			cur_idx = BreakString( line, file_name, sizeof( file_name ) );
			strcopy( g_displayNames[ g_numSounds ], sizeof( g_displayNames[ ] ), file_name );
			
			idx = cur_idx;
			cur_idx = BreakString( line[ idx ], file_sound, sizeof( file_sound ) );
			strcopy( g_soundNames[ g_numSounds ], sizeof( g_soundNames[ ] ), file_sound );
			
			g_numSounds++;
		}
	
		CloseHandle( hFile );
	}
}