#include <sourcemod>
#include <sdktools>
#include <colors>

//===== [ CONSTANTS ] ==============
#define PLUGIN_NAME "Event sounds"
#define PLUGIN_AUTHOR "Kemsan"
#define PLUGIN_DESCRIPTION "Play sound / music every time, every event!"
#define PLUGIN_VERSION "1.2"
#define PLUGIN_URL "http://kemsan.pl"

//===== [ VARIABLES ] ==============
new Handle:g_hSoundPlayType;
new Handle:g_hNotifyUseColors;

new String:g_strClientSound[ 33 ][ 512 ];
new bool:g_bAllowSounds[ 33 ] = true;

//===== [ CVARS ] ==============
new Handle:g_hSoundsTrie;
new Handle:g_hNotifyMsg;
new Handle:g_hNotifyDelay;
new Handle:g_hSoundDelay;
new Handle:g_hClientOnly;

//===== [ PLUGIN INFO ] ==============
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

//===== [ PLUGIN REGISTER ] ==============
public OnPluginStart()
{
	CreateConVar( "sm_event_sounds", PLUGIN_VERSION, "Show me event sounds version", FCVAR_PLUGIN | FCVAR_NOTIFY );
	g_hSoundPlayType = CreateConVar( "sm_event_sounds_play_type", "1", "Default \"SOUND_PLAYTYPE\" value for each event; 1 - use client based command ( play SOUND ), 2 - use game sound effect", FCVAR_PLUGIN );
	g_hNotifyMsg = CreateConVar( "sm_event_sounds_notify_msg", "{olive}You listen {green}{SOUND_NAME}{olive}. Have fun", "Default \"NOTIFY_MSG\" value for each event; {SOUND_NAME} - actual played sound", FCVAR_PLUGIN );
	g_hNotifyDelay = CreateConVar( "sm_event_sounds_notify_delay", "0.1", "Default \"NOTIFY_MSG_DELAY\" value for each event; Delay before show notify, 0.0 turn off notify show", FCVAR_PLUGIN );
	g_hSoundDelay = CreateConVar( "sm_event_sounds_sound_delay", "0.1", "Default \"NOTIFY_SOUND_DELAY\" value for each event; Delay before play sound; Minimum 0.1", FCVAR_PLUGIN, true, 0.1 );
	g_hNotifyUseColors = CreateConVar( "sm_event_sounds_color_notify", "1", "Use special coloring function for notify? 0 - disable, 1 - enable", FCVAR_PLUGIN );
	g_hClientOnly = CreateConVar( "sm_event_sounds_clientonly", "0", "Default \"SOUND_CLIENTONLY\" value for each event; 0 - push sound to client and all ( if need ), 1 - push always to client ( if exists )", FCVAR_PLUGIN );
	
	AutoExecConfig( true, "event_sounds" );
	
	//Register commands for players
	RegConsoleCmd( "say", Cmd_Say );
	
	ParseSounds( );
}

public OnMapStart( )
{
	ParseSounds( );	
}

