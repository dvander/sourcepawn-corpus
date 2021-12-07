/*
* CHANGELOG:
* 1.0 - 
* 		First Release
* 
* 1.1 -
* 		Added Cvar to Control Round Ending.
* 		Added Cvar to Remove Objectives.
* 		Code Optimizations.
* 		Renamed to Respawn Management
* 
* 1.2 -
* 		Added extra checks: OnClientDisconnect and PostAdminCheck.
* 		Ordered Code a bit more.
* 		Using correct round end conditions now.
* 		Added method to detect servers runnuing plugin.
* 		Fixed Bug where clients would not respawn correct amount of times next round.
* 		Tag Changed to "rsm" to avoid same tag as another plugin.
* 
* 1.3 -
* 		Fixed a problem with new players not respawning when rsm_noend "1"
* 		Fixed possible round ending on client disconnect if rsm_noend "1"
* 		Fixed an issue where a spectator would respawn.
* 		Fixed errors being thrown in logs.
* 		Hook Convar Changes, Note: If you wish to change rsm_noend or rsm_noobjectives to "0" you will have to restart map.
* 		Unhooking Events on Plugin End.
* 
* 1.4 - 
* 		Improved WinConditions Logic.
* 		Using a more efficient stock (Thanks thetwistedpanda)
* 		Added cvar to control information messages. (rsm_messages "1")
* 
* 1.5 -	
* 		Fixed WinConditions after 1.4 Update.
* 		Fixed Messages Cvar.
* 		Fixed CT winning after killing all Terrorists with bomb ticking.
* 
* 1.6 -
* 		Fixed a bug where a player would not respawn on first join.
* 		Added an extra check to WinConditions.
* 
* 		Redone WinConditions actions.
* 
* 1.7 -
* 		Fixed Hostages rescued event.
* 
* 1.8 - 
* 		Fixed Missing Bracket.
* 
* 1.9 - 
* 		Added Spawn Protection (Can be toggled on/off using rsm_spawnprotect "0|1" and protection time controlled by rsm_spawnprotect_time "10")
*|||||||||||||||||||||||||||||||||||||||||||NOTE: Spawn Protection Only takes effect after the player has been respawned and not on Round Start! 
* 		Added VIP Killed/Escaped Events.
* 		Minor code improvements.
* 
* 2.0 - 
* 		Cleaned up code, arguments etc. (Thanks RedSword)
* 		Removed UnHooking of Events on Round End. (Thanks RedSword)
* 		Removed Convar Hooking (Makes things cleaner & more stable) - You must now restart map or server after changing convars.
* 		Replaced FCVAR_REPLICATED with FCVAR_DONTRECORD (Thanks RedSword)
* 		Improved Code Logic to avoid even more possible mishaps.
* 		Added Cvar to Control Round Restart Delay after round ends (rsm_round_restart_delay 5.0) (Thanks RedSword)
* 		Removed some redundant code.
* 
* 2.1 - 
* 		Cleaned up more code.
* 		Removed some more redundant code.
* 		Fixed Clients being able to respawn when they shouldn't! 
* 		Fixed bug where round would not end in some cases.
*  		Fixed Hooks. (Thanks RedSword)
* 		Fixed Timers. (Thanks RedSword)
* 		Improved Code Logic some more to avoid more possible mishaps.
* 		Spawn protected players now render.
* 2.2 - 
* 		More code cleanup.
* 		Removed an unnecessary boolean.
* 
* 2.3 - 
* 		Improved HandleStuff Function by shortening the code. (Thanks RedSword)
* 		Merged getting alive players and total players into one stock. (Thanks RedSword)
* 		Improved messaging upon death.
* 
* 2.4 - 
* 		Fixed a forgotten Timer. (I Don't know how I overlooked that one..)
* 
* CREDITS:
* 		Doc-Holiday - Objectives Remover.
* 		thetwistedpanda - Stock to count Teams.
* 		All others that have helped me out with code in scripting forums.
*/

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "2.4"

