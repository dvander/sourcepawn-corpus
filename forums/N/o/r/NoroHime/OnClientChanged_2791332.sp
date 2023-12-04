#define PLUGIN_NAME "OnClientChanged"

#pragma newdecls required

#include <sourcemod>

#define isClientIndex(%1) (1 <= %1 <= MaxClients)

public Plugin myinfo = {
	name = "OnClientChanged",
	author = "NoroHime",
	description = "forward void OnClientChanged(int client, int team, int changes)",
	version = "1.0",
};

GlobalForward OnClientChanged;

public void OnPluginStart() {

	OnClientChanged = new GlobalForward("OnClientChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell); //int client, int team, int changes

	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("respawning", OnRespawning);
	HookEvent("player_first_spawn", OnPlayerFirstSpawn);
	HookEvent("player_bot_replace", OnTakeover);
	HookEvent("bot_player_replace", OnTakeover);
}

enum {
	TEAM_CHANGED =	(1 << 0),
	IS_DEATH =		(1 << 1),
	IS_BOT =		(1 << 2),
	IS_SPAWN =		(1 << 3),
	IS_TAKEOVER =	(1 << 4),
	IS_DISCONNECT = (1 << 5),
	IS_CONNECT = 	(1 << 6),
}

public void OnClientPutInServer(int client) {
	MakeForward(client, GetClientTeam(client), IS_CONNECT | (IsFakeClient(client) ? IS_BOT : 0));
}

public void OnPlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (isClientIndex(client))
		MakeForward(client, GetClientTeam(client), IS_SPAWN | (event.GetBool("isbot") ? IS_BOT : 0));
}

public void OnRespawning(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (isClientIndex(client))
		MakeForward(client, GetClientTeam(client), IS_SPAWN | (IsFakeClient(client) ? IS_BOT : 0));
}

public void OnTakeover(Event event, const char[] name, bool dontBroadcast) {

	int bot = GetClientOfUserId(event.GetInt("bot")),
		player = GetClientOfUserId(event.GetInt("player"));

	if (isClientIndex(bot) && isClientIndex(player)) {
		
		if (strcmp(name, "player_bot_replace") == 0)
			MakeForward( bot, GetClientTeam(bot), IS_TAKEOVER | IS_BOT | (IsPlayerAlive(bot) ? 0 : IS_DEATH) );

		if (strcmp(name, "bot_player_replace") == 0)
			MakeForward( player, GetClientTeam(player), IS_TAKEOVER | (IsPlayerAlive(player) ? 0 : IS_DEATH) );
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (isClientIndex(client))
		MakeForward(client, GetClientTeam(client), IS_DEATH | (event.GetBool("victimisbot") ? IS_BOT : 0));
}

public void OnPlayerTeam(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (isClientIndex(client)) {

		int	changes = 0, 
			team_before = event.GetInt("oldteam"),
			team_after = event.GetInt("team");

		if (team_before != team_after)
			changes |= TEAM_CHANGED;

		if (event.GetBool("isbot"))
			changes |= IS_BOT;

		if (event.GetBool("disconnect"))
			changes |= IS_DISCONNECT;

		if (IsClientInGame(client) && !IsPlayerAlive(client))
			changes |= IS_DEATH;
		
		MakeForward(client, team_after, changes);
	}

}


void MakeForward(int client, int team, int changes) {

	Call_StartForward(OnClientChanged);

	Call_PushCell(client);
	Call_PushCell(team);
	Call_PushCell(changes);

	Call_Finish();
}