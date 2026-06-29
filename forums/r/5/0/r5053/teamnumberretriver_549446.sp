/*include includes :) */
#include <sourcemod>
#include <sdktools>


/* define Plugin version */
#define PLUGIN_VERSION "0.0.1"

/* Create Plugin info */
public Plugin:myinfo = 
{
	name = "TeamIdRetriver",
	author = "R-Hehl",
	description = "TeamIdRetriver",
	version = PLUGIN_VERSION,
	url = "http://www.compactaim.de/"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_getteamId", outputid , "Display team Id")
	RegConsoleCmd("sm_getmod", outputmod , "Display team Id")

}

public Action:outputid(client, args)
{
	new teamid = GetClientTeam(client)
	PrintToChat(client, "Team ID: %i",teamid)
 
	return Plugin_Handled
}
public Action:outputmod(client, args)
{
	new String:modname[32]
	GetGameFolderName(modname,sizeof(modname))
	PrintToChat(client, "Modname: %s",modname)
 
	return Plugin_Handled
}