new Handle: rsmClientTotalLives = INVALID_HANDLE // Total Client Lives Convar
new Handle: rsmClientRespawnDelay = INVALID_HANDLE // Client Respawn Delay Convar
new Handle: rsmNoRoundEnd = INVALID_HANDLE // Round End Disable Convar
new Handle: rsmRemoveObjectives = INVALID_HANDLE // Objectives Removal Covar
new Handle: rsmClientRespawnMessages = INVALID_HANDLE // Client Respawn Messages Convar
new Handle: rsmClientSpawnProtection = INVALID_HANDLE // Client Protection Covar
new Handle: rsmClientSpawnProtectionTime = INVALID_HANDLE // Client Protection Time Convar
new Handle: rsmRoundRestartDelay = INVALID_HANDLE // Time till round restarts after a team win.
new Handle: cookieClientDead // To make clients can't rejoin and spawn again in same round.

new bool: isClientRespawning [ MAXPLAYERS+1 ] // To prevent WinConditions from executing if somebody is Respawning.
new bool: isClientProtected [ MAXPLAYERS+1 ] // Is the client protected?
new bool: isClientDead [ MAXPLAYERS+1 ] // Is the client dead?

new isBombTicking // Has the bomb been planted?
new isRoundEnd // Is it the end of the round?
new noRoundEnd // Do we have no round ending enabled?
new noObjectives // Do we have Obectives removed?

new clientTotalLives // How many lives do client have in total?
new clientLivesRemaining [ MAXPLAYERS+1 ] // How many lives does the client have remaining?
new clientRespawnMessages // Should we disable client respawn messages?
new clientSpawnProtection // Do we protect the clients?

new Float: clientSpawnProtectionTime // Ho w long should we spawn protect clients for?
new Float: clientRespawnDelay // How long until a client respawns?
new Float: roundRestartDelay // How long till round restarts after a team wins?

new iHostagesCountOnMapLoad, iHostagesCount // Hostage Counter.
new iRemainingT, iRemainingCT, iTotalT, iTotalCT // The remaining and total team players.

public Plugin:myinfo = {
	
	name = "Respawn Management",
	author = "xCoderx",
	description = "Provides options to remove map objectives, set amount of respawns players gets and more.",
	version = PLUGIN_VERSION,
	url = "https://www.fragcore.com"
}

public OnPluginStart ( ) {
	
	CreateConVar ( "rsm_version", PLUGIN_VERSION, "Respawn Management", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY ) 
	
	// Total Client Lives ( Including first ) 3 = 2 Respawns 4 = 3 Respawns etc..
	rsmClientTotalLives = CreateConVar ( "rsm_lives", "3", "Player Respawns" ) 
	
	// Delay before respawning player.
	rsmClientRespawnDelay = CreateConVar ( "rsm_respawn_delay", "3", "Respawn Delay" )  
	
	// Delay before respawning player.
	rsmRoundRestartDelay = CreateConVar ( "rsm_round_restart_delay", "5.0", "Round Restart Delay" )  
	
	// If set 1 round will never end, players will always respawn and ojectives will be removed.
	rsmNoRoundEnd = CreateConVar ( "rsm_noend", "0", "No Round Ending." ) 
	
	// If set 1 there will be no Objectives.
	rsmRemoveObjectives = CreateConVar ( "rsm_remove_objectives", "0", "Remove Objectives" )  
	
	// If set 0 there will be no messages telling players of remaining lives.
	rsmClientRespawnMessages = CreateConVar ( "rsm_messages", "1", "Client Respawn Messages" )  
	
	// If set 0 there will be no spawn protection for clients.
	rsmClientSpawnProtection = CreateConVar ( "rsm_spawnprotect", "1", "Toggles Spawn Protect On/Off." )  
	
	// This is how long the player is spawn protected for.
	rsmClientSpawnProtectionTime = CreateConVar ( "rsm_spawnprotect_time", "10", "Spawn Protection Time." )  
	
	cookieClientDead = RegClientCookie ( "RSMClientDead", "RSM Client Dead", CookieAccess_Protected ) 
	
	// Event Hooks
	HookEvent ( "player_death", Event_PlayerDeath ) 
	HookEvent ( "round_end", Event_RoundEnd ) 
	HookEvent ( "round_start", Event_RoundStart ) 
	HookEvent ( "item_pickup", OnItemPickUp ) 
	
	// Objectives Hooks
	HookEvent ( "bomb_planted", Event_BombPlanted ) 
	HookEvent ( "bomb_defused", Event_BombDefused ) 
	HookEvent ( "bomb_exploded", Event_BombExploded ) 
	HookEvent ( "hostage_rescued", Event_HostageRescued ) 
	HookEvent ( "hostage_killed", Event_HostageKilled ) 
	HookEvent ( "vip_escaped", Event_VipEscaped ) 
	HookEvent ( "vip_killed", Event_VipKilled ) 
	
	AddCommandListener ( Command_JoinTeam, "jointeam" ) 
}

