#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <gametype>

#define PLUGIN_VERSION	"1.4.4"
/*
 *	L4D AFK Manager
 *
 *	Original Concept by Matthias Vance and his plugin found here:
 *		http://forums.alliedmods.net/showthread.php?t=115020
 *
 *	Version History:
 *	1.4 -		Complete re-write of almost the entire plugin.
 *				Added of Game Mode checks to determine 4 player and 8 player games.
 *				- This allows for improved team switching with chat commands instead of a menu.
 *				- While this is a tad more then is needed, it is what I use in other plugins as well.
 *				Reworked the !team menu to reduce (remove?) crashes and weird behavior.
 *				Addition of mins/maxes on pretty much every cvar.
 *				Most (if not all) of the content that anyone would want to tweak is found up top now.
 *				Added extended kick time to those who deliberately idle (!afk) instead of just afk'ing or crashing.
 *				- This lets people take a short break for nature or what not.
 *				Added detection of the game being paused via the Pause plugin (might try and find a better way)..
 *				Added detection of end game events so as to not prematurely exit.
 *				- Previous versions would auto spec everyone during the credits and then quickly R.T.L. (without sb_all_bot_team 1).
 *	1.4.1 -		Fixed a few bugs with the team menu.. it was possible to join a team that was full.
 *				Fixed event detection to disable during round ends (derr forgot the hooks).
 *	1.4.2 -		Added Scavenge as a seperate gameMode from versus (I use the same detection in other plugins, keeping consistant only).
 *	1.4.3 -		Worked on the new join code, fix a bug, create a bug, fix a bug.. and so on.
 *	1.4.4 -		Added gametype.inc for game detection
 *				Added new game modes (via gametype.inc).
 *				Removed OnMapStart function - don't think it is needed.
 *				Added L4D check.
 *				Removed some debuging code.
 *				Maybe(?) fixed the unable to rejoin survivors in coop.
 *				Added a fix for several potential client related error message (eg: client 0 is not valid).
 *				Changed the PrintToChats in command functions to ReplyToCommands.
 *				Updated/cleaned up code throughout plugin.
 *	1.4.5 -		Fixed l4d_afk_kicktime == 0.0  & l4d_afk_spectime == 0.0 not working.
 *				Fixed !teami no longer working.
 *				Another attempt at fixing !teams in coop.
 *				Fixed a chat message that was never updated.
 *				Fixed if an invalid immune flag is entered into the config file.. defaults to 'z'.
 *				Removed 9 globals.
 *				Updated gametype.inc for new modes.
 */

#define		TAG						"\x03[AFK]\x01"
#define		L4D_TEAM_UNASSIGNED	0
#define		L4D_TEAM_SPECTATOR	1
#define		L4D_TEAM_SURVIVOR		2
#define		L4D_TEAM_INFECTED		3

static	const			MAX_TEAM_SIZE		=	4;		// Change this for > 8 player servers.
static	const	String:	IMMUNE_FLAG_CHAR[]	=	"z";	// the 'default' in config file.
static	const	Float:	MIN_TIMER			=	30.0;
static	const	Float:	MIN_KICK			=	10.0;
static	const	Float:	TIMER_MSG			=	5.0;		// How often to display messages (about joining team and getting kicked)

static		g_iGameType		=	GT_UNKNOWN;
static		g_iGameMode		=	GM_UNKNOWN;

static	bool:	g_bEnabled				=	true;
static	AdminFlag:	g_afImmuneFlag		=	Admin_Root;
static			g_iMessageLevel			=	0;
static	Float:	g_fAdvertiseInterval	=	0.0;
static	Float:	g_fTimeToSpec			=	0.0;
static	Float:	g_fTimeToKick			=	0.0;
static	Float:	g_fTimeLeftInterval		=	0.0;
static	Float:	g_fTimerJoinMessage		=	0.0;
static	Float:	g_fIdleTimeMultiple		=	1.0;

static	Handle:	g_hAdvertiseTimer		=	INVALID_HANDLE;
static	Handle:	g_hAFKCheckTimer		=	INVALID_HANDLE;

