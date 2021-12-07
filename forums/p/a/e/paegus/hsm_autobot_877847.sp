/*
 * Hidden:SourceMod - Autobot
 *
 * Description:
 *  Based on Phaedrus' original Fight-Bot EventScript
 *  Spawns a bot in an empty or 1 person server.
 *  Bot leaves when there are 2 playable players.
 *
 * Changelog:
 *  v1.0.3
 *   Stopped trying to give the bot a shotgun if they're on hidden team.
 *  v1.0.2
 *   Bot attempts to target other player by mirroring his movement.
 *  v1.0.1
 *   Fixed the auto-kicking problem.
 *   Only 1 bot joins.
 *   Checks for server's cheat setting so it doesn't set sv_cheats 0 if it's already 1.
 *  v1.0.0
 *   Initial release.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
*/

#define PLUGIN_VERSION		"1.0.3"

#pragma semicolon 1

#include <sdktools>

#define HDN_TEAM_SPECTATOR	1
#define HDN_TEAM_IRIS		2
#define HDN_TEAM_HIDDEN		3


public Plugin:myinfo = {
	name		= "H:SM - Autobot",
	author		= "Paegus",
	description	= "Automatically adds a bot to an empty or 1 man server. The bot leaves when another player joins",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=877847"
}

/*
static const g_iKills[]	= {		// Kills gained when killing a member of this team.
	0,
	0,
	1,
	2
};
*/

new Handle:cvarJointime	= INVALID_HANDLE;
new Float:g_fTimer		= 10.0;
new g_osAmmoShotgun;

public OnPluginStart() {
	decl String:szModName[PLATFORM_MAX_PATH];
	GetGameFolderName(szModName, PLATFORM_MAX_PATH);
	
	if(!StrEqual(szModName, "hidden", false))
	{
		SetFailState("This plugins is for Hidden:Source.");
	}
	
	CreateConVar(
		"hsm_autobot_version",
		PLUGIN_VERSION,
		"H:SM - Autobot version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarJointime = FindConVar("hdn_jointime");
	
	RegAdminCmd(
		"hsm_bot_add",
		cmd_AddBot,
		ADMFLAG_KICK,
		"Adds a bot"
	);

	HookEvent("game_round_start", event_RoundStart);
	HookEvent("player_hurt", event_PlayerHurt);

	CreateTimer(
		g_fTimer,
		tCheckBot,
		INVALID_HANDLE,
		TIMER_FLAG_NO_MAPCHANGE
	);
}

public OnMapStart() {
	CreateTimer(20.0, tDelayedJoiner);
	g_osAmmoShotgun = FindSendPropOffs("CSDKPlayer","m_iAmmo") + (4 * 6);
}

public Action:tDelayedJoiner(Handle:timer) {
	if (GetClientCount() > 1) {	// more than 1 other client
		CreateTimer(GetConVarFloat(cvarJointime) - 10.25, tCheckBot, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	} else {	// Less than 2 clients
		CreateTimer(1.0, tCheckBot, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientPutInServer (client) {
	if (IsFakeClient(client)) {	// It's a bot
		SetEntProp(client, Prop_Send, "m_bNoHidden", 1);	// try to forfeit hidden
	} else {	// It's a Player
		SetEntProp(client, Prop_Send ,"deadflag", 2);	// Set their dead flag correctly
	}
}

public Action:event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new eVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	new eAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (
		!IsFakeClient(eVictim) ||	// victim is not a bot
		!eAttacker					// Attacker was world.
	) {
		return Plugin_Continue;
	}
	
	ServerCommand("bot_flipout %i", 1);
	CreateTimer(1.25,tUnFlip);
	
	/*
	if (!IsPlayerAlive(eVictim)) {	// Bot died
		SetEntProp(eAttacker, Prop_Data, "m_iFrags", GetEntProp(eAttacker, Prop_Data, "m_iFrags") - g_iKills[GetClientTeam(eVictim)]);	// Remove killer's point(s).
		SetEntProp(eVictim, Prop_Data, "m_iDeaths", GetEntProp(eVictim, Prop_Data, "m_iDeaths") - 1);	// Remove victim's death increment.
	}
	*/
	
	return Plugin_Continue;
}

public Action:tUnFlip(Handle:timer) {
	ServerCommand("bot_flipout %i", 0);
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i = 1; i <= MaxClients; i++) {
		if (
			IsClientInGame(i) &&					// Connected and in-game
			IsPlayerAlive(i) &&						// Alive
			GetClientTeam(i) == HDN_TEAM_IRIS &&	// IRIS
			IsFakeClient(i)							// A bot
		) {
			SetEntProp(i, Prop_Send, "m_iNewClass", 0);		// Set as Assault.
			SetEntProp(i, Prop_Send, "m_iPrimary", 2);		// Set shotgun.
			SetEntData(i, g_osAmmoShotgun, 32, true);		// Give ammo.
			GivePlayerItem(i, "weapon_shotgun");			// Give shotgun
			FakeClientCommand(i, "use weapon_shotgun");		// Use shotgun.
		}
	}
}

public Action:tCheckBot(Handle:timer) {
	new iRealClients = 0;
	new iBotClient = 0;

	for (new iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient)) {	// Connected and in-game
			if (GetClientTeam(iClient) > HDN_TEAM_SPECTATOR) {	// On a playable team
				if (IsFakeClient(iClient)) {	// It's a bot player
					iBotClient = iClient;
				} else {	// it's a real player
					iRealClients++;
				}
			}
		}
	}

	if (iRealClients < 2 && iBotClient == 0 ) {	// Only 1 real player no bot present
		ServerCommand("hsm_bot_add");
		ServerCommand("bot_mimic_yaw_offset %i", 180);

		if (iBotClient == 1) {
			ServerCommand("bot_mimic %i", 2);
		} else {
			ServerCommand("bot_mimic %i", 1);
		}
	} else if (iRealClients > 1 && iBotClient != 0) {	// More than 1 real player & a bot is present
		new String:sBotName[16];
		GetClientName(
			iBotClient,
			sBotName,
			sizeof(sBotName)
		);
		ServerCommand("sm_kick %s %s", sBotName, "Additional client joined the game");
	}

	new Float:fTimer = g_fTimer + GetRandomFloat(0.0, g_fTimer);

	CreateTimer(
		fTimer,
		tCheckBot,
		INVALID_HANDLE,
		TIMER_FLAG_NO_MAPCHANGE
	);

	//LogToGame("[AutoBot] rc%i b%i t%f", iRealClients, iBotClient, g_fTimer + fTimer);
}

public Action:cmd_AddBot(client, argc) {
	new fFlags = GetCommandFlags("bot_add");
	if (fFlags == -1) {	// Command not found
		ServerCommand("sv_cheats 1");	// Enable cheats
	} else {
		SetCommandFlags("bot_add", fFlags & ~FCVAR_CHEAT);	// Remove cheat flag from bot_add
	}
	
	ServerCommand("bot_add");
	CreateTimer(0.1, tmr_AddBot, fFlags);
	return Plugin_Handled;
}

public Action:tmr_AddBot(Handle:timer, any:fFlags) {
	if (fFlags == -1) {	// Command not found
		ServerCommand("sv_cheats 0");
	} else {
		SetCommandFlags("bot_add", fFlags);
	}
	return Plugin_Handled;
}

