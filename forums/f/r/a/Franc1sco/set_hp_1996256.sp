#include <sourcemod>
new Handle:g_health = INVALID_HANDLE;

public Plugin:myinfo = {

	name = "Health Giver",
	author = "Blackglade",
	description = "Gives Health",
	version = "1.0",
	url = "RatedAwesome.com"
}

public OnPluginStart()
{
	g_health = CreateConVar("sm_givehealth", "100", "Set Health Given");
	RegConsoleCmd("sm_hp", Command_hp, "Gives Health");
}

public Action:Command_hp(client, args)
{
	if(!client || IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	SetEntityHealth(client, GetConVarInt(g_health))
	ReplyToCommand(client, "You have been given %i health!", GetConVarInt(g_health))
	
	return Plugin_Handled;
}