static	String:	ads[][] = {
	"Use \x04!afk\x01 if you plan to go AFK (you will be kicked if gone too long).",
	"Use \x04!team\x01 to join a team by menu.",
	"Use \x04!teams\x01 to join the survivors and \x04!teami\x01 to join the infected."
};
static	adIndex = 0;	// current position in the ads

/* Is the Pause Plugin running and the game is paused? */
static	bool:	g_bGamePaused = false;
static	bool:	g_bActive	=	true;

static	Float:	g_fCheckInterval = 2.0;

static	bool:	g_bClientIsIdle[MAXPLAYERS+1]		=	{ false, ... };
static	Float:	g_fClientSpecTime[MAXPLAYERS+1]		=	{ 0.0, ... };
static	Float:	g_fClientAfkTime[MAXPLAYERS+1]		=	{ 0.0, ... };
static	Float:	g_fClientLastMsgTime[MAXPLAYERS+1]	=	{ 0.0, ... };
static	Float:	g_fClientPos[MAXPLAYERS+1][3];
static	Float:	g_fClientAngles[MAXPLAYERS+1][3];

static	Handle:	g_hSetHumanSpec	=	INVALID_HANDLE;
static	Handle:	g_hTakeOverBot	=	INVALID_HANDLE;

public Plugin:myinfo = {
	name			= "[L4D(2)] AFK Manager",
	author			= "Dirka_Dirka",
	description	= "Determines if someone has gone AFK (or crashed) and removes them from the game.",
	version			= PLUGIN_VERSION,
	url				= "http://forums.alliedmods.net/showpost.php?p=1162948&postcount=49"
};

