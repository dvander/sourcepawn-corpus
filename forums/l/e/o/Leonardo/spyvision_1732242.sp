#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.1"
#define CHECK_DELAY 0.1
#define CHAT_TAG "[SM] "

new Handle:sm_spyvision_version = INVALID_HANDLE;
new Handle:sm_spyvision_enabled = INVALID_HANDLE;

new bool:bEnabled = false;

new bool:bClientEnabled[MAXPLAYERS+1];

new nModelIndexes[2] = { -1, ... };

public Plugin:myinfo = {
	name = "[TF2] Spy Vision",
	author = "Leonardo",
	description = "...",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	
	sm_spyvision_version = CreateConVar( "sm_spyvision_version", PLUGIN_VERSION, "Spy Vision plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED );
	SetConVarString( sm_spyvision_version, PLUGIN_VERSION, true, true );
	HookConVarChange( sm_spyvision_version, OnConVarChanged_PluginVersion );
	
	sm_spyvision_enabled = CreateConVar( "sm_spyvision_enabled", "1", "Global access. Set 0 to disable plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
	HookConVarChange( sm_spyvision_enabled, OnConVarChanged );
	
	decl String:strGameDir[8];
	GetGameFolderName(strGameDir, sizeof(strGameDir));
	if(!StrEqual(strGameDir, "tf", false) && !StrEqual(strGameDir, "tf_beta", false))
		SetFailState("THIS PLUGIN IS FOR TEAM FORTRESS 2 ONLY!");
	
	HookEvent( "player_activate", OnPlayerActivate, EventHookMode_Post );
	
	RegConsoleCmd( "sm_spyvision", Command_ToggleEffect );
	
	for( new i = 0; i < MAXPLAYERS; i++ )
		bClientEnabled[i] = false;
}

public OnMapStart()
{
	nModelIndexes[0] = PrecacheModel( "sprites/redglow1.vmt" );
	nModelIndexes[1] = PrecacheModel( "sprites/blueglow1.vmt" );
}

public OnConfigsExecuted()
{
	bEnabled = GetConVarBool( sm_spyvision_enabled );
}

public OnGameFrame()
{
	static Float:flLastCall;
	
	if( !bEnabled )
		return;
	
	if( GetEngineTime() - CHECK_DELAY <= flLastCall )
		return;
	flLastCall = GetEngineTime();
	
	new nImmunity[MAXPLAYERS+1] = { -1, ... };
	
	new iClient, iOther, iCTeam, Float:vecOrigin[3];
	for( iClient = 1; iClient <= MaxClients; iClient++ )
		if( IsValidClient(iClient) && bClientEnabled[iClient] && !IsFakeClient(iClient) )
			for( iOther = 1; iOther <= MaxClients; iOther++ )
				if( iOther != iClient && nImmunity[iOther] != 1 && IsValidClient(iOther) && IsPlayerAlive(iOther) && TF2_GetPlayerClass(iOther) == TFClass_Spy )
				{
					if( nImmunity[iOther] == -1 )
						nImmunity[iOther] = _:CheckCommandAccess( iOther, "spyvision_immunity", ADMFLAG_ROOT );
					if( nImmunity[iOther] == 1 )
						continue;
					iCTeam = GetClientTeam(iOther);
					GetClientAbsOrigin( iOther, vecOrigin );
					vecOrigin[2] += ( (GetEntityFlags(iOther)&FL_DUCKING) == FL_DUCKING ? 32 : 42 );
					TE_SetupGlowSprite( vecOrigin, nModelIndexes[iCTeam-2], CHECK_DELAY+0.025, 0.875, ( iCTeam == 2 ? 75 : 25 ) );
					TE_SendToClient( iClient, CHECK_DELAY );
				}
}

public OnPlayerActivate( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	if( !IsValidClient(iClient) )
		return;
	bClientEnabled[iClient] = false;
}

public Action:Command_ToggleEffect( iClient, nArgs )
{
	new bool:bHasAccess = ( IsValidClient(iClient) && CheckCommandAccess( iClient, "spyvision_enabled", ADMFLAG_GENERIC ) );
	
	decl String:strCommandName[16];
	GetCmdArg( 0, strCommandName, sizeof(strCommandName) );
	
	if( nArgs == 0 && IsValidClient(iClient) ) 
	{
		if( !bClientEnabled[iClient] && !bHasAccess )
			return Plugin_Continue;
		bClientEnabled[iClient] = !bClientEnabled[iClient];
		PrintMessage( iClient, iClient );
	}
	else if( nArgs == 1 ) 
	{
		decl String:strTargets[64];
		GetCmdArg( 1, strTargets, sizeof(strTargets) );
		
		if( IsCharNumeric(strTargets[0]) )
		{
			if( !IsValidClient(iClient) )
			{
				ReplyToCommand( iClient, "Usage: %s <target> [0/1]", strCommandName );
				return Plugin_Handled;
			}
			
			if( !bClientEnabled[iClient] && !bHasAccess )
				return Plugin_Continue;
			
			bClientEnabled[iClient] = StringToInt(strTargets) != 0;
			PrintMessage( iClient, iClient );
			return Plugin_Handled;
		}
		else if( !bHasAccess )
			return Plugin_Continue;
		
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
			if( IsValidClient( iTargets[i] ) )
			{
				bClientEnabled[iTargets[i]] = !bClientEnabled[iTargets[i]];
				PrintMessage( iClient, iTargets[i] );
			}
	}
	else if( nArgs == 2 )
	{
		if( !bHasAccess )
			return Plugin_Continue;
		
		decl String:strState[2];
		GetCmdArg( 2, strState, sizeof(strState) );
		new bool:bState = StringToInt( strState ) != 0;
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl iTargets[MAXPLAYERS];
		decl nTargets;
		decl bool:tn_is_ml;
		decl String:strTargets[64];
		GetCmdArg( 1, strTargets, sizeof(strTargets) );
		if((nTargets = ProcessTargetString(strTargets, iClient, iTargets, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError( iClient, nTargets );
			return Plugin_Handled;
		}
		for( new i = 0; i < nTargets; i++ )
			if( IsValidClient( iTargets[i] ) )
			{
				bClientEnabled[iTargets[i]] = bState;
				PrintMessage( iClient, iTargets[i] );
			}
	}
	else if( bHasAccess )
		ReplyToCommand( iClient, "Usage: %s [target] [0/1]", strCommandName );
	else if( iClient == 0 )
		ReplyToCommand( iClient, "Usage: %s <target> [0/1]", strCommandName );
	else
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public OnConVarChanged_PluginVersion( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	if( strcmp( strNewValue, PLUGIN_VERSION, false ) != 0 )
		SetConVarString( hConVar, PLUGIN_VERSION, true, true );

public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
	OnConfigsExecuted();

PrintMessage( iAdmin, iTarget )
{
	ShowActivity2( iAdmin, CHAT_TAG, "%sabled Spy-Vision on %N.", bClientEnabled[iTarget] ? "En" : "Dis", iTarget );
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	return IsClientInGame(iClient);
}