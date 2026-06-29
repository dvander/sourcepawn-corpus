#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Spawn Room Music",
	author = "Leonardo",
	description = "Adds music to spawn rooms.",
	version = PLUGIN_VERSION,
	url = ""
}

new iMethod = 2;

#define MAX_NUMBER_OF_SOUNDS 100

new bool:bInRespawn[MAXPLAYERS+1];
new Handle:hSndRepeater[MAXPLAYERS+1];
new String:szSounds[MAX_NUMBER_OF_SOUNDS][PLATFORM_MAX_PATH];
new Float:flSoundsVol[MAX_NUMBER_OF_SOUNDS];
new Float:flSoundsLen[MAX_NUMBER_OF_SOUNDS];
new nSounds = 0;

public OnPluginStart()
{
	new Handle:hCVar = CreateConVar( "sm_respawn_music_version", PLUGIN_VERSION, "The version of the Spawn Room Music plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
	SetConVarString( hCVar, PLUGIN_VERSION, true, true );
	HookConVarChange( hCVar, OnConVarChanged_PluginVersion );
	
	RegAdminCmd( "sm_respawn_music_reload", Command_ReloadMusic, ADMFLAG_ROOT );
	
	nSounds = 0;
	
	new iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "func_respawnroom" ) ) != -1 )
	{
		SDKHook( iEntity, SDKHook_StartTouchPost, OnRespawnRoomStartTouch );
		SDKHook( iEntity, SDKHook_EndTouchPost, OnRespawnRoomEndTouch );
	}
	
	for( new i = 0; i <= MaxClients; i++ )
	{
		bInRespawn[i] = false;
		hSndRepeater[i] = INVALID_HANDLE;
	}
}

public OnPluginEnd()
{
	if( nSounds )
	{
		new iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "func_respawnroom" ) ) != -1 )
			DeleteSounds( iEntity );
		for( new i = 1; i <= MaxClients; i++ )
			if( IsClientInGame( i ) )
				DeleteSounds( i );
	}
	nSounds = 0;
}

public OnMapStart()
{
	OnPluginEnd();
	
	new Handle:hSounds = CreateKeyValues( "music" );
	decl String:szFilePath[PLATFORM_MAX_PATH];
	decl String:szSample[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, szFilePath, PLATFORM_MAX_PATH, "configs/respawn_music.cfg" );
	if( !FileToKeyValues( hSounds, szFilePath ) )
		KeyValuesToFile( hSounds, szFilePath );
	if( KvGotoFirstSubKey( hSounds ) )
		do
		{
			flSoundsVol[nSounds] = KvGetFloat( hSounds, "volume", 1.0 );
			if( !( 0.0 < flSoundsVol[nSounds] <= 1.0 ) )
				flSoundsVol[nSounds] = 1.0;
			
			flSoundsLen[nSounds] = KvGetFloat( hSounds, "length", 0.0 );
			
			KvGetString( hSounds, "file", szSample, PLATFORM_MAX_PATH );
			szFilePath = "sound/";
			StrCat( szFilePath, PLATFORM_MAX_PATH, szSample );
			szSounds[nSounds] = szSample;
			if( iMethod == 1 )
				ReplaceString( szSample, sizeof( szSample ), "/", "\\" );
			if( FileExists( szFilePath, true ) || FileExists( szFilePath, false ) )
			{
				nSounds++;
				AddFileToDownloadsTable( szFilePath );
				PrecacheSound( szSample, true );
			}
		}
		while( KvGotoNextKey( hSounds ) );
	else
		LogMessage( "No songs in file %s.", szFilePath );
	CloseHandle( hSounds );
	
	new iEntity = -1;
	if( nSounds )
		while( ( iEntity = FindEntityByClassname( iEntity, "func_respawnroom" ) ) != -1 )
			SpawnSound( iEntity );
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );

public OnClientPutInServer( iClient )
{
	bInRespawn[iClient] = false;
	hSndRepeater[iClient] = INVALID_HANDLE;
}

public OnClientDisconnect( iClient )
	OnRespawnRoomEndTouch( -1, iClient );