public OnPluginStart() {
	if (IsL4D() == -1)
		SetFailState("AFK Manager only works in Left 4 Dead (2).");
	
	decl String:t_string[12];
	FloatToString(TIMER_MSG, t_string, sizeof(t_string));
	
	CreateConVar(
		"l4d_afkmanager_version", PLUGIN_VERSION,
		"[L4D(2)] AFK Manager",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	SetConVarString(FindConVar("l4d_afkmanager_version"), PLUGIN_VERSION);
	
	new Handle:Enabled = CreateConVar(
		"l4d_afkmanager_enable", "1",
		"Enable this plugin, spectates and then kicks AFKers/crashers.",
		FCVAR_NOTIFY|FCVAR_PLUGIN,
		true, 0.0, true, 1.0 );
	g_bEnabled = GetConVarBool(Enabled);
	HookConVarChange(Enabled, ConVarChanged_Enable);
	
	new Handle:ImmuneFlag = CreateConVar(
		"l4d_afk_immuneflag", IMMUNE_FLAG_CHAR,
		"Admins with this flag have kick immunity.",
		FCVAR_NOTIFY|FCVAR_PLUGIN );
	decl String:tmp[2];
	GetConVarString(ImmuneFlag, tmp, sizeof(tmp));
	if (strlen(tmp) == 1) {
		if(!FindFlagByChar(tmp[0], g_afImmuneFlag)) {
			SetConVarString(ImmuneFlag, "z");
			g_afImmuneFlag = Admin_Root;
		}
	} else {
		SetConVarString(ImmuneFlag, "z");
		g_afImmuneFlag = Admin_Root;
	}
	HookConVarChange(ImmuneFlag, ConVarChanged_ImmuneFlag);
	new Handle:MessageLevel = CreateConVar(
		"l4d_afk_messages", "2",
		"Control spec/kick messages. (0 = disable, 1 = spec, 2 = kick, 3 = spec + kick)",
		FCVAR_NOTIFY|FCVAR_PLUGIN,
		true, 0.0, true, 3.0 );
	g_iMessageLevel = GetConVarInt(MessageLevel);
	HookConVarChange(MessageLevel, ConVarChanged_Messages);
	new Handle:TimerJoinMessage = CreateConVar(
		"l4d_afk_joinmsgtime", t_string,
		"Time between messages telling you how to rejoin your team.",
		FCVAR_NOTIFY|FCVAR_PLUGIN,
		true, 1.0, true, 30.0 );
	g_fTimerJoinMessage = GetConVarFloat(TimerJoinMessage);
	HookConVarChange(TimerJoinMessage, ConVarChanged_TimerJoinMessage);
	new Handle:TimeLeftInterval = CreateConVar(
		"l4d_afk_warningtime", t_string,
		"Time between messages telling you when your getting kicked.",
		FCVAR_NOTIFY|FCVAR_PLUGIN,
		true, 1.0, true, 30.0 );
	g_fTimeLeftInterval = GetConVarFloat(TimeLeftInterval);
	HookConVarChange(TimeLeftInterval, ConVarChanged_TimeLeftInterval);
	new Handle:IdleTimeMultiple = CreateConVar(
		"l4d_afk_idlemulti", "2.0",
		"Value to multiply l4d_afk_kicktime with for idlers (volunteer afkers). They then get l4d_afk_idlemulti * l4d_afk_kicktime seconds to spectate.",
		FCVAR_NOTIFY|FCVAR_PLUGIN,
		true, 1.0, true, 6.0 );
	g_fIdleTimeMultiple = GetConVarFloat(IdleTimeMultiple);
	HookConVarChange(IdleTimeMultiple, ConVarChanged_IdleTimeMultiple);
	new Handle:AdvertiseInterval = CreateConVar(
		"l4d_afk_adinterval", "180.0",
		"Interval in which the plugin will advertise the !afk command. (0 = disabled, otherwise MIN_TIMER = 30 seconds)",
		FCVAR_NOTIFY|FCVAR_PLUGIN,
		true, 0.0, true, 1200.0 );
	g_fAdvertiseInterval = GetConVarFloat(AdvertiseInterval);
	if (g_fAdvertiseInterval) {
		if (g_fAdvertiseInterval < MIN_TIMER) {
			g_fAdvertiseInterval = MIN_TIMER;
			SetConVarFloat(AdvertiseInterval, g_fAdvertiseInterval);
		}
		if (g_hAdvertiseTimer != INVALID_HANDLE)
			CloseHandle(g_hAdvertiseTimer);
		g_hAdvertiseTimer = CreateTimer(g_fAdvertiseInterval, _Timer__Advertise, _, TIMER_REPEAT);
	}
	HookConVarChange(AdvertiseInterval, ConVarChange_AdvertiseInterval);
	
	new Handle:TimeToSpec = CreateConVar(
		"l4d_afk_spectime", "30.0",
		"AFK time after which you will be moved to the Spectator team. (0 = disabled, otherwise MIN_KICK = 10 seconds)",
		FCVAR_NOTIFY|FCVAR_PLUGIN,
		true, 0.0, true, 300.0 );
	g_fTimeToSpec = GetConVarFloat(TimeToSpec);
	if (g_fTimeToSpec) {
		if (g_fTimeToSpec < MIN_KICK) {
			g_fTimeToSpec = MIN_KICK;
			SetConVarFloat(TimeToSpec, g_fTimeToSpec);
		}
	}
	HookConVarChange(TimeToSpec, ConVarChanged_TimeToSpec);
	new Handle:TimeToKick = CreateConVar(
		"l4d_afk_kicktime", "90.0",
		"AFK time after which you will be kicked.. counted AFTER l4d_afk_spectime. (0 = disabled, otherwise MIN_KICK = 10 seconds)",
		FCVAR_NOTIFY|FCVAR_PLUGIN,
		true, 0.0, true, 300.0 );
	g_fTimeToKick = GetConVarFloat(TimeToKick);
	if (g_fTimeToKick) {
		if (g_fTimeToKick < MIN_KICK) {
			g_fTimeToKick = MIN_KICK;
			SetConVarFloat(TimeToKick, g_fTimeToKick);
		}
	}
	HookConVarChange(TimeToKick, ConVarChanged_TimeToKick);
	
	if (g_fTimeToSpec || g_fTimeToKick) {
		if (g_hAFKCheckTimer != INVALID_HANDLE)
			CloseHandle(g_hAFKCheckTimer);
		g_hAFKCheckTimer = CreateTimer(g_fCheckInterval, _Timer__CheckIdle, _, TIMER_REPEAT);
	}
	
	AutoExecConfig(true, "l4d_afkmanager");
	
	new Handle:hConfig = LoadGameConfigFile("l4d_afkmanager");
	if (hConfig == INVALID_HANDLE)
		SetFailState("[AFK Manager] Could not load l4d_afkmanager gamedata.");
	// SetHumanSpec
	StartPrepSDKCall(SDKCall_Player);
	if (PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "SetHumanSpec")) {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		g_hSetHumanSpec = EndPrepSDKCall();
	}
	if (g_hSetHumanSpec == INVALID_HANDLE)
		SetFailState("[AFK Manager] SetHumanSpec not found.");
	// TakeOverBot
	StartPrepSDKCall(SDKCall_Player);
	if (PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "TakeOverBot")) {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hTakeOverBot = EndPrepSDKCall();
	}
	if (g_hTakeOverBot == INVALID_HANDLE)
		SetFailState("[AFK Manager] TakeOverBot not found.");
	
	RegConsoleCmd("sm_afk",	Command_Idle,	"Go AFK (Spectator team).");
	RegConsoleCmd("sm_team",	Command_Team,	"Change team.");
	RegConsoleCmd("sm_teami",	Command_TeamI,	"Goto Infected team.");
	RegConsoleCmd("sm_teams",	Command_TeamS,	"Goto Survivor team.");
	
	HookEvent("round_start_post_nav",	_Event__RoundStartPostNav);
	HookEvent("player_team",			_Event__PlayerTeam);
	HookEvent("round_start",			_Event__RoundStart);
	HookEvent("round_end",				_Event__RoundEnd);
	HookEvent("finale_win",			_Event__FinalWin);
	HookEvent("mission_lost",			_Event__MissionLost);
}

