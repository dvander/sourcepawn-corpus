#include <sourcemod>

#define		PLUGIN_VERSION		"0.3.2"
//////////////////////////////////////////////////////////////////////////////
//																			//
// -Plugin:		L4D2 Pause													//
// -Game:		Left 4 Dead 2												//
// -Author:		dirka_dirka													//
//				v.3 contributors: -999- & n3wton							//
//				original: Lee "pvtschlag" Silvey							//
// -URL:		http://forums.alliedmods.net/showthread.php?p=997585		//
// -Description:	Allows teams to pause the game when agreed on, and		//
//					allows admins to force the game to pause.				//
//																			//
// -Changelog:																//
//	* Version 0.1.0:														//
// 		-Initial Release													//
//	* Version 0.1.1:														//
//		-Fixed typo															//
//		-Added a timeout for pause requests									//
//		-Pause requests now get reset when map ends							//
//	* Version 0.2.0:														//
//		-Chat is now forced to display during pause							//
//		-Added option for enabling alltalk while game is paused				//
//		-Added cvar to configure how long a pause request takes to timeout.	//
//	* Version 0.2.1:														//
//		-Fixed some more chat that didn't show								//
//		-Added option for only allowing the !forcepause command				//
//																			//
//	* Version 0.3:															//
//		-Fixed AllTalk														//
//		-Added cvar to allow other plugins to detect when paused			//
//		-Added timers to allow for people to (dis)connect					//
//		-Added fix for chat flooding										//
//	* Version 0.3.1:														//
//		-Reduced pause-unpause-pause timers from 1.0 to 0.5 seconds			//
//		-Added convar option to re-color text while paused (def: off)		//
//		-Cleaned up code in a few places (eg: removed IsClientConnected		//
//		 check when there was a IsClientInGame check on same line			//
//		-Added convar to allow !pause to work (without a reply) in			//
//		 coop (4 player/1 team) games										//
//		-Added check for client 0 (server/console)							//
//		-Added in more of the coop mutations								//
//		-Customized/personalized the chat messages some						//
//	* Version 0.3.2:														//
//		-Removed some global variables										//
//		-Changed the forcepause admin flag from ban to kick					//
//		-Fixed errors related to timer handle								//
//		-Added conditions to stop timers if map is changed					//
//		-Fixed the pause notification (multiple prints added in last build)	//
//		-Added a message if someone tries to use !pause/!unpause while		//
//		 on the spectator team (or not survivor/infected)					//
//		-Removed a for loop that was doing nothing							//
//		-Unpause messages are now all hint (with color codes removed)		//
//		-Replaced RegConsoleCmd with AddCommandListener for pause, unpause	//
//		 and setpause														//
//																			//
//////////////////////////////////////////////////////////////////////////////

#define		L4D_TEAM_UNASSIGNED	0
#define		L4D_TEAM_SPECTATOR		1
#define		L4D_TEAM_SURVIVOR		2
#define		L4D_TEAM_INFECTED		3

new		Handle:	g_hPaused			=	INVALID_HANDLE;
static	bool:	g_bPauseAlltalk		=	false;
static	Float:	g_fPauseTimeout		=	0.0;
static	bool:	g_bPauseFlood		=	false;
static	Handle:	g_hGamemode			=	INVALID_HANDLE;
static	Handle:	g_hPausable			=	INVALID_HANDLE;
static	Handle:	g_hAlltalk			=	INVALID_HANDLE;
static	bool:	g_bForceOnly		=	false;
static	bool:	g_bColorPausedChat	=	false;
static	bool:	g_bAllowCoopPause	=	false;
static	Handle:	g_hFloodTime		=	INVALID_HANDLE;
static	Float:	g_fFloodTimeOrig	=	0.0;		// this stores the flood value
static	Float:	g_fFloodTimeNew		=	0.01;		// this is the temp flood value while paused

static	bool:	g_bIsPaused		=	false;
static	bool:	g_bIsUnpausing	=	false;
static	bool:	g_bAllowPause	=	false;
static	bool:	g_bAllowUnpause	=	false;
static	bool:	g_bWasForced	=	false;

