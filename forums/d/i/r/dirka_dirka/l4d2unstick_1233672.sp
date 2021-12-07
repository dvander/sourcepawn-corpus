#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.1.1"

/*
		These are adjustable
*/
#define MAX_PLAYERS		32
#define	MIN_TELEPORT		3
#define	MAX_TELEPORT		5
/*
		The above is adjustable
*/

/*
	v0-v1.0.6
	Orginial credit goes to Dean Poot for his save teleport locations plugin
	URL: http://forums.alliedmods.net/showthread.php?p=508657
	
	v1.0.7 was re-written by V10
	
	v1.1 (by me) was modified from v1.0.7:
	-	Fixed up 1 if/else if case.. removed 3 or 4 checks, with the poential to skip a couple more.
	-	Fixed another if/else case from 2 possibilites to 3 (with the same number of checks).
	-	Made the teleport somewhat random (x & y only - z should always be up).
	-	Renamed the command from stuck to sm_stuck. This allows you to use sm_stuck in console, as well as !stuck, !sm_stuck, /stuck and /sm_stuck in chat.
	-	Added color the the chat messages
	-	Renamed the global vars and initialized the handles.
	-	Reduced the number of calls on the teleport cvar.
	-	Enforced good code format (with #pragma semicolon 1)
	-	Cleaned up indentation and some un-necessary comments (either from code that no longer exists or because the var name is more clear now).
	v1.1.1
	-	Fixed a typo in Plugin:myinfo.
	-	Changed the desc for l4d2unstick_version.
	-	Changed the format of the timer flags for StuckPluginAnnounce.
	-	Moved the timer from OnMapStart to OnClientPutInServer..
		Also removed the repeating aspect of the timer (I personally will start using the announce now).
	-	The announce convar gets called more often, created a global bool for it to cut down on checks.
	-	Updated OnClientPutInServer to skip bots.
	-	Fixed the !stuck command .. it wasn't decreasing the # of uses..
		it also didn't return anything or fully check the client.
	-	Changed !stuck command to use ReplyToCommand (instead of nothing or PrintToChat)
	-	Changed !unstick to also use ReplyToCommand (consistantly)
	-	Changed the announce message (removed Survivors:).. it works for anyone.
		Also announces how many times you can use the command.
	-	Reduced the delay from 3 to 1 second in !stuck.
	v1.1.2
	-	Fixed invalid client in timer.
*/

static			g_iClientTeleportsRemaining[MAX_PLAYERS];
static			g_iNumOfTeleports;
static	Handle:	g_hPluginAnnounce					=	INVALID_HANDLE;
static	bool:	g_bPluginAnnounce;
static	Handle:	g_hClientDelayTimers[MAX_PLAYERS]	=	{ INVALID_HANDLE, ... };	// Timers for teleport delays on clients

public Plugin:myinfo = {
	name			=	"L4D2 Unstick",
	author			=	"HowIChrgeLazer, V10 & Dirka_Dirka",
	description	=	"Allows players to get themselves unstuck from charger glitches and level clips",
	version			=	PL_VERSION,
	url				=	"http://forums.alliedmods.net/showpost.php?p=1193573&postcount=65"
}

