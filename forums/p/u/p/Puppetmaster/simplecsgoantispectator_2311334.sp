#include <dbi>
#include <sourcemod> 
#include <cstrike>
#include <clientprefs>
#include <sdktools>

#define PLUGIN_VERSION "0.0.0"


//begin
public Plugin:myinfo =
{
	name = "SimpleCSGOAntiSpectator",
	author = "Puppetmaster",
	description = "SimpleCSGOAntiSpectator Addon",
	version = PLUGIN_VERSION,
	url = "http://gamingzone.ddns.net/"
};

//called at start of plugin, sets everything up.
public OnPluginStart()
{
	HookEvent("round_poststart", Event_RoundStart) //new round
	HookEvent("round_prestart", Event_RoundStart) //new round
}


public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast){
	move();
	return Plugin_Continue;
}


public move(){
	PrintToServer("New Round, Moving players out of spectator");
	new maxclients = GetMaxClients()
	for(new i=1; i <= maxclients; i++)
	{
		if(IsClientInGame(i)) 
		{
			if(GetClientTeam(i) < 2)
			{
				if(GetUserAdmin(i) == INVALID_ADMIN_ID) ChangeClientTeam(i, GetRandomInt(2, 3)); //move non-admins randomly to t or ct
			}
		}
	}
}

