#include <sourcemod>
#pragma semicolon 1

#define	PLUGIN_VERSION	"1.0"

/* **	****************************************
	*
	*	Plugin:		L4D2 Jockey Blindfold
	*	Author:		Dirka_Dirka ('beta' work by DieTeetasse)
	*	Version:	1.0 
	*
	*	****************************************
	*
	*	Version notes:
	*	1.0	-	Original idea came from http://forums.alliedmods.net/showthread.php?t=122759
	*			I expanded it to have multiple fades that come in and out with different colors.
	*			Also added many more checks to make sure the fade goes away.
	*
	*	****************************************
	*
	***	*/

#define FLAGS_FADE_IN		(0x0001)
#define FLAGS_FADE_OUT	(0x0002 | 0x0008)
#define FLAGS_RESTORE		(0x0002 | 0x0008 | 0x010)
/*
	FFADE_IN		0x0001
	FFADE_OUT		0x0002
	FFADE_STAYOUT	0x0008		// Ignore Duration
	FFADE_PURGE		0x0010		// Kill all other fades
*/

#define TEAM_SURVIVORS	2
#define TEAM_INFECTED		3

new	UserMsg:	g_FadeUserMsgId;
new	Handle:		g_hJockeyRideTimer[MAXPLAYERS + 1]	=	{ INVALID_HANDLE, ... };
new				g_iJockeyRideCount[MAXPLAYERS + 1]	=	{ 0, ... };
new				g_iJockeyRider[MAXPLAYERS + 1];			// Who is riding the victim
new				g_iJockeyVictim[MAXPLAYERS + 1];		// Who is the victim of the rider
new	Float:		g_fJockeyRideDelay;

#define	COLOR_RED		0
#define	COLOR_GREEN	1
#define	COLOR_BLUE	2
#define	COLOR_ALPHA	3
#define	COLOR_NUMBER	4
// This is 'normal' screen
static	g_iFadeIn_colors[COLOR_NUMBER] = {
	0,		// reg
	0,		// green
	0,		// blue
	0		// alpha
};
#define	g_iNum_FadeOut	6
static	g_iFadeOut_colors[g_iNum_FadeOut][COLOR_NUMBER] = {
	{	191,	63,		63,		127 },		// Fade into a red color 50% opaque
	{	0,		0,		0,		191	},		// Fade out from 75% opaque black
	{	127,	31,		31,		230	},		// Fade into dark red, almost opaque
	{	0,		0,		0,		191	},		// Fade out from 75% opaque black
	{	191,	63,		63,		127	},		// Fade into a red color 50% opaque
	{	0,		0,		0,		191	}		// Fade out from 75% opaque black
};

public Plugin:myinfo = {
    name = "[L4D2] Jockey Blindfold",
    author = "Dirka_Dirka",
    description = "Obscures the vision of jockey ride victims, allowing the rider a better chance of getting a 'Qualified Ride'.",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart() {
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1)
		SetFailState("Jockey blind will only work with Left 4 Dead 2!");
	
	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	HookEvent("jockey_killed", Event_JockeyKilled);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("round_end", Event_RoundEnd);
	
	/*
		Used to change the color every time the Jockey does damage..
		Oddly they are both 1 second, and I think the jockey does damage every second.. so uhm.. dunno.
	*/
	new Float:JockeyRideDamageInterval = GetConVarFloat(FindConVar("z_jockey_ride_damage_interval"));
	new Float:JockeyRideDamageDelay = GetConVarFloat(FindConVar("z_jockey_ride_damage_delay"));
	g_fJockeyRideDelay = JockeyRideDamageInterval + JockeyRideDamageDelay;
	
	g_FadeUserMsgId = GetUserMessageId("Fade");
}

public OnClientDisconnect(client) {
	if (g_hJockeyRideTimer[client] != INVALID_HANDLE) {
		KillTimer(g_hJockeyRideTimer[client]);
		g_hJockeyRideTimer[client] = INVALID_HANDLE;
		g_iJockeyRideCount[client] = 0;
		g_iJockeyVictim[client] = 0;
		g_iJockeyRider[client] = 0;
		ClearRider(client);
		RestoreVision(client);
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i=1; i <= MaxClients; i++) {
		if (g_hJockeyRideTimer[i] != INVALID_HANDLE) {
			KillTimer(g_hJockeyRideTimer[i]);
			g_hJockeyRideTimer[i] = INVALID_HANDLE;
			g_iJockeyRideCount[i] = 0;
			g_iJockeyVictim[i] = 0;
			g_iJockeyRider[i] = 0;
			RestoreVision(i);
		}
	}
}

public Action:Event_JockeyRide(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!victim || !attacker)
		return;
	if (!IsClientInGame(victim) || !IsClientConnected(victim) || !IsClientInGame(attacker) || !IsClientConnected(attacker))
		return;
	if (!(GetClientTeam(victim) == TEAM_SURVIVORS) && !(GetClientTeam(attacker) == TEAM_INFECTED))
		return;
	//if (IsFakeClient(victim))
	//	return;
	
	g_iJockeyVictim[attacker] = victim;
	// Blind the victim
	g_iJockeyRideCount[victim] = 0;
	g_iJockeyRider[victim] = attacker;
	// Start the fading right away, then repeat it with the timer
	new time = RoundToZero(g_fJockeyRideDelay);
	DoFade(victim, time, time, false, g_iFadeOut_colors[g_iJockeyRideCount[victim]]);
	g_hJockeyRideTimer[victim] = CreateTimer(g_fJockeyRideDelay, Timer_JockeyRide, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	// Disable his hud for more blinding action
	SetEntProp(victim, Prop_Send, "m_iHideHUD", 64);
}