public OnConfigsExecuted() {
	if (!g_bEnabled) return;
	
	// Plugin Compatability: L4D2 Pause
	if (FindConVar("l4d2pause_enabled") != INVALID_HANDLE) {
		if (GetConVarBool(FindConVar("l4d2pause_enabled")))
			g_bGamePaused = true;
		else
			g_bGamePaused = false;
	}
}

public Action:_Event__PlayerTeam(Handle:event, const String:eventName[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ((client < 1) || (client > MaxClients))
		return;
	new team = GetEventInt(event, "team");
	
	switch(team) {
		case L4D_TEAM_SPECTATOR: {
			g_fClientSpecTime[client] = 0.0;
		}
		case L4D_TEAM_SURVIVOR, L4D_TEAM_INFECTED: {
			g_fClientAfkTime[client] = 0.0;
			g_bClientIsIdle[client] = false;
		}
	}
	if (GetEventBool(event, "disconnected")) {
		g_fClientPos[client] = Float:{ 0.0, 0.0, 0.0 };
		g_fClientAngles[client] = Float:{ 0.0, 0.0, 0.0 };
		g_bClientIsIdle[client] = false;
	}
}

public Action:_Event__RoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast) {
	g_iGameMode = GetGameMode();
	g_iGameType = GetGameType(g_iGameMode);
}

public Action:_Event__RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!g_bEnabled) return;
	
	g_bActive = true;
	for (new i=1; i <= MaxClients; i++)
		g_bClientIsIdle[i] = false;
}

public Action:_Event__RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	g_bActive = false;
}

public Action:_Event__FinalWin(Handle:event, const String:name[], bool:dontBroadcast) {
	g_bActive = false;
}

public Action:_Event__MissionLost(Handle:event, const String:name[], bool:dontBroadcast) {
	g_bActive = false;
}

