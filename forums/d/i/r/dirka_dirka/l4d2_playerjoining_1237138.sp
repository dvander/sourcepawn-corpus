#pragma semicolon	1
#include <sourcemod>
/*
	This is basically a fixed version of: http://forums.alliedmods.net/showthread.php?t=118503
	With added features:
		Color in messages.
		Delayed messages to be less spammy (so you don't see Player X joined spectators, Player X joined infected).
	
	Version History:
	1.0		Initial release
	1.0.1	Fixed a string format error.
			Removed potential fake client team change reports (do bots change teams?).
			Verify userid = clientid after timer.
*/
#define		PLUGIN_VERSION		"1.0.1"
#define		TAG_INFO			"\x03[Join]\x01"
#define		TEAM_SPECTATORS	1
#define		TEAM_SURVIVORS		2
#define		TEAM_INFECTED		3

static	Handle:	hTimer_ClientTeamChange[MAXPLAYERS+1]		=	{ INVALID_HANDLE, ... };

public Plugin:myinfo = {
	name			=	"[L4D2] Player Join Messages",
	author			=	"Dirka_Dirka",
	description	=	"Informs other players when a client connects to the server and changes teams.",
	version			=	PLUGIN_VERSION,
	url				=	"http://forums.alliedmods.net/showthread.php?t=132188"
}

public OnPluginStart() {
	CreateConVar(
		"l4d2_playerjoin_version", PLUGIN_VERSION,
		"Version of the [L4D2] Player Join Messages plugin.",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	HookEvent("player_team", _Event__Player_Team);
}

public OnClientConnected(client) {
	if (IsValidPlayer(client)) {
		if (!IsFakeClient(client)) {
			PrintToChatAll("%s \x04%N\x01 has connected to the server.", TAG_INFO, client);
			hTimer_ClientTeamChange[client] = INVALID_HANDLE;
		}
	}
}

public OnClientDisconnect(client) {
	if (IsValidPlayer(client)) {
		if (hTimer_ClientTeamChange[client] != INVALID_HANDLE) {
			KillTimer(hTimer_ClientTeamChange[client]);
			hTimer_ClientTeamChange[client] = INVALID_HANDLE;
		}
		// This isn't needed unless valve breaks something else..
		//if (!IsFakeClient(client))
		//	PrintToChatAll("%s \x04%N\x01 has left the server.", TAG_INFO, client);
	}
}

public Action:_Event__Player_Team(Handle:event, String:event_name[], bool:dontBroadcast) {
	new player_id = GetEventInt(event, "userid");
	new player = GetClientOfUserId(player_id);
	if (IsValidPlayer(player)) {
		if (!IsFakeClient(player)) {
			new team = GetEventInt(event, "team");
			new Handle:pack;
			// If the player has just changed teams recently..
			if (hTimer_ClientTeamChange[player] != INVALID_HANDLE)
				KillTimer(hTimer_ClientTeamChange[player]);
			hTimer_ClientTeamChange[player] = CreateDataTimer(1.0, _Timer__AnnounceJoining, pack);
			WritePackCell(pack, player_id);
			WritePackCell(pack, player);
			WritePackCell(pack, team);
		}
	}
}

public Action:_Timer__AnnounceJoining(Handle:timer, Handle:pack) {
	ResetPack(pack);
	new player_id = ReadPackCell(pack);
	new player = ReadPackCell(pack);
	new team = ReadPackCell(pack);
	if (GetClientOfUserId(player_id) == player) {	// if not, then it is somehow a different player
		hTimer_ClientTeamChange[player] = INVALID_HANDLE;
		if (IsClientInGame(player)) {		// if the client disconnected during the timer - stop.
			switch (team) {
				case TEAM_SPECTATORS:	{ PrintJoinToAll(player, TEAM_SPECTATORS); }
				case TEAM_SURVIVORS:	{ PrintJoinToAll(player, TEAM_SURVIVORS); }
				case TEAM_INFECTED:	{ PrintJoinToAll(player, TEAM_INFECTED); }
			}
		}
	}
}

static PrintJoinToAll(const player, const team) {
	decl String:sTeam[24];
	switch (team) {
		case TEAM_SPECTATORS:	{ Format(sTeam, sizeof(sTeam), "\x05Spectators\x01"); }
		case TEAM_SURVIVORS:	{ Format(sTeam, sizeof(sTeam), "\x05Survivors\x01"); }
		case TEAM_INFECTED:	{ Format(sTeam, sizeof(sTeam), "\x05Infected\x01"); }
	}
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (!IsFakeClient(i)) {
				if (i != player)
					PrintToChat(i, "%s \x04%N\x01 has joined the %s.", TAG_INFO, player, sTeam);
				//else
				//	PrintToChat(i, "%s You join the %s.", TAG_INFO, sTeam);
			}
		}
	}
}

static bool:IsValidPlayer(client) {
	if (0 < client <= MaxClients)
		return true;
	return false;
}