public Action:Timer_JockeyRide(Handle:timer, any:client) {
	// This checks everything that would/could end a jockey ride or a reason to blind
	if (!IsValidClient(client)) {
		KillTimer(g_hJockeyRideTimer[client]);
		g_hJockeyRideTimer[client] = INVALID_HANDLE;
		g_iJockeyRideCount[client] = 0;
		g_iJockeyVictim[client] = 0;
		g_iJockeyRider[client] = 0;
		ClearRider(client);
		RestoreVision(client);
		return;
	}
	
	g_iJockeyRideCount[client]++;
	if (g_iJockeyRideCount[client] == g_iNum_FadeOut)		// reset the position in the array
		g_iJockeyRideCount[client] = 0;
	
	new time = RoundToZero(g_fJockeyRideDelay);
	DoFade(client, time, time, false, g_iFadeOut_colors[g_iJockeyRideCount[client]]);
}

public Action:Event_JockeyRideEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (!victim)
		return;
	if (!IsClientInGame(victim) || !IsClientConnected(victim))
		return;
	//if (IsFakeClient(victim))
	//	return;
	
	if (g_hJockeyRideTimer[victim] != INVALID_HANDLE) {
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		
		KillTimer(g_hJockeyRideTimer[victim]);
		g_hJockeyRideTimer[victim] = INVALID_HANDLE;
		RestoreVision(victim);
		g_iJockeyRideCount[victim] = 0;
		g_iJockeyVictim[victim] = 0;
		g_iJockeyRider[attacker] = 0;
	}
}

public Action:Event_JockeyKilled(Handle:event, const String:name[], bool:dontBroadcast) {
	new jockey = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_iJockeyVictim[jockey]) {					// Does the jockey have a victim?
		if (g_hJockeyRideTimer[g_iJockeyVictim[jockey]] != INVALID_HANDLE) {	// Is there a timer active on that victim?
			KillTimer(g_hJockeyRideTimer[g_iJockeyVictim[jockey]]);			// Fix the victim
			g_hJockeyRideTimer[g_iJockeyVictim[jockey]] = INVALID_HANDLE;
			RestoreVision(g_iJockeyVictim[jockey]);
			g_iJockeyRideCount[g_iJockeyVictim[jockey]] = 0;
			g_iJockeyRider[g_iJockeyVictim[jockey]] = 0;
		}
		g_iJockeyVictim[jockey] = 0;
	}
}

public Action:Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!victim)
		return;
	if (!IsClientInGame(victim) || !IsClientConnected(victim))
		return;
	if (IsFakeClient(victim))
		return;
	
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (StrContains(weapon, "jockey_claw") == -1)
		return;
	
	if (g_hJockeyRideTimer[victim] != INVALID_HANDLE) {
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		
		KillTimer(g_hJockeyRideTimer[victim]);
		g_hJockeyRideTimer[victim] = INVALID_HANDLE;
		RestoreVision(victim);
		g_iJockeyRideCount[victim] = 0;
		g_iJockeyVictim[victim] = 0;
		g_iJockeyRider[attacker] = 0;
	}
	RestoreVision(victim);
}

static ClearRider(client) {
	for (new i=1; i <= MaxClients; i++) {
		if (g_iJockeyRider[i] == client) {
			g_iJockeyRider[i] = 0;
			break;
		}
	}
}

static RestoreVision(client) {
	//see again
	DoFade(client, 1, 1536, true, g_iFadeIn_colors);
	//hud enable
	SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
}

static DoFade(client, duration, time, bool:restore, colors[COLOR_NUMBER]) {
	new clients[2];
	clients[0] = client;
	
	// This should allow for multiple jockey attacks at once..
	static count[MAXPLAYERS + 1] = { 0, ... };
	count[client]++;
	new FLAGS;
	if (!restore) {
		if (count[client] % 2) {		// Fade In
			FLAGS = FLAGS_FADE_IN;
		} else {						// Fade Out
			FLAGS = FLAGS_FADE_OUT;
		}
	} else {
		FLAGS = FLAGS_RESTORE;
	}
	new Handle:hFadeClient = StartMessageEx(g_FadeUserMsgId, clients, 1);
	
	BfWriteShort(hFadeClient, duration);		// seconds duration to fade
	BfWriteShort(hFadeClient, time);			// seconds duration until reset (fade & hold)
	BfWriteShort(hFadeClient, FLAGS);
	BfWriteByte(hFadeClient, colors[COLOR_RED]);
	BfWriteByte(hFadeClient, colors[COLOR_GREEN]);
	BfWriteByte(hFadeClient, colors[COLOR_BLUE]);
	BfWriteByte(hFadeClient, colors[COLOR_ALPHA]);
	EndMessage();
}

static bool:IsValidClient(client) {
	if (client == 0)
		return false;
	if (!IsClientConnected(client))
		return false;
	//if (IsFakeClient(client))
		//return false;
	if (!IsClientInGame(client))
		return false;
	if (IsPlayerIncapacitated(client))
		return false;
	if (IsPlayerHanging(client))
		return false;
	if (!IsPlayerAlive(client))
		return false;
	if (!IsValidEntity(client))
		return false;
	
	return true;
}

static bool:IsPlayerIncapacitated(client) {
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
		return true;
	return false;
}

static bool:IsPlayerHanging(client) {
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)
			|| GetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1))
		return true;
	return false;
}