// 0 and 1 wont be used, but it makes for better coding below if team #'s ever get changed..
static	bool:	g_bPauseRequest[L4D_TEAM_INFECTED+1]		=	{ false, ... };

public Plugin:myinfo = {
	name			= "L4D2 Pause",
	author			= "Dirka_Dirka",
	description	= "Allows teams to pause the game when agreed on, and allows admins to force the game to pause.",
	version			= PLUGIN_VERSION,
	url				= "http://forums.alliedmods.net/showpost.php?p=1229148&postcount=52"
};

public OnPluginStart() {
	CreateConVar(
		"l4d2pause_version", PLUGIN_VERSION,
		"L4D2 Pause Plugin Version",
		FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED );
	
	new Handle:PauseTimeout = CreateConVar(
		"l4d2pause_timeout", "30.0",
		"The amount of time it takes an unaccepted pause request to expire.",
		FCVAR_PLUGIN,
		true, 0.0, false );
	g_fPauseTimeout = GetConVarFloat(PauseTimeout);
	new Handle:PauseAlltalk = CreateConVar(
		"l4d2pause_alltalk", "1",
		"Enables alltalk while the game is paused.",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0, true, 1.0 );
	g_bPauseAlltalk = GetConVarBool(PauseAlltalk);
	new Handle:PauseFlood = CreateConVar(
		"l4d2pause_stopchatflood", "1",
		"Makes it impossible to flood the chat whilst paused.",
		FCVAR_PLUGIN,
		true, 0.0, true, 1.0 );
	g_bPauseFlood = GetConVarBool(PauseFlood);
	new Handle:ForceOnly = CreateConVar(
		"l4d2pause_forceonly", "0",
		"Only allow the game to be paused by the forcepause command (Admin only).",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0, true, 1.0 );
	g_bForceOnly = GetConVarBool(ForceOnly);
	new Handle:ColorPausedChat = CreateConVar(
		"l4d2pause_colorchat", "0",
		"Intercepts chat messages while the game is paused, and re-colors them.",
		FCVAR_PLUGIN,
		true, 0.0, true, 1.0 );
	g_bColorPausedChat = GetConVarBool(ColorPausedChat);
	new Handle:AllowCoopPause = CreateConVar(
		"l4d2pause_allowcoop", "1",
		"Allows the use of !pause in coop style games (4-player/1-team). Effectively allowing everyone the use of !forcepause.",
		FCVAR_PLUGIN|FCVAR_NOTIFY,
		true, 0.0, true, 1.0 );
	g_bAllowCoopPause = GetConVarBool(AllowCoopPause);
	
	// This convar is how I detect the game is paused with other plugins..
	g_hPaused = CreateConVar(
		"l4d2pause_enabled", "0",
		"Game is paused (for other plugins to detect).",
		FCVAR_PLUGIN|FCVAR_DONTRECORD,
		true, 0.0, true, 1.0 );
	
	g_hGamemode = FindConVar("mp_gamemode");
	g_hPausable = FindConVar("sv_pausable");
	g_hAlltalk = FindConVar("sv_alltalk");
	g_hFloodTime = FindConVar("sm_flood_time");
	
	SetConVarInt(g_hPausable, 0);
	g_fFloodTimeOrig = GetConVarFloat(g_hFloodTime);
	
	AutoExecConfig(true, "l4d2pause");
	
	//RegConsoleCmd("pause",			Command_Pause);
	//RegConsoleCmd("setpause",		Command_Setpause);
	//RegConsoleCmd("unpause",		Command_Unpause);
	AddCommandListener(Command_Pause,	"pause");
	AddCommandListener(Command_Setpause,	"setpause");
	AddCommandListener(Command_Unpause,	"unpause");
	RegConsoleCmd("sm_pause",		Command_SMPause,		"Pauses the game");
	RegConsoleCmd("sm_unpause",	Command_SMUnpause,		"Unpauses the game");
	RegConsoleCmd("say",			Command_Say);
	RegConsoleCmd("say_team",		Command_SayTeam);
	RegAdminCmd("sm_forcepause",	Command_SMForcePause,	ADMFLAG_KICK,	"Forces the game to pause/unpause");
	
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Pre);
}