public Action:Command_ReloadMusic( iClient, nArgs )
{
	OnMapStart();
	return Plugin_Handled;
}

public OnEntityCreated( iEntity, const String:strClassname[] )
	if( StrEqual( strClassname, "func_respawnroom", false ) )
	{
		CreateTimer( 0.0, Timer_SpawnSound, EntIndexToEntRef( iEntity ) );
		SDKHook( iEntity, SDKHook_StartTouchPost, OnRespawnRoomStartTouch );
		SDKHook( iEntity, SDKHook_EndTouchPost, OnRespawnRoomEndTouch );
	}

public Action:Timer_SpawnSound( Handle:hTimer, any:iEntRef )
{
	new iEntity = EntRefToEntIndex( iEntRef );
	DeleteSounds( iEntity );
	SpawnSound( iEntity );
	return Plugin_Stop;
}

public OnRespawnRoomStartTouch( iSpawnRoom, iClient )
	if( 0 < iClient <= MaxClients )
	{
		bInRespawn[iClient] = true;
		StopTimer( hSndRepeater[iClient] );
		if( iMethod == 2 )
			SpawnSound( _, _, iClient );
	}

public OnRespawnRoomEndTouch( iSpawnRoom, iClient )
	if( 0 < iClient <= MaxClients )
	{
		bInRespawn[iClient] = false;
		StopTimer( hSndRepeater[iClient] );
		DeleteSounds( iClient );
	}

stock DeleteSounds( iEntity )
	if( nSounds && iEntity > 0 && IsValidEntity( iEntity ) )
		for( new s = 0; s < nSounds; s++ )
			StopSound( iEntity, SNDCHAN_USER_BASE, szSounds[s] );