public ConVarChanged_Enable(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(convar);
	
	if (g_bEnabled) {				// Plugin enabled, turn on (reset) timers if needed..
		if (g_fAdvertiseInterval) {
			if (g_hAdvertiseTimer != INVALID_HANDLE)
				CloseHandle(g_hAdvertiseTimer);
			g_hAdvertiseTimer = CreateTimer(g_fAdvertiseInterval, _Timer__Advertise, _, TIMER_REPEAT);
		}
		if (g_fTimeToSpec || g_fTimeToKick) {
			if (g_hAFKCheckTimer != INVALID_HANDLE)
				CloseHandle(g_hAFKCheckTimer);
			g_hAFKCheckTimer = CreateTimer(g_fCheckInterval, _Timer__CheckIdle, _, TIMER_REPEAT);
		}
	} else {						// Plugin disabled, turn off timers..
		if (g_hAdvertiseTimer != INVALID_HANDLE) {
			CloseHandle(g_hAdvertiseTimer);
			g_hAdvertiseTimer = INVALID_HANDLE;
		}
		if (g_hAFKCheckTimer != INVALID_HANDLE) {
			CloseHandle(g_hAFKCheckTimer);
			g_hAFKCheckTimer = INVALID_HANDLE;
		}
	}
}

public ConVarChanged_ImmuneFlag(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strlen(newValue) != 1) {
		PrintToServer("[AFK Manager] Invalid input: '%s'. Not a flag.", newValue);
		SetConVarString(convar, oldValue);
		return;
	}
	if(!FindFlagByChar(newValue[0], g_afImmuneFlag)) {
		PrintToServer("[AFK Manager] Invalid flag: '%s'.", newValue);
		SetConVarString(convar, oldValue);
		return;
	}
}

public ConVarChanged_Messages(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_iMessageLevel = GetConVarInt(convar);
}

public ConVarChange_AdvertiseInterval(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fAdvertiseInterval = GetConVarFloat(convar);
	
	if (!g_fAdvertiseInterval) {
		if (g_hAdvertiseTimer != INVALID_HANDLE) {
			CloseHandle(g_hAdvertiseTimer);
			g_hAdvertiseTimer = INVALID_HANDLE;
		}
	} else {
		if (g_fAdvertiseInterval < MIN_TIMER) {
			PrintToServer("[AFK Manager] Invalid timer interval (%i). Min = %i.", StringToInt(newValue), MIN_TIMER);
			SetConVarString(convar, oldValue);
			return;
		}
		if (g_hAdvertiseTimer != INVALID_HANDLE)
			CloseHandle(g_hAdvertiseTimer);
		g_hAdvertiseTimer = CreateTimer(g_fAdvertiseInterval, _Timer__Advertise, _, TIMER_REPEAT);
	}
}

public ConVarChanged_TimeToSpec(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fTimeToSpec = GetConVarFloat(convar);
	
	if (g_fTimeToSpec) {
		if (g_fTimeToSpec < MIN_KICK) {
			PrintToServer("[AFK Manager] Invalid time to spec (%i). Min = %i.", StringToInt(newValue), MIN_KICK);
			SetConVarString(convar, oldValue);
			return;
		}
	}
	if (g_fTimeToSpec || g_fTimeToKick) {
		if (g_hAFKCheckTimer != INVALID_HANDLE)
			CloseHandle(g_hAFKCheckTimer);
		g_hAFKCheckTimer = CreateTimer(g_fCheckInterval, _Timer__CheckIdle, _, TIMER_REPEAT);
	}
}

public ConVarChanged_TimeToKick(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fTimeToKick = GetConVarFloat(convar);
	
	if (g_fTimeToKick) {
		if (g_fTimeToKick < MIN_KICK) {
			PrintToServer("[AFK Manager] Invalid time to kick (%i). Min = %i.", StringToInt(newValue), MIN_KICK);
			SetConVarString(convar, oldValue);
			return;
		}
	}
	if (g_fTimeToSpec || g_fTimeToKick) {
		if (g_hAFKCheckTimer != INVALID_HANDLE)
			CloseHandle(g_hAFKCheckTimer);
		g_hAFKCheckTimer = CreateTimer(g_fCheckInterval, _Timer__CheckIdle, _, TIMER_REPEAT);
	}
}

