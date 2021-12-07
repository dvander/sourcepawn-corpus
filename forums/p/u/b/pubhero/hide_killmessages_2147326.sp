#include <sourcemod>

new Handle:cvar_enable;
new bool:enable;

public Plugin:myinfo =
{ 
	name = "Hide kill messages plugin",
	author = "unknown",
	description = "Allows you to hide kill messages",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=180270"
}

public OnPluginStart()
{
	cvar_enable = CreateConVar("sm_hud_deathnotice", "0", "Enable/Disable to show players hud kill messages", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(cvar_enable, cvar_changed);
	cvar_changed(cvar_enable, "", "");
	AutoExecConfig(true, "hide_killmessages");

	HookEvent("player_death", death, EventHookMode_Pre);
}

public cvar_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	enable = GetConVarBool(cvar_enable);
}

public Action:death(Handle:event, const String:name[], bool:dontBroadcast)
{
	return enable ? Plugin_Continue:Plugin_Handled;
}