public OnConfigsExecuted ( ) {
	
	HandleStuff ( ) 
}

public OnMapStart ( ) {
	
	if ( GetConVarInt ( rsmRemoveObjectives ) == 0 && GetConVarInt ( rsmNoRoundEnd ) == 0 ) {
		
		HostCount ( ) 
	}
	
	else {
		
		RemoveObjectives ( ) 
	}
}

public HandleStuff ( ) {
	
	clientRespawnMessages = GetConVarInt ( rsmClientRespawnMessages ) >= 1
	clientSpawnProtection = GetConVarInt ( rsmClientSpawnProtection ) >= 1
	noRoundEnd = GetConVarInt ( rsmNoRoundEnd ) >= 1	
	noObjectives = GetConVarInt ( rsmRemoveObjectives ) >= 1
	
	clientTotalLives = GetConVarInt ( rsmClientTotalLives ) 
	clientRespawnDelay = GetConVarFloat ( rsmClientRespawnDelay ) 
	clientSpawnProtectionTime = GetConVarFloat ( rsmClientSpawnProtectionTime ) 
	roundRestartDelay = GetConVarFloat ( rsmRoundRestartDelay ) 
	
	ServerCommand ( "mp_ignore_round_win_conditions 1" ) 
}

public OnClientPostAdminCheck ( client ) {
	
	if ( Client_IsValid ( client ) ) {
		if ( AreClientCookiesCached ( client ) ) {
			
			new Handle:clientDead = FindClientCookie ( "RSMClientDead" ) 
			
			if ( clientDead != INVALID_HANDLE ) {
				
				new String:value [ 12 ]
				GetClientCookie ( client, clientDead, value, sizeof ( value ) ) 
				
				if ( StrEqual ( value, "true" ) ) {
					
					clientLivesRemaining [ client ] = 0
					isClientDead [ client ] = true
				}
				
				if ( StrEqual ( value, "false" ) ) {
					
					clientLivesRemaining [ client ] = clientTotalLives
					isClientDead [ client ] = false
				}
				
				if ( noRoundEnd ) {
					
					isClientDead [ client ] = false
				}
				
			}
		}
	}
	
	if ( ! noRoundEnd ) {
		
		WinConditions ( ) 
	}
}

public Action:Command_JoinTeam ( client, const String:command [  ], argc ) {
	
	if ( Client_IsValid ( client ) ) {
		
		if ( GetClientTeam ( client ) != CS_TEAM_SPECTATOR ) {
			
			if ( clientLivesRemaining [ client ] << 1 ) {
				
				if ( IsPlayerAlive ( client ) ) {
					
					ForcePlayerSuicide ( client ) 
					isClientDead [ client ] = true
				}
			}
		}
		if ( noRoundEnd ) {
			
			isClientDead [ client ] = false
		}
		
	}
	
	WinConditions ( ) 
	
	return Plugin_Continue
}

public OnClientDisconnect ( client ) {
	
	if ( ! isRoundEnd && ! noRoundEnd ) {
		
		WinConditions ( ) 
	}
	
	new String:authid [ 64 ]
	GetClientAuthString ( client, authid, sizeof ( authid ) ) 
	SetAuthIdCookie ( authid, cookieClientDead, "true" ) 
}

public Event_RoundStart ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	isRoundEnd = false
	isBombTicking = false
	
	if ( noObjectives || noRoundEnd ) {
		
		RemoveObjectives ( ) 
	}
	
	else {
		
		iHostagesCount = iHostagesCountOnMapLoad
	}
	
	for ( new client = 1; client <= MaxClients; client++ ) 
		
	if ( Client_IsValid ( client ) ) {
		
		clientLivesRemaining [ client ] = clientTotalLives
		
		isClientDead [ client ] = false
		
		new String:authid [ 64 ]
		GetClientAuthString ( client, authid, sizeof ( authid ) ) 
		SetAuthIdCookie ( authid, cookieClientDead, "false" ) 
	}
}