public ConVarChanged_TimerJoinMessage(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fTimerJoinMessage = GetConVarFloat(convar);
}

public ConVarChanged_TimeLeftInterval(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fTimeLeftInterval = GetConVarFloat(convar);
}

public ConVarChanged_IdleTimeMultiple(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fIdleTimeMultiple = GetConVarFloat(convar);
}

public Action:Command_Team(client, args) {
	if ((client < 1) || (client > MaxClients)) {
		ReplyToCommand(client, "[SM] Command is in-game only.");
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(_Menu__Team);
	g_bClientIsIdle[client] = false;
	new team = GetClientTeam(client);
	switch (g_iGameType) {
		case GT_COOP, GT_SURVIVAL: {
			switch (team) {
				case L4D_TEAM_SURVIVOR: {
					SetMenuTitle(menu, "Choose your team:");
					AddMenuItem(menu, "1", "Spectators");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 0);
				}
				default: {		// L4D_TEAM_SPECTATOR
					SetMenuTitle(menu, "Choose your team:");
					AddMenuItem(menu, "2", "Survivors");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 0);
				}
			}
		}
		case GT_VERSUS, GT_SCAVENGE, GT_VS_SURV: {
			switch (team) {
				case L4D_TEAM_SURVIVOR: {
					SetMenuTitle(menu, "Choose your team:");
					AddMenuItem(menu, "1", "Spectators");
					AddMenuItem(menu, "3", "Infected");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 0);
				}
				case L4D_TEAM_INFECTED: {
					SetMenuTitle(menu, "Choose your team:");
					AddMenuItem(menu, "1", "Spectators");
					AddMenuItem(menu, "2", "Survivors");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 0);
				}
				default: {		// L4D_TEAM_SPECTATOR
					SetMenuTitle(menu, "Choose your team:");
					AddMenuItem(menu, "2", "Survivors");
					AddMenuItem(menu, "3", "Infected");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 0);
				}
			}
		}
		default: {		// Next time theres a new mutation type - it will at least give u this option..
			switch (team) {
				case L4D_TEAM_SURVIVOR: {
					SetMenuTitle(menu, "Choose your team:");
					AddMenuItem(menu, "1", "Spectators");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 0);
				}
				default: {		// L4D_TEAM_SPECTATOR
					SetMenuTitle(menu, "Choose your team:");
					AddMenuItem(menu, "2", "Survivors");
					SetMenuExitButton(menu, true);
					DisplayMenu(menu, client, 0);
				}
			}
		}
	}
	return Plugin_Continue;
}

