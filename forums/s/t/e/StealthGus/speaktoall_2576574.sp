#pragma semicolon 1

#define PLUGIN_NAME "Speak To All"
#define PLUGIN_AUTHOR "Gabriel Hirakawa"
#define PLUGIN_DESCRIPTION "Allows admins to speak to all players on command"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "https://gkh.systems"
#define UPDATE_URL "https://gkh.systems/git/SpeakToAll/update.txt"

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required

bool g_bSpeakingToAll[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
  RegAdminCmd("sm_speaktoall", Command_SpeakToAll, ADMFLAG_KICK, "sm_speaktoall - Allows Admins to speak to all players ");
}

public Action Command_SpeakToAll(int client, int args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
	{
		PrintToServer("[SM] Usage: Clients not in game cannot use the speaktoall command.");
		return Plugin_Continue;
	}

	if(g_bSpeakingToAll[client])
	{
		g_bSpeakingToAll[client] = false;
		SetClientListeningFlags(client, VOICE_NORMAL);
		ReplyToCommand(client, "[SM] You will no longer speak to all players.");
	}
	else
	{
		g_bSpeakingToAll[client] = true;
		SetClientListeningFlags(client, VOICE_SPEAKALL);
		ReplyToCommand(client, "[SM] You will now speak to all players.");
	}

	return Plugin_Handled;
}