public OnClientPostAdminCheck( iClient ) 
{
	PushSound( "player_enter", iClient );	
}
//===== [ EVENTS ] ==============
public GameEvents(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	//Get event name
	decl String:strEventName[ 150 ];
	GetEventName( hEvent, strEventName, sizeof( strEventName ) );
	
	//Declare conditions variables
	decl String:strName[ 512 ];
	decl String:strBuffer[ 512 ];
	decl String:strBuffer2[ 512 ];
	decl String:strExpBuffer[ 2 ][ 512 ];
	decl String:strCond[ 512 ];
	new iCondCount = 0;
	new iAllow = 0;
	
	//Get conditions count
	Format( strBuffer, sizeof( strBuffer ), "%s_condition_count", strEventName );
	GetTrieValue( g_hSoundsTrie, strBuffer, iCondCount );
	
	for( new i = 0; i < iCondCount; i++ )
	{			
		Format( strName, sizeof( strName ), "%s_condition_name_%i", strEventName, i );
		GetTrieString( g_hSoundsTrie, strName, strBuffer, sizeof( strBuffer ) );
		
		Format( strName, sizeof( strName ), "%s_condition_%i", strEventName, i );
		GetTrieString( g_hSoundsTrie, strName, strBuffer2, sizeof( strBuffer2 ) );
		
		ExplodeString( strBuffer, ":", strExpBuffer, 2, 512 );
		
		if( StrEqual( strExpBuffer[ 1 ], "string" ) )
		{
			GetEventString( hEvent, strExpBuffer[ 0 ], strCond, sizeof( strCond ) );
			if( StrEqual( strCond, strBuffer2 ) )
			{
				iAllow++;
			}
		}
		else if( StrEqual( strExpBuffer[ 1 ], "int" ) )
		{
			if( GetEventInt( hEvent, strBuffer2 ) == StringToInt( strBuffer2 ) )
			{
				iAllow++;
			}
		}
		else if( StrEqual( strExpBuffer[ 1 ], "float" ) )
		{
			if( GetEventFloat( hEvent, strBuffer2 ) == StringToFloat( strBuffer2 ) )
			{
				iAllow++;
			}
		}
		else if( StrEqual( strExpBuffer[ 1 ], "userid" ) )
		{
			if( GetClientOfUserId( GetEventInt( hEvent, "userid" ) ) == StringToInt( strBuffer2 ) )
			{
				iAllow++;
			}
		}
	
	}
	
	//Check for conditions true count
	if( iAllow == iCondCount )
	{
		//Get client id by userid pushed from event
		new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
		
		//Push sound
		PushSound( strEventName, iClient );
	}
}