public Event_PlayerDeath ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	new client = GetClientOfUserId ( GetEventInt ( event,"userid" ) ) 
	clientRespawnDelay = GetConVarFloat ( rsmClientRespawnDelay ) 
	
	if ( Client_IsValid ( client ) ) {
		
		new String:playername [ 32 ]
		GetClientName ( client, playername, sizeof ( playername ) ) 
		
		clientLivesRemaining [ client ]--
		
		if ( ! noRoundEnd ) {
			
			if ( clientLivesRemaining [ client ] > 0 ) {
				
				CreateTimer ( clientRespawnDelay, RespawnClient, GetClientUserId ( client ) ) 
				isClientRespawning [ client ] = true
				
				if ( clientRespawnMessages ) {
					
					if ( clientLivesRemaining [ client ] > 1 ) {
						
						PrintToChat ( client, "\x04%s, \x03You have \x04[%d] \x03lives remaining! ", playername, clientLivesRemaining [ client ] )
					}
					
					else if ( clientLivesRemaining [ client ] == 1 ) {
						
						PrintToChat ( client, "\x04%s, \x03You have \x04[%d] \x03life remaining! ", playername, clientLivesRemaining [ client ] )
						PrintToChat ( client, "\x04Be careful\x03, after this life it's all over! " ) 
					}
				}
			}
			
			
			if ( clientLivesRemaining [ client ] == 0 ) {
				
				if ( clientRespawnMessages ) {
					
					PrintToChat ( client, "\x03You are now \x04dead\x03, please wait until \x04next round\x03." ) 
				}
				
				isClientRespawning [ client ] = false 
				isClientDead [ client ] = true
			}
			
			if ( ! isClientRespawning [ client ] ) {
				
				WinConditions ( ) 
			}
		}
		
		else {
			
			CreateTimer ( clientRespawnDelay, RespawnClient, GetClientUserId ( client ) ) 
		}
	}
	
	if ( isClientDead [ client ] ) {
		
		new String:authid [ 64 ]
		GetClientAuthString ( client, authid, sizeof ( authid ) ) 
		SetAuthIdCookie ( authid, cookieClientDead, "true" ) 
	}
}

public Event_RoundEnd ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	isRoundEnd = true
	isBombTicking = false
	
	for ( new client = 1; client <= MaxClients; client++ ) 
	{
		if ( Client_IsValid ( client ) ) {
			
			CreateTimer ( 0.0, DisableProtection, GetClientUserId ( client ) ) 
		}
	}
	
	HandleStuff ( )  // Resync Stuff.
}

public RemoveObjectives ( ) {
	
	new iEnt = -1
	
	while ( ( iEnt = FindEntityByClassname ( iEnt, "func_bomb_target" ) ) != -1 ) {
		
		AcceptEntityInput ( iEnt,"kill" ) 
	}
	
	while ( ( iEnt = FindEntityByClassname ( iEnt, "func_hostage_rescue" ) ) != -1 ) {
		
		AcceptEntityInput ( iEnt,"kill" ) 
	}
	
	while ( ( iEnt = FindEntityByClassname ( iEnt, "hostage_entity" ) ) != -1 ) {
		
		AcceptEntityInput ( iEnt, "kill" ) 
	}
	
	while ( ( iEnt = FindEntityByClassname ( iEnt, "func_bombzone" ) ) != -1 ) {
		
		AcceptEntityInput ( iEnt, "kill" ) 
	}	
}

public Action:OnItemPickUp ( Handle:event, const String:name [  ], bool:dontBroadcast ) 
{
	if ( noObjectives || noRoundEnd ) {
		
		new String:temp [ 32 ]
		GetEventString ( event, "item", temp, sizeof ( temp ) ) 
		
		new client = GetClientOfUserId ( GetEventInt ( event, "userid" ) ) 
		
		if ( StrEqual ( temp, "weapon_c4", false ) ) {
			
			new weaponIndex = GetPlayerWeaponSlot ( client, 4 ) 
			RemovePlayerItem ( client, weaponIndex ) 
		}
	}
	
	return Plugin_Continue
}

