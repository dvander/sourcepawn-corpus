


public Plugin myinfo = 
{
	name = "[CSS/CSP/CSGO/TF2] Autorespawn",
	author = "shavit",
	description = "Autorespawn for CSS, CS:GO, TF2, CSPROMOD",
	version = "1.4 - 12.02.2022"
};

ConVar sm_autorespawn_enabled;
ConVar sm_autorespawn_message;
ConVar sm_autorespawn_time;

enum {
	none,
	cs,
	tf
}

int game;

#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2>
#define REQUIRE_EXTENSIONS

public void OnPluginStart()
{
	char modfolder[20];

	GetGameFolderName(modfolder, sizeof(modfolder));

	if(StrEqual(modfolder, "csgo", false) || StrEqual(modfolder, "cstrike", false))
	{
		game = cs;
	}
	else if(StrEqual(modfolder, "tf", false))
	{
		game = tf;

		// player_changeclass ??
		HookEventEx("player_class", player_death);
	}

	if(!game)
	{
		SetFailState("This respawn plugin is made for team fortress and Counter-Strike");
	}

	sm_autorespawn_enabled = CreateConVar("sm_autorespawn_enabled", "1", "Autorespawn enabled?", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_autorespawn_message = CreateConVar("sm_autorespawn_message", "1", "Message the player that he will respawn?", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_autorespawn_time = CreateConVar("sm_autorespawn_time", "0.0", "Time to wait before autorespawn. [Float] [0.0 - Instant]", FCVAR_NONE, true, 0.0, true, 300.0);

	HookEvent("player_death", player_death);

	AutoExecConfig(true, "autorespawn");
}


public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_autorespawn_enabled.BoolValue)
		return;

	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);

	// in some games, when player disconnect, it kill player after.
	if(!victim || !IsClientInGame(victim))
		return;

	float delay = sm_autorespawn_time.FloatValue;

	CreateTimer(delay, timer_delay, userid);

	if(sm_autorespawn_message.BoolValue && delay >= 1.0)
	{
		PrintHintText(victim, "You'll respawn in %.1f seconds.", delay);
	}
}

public Action timer_delay(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(!client || !IsClientInGame(client) || GetClientTeam(client) <= 1)
		return Plugin_Continue;


	if(game == tf)
	{
		TF2_RespawnPlayer(client);
	}
	else
	{
		CS_RespawnPlayer(client);
	}

	if(sm_autorespawn_message.BoolValue)
		PrintHintText(client, "Successfully respawned!");

	return Plugin_Continue;
}