public _Menu__Team(Handle:menu, MenuAction:action, param1, param2) {
	switch(action) {
		case MenuAction_Select: {
			decl String:info[32];
			if (GetMenuItem(menu, param2, info, sizeof(info))) {
				new team = StringToInt(info);
				new bot;
				switch(team) {
					case L4D_TEAM_SPECTATOR: {
						ChangeClientTeam(param1, L4D_TEAM_SPECTATOR);
						g_fClientSpecTime[param1] = 0.0;
					}
					case L4D_TEAM_SURVIVOR: {
						bot = MAX_TEAM_SIZE - FindHumans(L4D_TEAM_SURVIVOR);
						if (bot == 0) {
							PrintToChat(param1, "%s You cannot join that team, it is full already.", TAG);
						} else {
							// See if this fixes the unable to join a team in coop..
							switch (g_iGameType) {
								case GT_COOP, GT_SURVIVAL: {
									// This adds a 5th player..
									//ChangeClientTeam(param1, L4D_TEAM_SURVIVOR);
									SDKCall(g_hSetHumanSpec, bot, param1);
									SDKCall(g_hTakeOverBot, param1, true);
									FakeClientCommand(param1, "jointeam %s", L4D_TEAM_SURVIVOR);
								}
								case GT_VERSUS, GT_SCAVENGE, GT_VS_SURV: {
									SDKCall(g_hSetHumanSpec, bot, param1);
									SDKCall(g_hTakeOverBot, param1, true);
								}
								default: {
									ChangeClientTeam(param1, L4D_TEAM_SURVIVOR);
								}
							}
							g_bClientIsIdle[param1] = false;
							g_fClientAfkTime[param1] = 0.0;
						}
					}
					case L4D_TEAM_INFECTED: {
						bot = MAX_TEAM_SIZE - FindHumans(L4D_TEAM_INFECTED);
						if (bot == 0) {
							PrintToChat(param1, "%s You cannot join that team, it is full already.", TAG);
						} else {
							ChangeClientTeam(param1, L4D_TEAM_INFECTED);
							g_bClientIsIdle[param1] = false;
							g_fClientAfkTime[param1] = 0.0;
						}
					}
				}
			}
		}
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public Action:Command_Idle(client, args) {
	if ((client < 1) || (client > MaxClients)) {
		ReplyToCommand(client, "[SM]Command is in-game only.");
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != L4D_TEAM_SPECTATOR) {
		ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
		g_bClientIsIdle[client] = true;
	} else {
		ReplyToCommand(client, "%s You are already spectating!", TAG);
	}
	return Plugin_Continue;
}

public Action:Command_TeamS(client, args) {
	if ((client < 1) || (client > MaxClients)) {
		ReplyToCommand(client, "[SM] Command is in-game only.");
		return Plugin_Handled;
	}
	new bot = MAX_TEAM_SIZE - FindHumans(L4D_TEAM_SURVIVOR);
	switch (GetClientTeam(client)) {
		case L4D_TEAM_SURVIVOR: {
			ReplyToCommand(client, "%s You are already on that team!", TAG);
		}
		default: {
			if (!bot) {
				ReplyToCommand(client, "%s You cannot join that team, it is full already.", TAG);
			} else {
				switch (g_iGameType) {
					case GT_COOP, GT_SURVIVAL, GT_SP: {
						SDKCall(g_hSetHumanSpec, bot, client);
						SDKCall(g_hTakeOverBot, client, true);
						FakeClientCommand(client, "jointeam %s", L4D_TEAM_SURVIVOR);
					}
					case GT_VERSUS, GT_SCAVENGE, GT_VS_SURV: {
						SDKCall(g_hSetHumanSpec, bot, client);
						SDKCall(g_hTakeOverBot, client, true);
					}
					default: {
						ChangeClientTeam(client, L4D_TEAM_SURVIVOR);
					}
				}
				g_bClientIsIdle[client] = false;
				g_fClientAfkTime[client] = 0.0;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_TeamI(client, args) {
	if ((client < 1) || (client > MaxClients)) {
		ReplyToCommand(client, "[SM] Command is in-game only.");
		return Plugin_Handled;
	}
	
	switch (g_iGameType) {
		case GT_VERSUS, GT_SCAVENGE, GT_VS_SURV: {
			new bot = MAX_TEAM_SIZE - FindHumans(L4D_TEAM_INFECTED);
			switch (GetClientTeam(client)) {
				case L4D_TEAM_INFECTED: {
					ReplyToCommand(client, "%s You are already on that team!", TAG);
				}
				default: {
					if (!bot) {
						ReplyToCommand(client, "%s You cannot join that team, it is full already.", TAG);
					} else {
						ChangeClientTeam(client, L4D_TEAM_INFECTED);
						g_bClientIsIdle[client] = false;
						g_fClientAfkTime[client] = 0.0;
					}
				}
			}
		}
		default: {
			ReplyToCommand(client, "%s You cannot join that team, it is not valid.", TAG);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:_Timer__CheckIdle(Handle:timer) {
	if (!g_bEnabled) return Plugin_Handled;
	if (!g_bActive) return Plugin_Handled;
	
	if (FindConVar("l4d2pause_enabled") != INVALID_HANDLE) {
		if (GetConVarBool(FindConVar("l4d2pause_enabled")))
			g_bGamePaused = true;
		else
			g_bGamePaused = false;
	}
	if (g_bGamePaused) return Plugin_Handled;
	
	for (new client=1; client<=MaxClients; client++) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			new Float:time = GetClientTime(client);
			new team = GetClientTeam(client);
			switch (team) {
				case L4D_TEAM_SPECTATOR: {
					new AdminId:id = GetUserAdmin(client);
					if (id != INVALID_ADMIN_ID && GetAdminFlag(id, g_afImmuneFlag)) {
						if ((time - g_fClientLastMsgTime[client]) >= g_fTimerJoinMessage) {
							PrintToChat(client, "%s Say \x04!team\x01 to choose a team.", TAG);
							g_fClientLastMsgTime[client] = time;
						}
						continue;
					}
					if (g_fTimeToKick != 0.0) {
						g_fClientSpecTime[client] += g_fCheckInterval;
						if (((g_fClientSpecTime[client] >= g_fTimeToKick) && !g_bClientIsIdle[client])
								|| ((g_fClientSpecTime[client] >= (g_fIdleTimeMultiple * g_fTimeToKick)) && g_bClientIsIdle[client])) {
							KickClient(client, "%s You were AFK for too long.. \x04Goodbye\x01!", TAG);
							if (g_iMessageLevel >= 2)
								PrintToChatAll("%s Player: \x04%N\x01 was kicked for being AFK too long.", TAG, client);
							continue;
						}
						if ((time - g_fClientLastMsgTime[client]) >= g_fTimeLeftInterval) {
							if (g_bClientIsIdle[client])
								PrintToChat(client, "%s You can spectate for \x05%d\x01 more seconds before you will be kicked.", TAG, RoundToFloor((g_fIdleTimeMultiple * g_fTimeToKick) - g_fClientSpecTime[client]));
							else
								PrintToChat(client, "%s You can spectate for \x05%d\x01 more seconds before you will be kicked.", TAG, RoundToFloor(g_fTimeToKick - g_fClientSpecTime[client]));
						}
						g_fClientLastMsgTime[client] = time;
					}
					if ((time - g_fClientLastMsgTime[client]) >= g_fTimerJoinMessage) {
						PrintToChat(client, "%s Say \x04!team\x01 to choose a team.", TAG);
						g_fClientLastMsgTime[client] = time;
					}
				}
				case L4D_TEAM_SURVIVOR, L4D_TEAM_INFECTED: {
					if (IsPlayerAlive(client)) {
						new Float:currentPos[3], Float:currentAngles[3];
						GetClientAbsOrigin(client, currentPos);
						GetClientAbsAngles(client, currentAngles);
						// Assume everyone is afk and verify
						new bool:isAFK = true;
						new index;
						for (index=0; index<3; index++) {
							// Did the player move?
							if (currentPos[index] != g_fClientPos[client][index]) {
								isAFK = false;
								g_bClientIsIdle[client] = false;
								break;
							}
							// Did the player look around?
							if (currentAngles[index] != g_fClientAngles[client][index]) {
								isAFK = false;
								g_bClientIsIdle[client] = false;
								break;
							}
						}
						if (isAFK) {
							if (g_fTimeToSpec != 0.0) {
								g_fClientAfkTime[client] += g_fCheckInterval;
								if (g_fClientAfkTime[client] >= g_fTimeToSpec) {
									ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
									if (g_iMessageLevel == 1 || g_iMessageLevel == 3)
										PrintToChatAll("%s Player \x04%N\x01 was moved to the Spectator team.", TAG, client);
								}
							}
						} else {
							g_fClientAfkTime[client] = 0.0;
						}
						for (index=0; index<3; index++) {
							g_fClientPos[client][index] = currentPos[index];
							g_fClientAngles[client][index] = currentAngles[index];
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:_Timer__Advertise(Handle:timer) {
	PrintToChatAll("%s %s", TAG, ads[adIndex++]);
	if (adIndex >= sizeof(ads)) adIndex = 0;
	return Plugin_Continue;
}

static FindHumans(team) {
	new humans = 0;
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			if (GetClientTeam(i) == team)
				humans++;
		}
	}
	return humans;
}