//===== [ COMMANDS ] ==============
public Action:Cmd_Say( iClient, iArgs )
{
	//Check for valid client
	if( IsValidClient( iClient ) )
	{
		decl String:strChatText[512];
		GetCmdArgString( strChatText, sizeof( strChatText ) );
		
		new iStart = 0
		if ( strChatText[ 0 ] == '"' )
		{
			iStart = 1
			/* Strip the ending quote, if there is one */
			new iChatTextLen = strlen( strChatText );
			if ( strChatText[ iChatTextLen - 1 ] == '"')
			{
				strChatText[ iChatTextLen - 1 ] = '\0'
			}
		}
		
		if( StrEqual( strChatText[ iStart ], "!stop" ) || StrEqual( strChatText[ iStart ], "/stop" ) )
		{
			//Check for precached file
			if( IsSoundPrecached( g_strClientSound[ iClient ] ) )
			{
				//Stop playing sound with SDKTools
				StopSound( iClient, SNDCHAN_AUTO, g_strClientSound[ iClient ] ); 
				//Stop playing sound with normal command (play) - Tested on TF2 - works
				ClientCommand( iClient, "play vo/null.wav" ); 
				//Handle chat cmd
				return Plugin_Handled;
			}
		}
		else if( StrEqual( strChatText[ iStart ], "!stopall" ) || StrEqual( strChatText[ iStart ], "/stopall" ) )
		{
			//Set false / true to all sounds
			g_bAllowSounds[ iClient ] = g_bAllowSounds[ iClient ] ? false : true;
			
			//Check for precached file
			if( IsSoundPrecached( g_strClientSound[ iClient ] ) )
			{
				//Stop playing sound with SDKTools
				StopSound( iClient, SNDCHAN_AUTO, g_strClientSound[ iClient ] ); 
				//Stop playing sound with normal command (play) - Tested on TF2 - works
				ClientCommand( iClient, "play vo/null.wav" ); 
			}
			//Handle chat cmd
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

//===== [ SOUNDS ] ==============
stock PushSound( const String:strEventName[ 150 ], any:iClient = 0 )
{
	//Decl variable for check
	decl String:strSound[ 512 ];
	new iMaxSounds = 0;
	new iPushSound = 1;
	
	//Get max sounds ( check for event trie exists )
	Format( strSound, sizeof( strSound ), "%s_sound_count", strEventName );
	GetTrieValue( g_hSoundsTrie, strSound, iMaxSounds );
	
	Format( strSound, sizeof( strSound ), "%s_push_sound", strEventName );
	GetTrieValue( g_hSoundsTrie, strSound, iPushSound );

	//Check for trie exists
	if( ( iMaxSounds && iMaxSounds >= 1 ) || iPushSound == 0 )
	{
		//Decl some variables
		decl String:strSoundPath[ 512 ];
		decl String:strSoundName[ 512 ];
		decl String:strSoundNotify[ 512 ];
		decl String:strSoundDelay[ 30 ];
		decl String:strNotifyDelay[ 30 ];
		decl iRandomSound;
		decl iSoundPlayType;
		decl iSoundClientOnly;
		
		//Rand sound
		iRandomSound = GetRandomInt( 0, iMaxSounds );
		
		//Format for sound
		Format( strSound, sizeof( strSound ), "%s_sound_%i", strEventName, iRandomSound );
		GetTrieString( g_hSoundsTrie, strSound, strSoundPath, sizeof( strSoundPath ) );
		
		Format( strSound, sizeof( strSound ), "%s_sound_name_%i", strEventName, iRandomSound );
		GetTrieString( g_hSoundsTrie, strSound, strSoundName, sizeof( strSoundName ) );
		
		Format( strSound, sizeof( strSound ), "%s_notify", strEventName );
		GetTrieString( g_hSoundsTrie, strSound, strSoundNotify, sizeof( strSoundNotify ) );
		
		Format( strSound, sizeof( strSound ), "%s_playtype", strEventName );
		GetTrieValue( g_hSoundsTrie, strSound, iSoundPlayType );
		
		Format( strSound, sizeof( strSound ), "%s_clientonly", strEventName );
		GetTrieValue( g_hSoundsTrie, strSound, iSoundClientOnly );
		
		Format( strSound, sizeof( strSound ), "%s_sound_delay", strEventName );
		GetTrieString( g_hSoundsTrie, strSound, strSoundDelay, sizeof( strSoundDelay ) );
		
		Format( strSound, sizeof( strSound ), "%s_notify_delay", strEventName );
		GetTrieString( g_hSoundsTrie, strSound, strNotifyDelay, sizeof( strNotifyDelay ) );
		
		//Check for show only notify
		if( iPushSound == 1 )
		{
			//Check for clientonly sound
			if( ( iSoundClientOnly == 1 && IsValidClient( iClient ) ) || iSoundClientOnly == 0 )
			{
				//Create new data pack
				new Handle:hSoundPack = CreateDataPack( );
				//Create data timer
				CreateDataTimer( StringToFloat( strSoundDelay ), Timer_PlaySound, hSoundPack );
				//Write data to pack
				WritePackString( hSoundPack, strSoundPath );
				WritePackCell( hSoundPack, iSoundPlayType );
				WritePackCell( hSoundPack, iClient );
			}
		}
		
		//Check for timer allow
		if( StringToFloat( strNotifyDelay ) > 0.0 )
		{
			//Check for clientonly sound
			if( ( iSoundClientOnly == 1 && IsValidClient( iClient ) ) || iSoundClientOnly == 0 )
			{
				//Create new data pack
				new Handle:hNotifyPack = CreateDataPack( );
				//Create data timer
				CreateDataTimer( StringToFloat( strNotifyDelay ), Timer_ShowNotify, hNotifyPack );
				//Write data to pack
				WritePackString( hNotifyPack, strSoundNotify );
				WritePackString( hNotifyPack, strSoundName );
				WritePackString( hNotifyPack, strSoundPath );
				WritePackCell( hNotifyPack, iClient );
			}
		}
	}
}

//===== [ TIMERS ] ==============
public Action:Timer_PlaySound( Handle:hTimer, Handle:hPack )
{
	//Declare some variables
	decl String:strSoundPath[ 512 ];
	decl iSoundPlayType;
	decl iClient;
	decl i;
	
	//Read pack
	ResetPack( hPack );
	ReadPackString( hPack, strSoundPath, sizeof( strSoundPath ) );
	iSoundPlayType = ReadPackCell( hPack );
	iClient = ReadPackCell( hPack );
	
	//Check for file exists and precached sound
	if( FileExists( strSoundPath ) )
	{
		//Replace sound/ string
		ReplaceString( strSoundPath, sizeof( strSoundPath ), "sound/", "" );
		
		//Set actual sound to client
		if( IsValidClient( iClient ) )
		{
			Format( g_strClientSound[ iClient ], sizeof( g_strClientSound ), strSoundPath );
		} 
		else //Set actual sound to all players
		{
			for( i = 1; i < MaxClients; i++ )
			{
				if( IsValidClient( i ) )
				{
					Format( g_strClientSound[ i ], sizeof( g_strClientSound ), strSoundPath );	
				}
			}
		}
		
		if( iSoundPlayType == 1 ) //Use "play" command
		{
			if( IsValidClient( iClient ) )
			{
				if( g_bAllowSounds[ iClient ] == true )
				{
					ClientCommand( iClient, "play %s", strSoundPath ); 
				}
			}
			else
			{
				for( i = 1; i < MaxClients; i++ )
				{
					if( IsValidClient( i ) && g_bAllowSounds[ i ] == true )
					{
						ClientCommand( i, "play %s", strSoundPath );
					}
				}
			}
		}
		else if( iSoundPlayType == 2 ) //Use SDK Emit sound
		{
			if( IsValidClient( iClient ) )
			{
				if( g_bAllowSounds[ iClient ] == true )
				{
					EmitSoundToClient( iClient, strSoundPath );
				}
			}
			else
			{
				for( i = 1; i < MaxClients; i++ )
				{
					if( IsValidClient( i ) && g_bAllowSounds[ i ] == true )
					{
						EmitSoundToClient( i, strSoundPath );
					}
				}
			}
		}
		/*
		* else //Don't play antyhing
		* {
		* 	//NULL
		* }
		*/
	}	
}

public Action:Timer_ShowNotify( Handle:hTimer, Handle:hPack )
{
	//Declare some variables
	decl String:strSoundNotify[ 512 ];
	decl String:strSoundName[ 512 ];
	decl String:strSoundPath[ 512 ];
	decl iClient;
	decl bool:bColorNotify;
	
	//Read pack
	ResetPack( hPack );
	ReadPackString( hPack, strSoundNotify, sizeof( strSoundNotify ) );
	ReadPackString( hPack, strSoundName, sizeof( strSoundName ) );
	ReadPackString( hPack, strSoundPath, sizeof( strSoundPath ) );
	iClient = ReadPackCell( hPack );
	
	//Replace {SOUND_NAME} to normal sound name
	ReplaceString( strSoundNotify, sizeof( strSoundNotify ), "{SOUND_NAME}", strSoundName );
	
	//Replace {SOUND_PATH} to sound path in client game folder
	ReplaceString( strSoundNotify, sizeof( strSoundNotify ), "{SOUND_PATH}", strSoundPath );
	
	//Get cvar value
	bColorNotify = GetConVarBool( g_hNotifyUseColors );
	
	//Check for client exists
	if( IsValidClient( iClient ) )
	{
		if( g_bAllowSounds[ iClient ] == true )
		{
			//Check for use color print
			if( bColorNotify )
			{
				CPrintToChat( iClient, strSoundNotify );
			}
			else
			{
				PrintToChat( iClient, strSoundNotify );
			}
		}
	}
	else
	{
		//Check for use color print
		if( bColorNotify )
		{
			for( iClient = 1; iClient < MaxClients; iClient++ )
			{
				if( IsValidClient( iClient ) && g_bAllowSounds[ iClient ] == true )
				{
					CPrintToChat( iClient, strSoundNotify );
				}
			}
		}
		else
		{
			for( iClient = 1; iClient < MaxClients; iClient++ )
			{
				if( IsValidClient( iClient ) && g_bAllowSounds[ iClient ]  == true )
				{
					PrintToChat( iClient, strSoundNotify );
				}
			}
		}
	}
}


stock ParseSounds( )
{
	//Declare some variables
	decl String:strBuffer[ 512 ];
	decl String:strBuffer2[ 512 ];
	decl String:strEventName[ 256 ];
	decl String:strSoundName[ 256 ];
	decl String:strDefaultValue[ 256 ];
	decl iSoundCount, iConditions;
	
	// Create key values object and parse file.
	BuildPath( Path_SM, strBuffer, sizeof( strBuffer ), "configs/event_sounds.keys.txt" );
	
	//Create handle for event sounds
	new Handle:hKeyValues = CreateKeyValues( "EventSounds" );
	
	//Check for correct file
	if ( FileToKeyValues( hKeyValues, strBuffer ) == false )
		SetFailState( "Error, can't read file containing the event sounds : %s", strBuffer );
	
	// Check the version
	KvGetSectionName( hKeyValues, strBuffer, sizeof( strBuffer ) );
	
	//Throw error if file don't have latest version
	if ( StrEqual( "EventSounds", strBuffer ) == false )
		SetFailState( "event_sounds.keys.txt structure corrupt or incorrect version: \"%s\"", strBuffer );
	
	//Browse it, and create trie value for class
	
	if ( KvGotoFirstSubKey( hKeyValues, false ) )
	{
		g_hSoundsTrie = CreateTrie( );
		iSoundCount = 0;
		iConditions = 0;
		
		do
		{
			//Get event name
			KvGetSectionName( hKeyValues, strEventName, sizeof( strEventName ) );
			
			//Hook event
			HookEventEx( strEventName, GameEvents );
			
			if ( KvGotoFirstSubKey( hKeyValues, false ) )
			{
				do
				{
					KvGetSectionName( hKeyValues, strBuffer, sizeof( strBuffer ) );
					
					//Parse sounds
					if( StrEqual( strBuffer, "sounds" ) )
					{
						if ( KvGotoFirstSubKey( hKeyValues, false ) )
						{
							do
							{
								KvGetSectionName( hKeyValues, strBuffer, sizeof( strBuffer ) );
								KvGetString( hKeyValues, NULL_STRING, strBuffer2, sizeof( strBuffer2 ) );
								
								if( FileExists( strBuffer2 ) )
								{
									Format( strSoundName, sizeof( strSoundName ), "%s_sound_name_%i", strEventName, iSoundCount );
									SetTrieString( g_hSoundsTrie, strSoundName, strBuffer );
									
									Format( strSoundName, sizeof( strSoundName ), "%s_sound_%i", strEventName, iSoundCount );
									SetTrieString( g_hSoundsTrie, strSoundName, strBuffer2 );
									
									AddFileToDownloadsTable( strBuffer2 );
									
									ReplaceString( strBuffer2, sizeof( strBuffer2 ), "sound/", "" );
									PrecacheSound( strBuffer2 );
									
									iSoundCount++;
								}
							} while ( KvGotoNextKey( hKeyValues, false ) );	
							
							Format( strBuffer, sizeof( strBuffer ), "%s_sound_count", strEventName );
							SetTrieValue( g_hSoundsTrie, strBuffer, iSoundCount );
							
							iSoundCount = 0;
							
							KvGoBack( hKeyValues );
						}
					}
					//Parse conditions
					else if( StrEqual( strBuffer, "conditions" ) )
					{
						if ( KvGotoFirstSubKey( hKeyValues, false ) )
						{
							do
							{
								KvGetSectionName( hKeyValues, strBuffer, sizeof( strBuffer ) );
								KvGetString( hKeyValues, NULL_STRING, strBuffer2, sizeof( strBuffer2 ) );
								
								Format( strSoundName, sizeof( strSoundName ), "%s_condition_name_%i", strEventName, iConditions );
								SetTrieString( g_hSoundsTrie, strSoundName, strBuffer );
									
								Format( strSoundName, sizeof( strSoundName ), "%s_condition_%i", strEventName, iConditions );
								SetTrieString( g_hSoundsTrie, strSoundName, strBuffer2 );
									
								iConditions++;
							} while ( KvGotoNextKey( hKeyValues, false ) );	
							
							Format( strBuffer, sizeof( strBuffer ), "%s_condition_count", strEventName );
							SetTrieValue( g_hSoundsTrie, strBuffer, iConditions );
							
							iConditions = 0;
							
							KvGoBack( hKeyValues );
						}
					}
					//Parse options
					else if( StrEqual( strBuffer, "options" ) )
					{
						//Create default values
						Format( strBuffer, sizeof( strBuffer ), "%s_playtype", strEventName );
						SetTrieValue( g_hSoundsTrie, strBuffer, GetConVarInt( g_hSoundPlayType ) );
						
						Format( strBuffer, sizeof( strBuffer ), "%s_clientonly", strEventName );
						SetTrieValue( g_hSoundsTrie, strBuffer, GetConVarInt( g_hClientOnly ) );
						
						Format( strBuffer, sizeof( strBuffer ), "%s_notify", strEventName );
						GetConVarString( g_hNotifyMsg, strDefaultValue, sizeof( strDefaultValue ) );
						SetTrieString( g_hSoundsTrie, strBuffer, strDefaultValue );
						
						Format( strBuffer, sizeof( strBuffer ), "%s_notify_delay", strEventName );
						GetConVarString( g_hNotifyDelay, strDefaultValue, sizeof( strDefaultValue ) );
						SetTrieString( g_hSoundsTrie, strBuffer, strDefaultValue );
						
						Format( strBuffer, sizeof( strBuffer ), "%s_sound_delay", strEventName );
						GetConVarString( g_hSoundDelay, strDefaultValue, sizeof( strDefaultValue ) );
						SetTrieString( g_hSoundsTrie, strBuffer, strDefaultValue );
						
						if ( KvGotoFirstSubKey( hKeyValues, false ) )
						{
							do
							{
								KvGetSectionName( hKeyValues, strBuffer, sizeof( strBuffer ) );
								switch( KvGetDataType( hKeyValues, NULL_STRING ) )
								{
									case KvData_Int:
									{
										if( StrEqual( strBuffer, "SOUND_PLAYTYPE" ) )
										{
											Format( strBuffer, sizeof( strBuffer ), "%s_playtype", strEventName );
										}
										else if( StrEqual( strBuffer, "SOUND_CLIENTONLY" ) )
										{
											Format( strBuffer, sizeof( strBuffer ), "%s_clientonly", strEventName );
										}
										else if( StrEqual( strBuffer, "NOTIFY_PUSH_SOUND" ) )
										{
											Format( strBuffer, sizeof( strBuffer ), "%s_push_sound", strEventName );
										}
										
										SetTrieValue( g_hSoundsTrie, strBuffer, KvGetNum( hKeyValues, NULL_STRING ) );
										
									}
									case KvData_String, KvData_Float:
									{
										KvGetString( hKeyValues, NULL_STRING, strBuffer2, sizeof( strBuffer2 ) );
										if( StrEqual( strBuffer, "NOTIFY_MSG" ) )
										{
											Format( strBuffer, sizeof( strBuffer ), "%s_notify", strEventName );
											GetConVarString( g_hNotifyMsg, strDefaultValue, sizeof( strDefaultValue ) );
										}
										else if( StrEqual( strBuffer, "NOTIFY_MSG_DELAY" ) )
										{
											Format( strBuffer, sizeof( strBuffer ), "%s_notify_delay", strEventName );
											GetConVarString( g_hNotifyDelay, strDefaultValue, sizeof( strDefaultValue ) );
										}
										else if( StrEqual( strBuffer, "NOTIFY_SOUND_DELAY" ) )
										{
											Format( strBuffer, sizeof( strBuffer ), "%s_sound_delay", strEventName );
											GetConVarString( g_hSoundDelay, strDefaultValue, sizeof( strDefaultValue ) );
										}
										
										if( StrEqual( strBuffer2, "" ) )
										{
											Format( strBuffer2, sizeof( strBuffer2 ), strDefaultValue );
										}
										
										SetTrieString( g_hSoundsTrie, strBuffer, strBuffer2 );
									}
								}
							} while ( KvGotoNextKey( hKeyValues, false ) );	
						}
					}
				} while ( KvGotoNextKey( hKeyValues, false ) );
				
				KvRewind( hKeyValues );
				KvJumpToKey( hKeyValues,  strEventName );
			}
		} while ( KvGotoNextKey( hKeyValues, false ) );
	}
}

//===== [ STOCKS ] ==============
stock bool:IsValidClient( iClient, bool:bNoBots = true )
{
	if ( iClient <= 0 || iClient > MaxClients || !IsClientConnected( iClient ) || ( bNoBots && IsFakeClient( iClient ) ) )
	{
		return false;
	}
	
	return IsClientInGame( iClient );}