#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.7"

public Plugin:myinfo =
{
	name = "ci forceteam",
	author = "SMM forums_mega_MrG",
	description = "Force player into a team as soon as they connect.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar ("sm_ci_forceteam_version", PLUGIN_VERSION, "ci forceteam Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
}

public OnClientPutInServer(client)
{
	new iBluTeam = GetTeamClientCount(2);
	new iRedTeam = GetTeamClientCount(3);
	
	if(iBluTeam > iRedTeam)
	{
		ChangeClientTeam(client, 3);
		FakeClientCommand(client, "joinclass %s", "random");
	}
	else if (iRedTeam > iBluTeam)
	{
		ChangeClientTeam(client, 2);
		FakeClientCommand(client, "joinclass %s", "random");
	}
	else if (iBluTeam == iRedTeam)
	{
		ChangeClientTeam(client, GetRandomInt(2, 3));
		FakeClientCommand(client, "joinclass %s", "random");
	}}
