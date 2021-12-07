/*
==============================
ZOMBIE PANIC! SOURCE - ROUND WARM UP
Coded by Shepard62700FR (~*L-M*~ -/TFH\- Shepard)
Idea by ~*L-M*~ L0chness
Thanks to exvel and XARIUS
==============================
*/

#include <colors>
#include <sdktools>
#include <sourcemod>

// Variable which pickup CVARs value
new bEnableFFAfterWarmUp;
new bEnableFFWhileWarmUp;
new iCount;

// CVARs and timer handles
new Handle:bCVAR_FF_After_WarmUp = INVALID_HANDLE;
new Handle:bCVAR_FF_While_WarmUp = INVALID_HANDLE;
new Handle:iCVAR_WarmUp_Time = INVALID_HANDLE;
new Handle:Handler_WarmUp_Countdown = INVALID_HANDLE;
new Handle:Handler_ResetPlayersScores_Countdown = INVALID_HANDLE;

// Scores reset
new iMaxClients;
new iResetPlayersScoresCount = 3;
// BUGFIX => Infection offset
new sInfectedOffset;

//====================
//Plugin:myinfo - Plugin's information
//====================

public Plugin:myinfo =
{
	name = "[ZPS] Warm Up",
	author = "Shepard62700FR",
	description = "Setup a warm up round to wait for late joiners.",
	version = "1.0.0.1",
	url = "http://www.sourcemod.net"
}

//====================
//OnPluginStart - Prepare the plugin to do it's job =)
//====================

