
#include <sourcemod>
#include <chat-processor>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = {
	name = "CAPS",
	author = "MASTEROFTHEXP",
	description = "OH GOD I AM NOT GOOD WITH COMPUTER",
	version = PLUGIN_VERSION,
	url = "HTTP://MSTR.CA/"
};

bool Caps[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegAdminCmd("sm_caps", Command_caps, ADMFLAG_KICK);
	RegAdminCmd("sm_capslock", Command_caps, ADMFLAG_KICK);
	CreateConVar("sm_trolecaps_version", PLUGIN_VERSION, "Plugin Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
}

public void OnClientDisconnect(int client)
{
	Caps[client] = false;
}

public Action Command_caps(int client, int args)
{
	if (args < 1)
	{
		char arg0[25];
		GetCmdArg(0, arg0, sizeof(arg0));
		ReplyToCommand(client, "[SM] Usage: sm_caps <#userid|name>");

		return Plugin_Handled;
	}
	char arg1[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		Caps[target_list[i]] = !Caps[target_list[i]];
		ShowActivity2(client, "[SM] ", "%s capslock on %N.", (Caps[target_list[i]] ? "Enabled" : "Disabled"), target_list[i]); 
		LogAction(client, target_list[i], "[SM] %s capslock on %N.", (Caps[target_list[i]] ? "Enabled" : "Disabled"), target_list[i]); 
	}
	return Plugin_Handled;
}

public Action CP_OnChatMessage(int &author, ArrayList hRecipients, char[] sFlags, char[] sName, char[] sMessage, bool& bProcesscolors, bool& bRemovecolors)
{
	if (!Caps[author]) return Plugin_Continue;
	char len = strlen(sMessage);
	for (int i = 0; i < len; i++)
	{
		if (!IsCharUpper(sMessage[i]))
			sMessage[i] = CharToUpper(sMessage[i]);
	}
	return Plugin_Changed;
}