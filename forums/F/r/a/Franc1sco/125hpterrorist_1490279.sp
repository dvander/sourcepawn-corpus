
#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define VERSION "v1.0"

public Plugin:myinfo =
{
	name = "SM 125 HP Terrorist",
	author = "Franc1sco Steam: franug",
	description = "Set 125 HP for All Terrorist",
	version = VERSION,
	url = "http://servers-cfg.foroactivo.com/"
}

public OnPluginStart()
{
	CreateConVar("sm_125hpterrorist", VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("player_spawn", Event_PlayerSpawn);


}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

        if (GetClientTeam(client) == CS_TEAM_T)
        {
           SetEntityHealth(client, 125);
        }
}
// Very Easy :D