public OnPluginStart() {	
	CreateConVar(
		"l4d2unstick_version", PL_VERSION,
		"L4D2 Unstuck plugin version.",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	
	new Handle:NumOfTeleports = CreateConVar(
		"l4d2unstick_teleports", "2",
		"Amount of times the client can use !stuck per map",
		FCVAR_PLUGIN );
	g_iNumOfTeleports = GetConVarInt(NumOfTeleports);
	g_hPluginAnnounce = CreateConVar(
		"l4d2unstick_announce", "1",
		"Announces at each map start that the !stuck command is available",
		FCVAR_PLUGIN );
	g_bPluginAnnounce = GetConVarBool(g_hPluginAnnounce);
	
	RegConsoleCmd("sm_stuck", Command_Stuck);
	RegAdminCmd("sm_unstick", Command_Unstick, ADMFLAG_GENERIC);
}

public OnClientPutInServer(client) {
	if (!IsFakeClient(client)) {
		g_iClientTeleportsRemaining[client] = g_iNumOfTeleports;
		if(g_bPluginAnnounce)
			CreateTimer(120.0, StuckPluginAnnounce, client);
	}
}

public OnClientDisconnect(client) {
	if (g_hClientDelayTimers[client] != INVALID_HANDLE) {
		KillTimer(g_hClientDelayTimers[client]);
		g_hClientDelayTimers[client] = INVALID_HANDLE;
	}
}

public Action:DelayTeleport(Handle:timer, any:client) {
	g_hClientDelayTimers[client] = INVALID_HANDLE;
	Teleport_User(client);
	g_iClientTeleportsRemaining[client]--;
	// Notify the client that they have been unstuck and take away a teleport use
	if (g_iClientTeleportsRemaining[client] > 1) {
		PrintToChat(client, "\x03[Stuck]\x01 You have been unstuck! You have \x05%i\x01 attempts left this map.", g_iClientTeleportsRemaining[client]);
	} else if (g_iClientTeleportsRemaining[client] == 1) {
		PrintToChat(client, "\x03[Stuck]\x01 You have been unstuck! You have \x05%i\x01 attempt left this map.", g_iClientTeleportsRemaining[client]);
	} else {
		PrintToChat(client, "\x03[Stuck]\x01 You have been unstuck! However, you are \x05out of uses\x01 for this command until the next map.");
	}
}

public Action:Command_Stuck(client, args) {
	if ((client < 1) || (client > MaxClients)) {
		ReplyToCommand(client, "Command is in-game only.");
		return Plugin_Handled;
	}
	
	// We're checking for client to say !stuck here, also check if client is hanging from a ledge
	new CheckLedge = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	if (CheckLedge) {
		ReplyToCommand(client, "You cannot use !stuck right now!");
		return Plugin_Handled;
	}
	
	if (g_iClientTeleportsRemaining[client] > 0) {
		ReplyToCommand(client, "Unsticking in 1 second...");
		g_hClientDelayTimers[client] = CreateTimer(1.0, DelayTeleport, client);
	} else {
		ReplyToCommand(client, "You are out of teleports this round!");
	}
	return Plugin_Handled;
}

public Action:Command_Unstick(client, args) {	
	if (args < 1) {
		ReplyToCommand(client, "Usage: sm_unstick <name>");
		return Plugin_Handled;
	}
	
	/* Get the first argument */
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	/* Try and find a matching player */
	new target = FindTarget(client, arg1);
	if (target == -1) {
	/*
		FindTarget() automatically replies with the failure reason.
	*/
		return Plugin_Handled;
	}
	
	Teleport_User(target);
	ReplyToCommand(client, "You unstuck %N.", target);
	return Plugin_Handled;
}

public Action:StuckPluginAnnounce(Handle:timer, any:client) {
	if (IsClientInGame(client))
		PrintToChat(client, "\x03[Stuck]\x01 If you become glitched and unable to move, type \x04!stuck\x01 (\x05%i\x01 uses per map) during the round to free yourself.", g_iNumOfTeleports);
}

stock Teleport_User(client) {
	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);
	// Randomly move + or -
	new distance = GetRandomInt(MIN_TELEPORT, MAX_TELEPORT);
	if (GetRandomInt(0, 1))
		Origin[0] = Origin[0] + distance;
	else
		Origin[0] = Origin[0] - distance;
	if (GetRandomInt(0, 1))
		Origin[1] = Origin[1] + distance;
	else
		Origin[1] = Origin[1] - distance;
	// Don't move down in the z-axis.. will either make the stuck worse, or fall through map
	Origin[2] = Origin[2] + distance;
	
	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(client, MOVETYPE_WALK);  
}
