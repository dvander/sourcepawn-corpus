/*
*  Written by Drux
*  For support visit the oficial plugin thread:
*  http://forums.alliedmods.net/showthread.php?t=122090
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation,
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#include <sourcemod>

#define IMMUNITY_FLAG    ADMFLAG_RESERVATION
#define UMIN(%1,%2) (%1 < %2 ? %2 : %1)

enum
{
	PUNISHMENT_KICK = 0,
	PUNISHMENT_AUTHBAN,
	PUNISHMENT_IPBAN
};

new Handle:g_hCvarFlux = INVALID_HANDLE;
new Handle:g_hCvarFluxTests = INVALID_HANDLE;
new Handle:g_hCvarLoss = INVALID_HANDLE;
new Handle:g_hCvarLossTests = INVALID_HANDLE;
new Handle:g_hCvarDelayTime = INVALID_HANDLE;
new Handle:g_hCvarCheckFreq = INVALID_HANDLE;
new Handle:g_hCvarPunishment = INVALID_HANDLE;
new Handle:g_hCvarBanTime = INVALID_HANDLE;

new String:g_szName[ MAXPLAYERS+1 ][ MAX_NAME_LENGTH ];
new String:g_szCmdRate[ MAXPLAYERS+1 ][ 32 ];
new g_bConnected[ MAXPLAYERS+1 ];
new g_iFluxCounter[ MAXPLAYERS+1 ];
new g_iLossCounter[ MAXPLAYERS+1 ];
new g_iLastPing[ MAXPLAYERS+1 ];
new g_bImmune[ MAXPLAYERS+1 ];

new String:g_szPluginVersion[ ] = { "0.1.3" };

public Plugin:myinfo = 
{
	name = "Lame Connection Punisher: Source",
	author = "Drux",
	description = "This plugin improves your server's gameplay experience by automatically rejecting clients with 'bad' conections.",
	version = g_szPluginVersion,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	g_hCvarFlux = CreateConVar( "lcp_flux_limit", "100", "Ping fluctuation limit (in ms.)" );
	g_hCvarFluxTests = CreateConVar( "lcp_flux_tests", "12", "Max flux tests before punishment process starts" );
	g_hCvarLoss = CreateConVar( "lcp_loss_limit", "10", "Loss limit (% of packets)" );
	g_hCvarLossTests = CreateConVar( "lcp_loss_tests", "12", "Max loss tests before punishment process starts" );
	g_hCvarDelayTime = CreateConVar( "lcp_delay_time", "20", "Delay time (in seconds) before the punishment process starts" );
	g_hCvarCheckFreq = CreateConVar( "lcp_check_freq", "5", "How often the plugin checks flux & loss" );
	g_hCvarPunishment = CreateConVar( "lcp_punishment", "0", "Punishment method" );
	g_hCvarBanTime = CreateConVar( "lcp_ban_time", "5", "Ban time in minutes (use 0 to permanently ban)" );
	
	HookEvent( "player_spawn", HookPlayerSpawn );
	
	CreateConVar( "sm_lcp_version", g_szPluginVersion, "LCP Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
}

public OnMapStart( )
{
	CreateTimer( GetConVarFloat( g_hCvarDelayTime ), DelayTimer );
}

public OnClientAuthorized( iClient, const String:szAuth[ ] )
{
	CheckFlags( iClient );
}

public OnClientPutInServer( iClient )
{
	GetClientName( iClient, g_szName[ iClient ], sizeof( g_szName[ ] ) - 1 );
	GetClientInfo( iClient, "cl_cmdrate", g_szCmdRate[ iClient ], sizeof( g_szCmdRate[ ] ) - 1 );
	
	CreateTimer( 16.0, ShowJoinMessage, iClient );
}

public OnClientDisconnect( iClient )
{
	g_iFluxCounter[ iClient ] = 0;
	g_iLossCounter[ iClient ] = 0;
	g_iLastPing[ iClient ] = 0;
	g_bImmune[ iClient ] = 0;
	g_bConnected[ iClient ] = false;
}

public OnClientSettingsChanged( iClient )
{
	CheckFlags( iClient );
	
	GetClientInfo( iClient, "cl_cmdrate", g_szCmdRate[ iClient ], sizeof( g_szCmdRate[ ] ) - 1 );
}

public HookPlayerSpawn( Handle:hEvent, const String:szName[ ], bool:bDontBroadcast )
{
	new iClient = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );

	if ( !g_bConnected[ iClient ] && !IsFakeClient( iClient ) )
	{
		g_bConnected[ iClient ] = true;
	}
}

public Action:DelayTimer( Handle:hTimer )
{
	CreateTimer( GetConVarFloat( g_hCvarCheckFreq ), CheckPlayersPing, 0, TIMER_REPEAT );
}

public Action:CheckPlayersPing( Handle:hTimer )
{
	new Float:fPing;
	new iActualPing;
	new Float:fLoss;
	new Float:fTickRate;
	new iPunishment;
	new iCmdRate;
	new iMinutes;
	
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( g_bConnected[ i ] && !g_bImmune[ i ] )
		{
			fLoss = 100.0 * GetClientAvgLoss( i, NetFlow_Both );
			
			fPing = GetClientAvgLatency( i, NetFlow_Outgoing );
			fTickRate = GetTickInterval( );
			iCmdRate = UMIN( StringToInt( g_szCmdRate[ i ] ), 20 );
			fPing -= ( ( 0.5 / iCmdRate ) + ( fTickRate * 1.0 ) );
			fPing -= ( fTickRate / 2.0 );
			fPing *= 1000.0;
			iActualPing = RoundToZero( fPing );
			
			iMinutes = GetConVarInt( g_hCvarBanTime );
			iPunishment = GetConVarInt( g_hCvarPunishment );
			
			if ( fLoss >= GetConVarInt( g_hCvarLoss ) )
			{
				g_iLossCounter[ i ]++;
			}
			else if ( g_iLossCounter[ i ] > 0 )
			{
				g_iLossCounter[ i ]--;
			}
			
			if ( g_iLossCounter[ i ] >= GetConVarInt( g_hCvarLossTests ) )
			{
				switch ( iPunishment )
				{
					case PUNISHMENT_KICK:
					{
						KickClient( i, "Your connection is loosing too many packets." );
						PrintToChatAll( "[SM] %s was kicked for his/her lame connection.", g_szName[ i ] );
						LogMessage( "[SM] %s was kicked for his/her lame connection.", g_szName[ i ] );
                    				}
					case PUNISHMENT_AUTHBAN:
					{
						BanClient( i, iMinutes, BANFLAG_AUTHID, "Your connection is loosing too many packets.", "Your connection is loosing too many packets." );
						
						if ( iMinutes > 0 )
						{
							PrintToChatAll( "[SM] %s was banned %d for his/her lame connection.", g_szName[ i ], iMinutes );
							LogMessage( "[SM] %s was banned %d for his/her lame connection.", g_szName[ i ], iMinutes );
						}
						else
						{
							PrintToChatAll( "[SM] %s was permanently banned for his/her lame connection.", g_szName[ i ] );
							LogMessage( "[SM] %s was permanently banned for his/her lame connection.", g_szName[ i ] );
						}
					}
					case PUNISHMENT_IPBAN:
					{
						BanClient( i, iMinutes, BANFLAG_IP, "Your connection is loosing too many packets.", "Your connection is loosing too many packets." );
						
						if ( iMinutes > 0 )
						{
							PrintToChatAll( "[SM] %s was banned %d minutes for his/her lame connection.", g_szName[ i ], iMinutes );
							LogMessage( "[SM] %s was banned %d minutes for his/her lame connection.", g_szName[ i ], iMinutes );
						}
						else
						{
							PrintToChatAll( "[SM] %s was permanently banned for his/her lame connection.", g_szName[ i ] );
							LogMessage( "[SM] %s was permanently banned for his/her lame connection.", g_szName[ i ] );
						}
					}
				}
			}
			
			if ( Abs( iActualPing - g_iLastPing[ i ] ) > GetConVarInt( g_hCvarFlux ) )
			{
				g_iFluxCounter[ i ]++;
			}
			else if ( g_iFluxCounter[ i ] > 0 )
			{
				g_iFluxCounter[ i ]--;
			}
			
			if ( g_iFluxCounter[ i ] >= GetConVarInt( g_hCvarFluxTests ) )
			{
				switch ( iPunishment )
				{
					case PUNISHMENT_KICK:
					{
						KickClient( i, "Your ping is too unstable." );
						PrintToChatAll( "[SM] %s was kicked for his/her lame connection.", g_szName[ i ] );
						LogMessage( "[SM] %s was kicked for his/her lame connection.", g_szName[ i ] );
					}
					case PUNISHMENT_AUTHBAN:
					{
						BanClient( i, iMinutes, BANFLAG_AUTHID, "Your ping is too unstable.", "Your ping is too unstable." );
						
						if ( iMinutes > 0 )
						{
							PrintToChatAll( "[SM] %s was banned %d minutes for his/her lame connection.", g_szName[ i ], iMinutes );
							LogMessage( "[SM] %s was banned %d minutes for his/her lame connection.", g_szName[ i ], iMinutes );
						}
						else
						{
							PrintToChatAll( "[SM] %s was permanently banned for his/her lame connection.", g_szName[ i ] );
							LogMessage( "[SM] %s was permanently banned for his/her lame connection.", g_szName[ i ] );
						}
					}
					case PUNISHMENT_IPBAN:
					{
						BanClient( i, iMinutes, BANFLAG_IP, "Your ping is too unstable.", "Your ping is too unstable." );
						
						if ( iMinutes > 0 )
						{
							PrintToChatAll( "[SM] %s was banned %d minutes for his/her lame connection.", g_szName[ i ], iMinutes );
							LogMessage( "[SM] %s was banned %d minutes for his/her lame connection.", g_szName[ i ], iMinutes );
						}
						else
						{
							PrintToChatAll( "[SM] %s was permanently banned for his/her lame connection.", g_szName[ i ] );
							LogMessage( "[SM] %s was permanently banned for his/her lame connection.", g_szName[ i ] );
						}
					}
				}
			}
			
			g_iLastPing[ i ] = iActualPing;
		}
	}
}
		
public Action:ShowJoinMessage( Handle:hTimer, any:iClient )
{
	if ( g_bConnected[ iClient ] )
	{
		PrintToChat( iClient, "[SM] Players with a lame connection will be punished (ping flux limit: %d, loss limit: %d).", GetConVarInt( g_hCvarFlux ), GetConVarInt( g_hCvarLoss ) );
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
	
CheckFlags( iClient )
{
	g_bImmune[ iClient ] = GetUserFlagBits( iClient ) & IMMUNITY_FLAG;
}

Abs( iNum )
{
	return iNum > 0 ? iNum : -iNum;
}
