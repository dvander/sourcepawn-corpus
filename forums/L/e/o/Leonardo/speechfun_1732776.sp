#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"

new Handle:sm_speechfun_version;

new iClientPitch[MAXPLAYERS+1];

new bool:bIsTF;
new bool:bIsCSS;
new bool:bIsL4D;

public Plugin:myinfo = 
{
	name = "Speech Fun",
	author = "Leonardo",
	description = "...",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	
	sm_speechfun_version = CreateConVar( "sm_speechfun_version", PLUGIN_VERSION, "Speech Fun plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED );
	SetConVarString( sm_speechfun_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_speechfun_version, OnConVarChanged_PluginVersion );
	
	RegAdminCmd( "sm_setpitch", Command_SetPitch, ADMFLAG_GENERIC );
	RegAdminCmd( "sm_mypitch", Command_MyPitch, ADMFLAG_GENERIC );
	
	AddNormalSoundHook( NormalSoundHook );
	
	decl String:strGameDir[16];
	GetGameFolderName( strGameDir, sizeof(strGameDir) );
	bIsTF = strcmp( strGameDir, "tf", false ) == 0 || strcmp( strGameDir, "tf_beta", false ) == 0;
	bIsCSS = strcmp( strGameDir, "cstrike", false ) == 0 || strcmp( strGameDir, "cstrike_beta", false ) == 0;
	bIsL4D = strcmp( strGameDir, "left4dead", false ) == 0 || strcmp( strGameDir, "left4dead2", false ) == 0;
	
	for( new i = 0; i <= MAXPLAYERS; i++ )
		ResetData( i );
}

public OnClientConnected( iClient )
{
	ResetData( iClient );
}

public Action:NormalSoundHook( iClients[64], &iNumClients, String:strSample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:flVolume, &iLevel, &iPitch, &iFlags )
{
	if( StrContains( strSample, "/footstep", false ) != -1 )
		return Plugin_Continue;
	
	new bool:bValid = false;
	
	if( IsValidClient( iEntity ) )
	{
		if( bIsCSS )
			bValid = StrContains( strSample, "player/death", false ) == 0 || StrContains( strSample, "radio/", false ) == 0 || StrContains( strSample, "bot/", false ) == 0;
		else if( bIsTF )
			bValid = StrContains( strSample, "vo/", false ) == 0 || StrContains( strSample, "player/taunt_rockstar", false ) == 0;
		else if( bIsL4D )
			bValid = StrContains( strSample, "player\\", false ) == 0 && StrContains( strSample, "\\voice\\", false ) != -1 || StrContains( strSample, "player/", false ) == 0 && StrContains( strSample, "/voice/", false ) != -1;
		else
			bValid = StrContains( strSample, "player/", false ) == 0 || StrContains( strSample, "player\\", false ) == 0;
	}
	else
	{
		if( bIsL4D )
			bValid = StrContains( strSample, "npc/", false ) == 0 || StrContains( strSample, "player\\", false ) == 0 && StrContains( strSample, "\\voice\\", false ) != -1 || StrContains( strSample, "player/", false ) == 0 && StrContains( strSample, "/voice/", false ) != -1;
		//if( !bValid ) PrintToServer( "entity %d > %s", iEntity, strSample );
	}
	
	if( bValid )
	{
		iPitch = iClientPitch[ IsValidClient( iEntity ) ? iEntity : 0 ];
		iFlags |= SND_CHANGEPITCH;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:Command_MyPitch( iClient, nArgs )
{
	if( iClient == 0 )
		return Plugin_Continue;
	
	decl String:strCommandName[16];
	GetCmdArg( 0, strCommandName, sizeof(strCommandName) );
	
	if( nArgs >= 1 )
	{
		decl String:strPitch[8];
		GetCmdArg( 1, strPitch, sizeof(strPitch) );
		new iPitch = StringToInt( strPitch );
		if( iPitch < 24 || iPitch > 256 )
		{
			ReplyToCommand( iClient, "Pitch value %d is out of bounds [24...256]", iPitch );
			return Plugin_Handled;
		}
		
		iClientPitch[iClient] = iPitch;
	}
	else
		ReplyToCommand( iClient, "Usage: %s <number>", strCommandName );
	
	return Plugin_Handled;
}
public Action:Command_SetPitch( iClient, nArgs )
{
	decl String:strCommandName[16];
	GetCmdArg( 0, strCommandName, sizeof(strCommandName) );
	
	if( nArgs == 1 ) 
	{
		decl String:strTargets[64];
		GetCmdArg( 1, strTargets, sizeof(strTargets) );
		if( strTargets[0] == '0' )
		{
			iClientPitch[0] = SNDPITCH_NORMAL;
		}
		else
		{
			decl String:target_name[MAX_TARGET_LENGTH];
			decl iTargets[MAXPLAYERS];
			decl nTargets;
			decl bool:tn_is_ml;
			if((nTargets = ProcessTargetString(strTargets, iClient, iTargets, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError( iClient, nTargets );
				return Plugin_Handled;
			}
			for( new i = 0; i < nTargets; i++ )
				iClientPitch[iTargets[i]] = SNDPITCH_NORMAL;
		}
	}
	else if( nArgs >= 2 )
	{
		
		decl String:strPitch[8];
		GetCmdArg( 2, strPitch, sizeof(strPitch) );
		new iPitch = StringToInt( strPitch );
		if( iPitch < 24 || iPitch > 256 )
		{
			ReplyToCommand( iClient, "Pitch value %d is out of bounds [24...256]", iPitch );
			return Plugin_Handled;
		}
		
		decl String:strTargets[64];
		GetCmdArg( 1, strTargets, sizeof(strTargets) );
		if( strTargets[0] == '0' )
		{
			iClientPitch[0] = iPitch;
		}
		else
		{
			decl String:target_name[MAX_TARGET_LENGTH];
			decl iTargets[MAXPLAYERS];
			decl nTargets;
			decl bool:tn_is_ml;
			if((nTargets = ProcessTargetString(strTargets, iClient, iTargets, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError( iClient, nTargets );
				return Plugin_Handled;
			}
			for( new i = 0; i < nTargets; i++ )
				iClientPitch[iTargets[i]] = iPitch;
		}
	}
	else
		ReplyToCommand( iClient, "Usage: %s <target> [number]", strCommandName );
	
	return Plugin_Handled;
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );

ResetData( iClient )
{
	if( iClient < 0 || iClient > MAXPLAYERS )
		return;
	iClientPitch[iClient] = SNDPITCH_NORMAL;
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}