stock bool:SpawnSound( iEntity = -1, iForcedSampleID = -1, iClient = 0 )
{
	new iSampleID = ( 0 <= iForcedSampleID < nSounds ? iForcedSampleID : GetRandomInt( 0, nSounds - 1 ) );
	//PrintToServer( "sample %s volume %.2f length %.2f", szSounds[iSampleID], flSoundsVol[iSampleID], flSoundsLen[iSampleID] );
	
	if( iMethod == 2 )
	{
		if( 0 < iClient <= MaxClients && bInRespawn[iClient] )
		{
			EmitSoundToClient( iClient, szSounds[iSampleID], _, SNDCHAN_USER_BASE, _, SND_CHANGEVOL, flSoundsVol[iSampleID], _, _, _, _, _, ( flSoundsLen[nSounds] > 0.0 ? flSoundsLen[nSounds] : 0.0 ) );
			if( flSoundsLen[iSampleID] > 0.0 )
			{
				new Handle:hPack = CreateDataPack();
				hSndRepeater[iClient] = CreateDataTimer( flSoundsLen[iSampleID] + 0.01, Timer_RepeatSound, hPack, TIMER_DATA_HNDL_CLOSE );
				WritePackCell( hPack, iEntity );
				WritePackCell( hPack, iSampleID );
				WritePackCell( hPack, GetClientUserId( iClient ) );
			}
			return true;
		}
		else
			return false;
	}
	
	if( iEntity <= 0 || !IsValidEntity( iEntity ) )
		return false;
	
	new Float:vecOrigin[3], Float:vecMins[3], Float:vecMaxs[3];
	GetEntPropVector( iEntity, Prop_Send, "m_vecOrigin", vecOrigin ); 
	GetEntPropVector( iEntity, Prop_Send, "m_vecMins", vecMins );
	GetEntPropVector( iEntity, Prop_Send, "m_vecMaxs", vecMaxs );
	vecOrigin[0] += ( vecMins[0] + vecMaxs[0] ) * 0.5;
	vecOrigin[1] += ( vecMins[1] + vecMaxs[1] ) * 0.5;
	vecOrigin[2] += ( vecMins[2] + vecMaxs[2] ) * 0.5;
	//PrintToServer( "func_respawnroom %d - %.2f %.2f %.2f", iEntity, vecOrigin[0], vecOrigin[1], vecOrigin[2] );
	if( vecOrigin[0] == 0.0 && vecOrigin[1] == 0.0 && vecOrigin[2] == 0.0 )
		return false;
	
	if( iMethod == 1 )
	{
		new iAmbient = CreateEntityByName( "ambient_generic" );
		if( iAmbient > 0 && IsValidEntity( iAmbient ) )
		{
			DispatchKeyValue( iAmbient, "health", "10" );
			DispatchKeyValue( iAmbient, "message", szSounds[iSampleID] );
			DispatchKeyValueVector( iAmbient, "origin", vecOrigin );
			DispatchKeyValue( iAmbient, "pitchstart", "100" );
			DispatchKeyValue( iAmbient, "pitch", "100" );
			DispatchKeyValue( iAmbient, "radius", "1000" );
			DispatchSpawn( iAmbient );
			TeleportEntity( iAmbient, vecOrigin, NULL_VECTOR, NULL_VECTOR );
			AcceptEntityInput( iEntity, "StopSound" );
			CreateTimer( 0.5, Timer_ActivateAmbient, EntIndexToEntRef( iAmbient ) );
		}
	}
	else
	{
		EmitSoundToAll( szSounds[iSampleID], iEntity, SNDCHAN_STREAM, _, SND_CHANGEVOL, flSoundsVol[iSampleID], _, _, vecOrigin, _, _, ( flSoundsLen[nSounds] > 0.0 ? flSoundsLen[nSounds] : 0.0 ) );
		if( flSoundsLen[iSampleID] > 0.0 )
		{
			new Handle:hPack = CreateDataPack();
			CreateDataTimer( flSoundsLen[iSampleID], Timer_RepeatSound, hPack, TIMER_DATA_HNDL_CLOSE );
			WritePackCell( hPack, EntIndexToEntRef( iEntity ) );
			WritePackCell( hPack, iSampleID );
			WritePackCell( hPack, iClient );
		}
	}
	
	/*
	new Handle:hEvent = CreateEvent( "show_annotation" );
	if( hEvent != INVALID_HANDLE )
	{
		SetEventFloat( hEvent, "worldPosX", vecOrigin[0] );
		SetEventFloat( hEvent, "worldPosY", vecOrigin[1] );
		SetEventFloat( hEvent, "worldPosZ", vecOrigin[2] );
		SetEventFloat( hEvent, "lifetime", 10.0 );
		SetEventInt( hEvent, "id", GetRandomInt(1,15) );
		SetEventString( hEvent, "text", "Sound is here!" );
		SetEventInt( hEvent, "visibilityBitfield", BuildBitString() );
		FireEvent( hEvent );
	}
	*/
	
	return true;
}

public Action:Timer_ActivateAmbient( Handle:hTimer, any:iEntRef )
{
	new iEntity = EntRefToEntIndex( iEntRef );
	if( iEntity > 0 && IsValidEntity( iEntity ) )
		AcceptEntityInput( iEntity, "PlaySound" );
	return Plugin_Stop;
}

public Action:Timer_RepeatSound( Handle:hTimer, Handle:hPack )
{
	if( hPack == INVALID_HANDLE )
		return Plugin_Stop;
	ResetPack( hPack );
	new iEntity = EntRefToEntIndex( ReadPackCell( hPack ) );
	new iSampleID = ReadPackCell( hPack );
	new iClient = GetClientOfUserId( ReadPackCell( hPack ) );
	if( iMethod == 2 && 0 < iClient <= MaxClients )
	{
		DeleteSounds( iClient );
		SpawnSound( _, iSampleID, iClient );
	}
	else
	{
		DeleteSounds( iEntity );
		SpawnSound( iEntity, iSampleID );
	}
	return Plugin_Stop;
}

stock StopTimer( &Handle:hTimer )
{
	if( hTimer != INVALID_HANDLE )
		KillTimer( hTimer );
	hTimer = INVALID_HANDLE;
}

stock BuildBitString()
{
	new bitstring=1;
	for(new client=1; client <= MaxClients; client++)
		if( IsClientInGame(client) && GetClientTeam(client) <= 1 )
			bitstring |= RoundFloat(Pow(2.0, float(client)));
	return bitstring;
}