public OnPluginStart()
{
	// Are we running this plugin under ZPS?
	decl String:GameName[32];
	GetGameFolderName( GameName, sizeof( GameName ) );

	if ( !StrEqual( GameName, "zps" ) )
		SetFailState( "[ZPS Warm Up] This plugin is for Zombie Panic! Source only!" );
	else
	{
		// BUGFIX => Find the infection offset
		sInfectedOffset = FindSendPropOffs( "CHL2MP_Player", "m_IsInfected" );

		// Plugin's CVARs
		bCVAR_FF_After_WarmUp = CreateConVar( "sm_zps_warmup_after_ff", "0", "Activate the friendly fire once the warm up round is over", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
		bCVAR_FF_While_WarmUp = CreateConVar( "sm_zps_warmup_while_ff", "0", "Activate the friendly fire during the warm up round", FCVAR_PLUGIN, true, 0.0, true, 1.0 );
		iCVAR_WarmUp_Time = CreateConVar( "sm_zps_warmup_time", "90", "Duration of the warm up round (90 seconds is recommended)", FCVAR_PLUGIN, true, 0.0, true, 300.0 );

		// Hook changes of CVARs
		HookConVarChange( bCVAR_FF_After_WarmUp, OnCVARChange );
		HookConVarChange( bCVAR_FF_While_WarmUp, OnCVARChange );
		HookConVarChange( iCVAR_WarmUp_Time, OnCVARChange );

		// If there is already a timer, kill it
		if ( Handler_WarmUp_Countdown != INVALID_HANDLE )
			KillTimer( Handler_WarmUp_Countdown );

		if ( Handler_ResetPlayersScores_Countdown != INVALID_HANDLE )
			KillTimer( Handler_ResetPlayersScores_Countdown );

		// Execute the plugin's configuration
		AutoExecConfig( true, "zps_warmup" );
		// Load the translations
		LoadTranslations( "zps_warmup.phrases" );
	}
}

//====================
//OnConfigsExecuted - Load the configuration and set up the plugin to server's admin needs
//====================

public OnConfigsExecuted()
{
	bEnableFFAfterWarmUp = GetConVarBool( bCVAR_FF_After_WarmUp );
	bEnableFFWhileWarmUp = GetConVarBool( bCVAR_FF_While_WarmUp );
	iCount = GetConVarInt( iCVAR_WarmUp_Time );
}

//====================
//OnCVARChange - Same as OnConfigsExecuted but when server's admin is changing CVARs values "on-the-fly"
//====================

public OnCVARChange( Handle:convar_hndl, const String:oldValue[], const String:newValue[] )
{
	bEnableFFAfterWarmUp = GetConVarBool( bCVAR_FF_After_WarmUp );
	bEnableFFWhileWarmUp = GetConVarBool( bCVAR_FF_While_WarmUp );
	iCount = GetConVarInt( iCVAR_WarmUp_Time );
}

//====================
//OnMapStart - Server has loaded the map
//====================

public OnMapStart()
{
	// Manages the sounds
	AddFileToDownloadsTable( "sound/warmup_beep.wav" );
	AddFileToDownloadsTable( "sound/warmup_finished.wav" );
	PrecacheSound( "warmup_beep.wav", true );
	PrecacheSound( "warmup_finished.wav", true );

	// Enable the FF if wished
	if ( bEnableFFWhileWarmUp )
		ServerCommand( "mp_friendlyfire 1;sv_testmode 1" );
	else
		ServerCommand( "mp_friendlyfire 0;sv_testmode 1" );

	// Warm up time =)
	Handler_WarmUp_Countdown = CreateTimer( 1.0, WarmUp_Countdown, _, TIMER_REPEAT );
}

//====================
//WarmUp_Countdown - Warm up's core
//====================

public Action:WarmUp_Countdown( Handle:timer )
{
	// Warm up is not over yet
	if ( iCount >= 1 )
	{
		// Show the message
		PrintCenterTextAll( "%t", "WarmUp_Countdown", iCount );
		// Blip sound when 10 seconds left
		if ( iCount <= 10 )
			EmitSoundToAll( "warmup_beep.wav" );

		// Reset frags and death scores
		for ( new i=1 ; i <= iMaxClients ; i++ )
		{
			// BUG => Values can't be changed if player is dead, otherwise server crash
			if ( IsClientInGame( i ) && IsPlayerAlive( i ) )
			{
				SetEntProp( i, Prop_Data, "m_iFrags", 0 );
				SetEntProp( i, Prop_Data, "m_iDeaths", 0 );
				// BUGFIX => Infection and spawning problem
				SetEntData( i, sInfectedOffset, 0 );
			}
		}

		// Decrease the countdown of 1 second
		iCount--;
	}
	// Warm up is finished
	else
	{
		// Reset the countdown to it's default
		iCount = GetConVarInt( iCVAR_WarmUp_Time );
		// Finished sound
		EmitSoundToAll( "warmup_finished.wav" );
		// Show that the warmup has ended
		CPrintToChatAll( "{green}[ZPS Warm Up] {default}%t", "WarmUp_Finished" );

		// Reset frags and death scores
		for ( new i=1 ; i <= iMaxClients ; i++ )
		{
			// BUG => Values can't be changed if player is dead, otherwise server crash
			if ( IsClientInGame( i ) && IsPlayerAlive( i ) )
			{
				SetEntProp( i, Prop_Data, "m_iFrags", 0 );
				SetEntProp( i, Prop_Data, "m_iDeaths", 0 );
				// BUGFIX => Infection and spawning problem
				SetEntData( i, sInfectedOffset, 0 );
			}
		}

		// Let the FF on if wished, otherwise turn it off and set everything back to normal
		if ( bEnableFFAfterWarmUp )
			ServerCommand( "mp_friendlyfire 1;sv_testmode 0" );
		else
			ServerCommand( "mp_friendlyfire 0;sv_testmode 0" );

		// Kill the timer and tell the plugin and activate the timer to reset the score
		Handler_WarmUp_Countdown = INVALID_HANDLE;
		Handler_ResetPlayersScores_Countdown = CreateTimer( 1.0, ResetPlayersScores_Countdown, _, TIMER_REPEAT );
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

//====================
//ResetPlayersScores_Countdown - Reset players frags and deaths values
//====================

public Action:ResetPlayersScores_Countdown( Handle:timer )
{
	// Wait 3 seconds before scores get reset to 0
	if ( iResetPlayersScoresCount >= 1 )
	{
		CPrintToChatAll( "{green}[ZPS Warm Up] {default}%t", "Resetting_Scores", iResetPlayersScoresCount );
		iResetPlayersScoresCount--;
	}
	else
	{
		iResetPlayersScoresCount = 3;
		iMaxClients = GetMaxClients();
		// Reset frags and death scores
		for ( new i=1 ; i <= iMaxClients ; i++ )
		{
			// BUG => Values can't be changed if player is dead, otherwise server crash
			if ( IsClientInGame( i ) && IsPlayerAlive( i ) )
			{
				SetEntProp( i, Prop_Data, "m_iFrags", 0 );
				SetEntProp( i, Prop_Data, "m_iDeaths", 0 );
				// BUGFIX => Infection and spawning problem
				SetEntData( i, sInfectedOffset, 0 );
			}
		}
		CPrintToChatAll( "{green}[ZPS Warm Up] {default}%t", "Reset_of_Scores" );
		Handler_ResetPlayersScores_Countdown = INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}