public Action:Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bIsPaused && !g_bIsUnpausing && !IsFakeClient(client))  {
		Unpause(client);
		CreateTimer(0.5, _Timer__Pause, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientPutInServer(client) {
	if (g_bIsPaused && !g_bIsUnpausing && !IsFakeClient(client))  {
		Unpause(client);
		CreateTimer(0.5, _Timer__Pause, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientConnected(client) {
	if (g_bIsPaused && !g_bIsUnpausing && !IsFakeClient(client)) {
		Unpause(client);
		CreateTimer(0.5, _Timer__Pause, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client) {
	if(g_bIsPaused && !g_bIsUnpausing && !IsFakeClient(client)) {
		Unpause(client);
		new InGame = GetAnyClient(false);
		if (InGame != 0)
			CreateTimer(0.5, _Timer__Pause, InGame, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public OnMapEnd() {
	ResetPauseRequest();
	if (g_bPauseAlltalk) {
		DisablePausedAlltalk();
		SetConVarInt(g_hPaused, 0);
	}
}

public Action:Command_Say(client, args) {
	if (g_bIsPaused && g_bColorPausedChat) {
		decl String:sText[256];
		GetCmdArg(1, sText, sizeof(sText));
		if (client == 0 || (IsChatTrigger() && sText[0] == '/'))
			return Plugin_Continue;
		PrintToChatAll("\x03%N\x01 : %s", client, sText);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_SayTeam(client, args) {
	if (g_bIsPaused && g_bColorPausedChat) 	{
		decl String:sText[256];
		GetCmdArg(1, sText, sizeof(sText));
		if (client == 0 || (IsChatTrigger() && sText[0] == '/'))
			return Plugin_Continue;
		
		decl String:sTeamName[16];
		new iTeam = GetClientTeam(client);
		if (iTeam == L4D_TEAM_INFECTED)
			sTeamName = "Infected";
		else if (iTeam == L4D_TEAM_SURVIVOR)
			sTeamName = "Survivor";
		else
			sTeamName = "Spectator";
			
		for (new i=1; i<=MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i))
				continue;
			if (GetClientTeam(i) == iTeam)
				PrintToChat(i, "\x01(%s) \x03%N\x01 : %s", sTeamName, client, sText);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Pause(client, const String:command[], argc) {
//public Action:Command_Pause(client, args) {
	// Prevent the actual pause command from doing anything
	return Plugin_Handled; 
}

public Action:Command_Setpause(client, const String:command[], argc) {
//public Action:Command_Setpause(client, args) {
	if (g_bAllowPause) {
		g_bIsPaused = true;		//Game is now paused
		g_bIsUnpausing = false;	//Game was just paused and can no longer be unpausing if it was
		g_bAllowPause = false;	//Don't allow this command to be used again untill we say
		SetConVarInt(g_hPaused, 1);
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:Command_Unpause(client, const String:command[], argc) {
//public Action:Command_Unpause(client, args) {
	if (g_bAllowUnpause) {
		g_bIsPaused = false;		//Game is now active
		g_bIsUnpausing = false;		//Game is active so it is no longer in the unpausing state
		g_bAllowUnpause = false;	//Don't allow this command to be used again untill we say
		SetConVarInt(g_hPaused, 0);
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:Command_SMPause(client, args) {
	if ((client < 1) || (client > MaxClients)) {
		ReplyToCommand(client, "[Pause] Command is in-game only.");
		return Plugin_Handled;
	}
	// Can only pause the game if your playing on a team..
	new iTeam = GetClientTeam(client);
	if ((iTeam != L4D_TEAM_SURVIVOR) && (iTeam != L4D_TEAM_INFECTED)) {
		ReplyToCommand(client, "[Pause] Command is only available to players who are 'playing' (on a team).");
		return Plugin_Handled;
	}
	
	if (g_bForceOnly) {
		ReplyToCommand(client, "\x03[Pause]\x01 Only an Admin can pause the game using \x04!forcepause\x01.");
		return Plugin_Handled;
	}
	
	if (g_bIsPaused) {
		ReplyToCommand(client, "\x03[Pause]\x01 Game is already paused. Use \x04!unpause\x01 to resume the game.");
		return Plugin_Handled;
	}
	
	new bool:coop = IsCoop();
	if (coop) {
		if (!g_bAllowCoopPause) {
			ReplyToCommand(client, "\x03[Pause]\x01 Only an Admin can pause the game by using \x04!forcepause\x01.");
			return Plugin_Handled;
		} else {
			g_bPauseRequest[L4D_TEAM_SURVIVOR] = true;
			g_bPauseRequest[L4D_TEAM_INFECTED] = true;
		}
	} else {
		// Check if pause request is in progress
		if (g_bPauseRequest[iTeam])
			return Plugin_Handled;
		else
			g_bPauseRequest[iTeam] = true;
	}
	
	if (g_bPauseRequest[L4D_TEAM_SURVIVOR] && g_bPauseRequest[L4D_TEAM_INFECTED]) {
		if (coop) {
			PrintToChat(client, "\x03[Pause]\x01 You have paused the game. Use \x04!unpause\x01 to resume.");
			for (new i=1; i<=MaxClients; i++) {
				if (!IsClientInGame(i) || IsFakeClient(i) || (i == client))
					continue;
				// Should be coop/survival only - which means only survivors, so team check doesn't matter.
				PrintToChat(i, "\x03[Pause]\x01 \x05%N\x01 has paused the game. Use \x04!unpause\x01 to resume.", client);
			}
		} else {
			PrintToChatAll("\x03[Pause]\x01 Both teams have agreed to pause the game. Use \x04!unpause\x01 to resume.");
		}
		if (g_bPauseAlltalk)
			EnablePausedAlltalk();
		CreateTimer(0.5, _Timer__Pause, client, TIMER_FLAG_NO_MAPCHANGE);
	} else if (g_bPauseRequest[L4D_TEAM_SURVIVOR] && !g_bPauseRequest[L4D_TEAM_INFECTED]) {
		for (new i=1; i<=MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			if (GetClientTeam(i) == L4D_TEAM_INFECTED)
				PrintToChat(i, "\x03[Pause]\x01 The Survivors want to pause the game. You can accept the request with the \x04!pause\x01 command.");
		}
		if (g_fPauseTimeout > 0.0)
			CreateTimer(g_fPauseTimeout, _Timer__PauseRequest, L4D_TEAM_SURVIVOR, TIMER_FLAG_NO_MAPCHANGE);
	} else if (g_bPauseRequest[L4D_TEAM_INFECTED] && !g_bPauseRequest[L4D_TEAM_SURVIVOR]) {
		for (new i=1; i<=MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			if (GetClientTeam(i) == L4D_TEAM_SURVIVOR)
				PrintToChat(i, "\x03[Pause]\x01 The Infected want to pause the game. You can accept the request with the \x04!pause\x01 command.");
		}
		if (g_fPauseTimeout > 0.0)
			CreateTimer(g_fPauseTimeout, _Timer__PauseRequest, L4D_TEAM_INFECTED, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_SMUnpause(client, args) {
	if ((client < 1) || (client > MaxClients)) {
		ReplyToCommand(client, "[Pause] Command is in-game only.");
		return Plugin_Handled;
	}
	// Can only pause the game if your playing on a team..
	new iTeam = GetClientTeam(client);
	if ((iTeam != L4D_TEAM_SURVIVOR) && (iTeam != L4D_TEAM_INFECTED)) {
		ReplyToCommand(client, "[Pause] Command is only available to players who are 'playing' (on a team).");
		return Plugin_Handled;
	}
	
	if (g_bWasForced) {
		ReplyToCommand(client, "\x03[Pause]\x01 The game was paused by an admin, and can only be unpaused with \x04!forcepause\x01.");
		return Plugin_Handled;
	}
	
	if (g_bIsPaused && !g_bIsUnpausing) {
		if (IsCoop()) {
			if (g_bAllowCoopPause) {
				PrintToChat(client, "\x03[Pause]\x01 You just unpaused the game.");
				for (new i=1; i<=MaxClients; i++) {
					if (IsClientInGame(i) && !IsFakeClient(i) && (i != client))
						PrintToChat(i, "\x03[Pause]\x01 The game has been unpaused by \x04%N\x01.");
				}
			} else {
				// shouldnt even reach this else..
			}
		} else {
			if (iTeam == L4D_TEAM_SURVIVOR)
				PrintToChatAll("\x03[Pause]\x01 The game has been unpaused by the Survivors.");
			else if (iTeam == L4D_TEAM_INFECTED)
				PrintToChatAll("\x03[Pause]\x01 The game has bee unpaused by the Infected.");
		}
		g_bIsUnpausing = true;
		if (g_bPauseAlltalk)
			DisablePausedAlltalk();
		CreateTimer(0.5, _Timer__UnPause, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:Command_SMForcePause(client, args) {
	if ((client < 1) || (client > MaxClients)) {
		ReplyToCommand(client, "[Pause] Command is in-game only.");
		return Plugin_Handled;
	}
	if (g_bIsPaused && !g_bIsUnpausing) {
		g_bWasForced = false;
		PrintToChatAll("\x03[Pause]\x01 The game has been unpaused by an Admin.");
		g_bIsUnpausing = true;
		if (g_bPauseAlltalk)
			DisablePausedAlltalk();
		CreateTimer(0.5, _Timer__UnPause, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	} else if (!g_bIsPaused) {
		g_bWasForced = true;
		PrintToChatAll("\x03[Pause]\x01 The game has been paused by an Admin.");
		if (g_bPauseAlltalk)
			EnablePausedAlltalk();
		CreateTimer(0.5, _Timer__Pause, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:_Timer__Pause(Handle:timer, any:client) {
	Pause(client);
}

public Action:_Timer__UnPause(Handle:timer, any:client) {
	if (!g_bIsUnpausing)
		return Plugin_Stop;
	
	static iCountdown = 5;
	if(iCountdown == 0) {
		PrintHintTextToAll("[Pause] Game is Live!");
		Unpause(client);
		iCountdown = 5;
		return Plugin_Stop;
	} else if (iCountdown == 5) {
		PrintHintTextToAll("[Pause] Game will resume in %d..", iCountdown);
	} else {
		PrintHintTextToAll("[Pause] Game will resume in %d..", iCountdown);
	}
	iCountdown--;
	return Plugin_Continue;
}

public Action:_Timer__PauseRequest(Handle:timer, any:team) {
	if (g_bIsPaused || (!g_bPauseRequest[L4D_TEAM_SURVIVOR] && !g_bPauseRequest[L4D_TEAM_INFECTED])) {
		return;
	} else {
		for (new i=1; i<=MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;
			if (GetClientTeam(i) == L4D_TEAM_SURVIVOR) {
				if (team == L4D_TEAM_SURVIVOR)
					PrintToChat(i, "\x03[Pause]\x01 Your teams request to pause the game has expired. Either the Infected didn't see it, or they don't care.");
				else
					PrintToChat(i, "\x03[Pause]\x01 The Infected team request to pause the game has expired. How nice of you to ignore them.");
			} else if (GetClientTeam(i) == L4D_TEAM_INFECTED) {
				if (team == L4D_TEAM_SURVIVOR)
					PrintToChat(i, "\x03[Pause]\x01 The Survivors team request to pause the game has expired. How nice of you to ignore them.");
				else
					PrintToChat(i, "\x03[Pause]\x01 Your teams request to pause the game has expired. Either the Survivors didn't see it, or they don't care.");
			}
		}
		ResetPauseRequest();
	}
}

stock Pause(client) {
	if (g_bPauseAlltalk)
		SetConVarFloat(g_hFloodTime, g_fFloodTimeNew);		// fix to prevent chat messages from flooding (and gagging people)
	ResetPauseRequest();						//Reset all pause requests since we are now pausing the game
	g_bAllowPause = true;						//Allow the next setpause command to go through
	SetConVarInt(g_hPausable, 1);				//Ensure sv_pausable is set to 1
	FakeClientCommand(client, "setpause");	//Send pause command
	SetConVarInt(g_hPausable, 0);				//Reset sv_pausable back to 0
}

stock Unpause(client) {
	if (g_bPauseFlood)
		SetConVarFloat( g_hFloodTime, g_fFloodTimeOrig );	//change flooding back to original value
	ResetPauseRequest();						//Reset all pause requests since we are now resuming the game
	g_bAllowUnpause = true;						//Allow the next unpause command to go through
	SetConVarInt(g_hPausable, 1);				//Ensure sv_pausable is set to 1
	FakeClientCommand(client, "unpause");		//Send unpause command
	SetConVarInt(g_hPausable, 0);				//Rest sv_pausable back to 0
}

stock ResetPauseRequest() {
	g_bPauseRequest[L4D_TEAM_SURVIVOR] = false;
	g_bPauseRequest[L4D_TEAM_INFECTED] = false;
}

stock bool:IsCoop() {
	decl String:sGamemode[64];
	GetConVarString(g_hGamemode, sGamemode, sizeof(sGamemode));
	if (StrEqual(sGamemode, "coop"))
		return true;
	else if (StrEqual(sGamemode, "realism"))
		return true;
	else if (StrEqual(sGamemode, "mutation1"))
		return true;
	else if (StrEqual(sGamemode, "mutation2"))
		return true;
	else if (StrEqual(sGamemode, "mutation3"))
		return true;
	else if (StrEqual(sGamemode, "mutation4"))
		return true;
	else if (StrEqual(sGamemode, "mutation5"))
		return true;
	// mutations 6 & 8 haven't been released yet, but they most likely will be coop..
	else if (StrEqual(sGamemode, "mutation6"))
		return true;
	else if (StrEqual(sGamemode, "mutation7"))
		return true;
	else if (StrEqual(sGamemode, "mutation8"))
		return true;
	else if (StrEqual(sGamemode, "mutation9"))
		return true;
	else if (StrEqual(sGamemode, "mutation10"))
		return true;
	else if (StrEqual(sGamemode, "survival"))
		return true;
	
	return false;
	// dunno if this will work, but it would be better then the above:
	//else if (StrContains(sGamemode, "mutation", true)) {
	//	new mut = StringToInt(sGamemode[8]);
	//	if (mut < 11)
	//		return true;
	//	else
	//		return false;
	//}
}

stock EnablePausedAlltalk() {
	// coop is only 1 team, and you can already talk to your team..
	if (IsCoop())
		return;
	
	new Flags = GetConVarFlags(g_hAlltalk);
	SetConVarFlags(g_hAlltalk, (Flags & ~FCVAR_NOTIFY));
	SetConVarInt(g_hAlltalk, 1);
	SetConVarFlags(g_hAlltalk, Flags);
	PrintToChatAll("\x03[Pause]\x01 Alltalk is \x05Enabled\x01.");
}

stock DisablePausedAlltalk() {
	if (IsCoop())
		return;
	
	new Flags = GetConVarFlags(g_hAlltalk);
	SetConVarFlags(g_hAlltalk, (Flags & ~FCVAR_NOTIFY));
	SetConVarInt(g_hAlltalk, 0);
	SetConVarFlags(g_hAlltalk, Flags);
	if (g_bIsPaused)
		PrintToChatAll("\x03[Pause]\x01 Alltalk is \x05Disabled\x01.");
}

stock GetAnyClient(bool:InGameOnly = true) {
	for (new i=1; i<=MaxClients; i++) {
		if ((InGameOnly ? IsClientConnected(i) : IsClientInGame(i)) && !IsFakeClient(i)) {
			return i;
		}
	}
	return 0;
}
