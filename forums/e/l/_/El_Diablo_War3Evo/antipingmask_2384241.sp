/**
 * antipingmask.sp
 * =============================================================================
 * Anti-Ping Mask Plugin
 * Auto-kicks players who are using a known exploit to mask their ping.
 *
 * Anti-Ping Mask (C)2009 atom0s  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

 /*
  * Change Log
  * -----------------------------------
  * v1.6.1
  * - This version does not kick or ban, but actually shows the player's real ping on the server.
  *
  * v1.6.0
  * - Fixed version CVAR as requested by plugin approver.
  * - Added Russian translation. "ru" (Thanks to exvel.)
  *
  * v1.5.0
  * - Added Polish translation. "pl" (Thanks to Zuko.)
  * - Added Danish translation. "dk" (Thanks to Da BuzZ : "OLLI, QUIT WOW NOW")
  * - Added German translation. "de" (Thanks to Abus3.)
  * - Added Japanese translation. "jp" (Thanks to Sakuri.) (In Romanji to ensure character visibility.)
  * - Added Norwegian translation. "no" (Thanks to olli : "Quit whining Da_BuzZ")
  * - Added handler for OnPluginEnd to close timer manually. (Crash reports.)
  * - Added handler for OnMapEnd to close timer per-map. (Crash reports.) (Possible lag report fix.)
  * - Added pragma for semicolon enforcement.
  * - Changed KillTimer to CloseHandle inside of TimerIntervalChanged.
  * - Fixed spelling of TimerIntervalChanged. (Whoops lol..)
  * - Fixed case-sensitive issue with plugin info structure.
  *
  * v1.4.0
  * - Removed hander for forcing rate changes on a client. (No use as Valve patched it.)
  * - Removed extra debug message that was left behind in a previous version.
  * - Removed extra messages from the phrase file.
  *
  * v1.3.0
  * - Removed additional cmdrate checking against server min/max values. (Due to false-positive kicking.)
  *
  * v1.2.0
  * - Added SourceBan support.
  * - Removed extra zero from version number.
  *
  * v1.1.0.0
  * - Added new CVARs for additional options.
  * - Fixed regex expression to determine invalid command rates.
  * - Added checks against the servers min/max cmd rate. (Thanks for the suggestion meng.)
  * - Added ability to ban players on invalid rate.
  * - Added ability to force rate setting on invalid clients. (Thanks for the suggestion bman87.)
  * - Fixed onfusion with IsValidCmdRate command.
  *
  */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <regex>

/**
* Current Plugin Version
*/
#define PLUGIN_VERSION "1.6.1" //1.6.0

/**
* General Definitions
*/
#define COLOR_DEFAULT 			0x01
#define COLOR_GREEN 				0x04
#define DEFAULT_TIMER_FLAGS 	TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE

bool ForcePing[34];

/**
* Plugin Information Array
*/
public Plugin:myinfo = {
	name 			= "Anti-Ping Mask",
	author 		= "atom0s & ElDiabloWar3Evo",
	description 	= "Prevents ping masking via cl_cmdrate exploit.",
	version 		= PLUGIN_VERSION,
	url 			= "N/A"
};

/**
 *  Handles
 */
new Handle:t_TimerHandle 			= INVALID_HANDLE;
new Handle:g_Cvar_TimerInterval 	= INVALID_HANDLE;

/**
* OnEvent Handlers
*/

public OnPluginStart( )
{
	/* Create version CVAR. */
	CreateConVar( "antipingmask_version", PLUGIN_VERSION, "Anti-Ping Mask Version Number", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );

	/* Create handler CVARs. */
	g_Cvar_TimerInterval 	= CreateConVar( "apm_timerinterval", "15", "The interval time, in seconds, that the timer should tick at to check for ping masking clients.", 0 );

	/* Hook Anti-Ping Mask timer CVAR. */
	HookConVarChange( g_Cvar_TimerInterval, TimerIntervalChanged );
}

public OnPluginEnd( )
{
	/* Kill ping mask check timer. */
	if( t_TimerHandle != INVALID_HANDLE )
	{
		CloseHandle( t_TimerHandle );
		t_TimerHandle = INVALID_HANDLE;
	}
}

