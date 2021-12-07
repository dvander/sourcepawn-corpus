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
  *
  * v1.7.0 by kroleg
  * - Removed timer thingy
  * - Removed REGX dependency
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

#define PLUGIN_VERSION "1.7.0"

#define COLOR_DEFAULT 			0x01
#define COLOR_GREEN			0x04

public Plugin:myinfo = {
	name = "Anti-Ping Mask",
	author = "atom0s, mod by kroleg",
	description = "Prevents ping masking via cl_cmdrate exploit.",
	version = PLUGIN_VERSION,
	url = "http://tf2.kz"
};

new Handle:g_Cvar_Handler			= INVALID_HANDLE;
new Handle:g_Cvar_BanLength 		= INVALID_HANDLE;

public OnPluginStart( )
{
	/* Load our translations. */
	LoadTranslations( "antipingmask.phrases" );
	
	/* Create version CVAR. */
	CreateConVar( "antipingmask_version", PLUGIN_VERSION, "Anti-Ping Mask Version Number", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	/* Create handler CVARs. */
	g_Cvar_Handler 			= CreateConVar( "apm_handler", "0", "Determines how Anti-Ping Mask should handle ping masked clients.", 0, true, 0.0, true, 2.0 );
	g_Cvar_BanLength 		= CreateConVar( "apm_banlength", "30", "The length in minutes that a player is banned for ping masking.", 0 );

	//HookConVarChange( g_Cvar_TimerInterval, TimerIntervalChanged );
}

public OnClientSettingsChanged(client) {
	if (IsClientInGame(client) && GetClientTeam(client))
	{
		//new Check = GetConVarInt(sm_rate_check);
		//if (Check & 2) 
		CheckPingMasked(client);
	}
}

public OnClientPostAdminCheck(client){
	CheckPingMasked(client);
}


/**
 * Determines if the given command rate has invalid
 * characters other then numbers via a regular expression.
 *
 * @param CmdRate 		The current clients command rate.
 * @return 				True if command rate is valid, false otherwise.
 */
bool:IsValidCmdRate(String:CmdRate[]){
	/* Check command rate for invalid characters. */
	new len = strlen(CmdRate);
	for (new i=0;i<len;i++)
		if (!IsCharNumeric(CmdRate[i]))
			return false;
/*	new nMatches = SimpleRegexMatch( CmdRate, "[^\\d\\s\\.]+" );
	if( nMatches >= 1 )
		return false;*/
	return true;
}

/**
 * Checks the given clients cl_cmdrate for invalid characters
 * which are used to mask pings.
 *
 * @param client 		The client number to check.
 * @noreturn
 */
CheckPingMasked(client){
	/* Ensure we are a valid client and are connected. */
	if(!IsClientInGame( client ) || IsFakeClient( client ) )
		return;
	
	/* Get clients command rate. */
	decl String:cmdRate[ 32 ];
	GetClientInfo( client, "cl_cmdrate", cmdRate, sizeof( cmdRate ) );
	
	/* Ensure that the rate does not contain invalid characters. */
	if( ! IsValidCmdRate( cmdRate ) )
	{
		/* Get client name before kick. */
		decl String:cl_Name[ 64 ];
		GetClientName( client, cl_Name, sizeof( cl_Name ) );
		
		/* Determine how we should handle a ping masked client. */
		switch( GetConVarInt( g_Cvar_Handler ) )
		{
			case 0: // Kick Client
			{
				/* Player is ping masking, kick them. */
				KickClient( client, "%t", "Kicked By Rate" );
				
				/* Announce that player was kicked for ping masking. */
				PrintToChatAll( "%c[Anti-Ping Mask]%c %s %t", COLOR_GREEN, COLOR_DEFAULT, cl_Name, "Player Kicked By Rate" );
			}
			
			case 1: // Ban Client
			{
				/* Create translated ban message. */
				decl String:cl_BanMessage[ 255 ];
				Format( cl_BanMessage, sizeof( cl_BanMessage ), "%t", "Banned For Ping Mask" );
				
				/* Determine if SourceBans is found on this server. */
				new Handle:g_Cvar_SourceBans = FindConVar( "sb_version" );
				if( g_Cvar_SourceBans != INVALID_HANDLE )
				{
					/* Use SourceBans system. */
					ServerCommand( "sm_ban #%d %d \"%s\"", GetClientUserId( client ), GetConVarInt( g_Cvar_BanLength ), cl_BanMessage );
					CloseHandle( g_Cvar_SourceBans );
				}
				else
				{
					/* Use the normal ban system. */
					BanClient( client, GetConVarInt( g_Cvar_BanLength ), BANFLAG_AUTO, cl_BanMessage, cl_BanMessage, "CheckPingMasked", client );
				}
				
				/* Announce that player was banned for ping masking. */
				PrintToChatAll( "%c[Anti-Ping Mask]%c %s %t", COLOR_GREEN, COLOR_DEFAULT, cl_Name, "Player Banned By Rate" );
			}
		}
		
	}
}
