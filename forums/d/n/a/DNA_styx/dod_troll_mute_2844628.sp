#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

// Mute tracking
bool    g_bMuted[MAXPLAYERS + 1];
Handle  g_hMuteTimer[MAXPLAYERS + 1];

// ConVars
ConVar  g_cvEnabled;
ConVar  g_cvDuration;
ConVar  g_cvWhitelistMedic;
ConVar  g_cvTargets;
ConVar  g_cvNotify;

public Plugin myinfo =
{
	name        = "Troll Mute",
	author      = "Claude.ai guided by DNA.styx",
	description = "Suppresses voice commands from players after they kill someone",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/DNA-styx/DoDS-Plugins"
};

public void OnPluginStart()
{
	LoadTranslations("dod_troll_mute.phrases");

	CreateConVar("dod_troll_mute_version", PLUGIN_VERSION,
		"Troll Mute version",
		FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

	g_cvEnabled = CreateConVar("dod_troll_mute_enabled", "1",
		"Enable or disable the plugin",
		FCVAR_NOTIFY,
		true, 0.0,
		true, 1.0);

	g_cvDuration = CreateConVar("dod_troll_mute_duration", "3",
		"Duration (seconds) to suppress voice commands after a kill",
		FCVAR_NOTIFY,
		true, 0.0,
		true, 10.0);

	g_cvWhitelistMedic = CreateConVar("dod_troll_mute_whitelist_medic", "1",
		"Allow voice_medic to bypass the mute",
		FCVAR_NOTIFY,
		true, 0.0,
		true, 1.0);

	g_cvTargets = CreateConVar("dod_troll_mute_targets", "0",
		"Mute trigger: 0=human kills only, 1=all kills including bots",
		FCVAR_NOTIFY,
		true, 0.0,
		true, 1.0);

	g_cvNotify = CreateConVar("dod_troll_mute_notify", "0",
		"Notify player when their voice command is suppressed",
		FCVAR_NOTIFY,
		true, 0.0,
		true, 1.0);

	AutoExecConfig(true, "dod_troll_mute");

	HookEvent("player_death", Event_PlayerDeath);

	// Global listener — fires on every client command.
	// We filter for voice_ prefix inside the callback.
	// This avoids maintaining a hardcoded list of DoD:S voice commands.
	AddCommandListener(CommandListener_VoiceCommand);
}

public void OnClientDisconnect(int client)
{
	if (g_hMuteTimer[client] != null)
	{
		KillTimer(g_hMuteTimer[client]);
		g_hMuteTimer[client] = null;
	}
	g_bMuted[client] = false;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim   = GetClientOfUserId(event.GetInt("userid"));

	// Invalid or self-kill
	if (attacker <= 0 || victim <= 0 || attacker == victim)
		return Plugin_Continue;

	// Attacker must be in-game and human
	if (!IsClientInGame(attacker) || IsFakeClient(attacker))
		return Plugin_Continue;

	// Victim must be in-game
	if (!IsClientInGame(victim))
		return Plugin_Continue;

	// Check target filter: 0 = human kills only
	if (g_cvTargets.IntValue == 0 && IsFakeClient(victim))
		return Plugin_Continue;

	MutePlayer(attacker);

	return Plugin_Continue;
}

void MutePlayer(int client)
{
	// Already muted — reset the timer
	if (g_bMuted[client] && g_hMuteTimer[client] != null)
		KillTimer(g_hMuteTimer[client]);

	g_bMuted[client] = true;
	g_hMuteTimer[client] = CreateTimer(g_cvDuration.FloatValue, Timer_UnmutePlayer, GetClientUserId(client));
}

public Action Timer_UnmutePlayer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if (client > 0)
	{
		g_bMuted[client] = false;
		g_hMuteTimer[client] = null;
	}

	return Plugin_Stop;
}

public Action CommandListener_VoiceCommand(int client, const char[] command, int argc)
{
	// Only act on voice_ commands
	if (strncmp(command, "voice_", 6, false) != 0)
		return Plugin_Continue;

	if (client <= 0 || !IsClientInGame(client))
		return Plugin_Continue;

	if (!g_cvEnabled.BoolValue)
		return Plugin_Continue;

	if (!g_bMuted[client])
		return Plugin_Continue;

	// Allow voice_medic if whitelisted
	if (g_cvWhitelistMedic.BoolValue && StrEqual(command, "voice_medic", false))
		return Plugin_Continue;

	// Notify the player
	if (g_cvNotify.BoolValue)
		PrintToChat(client, "\x01\x04[Troll Mute]\x01 %t", "Voice Suppressed");

	return Plugin_Handled;
}
