#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "0.3.8"

public Plugin:myinfo = {
	name        = "disable_kill",
	author      = "Doktor",
	description = "Disable the Kill and explode command for TF2.",
	version     = PL_VERSION,
	url         = "http://iron.site.nfoservers.com/sourcemod_plugins/disable_kill.zip"
};

public OnPluginStart()
{
	//translation
	LoadTranslations("disable_kill.phrases");
	// hooks
	RegConsoleCmd("kill", cmd_kill);
	RegConsoleCmd("explode", cmd_explode);
}

public Action:cmd_kill(client, args) {
	PrintToChat(client, "\x04[SourceMod] %t", "You are not allowed to kill yourself");
	return Plugin_Handled;
}

public Action:cmd_explode(client, args) {
	PrintToChat(client, "\x03[SourceMod] %t", "You are not allowed to explode yourself");
	return Plugin_Handled;
}