public HostCount ( ) {
	
	new iEnt = -1
	
	while ( ( iEnt = FindEntityByClassname ( iEnt, "hostage_entity" ) ) != -1 ) {
		
		iHostagesCountOnMapLoad++
	}
}

public Action:Event_BombPlanted ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	isBombTicking = true
}

public Action:Event_BombDefused ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	if ( ! isRoundEnd && ! noObjectives && ! noRoundEnd ) {
		
		CS_TerminateRound ( roundRestartDelay, CSRoundEnd_BombDefused, true ) 
		isBombTicking = false
	}
}

public Action:Event_HostageKilled ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	if ( ! isRoundEnd && ! noObjectives && ! noRoundEnd ) {
		
		iHostagesCount--
	}
}

public Action:Event_HostageRescued ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	if ( ! isRoundEnd && ! noObjectives && ! noRoundEnd ) {
		
		iHostagesCount--
		
		if ( iHostagesCount == 0 ) {
			
			dontBroadcast = true 
			CS_TerminateRound ( roundRestartDelay, CSRoundEnd_HostagesRescued, true ) 
			isRoundEnd = true
		}
	}
}

public Action:Event_BombExploded ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	if ( ! isRoundEnd && ! noObjectives && ! noRoundEnd ) {
		
		CS_TerminateRound ( roundRestartDelay, CSRoundEnd_TargetBombed, true ) 
		isBombTicking = false
		isRoundEnd = true
	}
}

public Action:Event_VipEscaped ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	if ( ! isRoundEnd && ! noObjectives && ! noRoundEnd ) {
		
		CS_TerminateRound ( roundRestartDelay, CSRoundEnd_VIPEscaped, true ) 
		isRoundEnd = true
	}
}

public Action:Event_VipKilled ( Handle:event, const String:name [  ], bool:dontBroadcast ) {
	
	if ( ! isRoundEnd && ! noObjectives && ! noRoundEnd ) {
		
		CS_TerminateRound ( roundRestartDelay, CSRoundEnd_VIPKilled, true ) 
		isRoundEnd = true
	}
}

public WinConditions ( ) {	
	
	GetTeamsCount ( iRemainingT, iRemainingCT, iTotalT, iTotalCT ) 
	
	if ( ! isRoundEnd && ! noObjectives && ! noRoundEnd ) {
		
		if ( iTotalCT == 1 && iTotalT == 0 && ! isBombTicking && ! isRoundEnd ) {
			
			CS_TerminateRound ( roundRestartDelay, CSRoundEnd_Draw, true ) 
			isRoundEnd = true
		}
		
		if ( iTotalCT == 0 && iTotalT == 1 && ! isBombTicking && ! isRoundEnd ) {
			
			CS_TerminateRound ( roundRestartDelay, CSRoundEnd_Draw, true ) 
			isRoundEnd = true
		}
		
		if ( iTotalT == 0 && iRemainingCT > 0 && ! isRoundEnd ) {
			
			CS_TerminateRound ( roundRestartDelay, CSRoundEnd_CTWin, true ) 
			SetTeamScore(CS_TEAM_CT, GetTeamScore(CS_TEAM_CT) + 1)
			CS_SetTeamScore(CS_TEAM_CT, GetTeamScore(CS_TEAM_CT))


			}

			isRoundEnd = true
		}
		
		if ( iTotalCT == 0 && iRemainingT > 0 && ! isRoundEnd ) {
			
			CS_TerminateRound ( roundRestartDelay, CSRoundEnd_TerroristWin, true ) 
			SetTeamScore(CS_TEAM_T, GetTeamScore(CS_TEAM_T) + 1)
			CS_SetTeamScore(CS_TEAM_T, GetTeamScore(CS_TEAM_T))

			}

			isRoundEnd = true
		}
		
		else if ( iTotalCT > 0 && iTotalT > 0  && ! isRoundEnd ) {
			
			if ( iRemainingT == 0 && iRemainingCT > 0 && ! isBombTicking && ! isRoundEnd ) {
				
				CS_TerminateRound ( roundRestartDelay, CSRoundEnd_CTWin, true ) 
				SetTeamScore(CS_TEAM_CT, GetTeamScore(CS_TEAM_CT) + 1)
				CS_SetTeamScore(CS_TEAM_CT, GetTeamScore(CS_TEAM_CT))


				isRoundEnd = true
			}
			
			if ( iRemainingT > 0 && iRemainingCT == 0 && ! isRoundEnd ) {
				
				CS_TerminateRound ( roundRestartDelay, CSRoundEnd_TerroristWin, true ) 
				SetTeamScore(CS_TEAM_T, GetTeamScore(CS_TEAM_T) + 1)
				CS_SetTeamScore(CS_TEAM_T, GetTeamScore(CS_TEAM_T))



				isRoundEnd = true
			}
			
			if ( iRemainingT == 0 && iRemainingCT == 0 && ! isRoundEnd ) {
				
				CS_TerminateRound ( roundRestartDelay, CSRoundEnd_Draw, true ) 
				isRoundEnd = true
			}
		}
	}
}

