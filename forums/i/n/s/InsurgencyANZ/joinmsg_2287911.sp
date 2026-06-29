/*
Join Messages (joinmsg.smx) 
Created by [AUR] Ace of Insurgency ANZ

CHANGELOG:
v1.0
* Initial Release
v2.0
* Added CvarEnabled - Ability to turn joinmsg on and off
*/

#include <sourcemod>

#define Plugin_Version "2.0"

new Handle:g_CvarEnabled;

public Plugin:myinfo = {
	name = "Join Messages",
	author = "Insurgency ANZ",
	description = "Notify on Player Join",
	version = Plugin_Version,
	url = "http://www.insurgencyanz.com"
};

public OnPluginStart()
{
	g_CvarEnabled = CreateConVar("sm_joinmsg_enabled","1","Enables(1) or disables(0) the plugin.",FCVAR_NOTIFY);
	AutoExecConfig(true,"plugin.joinmsg");
}

public OnClientPutInServer(client)
{
	if (!GetConVarBool(g_CvarEnabled)) return;
	
	new String:name[32];
	
	GetClientName(client, name, sizeof(name));
	
	PrintToChatAll("%s joined the fight.", name);
}