public OnMapStart( )
{
	/* Start ping mask check timer. */
	t_TimerHandle = CreateTimer( GetConVarFloat( g_Cvar_TimerInterval ), Timer_CheckAntiPingMask, _, DEFAULT_TIMER_FLAGS );
}

public OnMapEnd( )
{
	/* Kill ping mask check timer. */
	if( t_TimerHandle != INVALID_HANDLE )
	{
		CloseHandle( t_TimerHandle );
		t_TimerHandle = INVALID_HANDLE;
	}
}

public OnClientAuthorized( client, const String:auth[] )
{
	ForcePing[client]=false;
	CheckPingMasked( client );
}

public OnClientDisconnect_Post(client)
{
	ForcePing[client]=false;
}

/**
 * CVAR Change Callbacks
 */
public TimerIntervalChanged( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	new Float:fOldValue, Float:fNewValue;

	fOldValue = StringToFloat( oldValue );
	fNewValue = StringToFloat( newValue );

	/* Ensure a change was made. */
	if( fOldValue == fNewValue )
		return;

	/* Ensure we have a valid interval. */
	if( fNewValue <= 0 )
		fNewValue = 15.0;

	/* Kill our scan timer. */
	CloseHandle( t_TimerHandle );
	t_TimerHandle = INVALID_HANDLE;

	/* Restart timer with new interval */
	t_TimerHandle = CreateTimer( fNewValue, Timer_CheckAntiPingMask, _, DEFAULT_TIMER_FLAGS );
}


/**
* Anti-Ping Mask Timer
*/
public Action:Timer_CheckAntiPingMask( Handle:Timer )
{
	/* Loop the client connections and check for masks. */
	new _maxClients = GetMaxClients( );
	for( new i = 1; i < _maxClients; i++ ) {
		CheckPingMasked( i );
	}

	return Plugin_Continue;
}

/**
 * Determines if the given command rate has invalid
 * characters other then numbers via a regular expression.
 *
 * @param CmdRate 		The current clients command rate.
 * @return 				True if command rate is valid, false otherwise.
 */
bool:IsValidCmdRate( String:CmdRate[] )
{
	/* Check command rate for invalid characters. */
	// old version:
	//new nMatches = SimpleRegexMatch( CmdRate, "[^\\d\\s\\.]+" );
	//if( nMatches >= 1 )
		//return false;
	//return true;
	// new version:
	int nMatches = SimpleRegexMatch( CmdRate, "[^0-9.]" );
	if (nMatches == 0 && StringToInt(CmdRate) >= 30) {
		return true;
	}
	else {
		return false;
	}
}

/**
 * Checks the given clients cl_cmdrate for invalid characters
 * which are used to mask pings.
 *
 * @param client 		The client number to check.
 * @noreturn
 */
CheckPingMasked( client )
{
	/* Ensure we are a valid client and are connected. */
	if( !IsClientConnected( client ) || !IsClientInGame( client ) || IsFakeClient( client ) )
	{
		ForcePing[client]=false;
		return;
	}

	/* Get clients command rate. */
	char cmdRate[ 32 ];
	GetClientInfo( client, "cl_cmdrate", cmdRate, sizeof( cmdRate ) );

	/* Ensure that the rate does not contain invalid characters. */
	if( ! IsValidCmdRate( cmdRate ) )
	{
		/* Determine how we should handle a ping masked client. */

		ForcePing[client]=true;
	}
}

stock ClientPing( iClient )
{
	if( iClient <= 0 || iClient > MaxClients || !IsClientInGame( iClient ) )
		return ;

	new iResEnt = GetPlayerResourceEntity();
	if( iResEnt == INVALID_ENT_REFERENCE )
		return;

	int iLatency = RoundToNearest(GetClientAvgLatency(iClient, NetFlow_Outgoing) * 1000.0);
	SetEntProp( iResEnt, Prop_Send, "m_iPing", iLatency, _, iClient );
}

public OnGameFrame()
{
	for (int x=1; x<=MaxClients; x++)
	{
		if(!ForcePing[x])
			continue;

		ClientPing( x );
	}
}