public Action:RespawnClient ( Handle:timer, any:userid ) {
	
	new client = GetClientOfUserId ( userid ) 
	
	if ( ! isRoundEnd && Client_IsValid ( client ) && GetClientTeam ( client ) != CS_TEAM_SPECTATOR ) {
		
		if ( ! IsPlayerAlive ( client )&& ! isClientDead [ client ] ) {
			
			DoRespawn ( client )
		}
	}
}

public DoRespawn ( client ) {
	
	if ( Client_IsValid ( client ) ) {
		
		CS_RespawnPlayer ( client ) 
		
		isClientRespawning [ client ] = false
		
		if ( ! isClientProtected [ client ] && clientSpawnProtection ) 
			
		EnableProtection ( client, clientSpawnProtectionTime ) 
	}
}

public Action:EnableProtection ( client, Float:ptime ) {
	
	if ( Client_IsValid ( client )&& IsPlayerAlive ( client ) ) {
		
		isClientProtected [ client ] = true
		
		SetEntProp ( client, Prop_Data, "m_takedamage", 0, 1 ) 
		SetEntityRenderMode ( client, RENDER_TRANSCOLOR ) 
		SetEntityRenderColor ( client, 128, 128, 128, 50 ) 
		
		CreateTimer ( ptime, DisableProtection, GetClientUserId ( client ) ) 
	}
}

public Action:DisableProtection ( Handle:timer, any:userid ) {
	
	new client = GetClientOfUserId ( userid ) 
	
	if ( ! Client_IsValid ( client ) || ( ! IsPlayerAlive ( client ) ) ) {
		
		return Plugin_Stop
	}
	
	isClientProtected [ client ] = false
	
	SetEntProp ( client, Prop_Data, "m_takedamage", 2, 1 ) 
	SetEntityRenderColor ( client, 255, 255, 255, 255 ) 
	
	if ( ! isRoundEnd ) {
		
		PrintHintText ( client, " [WARNING] Spawn Protection is now OFF! " ) 
	}
	
	return Plugin_Stop
}

stock GetTeamsCount ( &aRed, &aBlue, &tRed, &tBlue ) {
	
	new iTotalRed, iAliveRed
	new iTotalBlue, iAliveBlue
	
	for ( new client = 1; client <= MaxClients; client++ ) {
		
		if ( Client_IsValid ( client ) ) {
			
			switch ( GetClientTeam ( client ) ) {
				
				case CS_TEAM_T:
				iTotalRed++
				
				case CS_TEAM_CT:
				iTotalBlue++
			}
			
			if ( IsPlayerAlive ( client ) ) {
				
				switch ( GetClientTeam ( client ) ) {
					
					case CS_TEAM_T:
					iAliveRed++
					
					case CS_TEAM_CT:
					iAliveBlue++
				}
			}
		}
	}
	
	tRed = iTotalRed // Total Terrorists.
	tBlue = iTotalBlue // Total CTs
	
	aRed = iAliveRed // Alive Terrorists
	aBlue = iAliveBlue // Alive CTs
}

stock bool:Client_IsValid ( client, bool:checkConnected=true ) {
	
	if ( client > 4096 ) {
		
		client = EntRefToEntIndex ( client ) 
	}
	
	if ( client < 1 || client > MaxClients ) {
		
		return false
	}
	
	if ( !  ( 1 <= client <= MaxClients ) || ! IsClientInGame ( client ) ) {
		
		return false 
	}
	
	if ( checkConnected && ! IsClientConnected ( client ) ) {
		
		return false
	}
	
	return true
}