#include <sourcemod>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.3"

public Plugin:myinfo =
{
	name = "Show my Spectators",
	author = "Die Teetasse",
	description = "This plugin will show a player who is spectating him.",
	version = PLUGIN_VERSION,
	url = ""
};

/*
 * ############################################
 * Plugin history:
 * ############################################
 *
 * v1.4:
 * - deleted unnecessary variable
 * - fixed error 18: Heap memory leaked by native
 *
 * v1.3:
 * - added cvar to change behavior if infected player will be listed as specs
 * - fixed dead bots spectating someone
 * - added game check
 *
 * v1.2:
 * - added cvar to change hud update interval
 * - added version cvar
 * - added spectator panel for bot player
 *
 * v1.1:
 * - added panel for spectators to see who is watching this player too
 * - fixed teamchat hud toggle not working 
 * 
 */
 
new bool:isHudActive[MAXPLAYERS+1];
new Handle:cvarHudUpdateInterval;
new Handle:cvarListInfectedAsSpecs;

/*
 * Init array at plugin start and hook commands
 */
public OnPluginStart() {
	// check game
	decl String:gameFolder[12];
	GetGameFolderName(gameFolder, sizeof(gameFolder));
	if (StrContains(gameFolder, "left4dead") == -1) SetFailState("Show my Spectators work with Left 4 Dead 1 or 2 only!");

	// create cvars
	CreateConVar("l4d_showmyspecs_version", PLUGIN_VERSION, "Show my Spectators - Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	cvarHudUpdateInterval = CreateConVar("l4d_showmyspecs_update_interval", "5.0", "Show my Spectators - Hud update interval in seconds.", CVAR_FLAGS, true, 0.5);
	cvarListInfectedAsSpecs = CreateConVar("l4d_showmyspecs_list_infected_as_specs", "1", "Show my Spectators - List dead infected as spectators. (0 = no, 1 = yes)", CVAR_FLAGS);
	
	// hook console commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	// activate hud for everybody
	for (new i = 0; i < MAXPLAYERS+1; i++) {
		isHudActive[i] = true;
	}
}

/*
 * ############################################
 * Spec hud toggle functions
 * ############################################
 */
 
/*
 * Check for !myspecs
 */
public Action:Command_Say(client, args) {
	if (args < 1) {
		return Plugin_Continue;
	}
	
	// get text
	decl String:text[10];
	GetCmdArg(1, text, sizeof(text));
	
	// check text
	if (StrContains(text, "!myspecs") == 0) {
		ToggleHud(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}	

/*
 * Toggle hud active/inactive for a client
 */
ToggleHud(client) {
	if (isHudActive[client]) {
		isHudActive[client] = false;
		PrintToChat(client, "[SM] Deactivated My Spec Hud");
	}
	else {
		isHudActive[client] = true;
		PrintToChat(client, "[SM] Activated My Spec Hud");
	}
}

/*
 * Reset hud to active
 */
public OnClientDisconnect(client) {
	isHudActive[client] = true;
}

/*
 * ############################################
 * Spec hud print functions
 * ############################################
 */

/*
 * Start update timer in 10 seconds
 */
public OnMapStart() {
	CreateTimer(10.0, Timer_WaitingForPlayers, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

/*
 * Timer to start the update timer
 */
public Action:Timer_WaitingForPlayers(Handle:timer) {
	CreateTimer(GetConVarFloat(cvarHudUpdateInterval), Timer_UpdateHud, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

/*
 * Update hud for every player 
 */
public Action:Timer_UpdateHud(Handle:timer) {
	new bool:isBot[MaxClients];
	new bool:isSpec[MaxClients];
	new botCount = 0;
	new clientCount = 0;
	new clientId[MaxClients];
	new clientTeam[MaxClients];
	new specMode[MaxClients];
	new specTarget[MaxClients];
	
	// gather informations about users
	for (new i = 1; i < MaxClients+1; i++) {
		if (!IsClientInGame(i)) continue;
		
		clientId[clientCount] = i;
		clientTeam[clientCount] = GetClientTeam(i);
		isBot[clientCount] = IsFakeClient(i);
		isSpec[clientCount] = IsClientObserver(i);
		specMode[clientCount] = GetEntPropEnt(i, Prop_Send, "m_iObserverMode");
		specTarget[clientCount] = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
		
		if (isBot[clientCount]) botCount++;
		clientCount++;
	}
	
	// any client? if not next check in 30 seconds and stop this timer
	if ((clientCount - botCount) == 0) {
		CreateTimer(30.0, Timer_WaitingForPlayers, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	
	// declaration of variables for the loops (fixing heap memory error)
	new Handle:activePanel;
	new Handle:specPanel;
	decl String:panelTitle[128];
	decl String:panelText[128];
	new activeSpecs[clientCount];
	new activeSpecsCount;
	
	// loop through players
	for (new activePlayer = 0; activePlayer < clientCount; activePlayer++) {
		// spectator? NEXT!
		if (isSpec[activePlayer]) continue;
		
		// hud deactivated?
		if (!isHudActive[clientId[activePlayer]]) continue;
		
		// create active player panel
		activePanel = CreatePanel();
		SetPanelTitle(activePanel, "Your spectators:");
		
		// create spec title string
		Format(panelTitle, sizeof(panelTitle), "%N's spectators:", clientId[activePlayer]);
		
		// create spectaor of him panel
		specPanel = CreatePanel();
		SetPanelTitle(specPanel, panelTitle);
		
		for (new i = 0; i < clientCount; i++) activeSpecs[i] = 0;
		activeSpecsCount = 0;
		
		// search people spectating him
		for (new specPlayer = 0; specPlayer < clientCount; specPlayer++) {
			// not spectator?
			if (!isSpec[specPlayer]) continue;	
			// human?
			if (isBot[specPlayer]) continue;
			// spectating him?
			if (specTarget[specPlayer] != clientId[activePlayer]) continue;
			// really him? (mode: 6 == free look)
			if (specMode[specPlayer] == 6) continue;
			
			// list dead infected + is he infected?
			if (!GetConVarBool(cvarListInfectedAsSpecs) && clientTeam[specPlayer] == 3) continue;
			
			Format(panelText, sizeof(panelText), "%s - %N (%s)", (clientTeam[specPlayer] == 1) ? "SPEC" : "DEAD", clientId[specPlayer], (specMode[specPlayer] == 5) ? "3rd" : "1st");
			DrawPanelText(activePanel, panelText);
			DrawPanelText(specPanel, panelText);
			
			// save spec for spec hud
			activeSpecs[activeSpecsCount] = specPlayer;
			activeSpecsCount++;
		}
		
		// nothing to draw? NEXT!
		if (activeSpecsCount < 1) {
			CloseHandle(activePanel);
			CloseHandle(specPanel);
			
			continue;
		}
		
		// draw say command text
		DrawPanelText(activePanel, "-- toggle hud with !myspecs");
		DrawPanelText(specPanel, "-- toggle hud with !myspecs");
		
		// draw panel of active player (if human)
		if (!isBot[activePlayer]) SendPanelToClient(activePanel, clientId[activePlayer], PanelHandler, 5);
		
		// draw panel of specs
		for (new index = 0; index < activeSpecsCount; index++) {
				if (!isHudActive[clientId[activeSpecs[index]]]) continue;
				SendPanelToClient(specPanel, clientId[activeSpecs[index]], PanelHandler, 5);
		}
		
		// destroy panels
		CloseHandle(activePanel);
		CloseHandle(specPanel);
	}
	
	return Plugin_Continue;
}

/*
 * Panel answer handler
 */
public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	// nothing to do
}